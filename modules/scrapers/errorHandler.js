class ScraperError extends Error {
  constructor(message, code, details = {}) {
    super(message);
    this.name = 'ScraperError';
    this.code = code;
    this.details = details;
    this.timestamp = new Date().toISOString();
  }
}

class ErrorHandler {
  constructor(options = {}) {
    this.maxRetries = options.maxRetries || 3;
    this.retryDelay = options.retryDelay || 1000;
    this.exponentialBackoff = options.exponentialBackoff !== false;
    this.maxBackoffDelay = options.maxBackoffDelay || 30000;
    
    this.errorCategories = {
      network: ['ECONNREFUSED', 'ETIMEDOUT', 'ENOTFOUND', 'ENETUNREACH'],
      rateLimit: ['429', 'RATE_LIMIT', 'TOO_MANY_REQUESTS'],
      auth: ['401', '403', 'UNAUTHORIZED', 'FORBIDDEN'],
      notFound: ['404', 'NOT_FOUND'],
      serverError: ['500', '502', '503', '504'],
      parsing: ['PARSE_ERROR', 'INVALID_HTML', 'EXTRACTION_FAILED'],
      validation: ['VALIDATION_ERROR', 'INVALID_DATA']
    };

    this.errorHandlers = {
      network: this.handleNetworkError.bind(this),
      rateLimit: this.handleRateLimitError.bind(this),
      auth: this.handleAuthError.bind(this),
      notFound: this.handleNotFoundError.bind(this),
      serverError: this.handleServerError.bind(this),
      parsing: this.handleParsingError.bind(this),
      validation: this.handleValidationError.bind(this),
      ...options.customHandlers
    };

    this.errorLog = [];
    this.stats = {
      totalErrors: 0,
      retriedErrors: 0,
      recoveredErrors: 0,
      fatalErrors: 0,
      errorsByCategory: {}
    };
  }

  async handleError(error, context = {}) {
    this.logError(error, context);
    
    const category = this.categorizeError(error);
    const handler = this.errorHandlers[category] || this.handleGenericError.bind(this);
    
    this.stats.totalErrors++;
    this.stats.errorsByCategory[category] = (this.stats.errorsByCategory[category] || 0) + 1;
    
    return await handler(error, context);
  }

  categorizeError(error) {
    const errorCode = error.code || error.response?.status?.toString() || error.message;
    
    for (const [category, codes] of Object.entries(this.errorCategories)) {
      if (codes.some(code => errorCode?.includes(code))) {
        return category;
      }
    }
    
    return 'unknown';
  }

  async handleNetworkError(error, context) {
    console.log('[R] Network error detected:', error.message);
    
    return {
      retry: true,
      delay: this.calculateRetryDelay(context.attempt || 0),
      message: 'Network connectivity issue, will retry',
      category: 'network'
    };
  }

  async handleRateLimitError(error, context) {
    console.log('[R] Rate limit error detected');
    
    const retryAfter = this.extractRetryAfter(error);
    const delay = retryAfter || this.calculateRetryDelay(context.attempt || 0, 5000);
    
    return {
      retry: true,
      delay,
      message: `Rate limited, waiting ${delay}ms before retry`,
      category: 'rateLimit',
      blockDuration: delay
    };
  }

  async handleAuthError(error, context) {
    console.error('[R] Authentication error:', error.message);
    
    if (context.refreshAuth && context.attempt < 2) {
      try {
        await context.refreshAuth();
        return {
          retry: true,
          delay: 0,
          message: 'Authentication refreshed, retrying',
          category: 'auth'
        };
      } catch (refreshError) {
        console.error('[R] Failed to refresh authentication:', refreshError.message);
      }
    }
    
    return {
      retry: false,
      message: 'Authentication failed',
      category: 'auth',
      fatal: true
    };
  }

  async handleNotFoundError(error, context) {
    console.log('[R] Resource not found:', context.url || error.message);
    
    return {
      retry: false,
      message: 'Resource not found',
      category: 'notFound',
      skipResource: true
    };
  }

  async handleServerError(error, context) {
    console.log('[R] Server error detected:', error.response?.status);
    
    const shouldRetry = context.attempt < this.maxRetries;
    
    return {
      retry: shouldRetry,
      delay: this.calculateRetryDelay(context.attempt || 0, 2000),
      message: `Server error (${error.response?.status}), ${shouldRetry ? 'will retry' : 'max retries reached'}`,
      category: 'serverError'
    };
  }

  async handleParsingError(error, context) {
    console.error('[R] Parsing error:', error.message);
    
    if (context.fallbackParser) {
      try {
        const result = await context.fallbackParser();
        return {
          retry: false,
          message: 'Used fallback parser successfully',
          category: 'parsing',
          result
        };
      } catch (fallbackError) {
        console.error('[R] Fallback parser also failed:', fallbackError.message);
      }
    }
    
    return {
      retry: false,
      message: 'Failed to parse content',
      category: 'parsing',
      partialData: context.partialData || null
    };
  }

  async handleValidationError(error, context) {
    console.error('[R] Validation error:', error.message);
    
    return {
      retry: false,
      message: 'Data validation failed',
      category: 'validation',
      invalidFields: error.details?.fields || []
    };
  }

  async handleGenericError(error, context) {
    console.error('[R] Unhandled error:', error.message);
    
    const shouldRetry = context.attempt < Math.floor(this.maxRetries / 2);
    
    return {
      retry: shouldRetry,
      delay: this.calculateRetryDelay(context.attempt || 0),
      message: `Generic error: ${error.message}`,
      category: 'unknown'
    };
  }

  async retryWithBackoff(fn, context = {}) {
    let lastError;
    
    for (let attempt = 0; attempt < this.maxRetries; attempt++) {
      try {
        context.attempt = attempt;
        const result = await fn();
        
        if (attempt > 0) {
          this.stats.recoveredErrors++;
          console.log(`[R] Recovered after ${attempt} retries`);
        }
        
        return result;
      } catch (error) {
        lastError = error;
        this.stats.retriedErrors++;
        
        const errorResponse = await this.handleError(error, context);
        
        if (!errorResponse.retry) {
          if (errorResponse.fatal) {
            this.stats.fatalErrors++;
          }
          throw new ScraperError(
            errorResponse.message || error.message,
            errorResponse.category,
            { originalError: error, ...errorResponse }
          );
        }
        
        if (attempt < this.maxRetries - 1) {
          const delay = errorResponse.delay || this.calculateRetryDelay(attempt);
          console.log(`[R] Retry ${attempt + 1}/${this.maxRetries} after ${delay}ms`);
          await this.delay(delay);
        }
      }
    }
    
    this.stats.fatalErrors++;
    throw new ScraperError(
      `Failed after ${this.maxRetries} retries: ${lastError.message}`,
      'max_retries_exceeded',
      { originalError: lastError, attempts: this.maxRetries }
    );
  }

  calculateRetryDelay(attempt, baseDelay = null) {
    const base = baseDelay || this.retryDelay;
    
    if (!this.exponentialBackoff) {
      return base;
    }
    
    const delay = base * Math.pow(2, attempt);
    const jitter = Math.random() * 0.1 * delay;
    
    return Math.min(delay + jitter, this.maxBackoffDelay);
  }

  extractRetryAfter(error) {
    const retryAfter = error.response?.headers?.['retry-after'];
    
    if (!retryAfter) return null;
    
    if (isNaN(retryAfter)) {
      const retryDate = new Date(retryAfter);
      return Math.max(0, retryDate.getTime() - Date.now());
    }
    
    return parseInt(retryAfter) * 1000;
  }

  logError(error, context) {
    const errorEntry = {
      timestamp: new Date().toISOString(),
      message: error.message,
      code: error.code || error.response?.status,
      category: this.categorizeError(error),
      context,
      stack: error.stack
    };
    
    this.errorLog.push(errorEntry);
    
    if (this.errorLog.length > 1000) {
      this.errorLog = this.errorLog.slice(-500);
    }
  }

  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  getStats() {
    return {
      ...this.stats,
      errorRate: this.stats.totalErrors > 0 
        ? ((this.stats.totalErrors - this.stats.recoveredErrors) / this.stats.totalErrors * 100).toFixed(2) + '%'
        : '0%',
      recoveryRate: this.stats.retriedErrors > 0
        ? (this.stats.recoveredErrors / this.stats.retriedErrors * 100).toFixed(2) + '%'
        : '0%'
    };
  }

  getRecentErrors(limit = 10) {
    return this.errorLog.slice(-limit);
  }

  clearErrorLog() {
    this.errorLog = [];
  }

  reset() {
    this.errorLog = [];
    this.stats = {
      totalErrors: 0,
      retriedErrors: 0,
      recoveredErrors: 0,
      fatalErrors: 0,
      errorsByCategory: {}
    };
  }
}

class CircuitBreaker {
  constructor(options = {}) {
    this.threshold = options.threshold || 5;
    this.timeout = options.timeout || 60000;
    this.resetTimeout = options.resetTimeout || 30000;
    
    this.state = 'CLOSED';
    this.failures = 0;
    this.successCount = 0;
    this.lastFailureTime = null;
    this.nextAttempt = null;
  }

  async execute(fn) {
    if (this.state === 'OPEN') {
      if (Date.now() < this.nextAttempt) {
        throw new ScraperError(
          'Circuit breaker is OPEN',
          'CIRCUIT_OPEN',
          { 
            nextAttempt: new Date(this.nextAttempt).toISOString(),
            failures: this.failures 
          }
        );
      }
      
      this.state = 'HALF_OPEN';
      console.log('[R] Circuit breaker entering HALF_OPEN state');
    }

    try {
      const result = await Promise.race([
        fn(),
        new Promise((_, reject) => 
          setTimeout(() => reject(new Error('Circuit breaker timeout')), this.timeout)
        )
      ]);
      
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  onSuccess() {
    this.failures = 0;
    
    if (this.state === 'HALF_OPEN') {
      this.successCount++;
      
      if (this.successCount >= 3) {
        this.state = 'CLOSED';
        this.successCount = 0;
        console.log('[R] Circuit breaker is now CLOSED');
      }
    }
  }

  onFailure() {
    this.failures++;
    this.lastFailureTime = Date.now();
    
    if (this.failures >= this.threshold) {
      this.state = 'OPEN';
      this.nextAttempt = Date.now() + this.resetTimeout;
      console.log(`[R] Circuit breaker is now OPEN until ${new Date(this.nextAttempt).toISOString()}`);
    }
    
    if (this.state === 'HALF_OPEN') {
      this.state = 'OPEN';
      this.nextAttempt = Date.now() + this.resetTimeout;
      this.successCount = 0;
    }
  }

  getState() {
    return {
      state: this.state,
      failures: this.failures,
      lastFailureTime: this.lastFailureTime ? new Date(this.lastFailureTime).toISOString() : null,
      nextAttempt: this.nextAttempt ? new Date(this.nextAttempt).toISOString() : null
    };
  }

  reset() {
    this.state = 'CLOSED';
    this.failures = 0;
    this.successCount = 0;
    this.lastFailureTime = null;
    this.nextAttempt = null;
    console.log('[R] Circuit breaker manually reset');
  }
}

module.exports = { 
  ScraperError, 
  ErrorHandler, 
  CircuitBreaker 
};