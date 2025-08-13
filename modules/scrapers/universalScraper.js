const axios = require('axios');
const { ApifyClient } = require('apify-client');

class UniversalScraper {
  constructor(config = {}) {
    this.config = {
      timeout: config.timeout || 30000,
      maxRetries: config.maxRetries || 3,
      retryDelay: config.retryDelay || 1000,
      userAgent: config.userAgent || 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      rateLimit: config.rateLimit || { requests: 10, perSeconds: 1 },
      proxies: config.proxies || [],
      headers: config.headers || {},
      ...config
    };
    
    this.stats = {
      totalRequests: 0,
      successfulRequests: 0,
      failedRequests: 0,
      totalDataExtracted: 0,
      startTime: Date.now()
    };

    this.requestQueue = [];
    this.isProcessing = false;
    this.lastRequestTime = 0;
    
    if (process.env.APIFY_API_KEY) {
      this.apifyClient = new ApifyClient({
        token: process.env.APIFY_API_KEY
      });
    }
  }

  async scrapeLinkedIn(profileUrl, options = {}) {
    console.log('[O] Starting LinkedIn scrape for:', profileUrl);
    
    if (!this.apifyClient) {
      throw new Error('APIFY_API_KEY not configured for LinkedIn scraping');
    }

    try {
      const input = {
        startUrls: [{ url: profileUrl }],
        searchType: options.searchType || 'profile',
        maxResults: options.maxResults || 10,
        ...options.apifyInput
      };

      const run = await this.apifyClient.actor('apify/linkedin-scraper').call(input);
      
      const { items } = await this.apifyClient.dataset(run.defaultDatasetId).listItems();
      
      this.stats.successfulRequests++;
      this.stats.totalDataExtracted += items.length;
      
      return this.formatLinkedInData(items);
    } catch (error) {
      this.stats.failedRequests++;
      console.error('[R] LinkedIn scrape failed:', error.message);
      throw error;
    }
  }

  async scrapeApollo(searchQuery, options = {}) {
    console.log('[O] Starting Apollo.io scrape for:', searchQuery);
    
    if (!this.apifyClient) {
      throw new Error('APIFY_API_KEY not configured for Apollo scraping');
    }

    try {
      const input = {
        searchQuery,
        maxResults: options.maxResults || 100,
        includeEmails: options.includeEmails !== false,
        includePhones: options.includePhones !== false,
        ...options.apifyInput
      };

      const run = await this.apifyClient.actor('apollo-scraper').call(input);
      
      const { items } = await this.apifyClient.dataset(run.defaultDatasetId).listItems();
      
      this.stats.successfulRequests++;
      this.stats.totalDataExtracted += items.length;
      
      return this.formatApolloData(items);
    } catch (error) {
      this.stats.failedRequests++;
      console.error('[R] Apollo scrape failed:', error.message);
      throw error;
    }
  }

  async scrapeWebsite(url, selectors = {}) {
    console.log('[O] Starting website scrape for:', url);
    
    const defaultSelectors = {
      emails: /([a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+\.[a-zA-Z0-9_-]+)/gi,
      phones: /(\+?\d{1,4}?[-.\s]?\(?\d{1,3}?\)?[-.\s]?\d{1,4}[-.\s]?\d{1,4}[-.\s]?\d{1,9})/g,
      socialLinks: {
        linkedin: /(?:https?:\/\/)?(?:www\.)?linkedin\.com\/(?:company|in)\/[\w-]+/gi,
        twitter: /(?:https?:\/\/)?(?:www\.)?twitter\.com\/[\w]+/gi,
        facebook: /(?:https?:\/\/)?(?:www\.)?facebook\.com\/[\w.]+/gi
      },
      ...selectors
    };

    try {
      await this.enforceRateLimit();
      
      const response = await this.makeRequest(url);
      const html = response.data;
      
      const extractedData = {
        url,
        emails: this.extractEmails(html),
        phones: this.extractPhones(html),
        socialLinks: this.extractSocialLinks(html),
        customData: {}
      };

      if (selectors.custom) {
        for (const [key, selector] of Object.entries(selectors.custom)) {
          extractedData.customData[key] = this.extractWithSelector(html, selector);
        }
      }
      
      this.stats.successfulRequests++;
      this.stats.totalDataExtracted++;
      
      return extractedData;
    } catch (error) {
      this.stats.failedRequests++;
      console.error('[R] Website scrape failed:', error.message);
      throw error;
    }
  }

  async scrapeGoogleMaps(searchQuery, location, options = {}) {
    console.log('[O] Starting Google Maps scrape for:', searchQuery, 'in', location);
    
    if (!this.apifyClient) {
      throw new Error('APIFY_API_KEY not configured for Google Maps scraping');
    }

    try {
      const input = {
        searchString: searchQuery,
        locationQuery: location,
        maxCrawledPlaces: options.maxResults || 20,
        language: options.language || 'en',
        includeWebsite: true,
        includeEmail: true,
        includePhone: true,
        ...options.apifyInput
      };

      const run = await this.apifyClient.actor('nwua9Gu5YrADL7ZDj').call(input);
      
      const { items } = await this.apifyClient.dataset(run.defaultDatasetId).listItems();
      
      this.stats.successfulRequests++;
      this.stats.totalDataExtracted += items.length;
      
      return this.formatGoogleMapsData(items);
    } catch (error) {
      this.stats.failedRequests++;
      console.error('[R] Google Maps scrape failed:', error.message);
      throw error;
    }
  }

  async scrapeInstantly(domain, options = {}) {
    console.log('[O] Starting Instantly data enrichment for:', domain);
    
    try {
      const apiKey = process.env.INSTANTLY_API_KEY;
      if (!apiKey) {
        throw new Error('INSTANTLY_API_KEY not configured');
      }

      const response = await axios.post('https://api.instantly.ai/api/v1/lead/enrich', {
        domain,
        webhook_url: options.webhookUrl
      }, {
        headers: {
          'Authorization': `Bearer ${apiKey}`,
          'Content-Type': 'application/json'
        }
      });

      this.stats.successfulRequests++;
      this.stats.totalDataExtracted++;
      
      return this.formatInstantlyData(response.data);
    } catch (error) {
      this.stats.failedRequests++;
      console.error('[R] Instantly enrichment failed:', error.message);
      throw error;
    }
  }

  async bulkScrape(targets, scraperType, options = {}) {
    console.log(`[O] Starting bulk scrape of ${targets.length} targets using ${scraperType}`);
    
    const results = [];
    const errors = [];
    const batchSize = options.batchSize || 5;
    
    for (let i = 0; i < targets.length; i += batchSize) {
      const batch = targets.slice(i, i + batchSize);
      
      const batchPromises = batch.map(async (target) => {
        try {
          let result;
          switch (scraperType) {
            case 'linkedin':
              result = await this.scrapeLinkedIn(target, options);
              break;
            case 'apollo':
              result = await this.scrapeApollo(target, options);
              break;
            case 'website':
              result = await this.scrapeWebsite(target, options.selectors);
              break;
            case 'googlemaps':
              result = await this.scrapeGoogleMaps(target.query, target.location, options);
              break;
            case 'instantly':
              result = await this.scrapeInstantly(target, options);
              break;
            default:
              throw new Error(`Unknown scraper type: ${scraperType}`);
          }
          return { success: true, target, data: result };
        } catch (error) {
          return { success: false, target, error: error.message };
        }
      });
      
      const batchResults = await Promise.all(batchPromises);
      
      batchResults.forEach(result => {
        if (result.success) {
          results.push(result);
        } else {
          errors.push(result);
        }
      });
      
      console.log(`[O] Processed batch ${Math.floor(i / batchSize) + 1}/${Math.ceil(targets.length / batchSize)}`);
      
      if (i + batchSize < targets.length) {
        await this.delay(options.delayBetweenBatches || 2000);
      }
    }
    
    return {
      success: results,
      failed: errors,
      stats: this.getStats()
    };
  }

  async makeRequest(url, options = {}) {
    const config = {
      url,
      method: options.method || 'GET',
      timeout: this.config.timeout,
      headers: {
        'User-Agent': this.config.userAgent,
        ...this.config.headers,
        ...options.headers
      },
      ...options
    };

    if (this.config.proxies.length > 0) {
      const proxy = this.getRandomProxy();
      config.proxy = proxy;
    }

    let lastError;
    for (let i = 0; i < this.config.maxRetries; i++) {
      try {
        this.stats.totalRequests++;
        const response = await axios(config);
        return response;
      } catch (error) {
        lastError = error;
        console.log(`[R] Request failed (attempt ${i + 1}/${this.config.maxRetries}):`, error.message);
        if (i < this.config.maxRetries - 1) {
          await this.delay(this.config.retryDelay * Math.pow(2, i));
        }
      }
    }
    
    throw lastError;
  }

  async enforceRateLimit() {
    const now = Date.now();
    const timeSinceLastRequest = now - this.lastRequestTime;
    const minInterval = (this.config.rateLimit.perSeconds * 1000) / this.config.rateLimit.requests;
    
    if (timeSinceLastRequest < minInterval) {
      await this.delay(minInterval - timeSinceLastRequest);
    }
    
    this.lastRequestTime = Date.now();
  }

  extractEmails(html) {
    const emailRegex = /([a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+\.[a-zA-Z0-9_-]+)/gi;
    const matches = html.match(emailRegex) || [];
    return [...new Set(matches)].filter(email => !email.includes('.png') && !email.includes('.jpg'));
  }

  extractPhones(html) {
    const phoneRegex = /(\+?\d{1,4}?[-.\s]?\(?\d{1,3}?\)?[-.\s]?\d{1,4}[-.\s]?\d{1,4}[-.\s]?\d{1,9})/g;
    const matches = html.match(phoneRegex) || [];
    return [...new Set(matches)].filter(phone => phone.length >= 10);
  }

  extractSocialLinks(html) {
    const social = {
      linkedin: [],
      twitter: [],
      facebook: []
    };
    
    const linkedinRegex = /(?:https?:\/\/)?(?:www\.)?linkedin\.com\/(?:company|in)\/[\w-]+/gi;
    const twitterRegex = /(?:https?:\/\/)?(?:www\.)?twitter\.com\/[\w]+/gi;
    const facebookRegex = /(?:https?:\/\/)?(?:www\.)?facebook\.com\/[\w.]+/gi;
    
    social.linkedin = [...new Set(html.match(linkedinRegex) || [])];
    social.twitter = [...new Set(html.match(twitterRegex) || [])];
    social.facebook = [...new Set(html.match(facebookRegex) || [])];
    
    return social;
  }

  extractWithSelector(html, selector) {
    if (typeof selector === 'string') {
      const regex = new RegExp(selector, 'gi');
      return html.match(regex) || [];
    }
    return [];
  }

  formatLinkedInData(items) {
    return items.map(item => ({
      source: 'linkedin',
      name: item.name || item.fullName,
      title: item.title || item.headline,
      company: item.company || item.currentCompany,
      location: item.location,
      profileUrl: item.profileUrl || item.url,
      email: item.email,
      connectionDegree: item.connectionDegree,
      summary: item.summary || item.about,
      experience: item.experience || [],
      education: item.education || [],
      skills: item.skills || [],
      extractedAt: new Date().toISOString()
    }));
  }

  formatApolloData(items) {
    return items.map(item => ({
      source: 'apollo',
      name: item.name,
      title: item.title,
      company: item.company,
      companyDomain: item.company_domain,
      email: item.email,
      emailStatus: item.email_status,
      phone: item.phone,
      linkedinUrl: item.linkedin_url,
      location: {
        city: item.city,
        state: item.state,
        country: item.country
      },
      seniority: item.seniority,
      departments: item.departments || [],
      companyInfo: {
        industry: item.company_industry,
        size: item.company_size,
        revenue: item.company_revenue
      },
      extractedAt: new Date().toISOString()
    }));
  }

  formatGoogleMapsData(items) {
    return items.map(item => ({
      source: 'googlemaps',
      businessName: item.title,
      address: item.address,
      phone: item.phone,
      website: item.website,
      email: item.email,
      category: item.category,
      rating: item.rating,
      reviewsCount: item.reviewsCount,
      coordinates: {
        lat: item.latitude,
        lng: item.longitude
      },
      openingHours: item.openingHours,
      plusCode: item.plusCode,
      placeId: item.placeId,
      extractedAt: new Date().toISOString()
    }));
  }

  formatInstantlyData(data) {
    return {
      source: 'instantly',
      domain: data.domain,
      companyName: data.company_name,
      industry: data.industry,
      size: data.company_size,
      revenue: data.revenue,
      technologies: data.technologies || [],
      contacts: (data.contacts || []).map(contact => ({
        name: contact.name,
        title: contact.title,
        email: contact.email,
        emailValid: contact.email_valid,
        phone: contact.phone,
        linkedin: contact.linkedin_url
      })),
      socialProfiles: data.social_profiles || {},
      extractedAt: new Date().toISOString()
    };
  }

  getRandomProxy() {
    if (this.config.proxies.length === 0) return null;
    const randomIndex = Math.floor(Math.random() * this.config.proxies.length);
    return this.config.proxies[randomIndex];
  }

  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  getStats() {
    const runtime = Date.now() - this.stats.startTime;
    return {
      ...this.stats,
      runtime: Math.round(runtime / 1000),
      successRate: this.stats.totalRequests > 0 
        ? (this.stats.successfulRequests / this.stats.totalRequests * 100).toFixed(2) + '%'
        : '0%',
      averageDataPerRequest: this.stats.successfulRequests > 0
        ? (this.stats.totalDataExtracted / this.stats.successfulRequests).toFixed(2)
        : 0
    };
  }

  reset() {
    this.stats = {
      totalRequests: 0,
      successfulRequests: 0,
      failedRequests: 0,
      totalDataExtracted: 0,
      startTime: Date.now()
    };
    this.requestQueue = [];
    this.lastRequestTime = 0;
  }
}

module.exports = { UniversalScraper };