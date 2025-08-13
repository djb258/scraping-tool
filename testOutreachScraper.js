require('dotenv').config();
const { OutreachScraper } = require('./modules/outreachScraper');

async function testOutreachScraper() {
  console.log('=== Testing Outreach Scraper ===\n');

  const scraper = new OutreachScraper({
    batchSize: 3,
    exportFormat: 'json',
    outputDir: './test-output',
    enableCaching: true,
    enrichmentSources: ['apollo', 'linkedin', 'instantly']
  });

  const testTargets = [
    {
      company: 'Anthropic',
      domain: 'anthropic.com',
      linkedinUrl: 'https://linkedin.com/company/anthropic',
      location: 'San Francisco, CA'
    },
    {
      company: 'OpenAI',
      domain: 'openai.com',
      linkedinUrl: 'https://linkedin.com/company/openai'
    },
    'https://example.com',
    'technology startups'
  ];

  try {
    console.log('1. Testing company enrichment...');
    
    const companyEnrichment = await scraper.scrapeCompany({
      company: 'Test Company',
      domain: 'example.com'
    }, {
      enrich: true,
      maxResults: 5
    });
    
    console.log('Company enrichment result:', JSON.stringify(companyEnrichment, null, 2));
    
    console.log('\n2. Testing website scraping...');
    
    const websiteResult = await scraper.scrapeTarget('https://example.com', {
      selectors: {
        title: 'title',
        headings: 'h1, h2, h3',
        links: 'a[href]'
      }
    });
    
    console.log('Website scraping result:', JSON.stringify(websiteResult, null, 2));
    
    console.log('\n3. Testing search functionality...');
    
    const searchResult = await scraper.searchAndScrape('AI companies', {
      searchLocation: 'San Francisco',
      maxResults: 3
    });
    
    console.log('Search result:', JSON.stringify(searchResult, null, 2));
    
    console.log('\n4. Getting scraper stats...');
    
    const stats = scraper.getStats();
    console.log('Scraper statistics:', JSON.stringify(stats, null, 2));
    
  } catch (error) {
    console.error('Test failed:', error.message);
    console.error('Error details:', error);
  }
}

async function testBasicScraping() {
  console.log('\n=== Testing Basic Scraping Components ===\n');
  
  const { UniversalScraper } = require('./modules/scrapers/universalScraper');
  const { DataExtractor } = require('./modules/scrapers/dataExtractor');
  const { SmartThrottler } = require('./modules/scrapers/rateLimiter');
  
  console.log('1. Testing data extraction...');
  
  const extractor = new DataExtractor();
  const sampleHtml = `
    <!DOCTYPE html>
    <html>
    <head>
        <title>Test Company</title>
        <meta name="description" content="A test company for scraping">
    </head>
    <body>
        <h1>Welcome to Test Company</h1>
        <p>Contact us at contact@testcompany.com or call (555) 123-4567</p>
        <a href="https://linkedin.com/company/testcompany">LinkedIn</a>
        <a href="https://twitter.com/testcompany">Twitter</a>
        <address>
            123 Main St<br>
            San Francisco, CA 94105
        </address>
    </body>
    </html>
  `;
  
  const extractedData = extractor.extractFromHtml(sampleHtml);
  console.log('Extracted data:', JSON.stringify(extractedData, null, 2));
  
  console.log('\n2. Testing throttler...');
  
  const throttler = new SmartThrottler({
    rateLimits: {
      globalRequests: 5,
      globalPerSeconds: 1
    }
  });
  
  const throttleStart = Date.now();
  
  const throttlePromises = Array.from({ length: 3 }, (_, i) => 
    throttler.throttle('test', 'global', async () => {
      console.log(`Throttled request ${i + 1} at ${Date.now() - throttleStart}ms`);
      return `Result ${i + 1}`;
    })
  );
  
  const throttleResults = await Promise.all(throttlePromises);
  console.log('Throttle results:', throttleResults);
  
  console.log('\n3. Testing error handling...');
  
  const { ErrorHandler } = require('./modules/scrapers/errorHandler');
  
  const errorHandler = new ErrorHandler();
  
  try {
    await errorHandler.retryWithBackoff(async () => {
      throw new Error('Simulated network error');
    });
  } catch (error) {
    console.log('Expected error caught:', error.message);
  }
  
  const errorStats = errorHandler.getStats();
  console.log('Error handler stats:', errorStats);
}

async function testProxyManager() {
  console.log('\n=== Testing Proxy Manager ===\n');
  
  const { ProxyManager } = require('./modules/scrapers/proxyManager');
  
  const proxyManager = new ProxyManager({
    proxies: [
      'http://proxy1.example.com:8080',
      'http://proxy2.example.com:8080',
      'http://username:password@proxy3.example.com:3128'
    ],
    rotationStrategy: 'round-robin'
  });
  
  console.log('1. Testing proxy parsing...');
  
  const parsedProxy = proxyManager.parseProxyLine('http://user:pass@proxy.example.com:8080');
  console.log('Parsed proxy:', parsedProxy);
  
  console.log('\n2. Testing proxy rotation strategies...');
  
  try {
    const availableProxies = proxyManager.getAvailableProxies();
    console.log(`Available proxies: ${availableProxies.length}`);
    
    if (availableProxies.length > 0) {
      const proxy1 = proxyManager.getNextProxy();
      const proxy2 = proxyManager.getNextProxy();
      
      console.log('First proxy:', proxyManager.getProxyKey(proxy1));
      console.log('Second proxy:', proxyManager.getProxyKey(proxy2));
    }
    
    const proxyStats = proxyManager.getStats();
    console.log('Proxy manager stats:', JSON.stringify(proxyStats, null, 2));
    
  } catch (error) {
    console.log('Proxy test completed (expected with test data):', error.message);
  }
}

async function runAllTests() {
  try {
    await testBasicScraping();
    await testProxyManager();
    await testOutreachScraper();
    
    console.log('\n=== All Tests Completed ===');
    
  } catch (error) {
    console.error('Test suite failed:', error);
  }
}

if (require.main === module) {
  runAllTests();
}

module.exports = {
  testOutreachScraper,
  testBasicScraping,
  testProxyManager,
  runAllTests
};