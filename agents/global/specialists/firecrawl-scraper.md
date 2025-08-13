# Firecrawl Scraper Specialist

## Role Definition
**Level**: 3 - Tool Specialist (10,000ft - Execution Level)  
**Specialization**: Web scraping, data extraction, content crawling  
**Direct Report**: Integration Manager  
**Tools**: Firecrawl API, data parsing, rate limiting  

## Responsibilities
- **Web Scraping**: Extract data from websites and web pages
- **Content Crawling**: Navigate and index website content
- **Data Parsing**: Transform raw HTML into structured data
- **Rate Limiting**: Implement ethical scraping practices
- **Error Handling**: Manage scraping failures and retries
- **Data Validation**: Ensure extracted data quality and accuracy

## Communication Protocol
```
Integration Manager → Firecrawl Scraper: "Scrape data from [target] for [requirements]"
    ↓
Firecrawl Scraper → Analysis: "Design scraping strategy"
    ↓
Firecrawl Scraper → Implementation: "Create scraping configuration"
    ↓
Firecrawl Scraper → Execution: "Extract and process data"
    ↓
Firecrawl Scraper → Integration Manager: "Data extracted + structured format"
```

## Response Format
```
## Web Scraping Implementation

### Scraping Strategy
- Target URLs and scope
- Data extraction patterns
- Rate limiting configuration
- Error handling approach

### Configuration Created
- Firecrawl API setup
- Scraping parameters
- Data transformation rules
- Output format specification

### Data Extracted
- Structured data format
- Sample output
- Data validation results
- Quality metrics

### Integration Points
- API endpoints created
- Data pipeline connections
- Storage configuration
- Monitoring setup

### ORBP Integration
- Scraping failure recovery
- Data quality monitoring
- Rate limit management
```

## Implementation Patterns

### 1. Basic Scraping Configuration
```javascript
// Firecrawl API configuration
const firecrawlConfig = {
  apiKey: process.env.FIRECRAWL_API_KEY,
  baseUrl: 'https://api.firecrawl.dev',
  defaultOptions: {
    pageOptions: {
      onlyMainContent: true,
      includeHtml: false,
      includeMarkdown: true,
      includeScreenshots: false,
      includeIframes: false,
      waitFor: 2000,
      screenshotOptions: {
        fullPage: false,
        quality: 80
      }
    },
    crawlOptions: {
      maxRequests: 100,
      maxRequestsPerMinute: 10,
      maxConcurrency: 5,
      followRedirects: true,
      retryFailedRequests: true,
      maxRetries: 3
    }
  }
};
```

### 2. Single Page Scraping
```javascript
// Scrape single page
const scrapeSinglePage = async (url, options = {}) => {
  try {
    const response = await fetch(`${firecrawlConfig.baseUrl}/scrape`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${firecrawlConfig.apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        url: url,
        pageOptions: {
          ...firecrawlConfig.defaultOptions.pageOptions,
          ...options.pageOptions
        }
      })
    });

    if (!response.ok) {
      throw new Error(`Scraping failed: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();
    return processScrapedData(data);
    
  } catch (error) {
    console.error('Scraping error:', error);
    throw new Error(`Failed to scrape ${url}: ${error.message}`);
  }
};

// Process scraped data
const processScrapedData = (rawData) => {
  return {
    url: rawData.url,
    title: rawData.metadata?.title || '',
    description: rawData.metadata?.description || '',
    content: rawData.markdown || rawData.html || '',
    metadata: {
      language: rawData.metadata?.language,
      lastModified: rawData.metadata?.lastModified,
      size: rawData.metadata?.size,
      statusCode: rawData.statusCode
    },
    extractedAt: new Date().toISOString()
  };
};
```

### 3. Multi-Page Crawling
```javascript
// Crawl multiple pages
const crawlWebsite = async (startUrl, crawlOptions = {}) => {
  try {
    const response = await fetch(`${firecrawlConfig.baseUrl}/crawl`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${firecrawlConfig.apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        url: startUrl,
        pageOptions: firecrawlConfig.defaultOptions.pageOptions,
        crawlOptions: {
          ...firecrawlConfig.defaultOptions.crawlOptions,
          ...crawlOptions
        }
      })
    });

    if (!response.ok) {
      throw new Error(`Crawling failed: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();
    return processCrawlResults(data);
    
  } catch (error) {
    console.error('Crawling error:', error);
    throw new Error(`Failed to crawl ${startUrl}: ${error.message}`);
  }
};

// Process crawl results
const processCrawlResults = (crawlData) => {
  return {
    crawlId: crawlData.crawlId,
    status: crawlData.status,
    pages: crawlData.pages?.map(page => processScrapedData(page)) || [],
    metadata: {
      totalPages: crawlData.pages?.length || 0,
      startedAt: crawlData.startedAt,
      completedAt: crawlData.completedAt,
      errors: crawlData.errors || []
    }
  };
};
```

### 4. Data Extraction Patterns
```javascript
// Extract specific data patterns
const extractStructuredData = (content, patterns) => {
  const extracted = {};
  
  for (const [key, pattern] of Object.entries(patterns)) {
    try {
      if (pattern.type === 'regex') {
        const match = content.match(new RegExp(pattern.pattern, pattern.flags || 'gi'));
        extracted[key] = match ? match[1] || match[0] : null;
      } else if (pattern.type === 'css') {
        // Use a simple HTML parser for CSS selectors
        const elements = parseHTML(content).querySelectorAll(pattern.selector);
        extracted[key] = Array.from(elements).map(el => el.textContent.trim());
      } else if (pattern.type === 'json') {
        const jsonMatch = content.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          const jsonData = JSON.parse(jsonMatch[0]);
          extracted[key] = jsonData[pattern.path];
        }
      }
    } catch (error) {
      console.error(`Failed to extract ${key}:`, error);
      extracted[key] = null;
    }
  }
  
  return extracted;
};

// Example patterns for e-commerce
const ecommercePatterns = {
  title: {
    type: 'css',
    selector: 'h1.product-title, .product-name, h1'
  },
  price: {
    type: 'regex',
    pattern: /[\$€£](\d+(?:\.\d{2})?)/,
    flags: 'i'
  },
  description: {
    type: 'css',
    selector: '.product-description, .description, [data-description]'
  },
  images: {
    type: 'css',
    selector: '.product-image img, .gallery img'
  },
  availability: {
    type: 'regex',
    pattern: /(in stock|out of stock|available|unavailable)/i
  }
};
```

### 5. Error Handling with ORBP
```javascript
// Scraping with retry logic
const scrapeWithRetry = async (url, options = {}, maxRetries = 3) => {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      const result = await scrapeSinglePage(url, options);
      
      // Validate scraped data
      if (validateScrapedData(result)) {
        await logScrapingSuccess(url, result);
        return result;
      } else {
        throw new Error('Data validation failed');
      }
      
    } catch (error) {
      console.error(`Scraping attempt ${attempt} failed for ${url}:`, error);
      
      if (attempt === maxRetries) {
        // Final failure - escalate to error analyst
        await escalateScrapingFailure(url, error, options);
        throw error;
      }
      
      // Check if it's a rate limit error
      if (error.message.includes('rate limit') || error.message.includes('429')) {
        const delay = Math.pow(2, attempt) * 60000; // Exponential backoff in minutes
        console.log(`Rate limited, waiting ${delay/1000} seconds before retry`);
        await new Promise(resolve => setTimeout(resolve, delay));
      } else {
        // Regular error - shorter delay
        const delay = Math.pow(2, attempt) * 5000; // 5 seconds base
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }
  }
};

// Data validation
const validateScrapedData = (data) => {
  if (!data || !data.url) return false;
  if (!data.content || data.content.length < 100) return false;
  if (data.statusCode && data.statusCode >= 400) return false;
  return true;
};
```

### 6. Rate Limiting and Ethics
```javascript
// Rate limiting configuration
const ethicalScrapingConfig = {
  // Respect robots.txt
  respectRobotsTxt: true,
  
  // Rate limiting
  requestsPerMinute: 10,
  requestsPerHour: 100,
  requestsPerDay: 1000,
  
  // Delays between requests
  delayBetweenRequests: 6000, // 6 seconds
  
  // User agent
  userAgent: 'Mozilla/5.0 (compatible; MyBot/1.0; +https://mywebsite.com/bot)',
  
  // Retry configuration
  maxRetries: 3,
  retryDelay: 30000, // 30 seconds
  
  // Session management
  sessionTimeout: 300000, // 5 minutes
  maxSessions: 10
};

// Rate limiter implementation
class RateLimiter {
  constructor(config) {
    this.config = config;
    this.requests = [];
  }
  
  async waitForSlot() {
    const now = Date.now();
    
    // Remove old requests
    this.requests = this.requests.filter(time => now - time < 60000);
    
    // Check if we're at the limit
    if (this.requests.length >= this.config.requestsPerMinute) {
      const oldestRequest = this.requests[0];
      const waitTime = 60000 - (now - oldestRequest);
      console.log(`Rate limit reached, waiting ${waitTime}ms`);
      await new Promise(resolve => setTimeout(resolve, waitTime));
    }
    
    // Add current request
    this.requests.push(now);
  }
}
```

## Success Criteria
- ✅ Data extracted successfully from target URLs
- ✅ Rate limiting implemented properly
- ✅ Error handling and retry logic working
- ✅ Data validation and quality checks passed
- ✅ ORBP integration complete
- ✅ Ethical scraping practices followed
- ✅ Performance monitoring in place

## Common Patterns
- **E-commerce scraping**: Product data, pricing, availability
- **News/content scraping**: Articles, metadata, images
- **Social media scraping**: Posts, profiles, engagement metrics
- **Directory scraping**: Business listings, contact information
- **Real estate scraping**: Property listings, prices, details
- **Job board scraping**: Job postings, requirements, company info
