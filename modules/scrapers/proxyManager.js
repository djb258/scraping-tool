const axios = require('axios');

class ProxyManager {
  constructor(options = {}) {
    this.proxies = options.proxies || [];
    this.proxyProviders = options.providers || [];
    this.testUrl = options.testUrl || 'https://httpbin.org/ip';
    this.testTimeout = options.testTimeout || 5000;
    this.rotationStrategy = options.rotationStrategy || 'round-robin';
    this.maxFailures = options.maxFailures || 3;
    
    this.currentIndex = 0;
    this.proxyStats = new Map();
    this.blacklist = new Set();
    this.lastRotation = Date.now();
    
    this.strategies = {
      'round-robin': this.roundRobinStrategy.bind(this),
      'random': this.randomStrategy.bind(this),
      'least-used': this.leastUsedStrategy.bind(this),
      'fastest': this.fastestStrategy.bind(this),
      'weighted': this.weightedStrategy.bind(this)
    };

    if (options.autoLoad) {
      this.loadProxies();
    }
  }

  async loadProxies() {
    console.log('[O] Loading proxies from providers');
    
    for (const provider of this.proxyProviders) {
      try {
        const proxies = await this.fetchProxiesFromProvider(provider);
        this.addProxies(proxies);
      } catch (error) {
        console.error(`[R] Failed to load proxies from ${provider.name}:`, error.message);
      }
    }
    
    if (this.proxies.length > 0) {
      await this.testAllProxies();
    }
    
    console.log(`[O] Loaded ${this.proxies.length} working proxies`);
  }

  async fetchProxiesFromProvider(provider) {
    const proxies = [];
    
    if (provider.type === 'api') {
      const response = await axios.get(provider.url, {
        headers: provider.headers || {},
        timeout: 10000
      });
      
      const data = provider.parser ? provider.parser(response.data) : response.data;
      
      if (Array.isArray(data)) {
        data.forEach(proxy => {
          proxies.push(this.formatProxy(proxy));
        });
      }
    } else if (provider.type === 'file') {
      const fs = require('fs').promises;
      const content = await fs.readFile(provider.path, 'utf-8');
      const lines = content.split('\n');
      
      lines.forEach(line => {
        const proxy = this.parseProxyLine(line.trim());
        if (proxy) {
          proxies.push(proxy);
        }
      });
    } else if (provider.type === 'env') {
      const envProxies = process.env[provider.variable];
      if (envProxies) {
        envProxies.split(',').forEach(proxyStr => {
          const proxy = this.parseProxyLine(proxyStr.trim());
          if (proxy) {
            proxies.push(proxy);
          }
        });
      }
    }
    
    return proxies;
  }

  parseProxyLine(line) {
    if (!line || line.startsWith('#')) return null;
    
    const patterns = [
      /^(https?:\/\/)?([^:]+):([^@]+)@([^:]+):(\d+)$/,
      /^(https?:\/\/)?([^:]+):(\d+)$/,
      /^([^:]+):(\d+):([^:]+):(.+)$/
    ];
    
    for (const pattern of patterns) {
      const match = line.match(pattern);
      if (match) {
        if (match.length === 6) {
          return {
            protocol: match[1] || 'http://',
            auth: {
              username: match[2],
              password: match[3]
            },
            host: match[4],
            port: parseInt(match[5])
          };
        } else if (match.length === 4) {
          return {
            protocol: match[1] || 'http://',
            host: match[2],
            port: parseInt(match[3])
          };
        } else if (match.length === 5) {
          return {
            protocol: 'http://',
            host: match[1],
            port: parseInt(match[2]),
            auth: {
              username: match[3],
              password: match[4]
            }
          };
        }
      }
    }
    
    return null;
  }

  formatProxy(proxy) {
    if (typeof proxy === 'string') {
      return this.parseProxyLine(proxy);
    }
    
    return {
      protocol: proxy.protocol || 'http://',
      host: proxy.host || proxy.ip,
      port: proxy.port,
      auth: proxy.auth || (proxy.username && proxy.password ? {
        username: proxy.username,
        password: proxy.password
      } : null),
      country: proxy.country,
      type: proxy.type || 'http',
      speed: proxy.speed,
      anonymity: proxy.anonymity
    };
  }

  addProxies(proxies) {
    const newProxies = Array.isArray(proxies) ? proxies : [proxies];
    
    newProxies.forEach(proxy => {
      const formatted = this.formatProxy(proxy);
      if (formatted && !this.isDuplicate(formatted)) {
        this.proxies.push(formatted);
        this.initProxyStats(formatted);
      }
    });
  }

  isDuplicate(proxy) {
    return this.proxies.some(p => 
      p.host === proxy.host && p.port === proxy.port
    );
  }

  initProxyStats(proxy) {
    const key = this.getProxyKey(proxy);
    if (!this.proxyStats.has(key)) {
      this.proxyStats.set(key, {
        uses: 0,
        failures: 0,
        successes: 0,
        totalResponseTime: 0,
        avgResponseTime: 0,
        lastUsed: null,
        lastError: null,
        score: 100
      });
    }
  }

  async testProxy(proxy) {
    const startTime = Date.now();
    const key = this.getProxyKey(proxy);
    
    try {
      const proxyConfig = this.getAxiosProxyConfig(proxy);
      
      const response = await axios.get(this.testUrl, {
        proxy: proxyConfig,
        timeout: this.testTimeout,
        validateStatus: () => true
      });
      
      if (response.status === 200) {
        const responseTime = Date.now() - startTime;
        const stats = this.proxyStats.get(key);
        
        stats.successes++;
        stats.totalResponseTime += responseTime;
        stats.avgResponseTime = stats.totalResponseTime / stats.successes;
        stats.lastTested = Date.now();
        stats.working = true;
        
        console.log(`[O] Proxy ${key} working (${responseTime}ms)`);
        return true;
      }
    } catch (error) {
      const stats = this.proxyStats.get(key);
      stats.failures++;
      stats.lastError = error.message;
      stats.working = false;
      
      if (stats.failures >= this.maxFailures) {
        this.blacklist.add(key);
        console.log(`[R] Proxy ${key} blacklisted after ${stats.failures} failures`);
      }
    }
    
    return false;
  }

  async testAllProxies() {
    console.log(`[O] Testing ${this.proxies.length} proxies`);
    
    const testPromises = this.proxies.map(proxy => 
      this.testProxy(proxy).catch(() => false)
    );
    
    const results = await Promise.all(testPromises);
    
    const workingProxies = this.proxies.filter((proxy, index) => results[index]);
    const blacklistedCount = this.blacklist.size;
    
    console.log(`[O] ${workingProxies.length} working, ${blacklistedCount} blacklisted`);
    
    this.proxies = workingProxies;
    
    return workingProxies;
  }

  getNextProxy() {
    const availableProxies = this.getAvailableProxies();
    
    if (availableProxies.length === 0) {
      throw new Error('No available proxies');
    }
    
    const strategy = this.strategies[this.rotationStrategy];
    const proxy = strategy(availableProxies);
    
    this.updateProxyUsage(proxy);
    
    return proxy;
  }

  getAvailableProxies() {
    return this.proxies.filter(proxy => {
      const key = this.getProxyKey(proxy);
      return !this.blacklist.has(key);
    });
  }

  roundRobinStrategy(proxies) {
    const proxy = proxies[this.currentIndex % proxies.length];
    this.currentIndex++;
    return proxy;
  }

  randomStrategy(proxies) {
    const randomIndex = Math.floor(Math.random() * proxies.length);
    return proxies[randomIndex];
  }

  leastUsedStrategy(proxies) {
    let leastUsed = proxies[0];
    let minUses = Infinity;
    
    for (const proxy of proxies) {
      const key = this.getProxyKey(proxy);
      const stats = this.proxyStats.get(key);
      
      if (stats.uses < minUses) {
        minUses = stats.uses;
        leastUsed = proxy;
      }
    }
    
    return leastUsed;
  }

  fastestStrategy(proxies) {
    let fastest = proxies[0];
    let minResponseTime = Infinity;
    
    for (const proxy of proxies) {
      const key = this.getProxyKey(proxy);
      const stats = this.proxyStats.get(key);
      
      if (stats.avgResponseTime > 0 && stats.avgResponseTime < minResponseTime) {
        minResponseTime = stats.avgResponseTime;
        fastest = proxy;
      }
    }
    
    return fastest;
  }

  weightedStrategy(proxies) {
    const weights = proxies.map(proxy => {
      const key = this.getProxyKey(proxy);
      const stats = this.proxyStats.get(key);
      return this.calculateProxyScore(stats);
    });
    
    const totalWeight = weights.reduce((sum, w) => sum + w, 0);
    let random = Math.random() * totalWeight;
    
    for (let i = 0; i < proxies.length; i++) {
      random -= weights[i];
      if (random <= 0) {
        return proxies[i];
      }
    }
    
    return proxies[proxies.length - 1];
  }

  calculateProxyScore(stats) {
    let score = 100;
    
    const successRate = stats.uses > 0 
      ? stats.successes / stats.uses 
      : 1;
    score *= successRate;
    
    if (stats.avgResponseTime > 0) {
      const speedScore = Math.max(0, 1 - (stats.avgResponseTime / 10000));
      score *= speedScore;
    }
    
    const recencyBonus = stats.lastUsed 
      ? Math.max(0, 1 - ((Date.now() - stats.lastUsed) / (60 * 60 * 1000)))
      : 1;
    score *= (0.5 + 0.5 * recencyBonus);
    
    return Math.max(1, score);
  }

  updateProxyUsage(proxy) {
    const key = this.getProxyKey(proxy);
    const stats = this.proxyStats.get(key);
    
    if (stats) {
      stats.uses++;
      stats.lastUsed = Date.now();
    }
  }

  reportSuccess(proxy, responseTime) {
    const key = this.getProxyKey(proxy);
    const stats = this.proxyStats.get(key);
    
    if (stats) {
      stats.successes++;
      stats.totalResponseTime += responseTime;
      stats.avgResponseTime = stats.totalResponseTime / stats.successes;
      stats.failures = 0;
    }
  }

  reportFailure(proxy, error) {
    const key = this.getProxyKey(proxy);
    const stats = this.proxyStats.get(key);
    
    if (stats) {
      stats.failures++;
      stats.lastError = error.message;
      
      if (stats.failures >= this.maxFailures) {
        this.blacklist.add(key);
        console.log(`[R] Proxy ${key} blacklisted`);
      }
    }
  }

  getAxiosProxyConfig(proxy) {
    const config = {
      host: proxy.host,
      port: proxy.port,
      protocol: proxy.protocol.replace('://', '')
    };
    
    if (proxy.auth) {
      config.auth = proxy.auth;
    }
    
    return config;
  }

  getProxyUrl(proxy) {
    let url = proxy.protocol || 'http://';
    
    if (proxy.auth) {
      url += `${proxy.auth.username}:${proxy.auth.password}@`;
    }
    
    url += `${proxy.host}:${proxy.port}`;
    
    return url;
  }

  getProxyKey(proxy) {
    return `${proxy.host}:${proxy.port}`;
  }

  removeProxy(proxy) {
    const key = this.getProxyKey(proxy);
    this.proxies = this.proxies.filter(p => this.getProxyKey(p) !== key);
    this.blacklist.add(key);
  }

  clearBlacklist() {
    this.blacklist.clear();
    console.log('[O] Proxy blacklist cleared');
  }

  getStats() {
    const stats = {
      total: this.proxies.length,
      available: this.getAvailableProxies().length,
      blacklisted: this.blacklist.size,
      byCountry: {},
      byType: {},
      performance: []
    };
    
    for (const proxy of this.proxies) {
      if (proxy.country) {
        stats.byCountry[proxy.country] = (stats.byCountry[proxy.country] || 0) + 1;
      }
      
      const type = proxy.type || 'http';
      stats.byType[type] = (stats.byType[type] || 0) + 1;
    }
    
    for (const [key, proxyStats] of this.proxyStats.entries()) {
      if (proxyStats.uses > 0) {
        stats.performance.push({
          proxy: key,
          uses: proxyStats.uses,
          successRate: proxyStats.successes / proxyStats.uses,
          avgResponseTime: proxyStats.avgResponseTime,
          score: this.calculateProxyScore(proxyStats)
        });
      }
    }
    
    stats.performance.sort((a, b) => b.score - a.score);
    
    return stats;
  }

  async rotateProxies() {
    console.log('[O] Rotating proxy list');
    
    await this.testAllProxies();
    
    const threshold = Date.now() - (30 * 60 * 1000);
    for (const [key, stats] of this.proxyStats.entries()) {
      if (stats.lastUsed && stats.lastUsed < threshold && stats.failures > stats.successes) {
        this.blacklist.add(key);
      }
    }
    
    this.lastRotation = Date.now();
    
    console.log(`[O] Rotation complete: ${this.getAvailableProxies().length} proxies available`);
  }

  reset() {
    this.currentIndex = 0;
    this.proxyStats.clear();
    this.blacklist.clear();
    
    this.proxies.forEach(proxy => {
      this.initProxyStats(proxy);
    });
    
    console.log('[O] Proxy manager reset');
  }
}

module.exports = { ProxyManager };