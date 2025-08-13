require('dotenv').config();
const { UniversalScraper } = require('./scrapers/universalScraper');
const { SmartThrottler } = require('./scrapers/rateLimiter');
const { DataExtractor } = require('./scrapers/dataExtractor');
const { ErrorHandler, CircuitBreaker } = require('./scrapers/errorHandler');
const { neon } = require('@neondatabase/serverless');
const fs = require('fs').promises;
const path = require('path');

class OutreachScraper {
  constructor(config = {}) {
    this.config = {
      batchSize: config.batchSize || 10,
      maxConcurrent: config.maxConcurrent || 5,
      exportFormat: config.exportFormat || 'json',
      outputDir: config.outputDir || './output',
      enableCaching: config.enableCaching !== false,
      cacheDir: config.cacheDir || './cache',
      enrichmentSources: config.enrichmentSources || ['apollo', 'linkedin', 'instantly'],
      ...config
    };

    this.scraper = new UniversalScraper({
      maxRetries: 3,
      timeout: 30000,
      rateLimit: { requests: 10, perSeconds: 1 }
    });

    this.throttler = new SmartThrottler({
      rateLimits: {
        globalRequests: 100,
        globalPerSeconds: 60,
        perApi: {
          apollo: { requests: 50, perSeconds: 60 },
          linkedin: { requests: 30, perSeconds: 60 },
          instantly: { requests: 100, perSeconds: 60 }
        }
      },
      adaptive: true
    });

    this.extractor = new DataExtractor();
    this.errorHandler = new ErrorHandler({ maxRetries: 3 });
    this.circuitBreakers = new Map();

    this.stats = {
      companiesProcessed: 0,
      contactsFound: 0,
      enrichmentSuccess: 0,
      enrichmentFailed: 0,
      errors: [],
      startTime: Date.now()
    };

    if (process.env.NEON_DATABASE_URL) {
      this.sql = neon(process.env.NEON_DATABASE_URL);
    }
  }

  async scrapeForOutreach(targets, options = {}) {
    console.log(`[O] Starting outreach scraping for ${targets.length} targets`);
    
    await this.ensureDirectories();
    
    const results = {
      success: [],
      failed: [],
      stats: {}
    };

    const batches = this.createBatches(targets, this.config.batchSize);
    
    for (const [index, batch] of batches.entries()) {
      console.log(`[O] Processing batch ${index + 1}/${batches.length}`);
      
      const batchResults = await this.processBatch(batch, options);
      
      results.success.push(...batchResults.success);
      results.failed.push(...batchResults.failed);
      
      if (options.saveProgress) {
        await this.saveProgress(results, index);
      }
      
      if (index < batches.length - 1) {
        await this.delay(2000);
      }
    }

    results.stats = this.getStats();
    
    if (options.export !== false) {
      await this.exportResults(results);
    }
    
    if (this.sql && options.saveToDb !== false) {
      await this.saveToDatabase(results);
    }
    
    return results;
  }

  async processBatch(batch, options) {
    const results = {
      success: [],
      failed: []
    };

    const promises = batch.map(target => 
      this.processTarget(target, options)
        .then(result => ({ success: true, data: result }))
        .catch(error => ({ success: false, error: error.message, target }))
    );

    const batchResults = await Promise.allSettled(promises);
    
    for (const result of batchResults) {
      if (result.status === 'fulfilled') {
        if (result.value.success) {
          results.success.push(result.value.data);
        } else {
          results.failed.push(result.value);
        }
      } else {
        results.failed.push({
          target: batch[0],
          error: result.reason?.message || 'Unknown error'
        });
      }
    }

    return results;
  }

  async processTarget(target, options) {
    const targetId = this.getTargetId(target);
    const cachedData = await this.getCachedData(targetId);
    
    if (cachedData && !options.forceRefresh) {
      console.log(`[O] Using cached data for ${targetId}`);
      return cachedData;
    }

    const circuitBreaker = this.getOrCreateCircuitBreaker(targetId);
    
    return await circuitBreaker.execute(async () => {
      return await this.errorHandler.retryWithBackoff(async () => {
        const result = await this.scrapeTarget(target, options);
        
        if (this.config.enableCaching) {
          await this.cacheData(targetId, result);
        }
        
        return result;
      }, { url: targetId });
    });
  }

  async scrapeTarget(target, options) {
    let result = {
      target,
      timestamp: new Date().toISOString(),
      source: null,
      data: {},
      contacts: [],
      enrichment: {}
    };

    if (typeof target === 'string' && target.includes('linkedin.com')) {
      result.source = 'linkedin';
      const data = await this.throttler.throttle('linkedin', 'api', async () => {
        return await this.scraper.scrapeLinkedIn(target, options);
      });
      result.data = data[0] || data;
      
    } else if (typeof target === 'string' && target.includes('apollo.io')) {
      result.source = 'apollo';
      const data = await this.throttler.throttle('apollo', 'api', async () => {
        return await this.scraper.scrapeApollo(target, options);
      });
      result.data = data;
      
    } else if (typeof target === 'object' && target.company) {
      result = await this.scrapeCompany(target, options);
      
    } else if (typeof target === 'string' && this.isUrl(target)) {
      result.source = 'website';
      const data = await this.throttler.throttle(new URL(target).hostname, 'domain', async () => {
        return await this.scraper.scrapeWebsite(target, options.selectors);
      });
      result.data = data;
      
    } else {
      result = await this.searchAndScrape(target, options);
    }

    if (options.enrich && result.data) {
      result.enrichment = await this.enrichData(result.data, options);
    }

    if (result.data?.contacts || result.data?.emails) {
      result.contacts = this.extractContacts(result.data);
      this.stats.contactsFound += result.contacts.length;
    }

    this.stats.companiesProcessed++;
    
    return result;
  }

  async scrapeCompany(company, options) {
    const result = {
      target: company,
      timestamp: new Date().toISOString(),
      source: 'multi',
      data: {},
      contacts: [],
      enrichment: {}
    };

    const enrichmentPromises = [];

    if (company.domain && this.config.enrichmentSources.includes('instantly')) {
      enrichmentPromises.push(
        this.throttler.throttle('instantly', 'api', async () => {
          try {
            const data = await this.scraper.scrapeInstantly(company.domain, options);
            this.stats.enrichmentSuccess++;
            return { source: 'instantly', data };
          } catch (error) {
            this.stats.enrichmentFailed++;
            return { source: 'instantly', error: error.message };
          }
        })
      );
    }

    if (company.linkedinUrl && this.config.enrichmentSources.includes('linkedin')) {
      enrichmentPromises.push(
        this.throttler.throttle('linkedin', 'api', async () => {
          try {
            const data = await this.scraper.scrapeLinkedIn(company.linkedinUrl, options);
            this.stats.enrichmentSuccess++;
            return { source: 'linkedin', data };
          } catch (error) {
            this.stats.enrichmentFailed++;
            return { source: 'linkedin', error: error.message };
          }
        })
      );
    }

    if (company.apolloUrl && this.config.enrichmentSources.includes('apollo')) {
      enrichmentPromises.push(
        this.throttler.throttle('apollo', 'api', async () => {
          try {
            const data = await this.scraper.scrapeApollo(company.apolloUrl || company.name, options);
            this.stats.enrichmentSuccess++;
            return { source: 'apollo', data };
          } catch (error) {
            this.stats.enrichmentFailed++;
            return { source: 'apollo', error: error.message };
          }
        })
      );
    }

    const enrichmentResults = await Promise.allSettled(enrichmentPromises);
    
    for (const enrichResult of enrichmentResults) {
      if (enrichResult.status === 'fulfilled' && enrichResult.value.data) {
        const { source, data } = enrichResult.value;
        result.data[source] = data;
        
        if (data.contacts || data.emails) {
          const contacts = this.extractContacts(data);
          result.contacts.push(...contacts);
        }
      } else if (enrichResult.status === 'rejected') {
        this.stats.errors.push({
          company: company.name,
          error: enrichResult.reason?.message || 'Enrichment failed'
        });
      }
    }

    result.contacts = this.deduplicateContacts(result.contacts);
    
    return result;
  }

  async searchAndScrape(query, options) {
    const result = {
      target: query,
      timestamp: new Date().toISOString(),
      source: 'search',
      data: {},
      contacts: [],
      enrichment: {}
    };

    try {
      if (options.searchLocation) {
        const googleMapsData = await this.throttler.throttle('googlemaps', 'api', async () => {
          return await this.scraper.scrapeGoogleMaps(query, options.searchLocation, options);
        });
        result.data.googleMaps = googleMapsData;
      }

      const apolloData = await this.throttler.throttle('apollo', 'api', async () => {
        return await this.scraper.scrapeApollo(query, options);
      });
      result.data.apollo = apolloData;

      result.contacts = this.extractContacts(result.data);
      
    } catch (error) {
      this.stats.errors.push({
        query,
        error: error.message
      });
    }

    return result;
  }

  async enrichData(data, options) {
    const enrichment = {};

    if (data.domain || data.companyDomain) {
      const domain = data.domain || data.companyDomain;
      
      try {
        const websiteData = await this.throttler.throttle(domain, 'domain', async () => {
          return await this.scraper.scrapeWebsite(`https://${domain}`, options.selectors);
        });
        enrichment.website = websiteData;
      } catch (error) {
        enrichment.websiteError = error.message;
      }
    }

    if (data.linkedinUrl && !data.linkedinData) {
      try {
        const linkedinData = await this.throttler.throttle('linkedin', 'api', async () => {
          return await this.scraper.scrapeLinkedIn(data.linkedinUrl, options);
        });
        enrichment.linkedin = linkedinData;
      } catch (error) {
        enrichment.linkedinError = error.message;
      }
    }

    return enrichment;
  }

  extractContacts(data) {
    const contacts = [];

    if (Array.isArray(data)) {
      return data;
    }

    if (data.contacts) {
      contacts.push(...(Array.isArray(data.contacts) ? data.contacts : [data.contacts]));
    }

    if (data.apollo) {
      const apolloContacts = Array.isArray(data.apollo) ? data.apollo : [data.apollo];
      contacts.push(...apolloContacts);
    }

    if (data.instantly?.contacts) {
      contacts.push(...data.instantly.contacts);
    }

    if (data.linkedin) {
      const linkedinContacts = Array.isArray(data.linkedin) ? data.linkedin : [data.linkedin];
      contacts.push(...linkedinContacts);
    }

    if (data.emails || data.email) {
      const emails = data.emails || [data.email];
      emails.forEach(email => {
        if (!contacts.find(c => c.email === email)) {
          contacts.push({ 
            email, 
            source: data.source || 'website',
            extractedAt: new Date().toISOString()
          });
        }
      });
    }

    return contacts;
  }

  deduplicateContacts(contacts) {
    const seen = new Map();
    
    for (const contact of contacts) {
      const key = contact.email || `${contact.name}-${contact.company}`;
      
      if (!seen.has(key)) {
        seen.set(key, contact);
      } else {
        const existing = seen.get(key);
        seen.set(key, { ...existing, ...contact });
      }
    }
    
    return Array.from(seen.values());
  }

  async saveToDatabase(results) {
    if (!this.sql) {
      console.log('[B] Database not configured, skipping save');
      return;
    }

    try {
      console.log('[O] Saving results to database');
      
      for (const result of results.success) {
        if (result.contacts && result.contacts.length > 0) {
          for (const contact of result.contacts) {
            await this.sql`
              INSERT INTO outreach_contacts (
                email, name, title, company, source, 
                linkedin_url, phone, enrichment_data, 
                scraped_at, target_info
              ) VALUES (
                ${contact.email || null},
                ${contact.name || null},
                ${contact.title || null},
                ${contact.company || result.target.company || null},
                ${contact.source || result.source},
                ${contact.linkedinUrl || contact.linkedin_url || null},
                ${contact.phone || null},
                ${JSON.stringify(contact)},
                ${new Date()},
                ${JSON.stringify(result.target)}
              )
              ON CONFLICT (email) DO UPDATE SET
                enrichment_data = EXCLUDED.enrichment_data,
                scraped_at = EXCLUDED.scraped_at
            `;
          }
        }
      }
      
      console.log(`[O] Saved ${results.success.length} results to database`);
    } catch (error) {
      console.error('[R] Database save failed:', error.message);
      this.stats.errors.push({ operation: 'database_save', error: error.message });
    }
  }

  async exportResults(results) {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const filename = `outreach-scrape-${timestamp}`;
    
    await this.ensureDirectories();

    if (this.config.exportFormat === 'json' || this.config.exportFormat === 'all') {
      const jsonPath = path.join(this.config.outputDir, `${filename}.json`);
      await fs.writeFile(jsonPath, JSON.stringify(results, null, 2));
      console.log(`[O] Results exported to ${jsonPath}`);
    }

    if (this.config.exportFormat === 'csv' || this.config.exportFormat === 'all') {
      const csvPath = path.join(this.config.outputDir, `${filename}.csv`);
      const csv = this.convertToCSV(results.success);
      await fs.writeFile(csvPath, csv);
      console.log(`[O] Results exported to ${csvPath}`);
    }

    if (this.config.exportFormat === 'ndjson' || this.config.exportFormat === 'all') {
      const ndjsonPath = path.join(this.config.outputDir, `${filename}.ndjson`);
      const ndjson = results.success.map(r => JSON.stringify(r)).join('\n');
      await fs.writeFile(ndjsonPath, ndjson);
      console.log(`[O] Results exported to ${ndjsonPath}`);
    }
  }

  convertToCSV(results) {
    if (results.length === 0) return '';
    
    const contacts = [];
    
    for (const result of results) {
      if (result.contacts && result.contacts.length > 0) {
        for (const contact of result.contacts) {
          contacts.push({
            company: result.target.company || result.target.name || result.target,
            name: contact.name || '',
            title: contact.title || '',
            email: contact.email || '',
            phone: contact.phone || '',
            linkedin: contact.linkedinUrl || contact.linkedin_url || '',
            source: contact.source || result.source || '',
            scraped_at: result.timestamp
          });
        }
      }
    }
    
    if (contacts.length === 0) return '';
    
    const headers = Object.keys(contacts[0]);
    const csvRows = [
      headers.join(','),
      ...contacts.map(row => 
        headers.map(header => {
          const value = row[header];
          return typeof value === 'string' && value.includes(',') 
            ? `"${value.replace(/"/g, '""')}"` 
            : value;
        }).join(',')
      )
    ];
    
    return csvRows.join('\n');
  }

  async getCachedData(targetId) {
    if (!this.config.enableCaching) return null;
    
    try {
      const cachePath = path.join(this.config.cacheDir, `${this.hashTarget(targetId)}.json`);
      const data = await fs.readFile(cachePath, 'utf-8');
      const cached = JSON.parse(data);
      
      const age = Date.now() - new Date(cached.timestamp).getTime();
      const maxAge = this.config.cacheMaxAge || 24 * 60 * 60 * 1000;
      
      if (age < maxAge) {
        return cached.data;
      }
    } catch (error) {
      return null;
    }
    
    return null;
  }

  async cacheData(targetId, data) {
    if (!this.config.enableCaching) return;
    
    try {
      await this.ensureDirectories();
      const cachePath = path.join(this.config.cacheDir, `${this.hashTarget(targetId)}.json`);
      await fs.writeFile(cachePath, JSON.stringify({
        targetId,
        timestamp: new Date().toISOString(),
        data
      }));
    } catch (error) {
      console.error('[R] Cache write failed:', error.message);
    }
  }

  async saveProgress(results, batchIndex) {
    try {
      const progressPath = path.join(this.config.outputDir, 'progress.json');
      await fs.writeFile(progressPath, JSON.stringify({
        batchIndex,
        timestamp: new Date().toISOString(),
        stats: this.getStats(),
        resultsCount: {
          success: results.success.length,
          failed: results.failed.length
        }
      }, null, 2));
    } catch (error) {
      console.error('[R] Progress save failed:', error.message);
    }
  }

  async ensureDirectories() {
    const dirs = [this.config.outputDir];
    
    if (this.config.enableCaching) {
      dirs.push(this.config.cacheDir);
    }
    
    for (const dir of dirs) {
      try {
        await fs.mkdir(dir, { recursive: true });
      } catch (error) {
        
      }
    }
  }

  getOrCreateCircuitBreaker(identifier) {
    if (!this.circuitBreakers.has(identifier)) {
      this.circuitBreakers.set(identifier, new CircuitBreaker({
        threshold: 5,
        timeout: 30000,
        resetTimeout: 60000
      }));
    }
    return this.circuitBreakers.get(identifier);
  }

  createBatches(items, batchSize) {
    const batches = [];
    for (let i = 0; i < items.length; i += batchSize) {
      batches.push(items.slice(i, i + batchSize));
    }
    return batches;
  }

  getTargetId(target) {
    if (typeof target === 'string') {
      return target;
    }
    return target.id || target.name || target.company || JSON.stringify(target);
  }

  hashTarget(target) {
    const crypto = require('crypto');
    return crypto.createHash('md5').update(target).digest('hex');
  }

  isUrl(string) {
    try {
      new URL(string);
      return true;
    } catch {
      return false;
    }
  }

  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  getStats() {
    const runtime = Date.now() - this.stats.startTime;
    
    return {
      ...this.stats,
      runtime: Math.round(runtime / 1000) + 's',
      companiesPerMinute: this.stats.companiesProcessed > 0
        ? (this.stats.companiesProcessed / (runtime / 60000)).toFixed(2)
        : 0,
      contactsPerCompany: this.stats.companiesProcessed > 0
        ? (this.stats.contactsFound / this.stats.companiesProcessed).toFixed(2)
        : 0,
      enrichmentSuccessRate: this.stats.enrichmentSuccess + this.stats.enrichmentFailed > 0
        ? (this.stats.enrichmentSuccess / (this.stats.enrichmentSuccess + this.stats.enrichmentFailed) * 100).toFixed(2) + '%'
        : '0%',
      scraperStats: this.scraper.getStats(),
      throttlerMetrics: this.throttler.getMetrics(),
      errorStats: this.errorHandler.getStats()
    };
  }

  reset() {
    this.stats = {
      companiesProcessed: 0,
      contactsFound: 0,
      enrichmentSuccess: 0,
      enrichmentFailed: 0,
      errors: [],
      startTime: Date.now()
    };
    
    this.scraper.reset();
    this.errorHandler.reset();
    this.circuitBreakers.clear();
  }
}

module.exports = { OutreachScraper };