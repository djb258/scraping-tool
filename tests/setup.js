// HEIR Test Setup Configuration
// This file runs before all tests to set up the testing environment

require('dotenv').config({ path: '.env.test' });

// Mock environment variables for testing
process.env.NODE_ENV = 'test';
process.env.HEIR_VERSION = '2.0.0';
process.env.ORBT_ENABLED = 'true';
process.env.DATABASE_GATEKEEPER_ENABLED = 'true';
process.env.API_GATEWAY_ENABLED = 'true';

// Mock database URL for tests (use in-memory or test database)
if (!process.env.TEST_DATABASE_URL) {
  process.env.TEST_DATABASE_URL = 'postgresql://test_user:test_pass@localhost:5432/heir_test';
}

// Mock API keys for testing
process.env.APOLLO_API_KEY = 'test_apollo_key';
process.env.APIFY_API_KEY = 'test_apify_key';
process.env.INSTANTLY_API_KEY = 'test_instantly_key';
process.env.GOOGLE_MAPS_API_KEY = 'test_google_maps_key';

// Global test utilities
global.testUtils = {
  // Generate test doctrine headers
  generateTestHeaders: (operationId = 'TEST_OP_001', processId = 'TestProcess') => {
    const timestamp = Date.now().toString();
    return {
      unique_id: '[DB].[TEST].[PROC].[TOOL].[10000].[001]',
      process_id: processId,
      blueprint_id: 'test-blueprint',
      agent_signature: `test-agent:${timestamp}:abc123`,
      operation_type: 'test'
    };
  },
  
  // Generate test lead data
  generateTestLead: (overrides = {}) => {
    return {
      id: 'test_lead_001',
      name: 'John Test',
      title: 'Test Manager',
      email: 'john.test@example.com',
      company: {
        name: 'Test Company Inc',
        size: '100-500',
        industry: 'Technology',
        domain: 'testcompany.com'
      },
      location: 'San Francisco, CA',
      source: 'test',
      heirScore: 0.85,
      ...overrides
    };
  },
  
  // Mock API response generator
  mockAPIResponse: (data = {}, status = 200) => {
    return {
      status_code: status,
      headers: { 'content-type': 'application/json' },
      body: data,
      latency_ms: 150
    };
  },
  
  // Test timeout helper
  sleep: (ms) => new Promise(resolve => setTimeout(resolve, ms))
};

// Console override for cleaner test output
const originalConsoleLog = console.log;
const originalConsoleError = console.error;

if (process.env.SUPPRESS_TEST_LOGS !== 'false') {
  console.log = (...args) => {
    // Only show logs that start with [TEST] or are test-related
    if (args.some(arg => typeof arg === 'string' && arg.includes('[TEST]'))) {
      originalConsoleLog(...args);
    }
  };
  
  console.error = (...args) => {
    // Always show errors in tests
    originalConsoleError(...args);
  };
}

// Global teardown
process.on('exit', () => {
  console.log = originalConsoleLog;
  console.error = originalConsoleError;
});
