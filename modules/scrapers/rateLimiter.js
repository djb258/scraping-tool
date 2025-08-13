class RateLimiter {
  constructor(options = {}) {
    this.limits = {
      global: {
        requests: options.globalRequests || 100,
        perSeconds: options.globalPerSeconds || 60,
        burst: options.globalBurst || 10
      },
      perDomain: options.perDomain || {},
      perApi: {
        apollo: { requests: 50, perSeconds: 60 },
        linkedin: { requests: 30, perSeconds: 60 },
        instantly: { requests: 100, perSeconds: 60 },
        googlemaps: { requests: 25, perSeconds: 60 },
        ...options.perApi
      }
    };

    this.queues = new Map();
    this.history = new Map();
    this.blocked = new Map();
    this.stats = {
      totalRequests: 0,
      throttledRequests: 0,
      blockedRequests: 0,
      queuedRequests: 0
    };
  }

  async acquire(identifier, type = 'global') {
    const limit = this.getLimit(identifier, type);
    const queue = this.getOrCreateQueue(identifier);
    const history = this.getOrCreateHistory(identifier);

    if (this.isBlocked(identifier)) {
      this.stats.blockedRequests++;
      throw new Error(`Rate limit blocked for ${identifier} until ${this.blocked.get(identifier)}`);
    }

    return new Promise((resolve, reject) => {
      queue.push({ resolve, reject, timestamp: Date.now() });
      this.stats.queuedRequests++;
      this.processQueue(identifier, limit);
    });
  }

  async processQueue(identifier, limit) {
    const queue = this.queues.get(identifier);
    const history = this.history.get(identifier);

    if (!queue || queue.length === 0) return;

    const now = Date.now();
    const windowStart = now - (limit.perSeconds * 1000);
    
    history.requests = history.requests.filter(time => time > windowStart);

    if (history.requests.length >= limit.requests) {
      const oldestRequest = history.requests[0];
      const waitTime = (oldestRequest + limit.perSeconds * 1000) - now;
      
      if (waitTime > 0) {
        this.stats.throttledRequests++;
        setTimeout(() => this.processQueue(identifier, limit), waitTime);
        return;
      }
    }

    const burstWindow = now - 1000;
    const recentRequests = history.requests.filter(time => time > burstWindow);
    
    if (limit.burst && recentRequests.length >= limit.burst) {
      setTimeout(() => this.processQueue(identifier, limit), 100);
      return;
    }

    const request = queue.shift();
    if (request) {
      history.requests.push(now);
      history.lastRequest = now;
      this.stats.totalRequests++;
      this.stats.queuedRequests--;
      request.resolve();
      
      if (queue.length > 0) {
        const minInterval = (limit.perSeconds * 1000) / limit.requests;
        setTimeout(() => this.processQueue(identifier, limit), minInterval);
      }
    }
  }

  getLimit(identifier, type) {
    if (type === 'domain' && this.limits.perDomain[identifier]) {
      return this.limits.perDomain[identifier];
    }
    if (type === 'api' && this.limits.perApi[identifier]) {
      return this.limits.perApi[identifier];
    }
    return this.limits.global;
  }

  getOrCreateQueue(identifier) {
    if (!this.queues.has(identifier)) {
      this.queues.set(identifier, []);
    }
    return this.queues.get(identifier);
  }

  getOrCreateHistory(identifier) {
    if (!this.history.has(identifier)) {
      this.history.set(identifier, {
        requests: [],
        lastRequest: 0
      });
    }
    return this.history.get(identifier);
  }

  block(identifier, durationMs = 60000) {
    const unblockTime = new Date(Date.now() + durationMs);
    this.blocked.set(identifier, unblockTime);
    
    setTimeout(() => {
      this.blocked.delete(identifier);
      console.log(`[R] Unblocked ${identifier}`);
    }, durationMs);
    
    console.log(`[R] Blocked ${identifier} until ${unblockTime.toISOString()}`);
  }

  unblock(identifier) {
    this.blocked.delete(identifier);
    console.log(`[R] Manually unblocked ${identifier}`);
  }

  isBlocked(identifier) {
    if (!this.blocked.has(identifier)) return false;
    
    const unblockTime = this.blocked.get(identifier);
    if (Date.now() > unblockTime.getTime()) {
      this.blocked.delete(identifier);
      return false;
    }
    
    return true;
  }

  updateLimit(identifier, type, newLimit) {
    if (type === 'domain') {
      this.limits.perDomain[identifier] = newLimit;
    } else if (type === 'api') {
      this.limits.perApi[identifier] = newLimit;
    } else if (type === 'global') {
      this.limits.global = newLimit;
    }
    console.log(`[B] Updated rate limit for ${identifier}:`, newLimit);
  }

  getQueueSize(identifier) {
    const queue = this.queues.get(identifier);
    return queue ? queue.length : 0;
  }

  getStats() {
    const queueSizes = {};
    for (const [id, queue] of this.queues.entries()) {
      queueSizes[id] = queue.length;
    }

    return {
      ...this.stats,
      activeQueues: this.queues.size,
      blockedIdentifiers: this.blocked.size,
      queueSizes
    };
  }

  reset(identifier = null) {
    if (identifier) {
      this.queues.delete(identifier);
      this.history.delete(identifier);
      this.blocked.delete(identifier);
    } else {
      this.queues.clear();
      this.history.clear();
      this.blocked.clear();
      this.stats = {
        totalRequests: 0,
        throttledRequests: 0,
        blockedRequests: 0,
        queuedRequests: 0
      };
    }
    console.log(`[R] Rate limiter reset ${identifier || 'all'}`);
  }
}

class SmartThrottler {
  constructor(options = {}) {
    this.rateLimiter = new RateLimiter(options.rateLimits);
    this.adaptive = options.adaptive !== false;
    this.backoffMultiplier = options.backoffMultiplier || 2;
    this.maxBackoff = options.maxBackoff || 60000;
    this.responseTimeThreshold = options.responseTimeThreshold || 5000;
    
    this.metrics = new Map();
    this.adjustmentInterval = options.adjustmentInterval || 30000;
    
    if (this.adaptive) {
      this.startAdaptiveAdjustment();
    }
  }

  async throttle(identifier, type = 'global', fn) {
    await this.rateLimiter.acquire(identifier, type);
    
    const startTime = Date.now();
    let result, error;
    
    try {
      result = await fn();
      this.recordSuccess(identifier, Date.now() - startTime);
    } catch (err) {
      error = err;
      this.recordFailure(identifier, err);
    }
    
    if (this.adaptive) {
      this.adjustRateLimit(identifier, type);
    }
    
    if (error) throw error;
    return result;
  }

  recordSuccess(identifier, responseTime) {
    const metrics = this.getOrCreateMetrics(identifier);
    metrics.successes++;
    metrics.totalResponseTime += responseTime;
    metrics.lastResponseTime = responseTime;
    metrics.consecutiveFailures = 0;
    
    if (responseTime > this.responseTimeThreshold) {
      metrics.slowResponses++;
    }
  }

  recordFailure(identifier, error) {
    const metrics = this.getOrCreateMetrics(identifier);
    metrics.failures++;
    metrics.consecutiveFailures++;
    metrics.lastError = error.message;
    metrics.lastErrorTime = Date.now();
    
    if (error.response?.status === 429) {
      metrics.rateLimitHits++;
      this.handleRateLimitError(identifier, error);
    }
  }

  handleRateLimitError(identifier, error) {
    const retryAfter = error.response?.headers?.['retry-after'];
    let blockDuration = 60000;
    
    if (retryAfter) {
      blockDuration = isNaN(retryAfter) 
        ? new Date(retryAfter).getTime() - Date.now()
        : parseInt(retryAfter) * 1000;
    }
    
    this.rateLimiter.block(identifier, Math.min(blockDuration, this.maxBackoff));
  }

  adjustRateLimit(identifier, type) {
    const metrics = this.getOrCreateMetrics(identifier);
    const total = metrics.successes + metrics.failures;
    
    if (total < 10) return;
    
    const successRate = metrics.successes / total;
    const avgResponseTime = metrics.totalResponseTime / metrics.successes;
    const currentLimit = this.rateLimiter.getLimit(identifier, type);
    
    let adjustment = { ...currentLimit };
    
    if (metrics.rateLimitHits > 0 || metrics.consecutiveFailures > 3) {
      adjustment.requests = Math.max(1, Math.floor(currentLimit.requests * 0.5));
      console.log(`[R] Decreasing rate limit for ${identifier} due to failures`);
    } else if (successRate > 0.95 && avgResponseTime < this.responseTimeThreshold * 0.5) {
      adjustment.requests = Math.min(currentLimit.requests * 1.2, currentLimit.requests + 10);
      console.log(`[R] Increasing rate limit for ${identifier} due to good performance`);
    } else if (metrics.slowResponses / metrics.successes > 0.3) {
      adjustment.requests = Math.max(1, Math.floor(currentLimit.requests * 0.8));
      console.log(`[R] Decreasing rate limit for ${identifier} due to slow responses`);
    }
    
    if (adjustment.requests !== currentLimit.requests) {
      this.rateLimiter.updateLimit(identifier, type, adjustment);
      metrics.lastAdjustment = Date.now();
    }
  }

  getOrCreateMetrics(identifier) {
    if (!this.metrics.has(identifier)) {
      this.metrics.set(identifier, {
        successes: 0,
        failures: 0,
        rateLimitHits: 0,
        slowResponses: 0,
        totalResponseTime: 0,
        lastResponseTime: 0,
        consecutiveFailures: 0,
        lastError: null,
        lastErrorTime: null,
        lastAdjustment: Date.now()
      });
    }
    return this.metrics.get(identifier);
  }

  startAdaptiveAdjustment() {
    setInterval(() => {
      for (const [identifier, metrics] of this.metrics.entries()) {
        const timeSinceAdjustment = Date.now() - metrics.lastAdjustment;
        
        if (timeSinceAdjustment > this.adjustmentInterval) {
          const total = metrics.successes + metrics.failures;
          
          if (total > 0) {
            const successRate = metrics.successes / total;
            
            if (successRate > 0.98 && metrics.rateLimitHits === 0) {
              console.log(`[R] Considering rate limit increase for ${identifier}`);
              this.adjustRateLimit(identifier, 'global');
            }
          }
          
          this.resetMetrics(identifier);
        }
      }
    }, this.adjustmentInterval);
  }

  resetMetrics(identifier) {
    const metrics = this.getOrCreateMetrics(identifier);
    metrics.successes = 0;
    metrics.failures = 0;
    metrics.rateLimitHits = 0;
    metrics.slowResponses = 0;
    metrics.totalResponseTime = 0;
    metrics.consecutiveFailures = 0;
  }

  getMetrics() {
    const result = {};
    for (const [id, metrics] of this.metrics.entries()) {
      const total = metrics.successes + metrics.failures;
      result[id] = {
        ...metrics,
        successRate: total > 0 ? (metrics.successes / total * 100).toFixed(2) + '%' : 'N/A',
        avgResponseTime: metrics.successes > 0 
          ? Math.round(metrics.totalResponseTime / metrics.successes) + 'ms'
          : 'N/A'
      };
    }
    return result;
  }
}

module.exports = { RateLimiter, SmartThrottler };