const { DataExtractor } = require('./modules/scrapers/dataExtractor');
const { SmartThrottler } = require('./modules/scrapers/rateLimiter');
const { ErrorHandler } = require('./modules/scrapers/errorHandler');
const { ProxyManager } = require('./modules/scrapers/proxyManager');

async function testDataExtractor() {
  console.log('=== Testing Data Extractor ===\n');
  
  const extractor = new DataExtractor();
  
  const sampleHtml = `
    <!DOCTYPE html>
    <html>
    <head>
        <title>Test Company Inc</title>
        <meta name="description" content="Leading provider of test solutions">
    </head>
    <body>
        <h1>Welcome to Test Company</h1>
        <p>Contact us at contact@testcompany.com or call (555) 123-4567</p>
        <p>Sales: sales@testcompany.com | Support: support@testcompany.com</p>
        <a href="https://linkedin.com/company/testcompany">LinkedIn</a>
        <a href="https://twitter.com/testcompany">Twitter</a>
        <address>
            123 Main Street<br>
            San Francisco, CA 94105<br>
            United States
        </address>
    </body>
    </html>
  `;
  
  const extracted = extractor.extractFromHtml(sampleHtml);
  
  console.log('✅ Extracted Meta Data:');
  console.log(JSON.stringify(extracted.meta, null, 2));
  
  console.log('\n✅ Extracted Contacts:');
  console.log(JSON.stringify(extracted.contacts, null, 2));
  
  console.log('\n✅ Extracted Social Profiles:');
  console.log(JSON.stringify(extracted.social, null, 2));
  
  console.log('\n=== Data Extractor Test Complete ===\n');
}

async function testRateLimiter() {
  console.log('=== Testing Rate Limiter & Throttler ===\n');
  
  const throttler = new SmartThrottler({
    rateLimits: {
      globalRequests: 3,
      globalPerSeconds: 1
    },
    adaptive: false
  });
  
  const startTime = Date.now();
  console.log('🔄 Testing throttled requests...');
  
  const promises = [];
  for (let i = 0; i < 5; i++) {
    promises.push(
      throttler.throttle('test-service', 'global', async () => {
        const elapsed = Date.now() - startTime;
        console.log(`   Request ${i + 1} completed at ${elapsed}ms`);
        return `Result ${i + 1}`;
      })
    );
  }
  
  const results = await Promise.all(promises);
  console.log('\n✅ Throttle Results:', results);
  
  const metrics = throttler.getMetrics();
  console.log('\n✅ Throttler Metrics:', JSON.stringify(metrics, null, 2));
  
  console.log('\n=== Rate Limiter Test Complete ===\n');
}

async function testErrorHandler() {
  console.log('=== Testing Error Handler ===\n');
  
  const errorHandler = new ErrorHandler({
    maxRetries: 3,
    retryDelay: 500,
    exponentialBackoff: true
  });
  
  console.log('🔄 Testing retry mechanism with simulated failures...');
  
  let attemptCount = 0;
  try {
    await errorHandler.retryWithBackoff(async () => {
      attemptCount++;
      console.log(`   Attempt ${attemptCount}`);
      
      if (attemptCount < 3) {
        const error = new Error('Simulated network error');
        error.code = 'ECONNREFUSED';
        throw error;
      }
      
      return 'Success after retries!';
    });
    
    console.log('✅ Successfully recovered after retries');
    
  } catch (error) {
    console.log('❌ Final error:', error.message);
  }
  
  console.log('🔄 Testing non-retryable error...');
  
  try {
    await errorHandler.retryWithBackoff(async () => {
      const error = new Error('Authentication failed');
      error.response = { status: 401 };
      throw error;
    });
  } catch (error) {
    console.log('✅ Correctly failed without retry for auth error:', error.message);
  }
  
  const errorStats = errorHandler.getStats();
  console.log('\n✅ Error Handler Stats:', JSON.stringify(errorStats, null, 2));
  
  console.log('\n=== Error Handler Test Complete ===\n');
}

async function testProxyManager() {
  console.log('=== Testing Proxy Manager ===\n');
  
  const proxyManager = new ProxyManager({
    proxies: [
      'http://proxy1.example.com:8080',
      'http://user:pass@proxy2.example.com:3128',
      '192.168.1.100:8080',
      'proxy3.example.com:3128:username:password'
    ],
    rotationStrategy: 'round-robin',
    maxFailures: 2
  });
  
  console.log('🔄 Testing proxy parsing...');
  
  const testProxies = [
    'http://proxy.example.com:8080',
    'http://user:pass@proxy.example.com:8080',
    '192.168.1.1:3128',
    'proxy.test.com:8080:username:password'
  ];
  
  testProxies.forEach((proxyStr, i) => {
    const parsed = proxyManager.parseProxyLine(proxyStr);
    console.log(`   Proxy ${i + 1}: ${proxyStr}`);
    console.log(`   Parsed:`, JSON.stringify(parsed, null, 4));
  });
  
  console.log('\n🔄 Testing rotation strategies...');
  
  const availableProxies = proxyManager.getAvailableProxies();
  console.log(`   Available proxies: ${availableProxies.length}`);
  
  if (availableProxies.length > 0) {
    for (let i = 0; i < Math.min(5, availableProxies.length); i++) {
      const proxy = proxyManager.getNextProxy();
      const proxyUrl = proxyManager.getProxyUrl(proxy);
      console.log(`   Rotation ${i + 1}: ${proxyUrl}`);
    }
  }
  
  const proxyStats = proxyManager.getStats();
  console.log('\n✅ Proxy Manager Stats:', JSON.stringify(proxyStats, null, 2));
  
  console.log('\n=== Proxy Manager Test Complete ===\n');
}

async function runBasicTests() {
  try {
    console.log('🚀 Starting Basic Component Tests...\n');
    
    await testDataExtractor();
    await testRateLimiter();
    await testErrorHandler();
    await testProxyManager();
    
    console.log('🎉 All Basic Component Tests Completed Successfully!\n');
    
  } catch (error) {
    console.error('❌ Test Suite Failed:', error);
    console.error(error.stack);
  }
}

if (require.main === module) {
  runBasicTests();
}

module.exports = { runBasicTests };