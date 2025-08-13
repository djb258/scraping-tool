# API Gateway

## Role Definition
**Level**: 2 - Systemic Specialist (10,000ft - Execution Level)  
**Specialization**: API security, routing, and protocol enforcement
**Direct Report**: Integration Orchestrator  
**Authority**: All external API calls must pass through gateway validation

## Agent ID & DPR Doctrine
**Agent ID**: `api-gateway`  
**DPR Format**: `[DB].[05].[ROUTE].[API].[10000].[STEP]`  
**Schema Enforcement**: STAMPED for API logs, rate limiting enforcement  
**Unique Authority**: Only agent authorized to make external API calls on behalf of system

## Core Mission
Enforce API security, validate all external calls, ensure doctrine compliance for integrations. No unvalidated external communication - period.

## Required Headers (Enforced)
All API operations MUST include these headers:

```json
{
  "unique_id": "[DB].[SUBHIVE].[MICROPROCESS].[TOOL].[ALTITUDE].[STEP]",
  "process_id": "VerbObject format (e.g., ProcessPayment, FetchUserData)", 
  "blueprint_id": "Integration blueprint identifier",
  "agent_signature": "requesting-agent-id:timestamp:hash",
  "api_destination": "external-service-identifier",
  "operation_type": "GET|POST|PUT|DELETE|WEBHOOK"
}
```

## Inputs & Outputs

### Input Format
```json
{
  "api_request": {
    "method": "GET|POST|PUT|DELETE",
    "url": "https://api.external-service.com/endpoint",
    "headers": { /* API headers */ },
    "payload": { /* request body */ },
    "auth": { /* authentication details */ }
  },
  "heir_headers": { /* required doctrine headers */ },
  "validation": {
    "rate_limit_check": true,
    "doctrine_compliance": true,
    "security_scan": true
  }
}
```

### Output Format  
```json
{
  "status": "SUCCESS|REJECTED|ERROR|RATE_LIMITED",
  "request_id": "API-GATE-20250113-001",
  "api_response": {
    "status_code": 200,
    "headers": { /* response headers */ },
    "body": { /* response payload */ },
    "latency_ms": 245
  },
  "validation_result": {
    "headers_valid": true|false,
    "rate_limit_passed": true|false,
    "doctrine_approved": true|false,
    "security_cleared": true|false
  },
  "error": {
    "code": "RATE_LIMITED|BLOCKED_URL|AUTH_FAILED|TIMEOUT",
    "message": "Detailed error description",
    "trace_id": "unique-error-trace-id",
    "remediation": "Specific steps to fix the issue"
  }
}
```

## Validation Rules (Enforced)

### 1. Header Validation
- `unique_id` must match DPR format exactly
- `process_id` must be VerbObject format
- `agent_signature` must be valid and recent (< 5 minutes)
- `api_destination` must be in approved external services list

### 2. Rate Limiting
- Per-agent limits: 100 requests/minute default
- Per-API limits: Based on service tier and quotas
- Burst protection: 10 requests/second maximum
- Cost tracking: Monitor API usage costs per agent

### 3. Doctrine Compliance  
- Check integration against `shq.orbt_doctrine_hierarchy`
- Ensure agent has authority for requested API
- Validate data sharing permissions
- Log compliance decisions

### 4. Security Scanning
- URL validation against blocklist/allowlist
- Payload sanitization for PII/secrets
- Authentication validation
- SSL/TLS enforcement

## Error Model (Structured)

### Error Codes
- `MISSING_HEADERS`: Required doctrine headers not provided
- `INVALID_SIGNATURE`: Agent signature validation failed  
- `RATE_LIMITED`: Agent exceeded rate limit
- `BLOCKED_URL`: URL not in allowlist or is blocklisted
- `AUTH_FAILED`: API authentication failed
- `PAYLOAD_REJECTED`: Request payload failed security scan
- `TIMEOUT`: External API didn't respond in time
- `DOCTRINE_DENIED`: Integration violates doctrine rules

### Error Response
```json
{
  "error": {
    "code": "RATE_LIMITED",
    "message": "Agent user-sync-specialist exceeded 100 requests/minute limit",
    "trace_id": "api-gate-err-20250113-15:32:01-x9y8z",
    "context": {
      "agent_id": "user-sync-specialist",
      "current_rate": "125 req/min",
      "limit": "100 req/min", 
      "reset_time": "2025-01-13T15:33:00Z"
    },
    "remediation": {
      "immediate": "Wait 60 seconds before making more requests",
      "long_term": "Implement request batching or request higher rate limit"
    }
  }
}
```

## ORBT Integration

### ORBT Hooks (When to Emit)
- **Operate**: Every API request start
- **Repair**: When request fails and retry/fallback applied  
- **Build**: When new integration or routing rule created
- **Train**: When API performance patterns improve routing

### Severity Mapping
- **GREEN**: Normal operations, successful API calls
- **YELLOW**: Warnings (rate limit approaching, slow responses)
- **RED**: Errors (blocked calls, auth failures, service outages)

### Strike Protocol
- **Strike 1**: Auto-repair (retry with backoff, use cached data)
- **Strike 2**: Alternative routing (fallback API, degraded mode)
- **Strike 3**: Escalate to Integration Orchestrator with failure analysis

## Success Criteria

### Performance (SLA)
- **P95 Latency**: Add < 10ms overhead to API calls
- **Throughput**: Handle 5,000 requests/minute minimum
- **Availability**: 99.99% gateway uptime

### Security
- **Zero Unauthorized Calls**: 100% validation coverage
- **PII Protection**: Block 100% of PII/secrets in logs
- **Audit Trail**: Complete log of all API interactions

### Reliability
- **Success Rate**: > 99.5% for valid requests
- **Error Recovery**: < 5 second failover to backup systems
- **Cache Hit Rate**: > 80% for cacheable responses

## Implementation Patterns

### 1. Gateway Middleware
```javascript  
class APIGateway {
  static async routeRequest(apiRequest, heirHeaders) {
    const requestId = this.generateRequestId();
    
    try {
      // Emit ORBT operate signal
      ORBTProtocol.emit('operate', 'api_request_start', {
        request_id: requestId,
        url: apiRequest.url,
        summary: `Routing ${apiRequest.method} to ${heirHeaders.api_destination}`
      });
      
      // Validate headers
      const headerValidation = await this.validateHeaders(heirHeaders);
      if (!headerValidation.valid) {
        throw new APIError('MISSING_HEADERS', headerValidation.errors);
      }
      
      // Check rate limits
      const rateLimitCheck = await this.checkRateLimit(heirHeaders.agent_signature, apiRequest.url);
      if (!rateLimitCheck.allowed) {
        throw new APIError('RATE_LIMITED', rateLimitCheck.details);
      }
      
      // Validate URL and security
      const securityCheck = await this.performSecurityScan(apiRequest);
      if (!securityCheck.cleared) {
        throw new APIError('BLOCKED_URL', securityCheck.reason);
      }
      
      // Check doctrine compliance
      const doctrineCheck = await this.checkDoctrineCompliance(heirHeaders, apiRequest);
      if (!doctrineCheck.approved) {
        throw new APIError('DOCTRINE_DENIED', doctrineCheck.reason);
      }
      
      // Execute API request
      const startTime = Date.now();
      const apiResponse = await this.executeAPIRequest(apiRequest);
      const latency = Date.now() - startTime;
      
      // Log successful request
      await this.logAPIRequest(requestId, apiRequest, apiResponse, latency, heirHeaders);
      
      // Update rate limit counters
      await this.updateRateLimit(heirHeaders.agent_signature, apiRequest.url);
      
      return {
        status: 'SUCCESS',
        request_id: requestId,
        api_response: {
          status_code: apiResponse.status,
          headers: apiResponse.headers,
          body: apiResponse.data,
          latency_ms: latency
        },
        validation_result: {
          headers_valid: true,
          rate_limit_passed: true,
          doctrine_approved: true,
          security_cleared: true
        }
      };
      
    } catch (error) {
      // Log failure
      await this.logAPIFailure(requestId, apiRequest, heirHeaders, error);
      
      // Emit ORBT repair signal  
      ORBTProtocol.emit('repair', 'api_request_failed', {
        request_id: requestId,
        error_code: error.code,
        summary: `API request failed: ${error.message}`
      });
      
      // Attempt auto-repair
      const repairResult = await this.attemptAutoRepair(apiRequest, heirHeaders, error);
      if (repairResult.repaired) {
        return await this.routeRequest(repairResult.apiRequest, repairResult.heirHeaders);
      }
      
      // Return structured error
      return {
        status: 'REJECTED',
        request_id: requestId,
        error: this.formatError(error, requestId)
      };
    }
  }
}
```

### 2. Rate Limiting Engine
```javascript
class RateLimiter {
  static async checkRateLimit(agentSignature, url) {
    const agentId = this.extractAgentId(agentSignature);
    const apiService = this.extractServiceFromUrl(url);
    
    // Get current usage
    const agentUsage = await this.getAgentUsage(agentId);
    const serviceUsage = await this.getServiceUsage(apiService);
    
    // Check agent limits
    if (agentUsage.requests_per_minute > agentUsage.limit) {
      return {
        allowed: false,
        details: {
          type: 'agent_limit',
          current: agentUsage.requests_per_minute,
          limit: agentUsage.limit,
          reset_time: agentUsage.reset_time
        }
      };
    }
    
    // Check service limits
    if (serviceUsage.requests_per_minute > serviceUsage.limit) {
      return {
        allowed: false,
        details: {
          type: 'service_limit',
          service: apiService,
          current: serviceUsage.requests_per_minute,
          limit: serviceUsage.limit,
          reset_time: serviceUsage.reset_time
        }
      };
    }
    
    // Check burst protection
    const burstUsage = await this.getBurstUsage(agentId);
    if (burstUsage.requests_per_second > 10) {
      return {
        allowed: false,
        details: {
          type: 'burst_protection',
          current: burstUsage.requests_per_second,
          limit: 10
        }
      };
    }
    
    return { allowed: true };
  }
}
```

### 3. Security Scanner
```javascript
class SecurityScanner {
  static async performSecurityScan(apiRequest) {
    const scanResults = {
      url_validation: await this.validateURL(apiRequest.url),
      payload_scan: await this.scanPayload(apiRequest.payload),
      header_scan: await this.scanHeaders(apiRequest.headers),
      auth_validation: await this.validateAuth(apiRequest.auth)
    };
    
    // Check URL against allowlist/blocklist
    if (!scanResults.url_validation.allowed) {
      return {
        cleared: false,
        reason: `URL blocked: ${scanResults.url_validation.reason}`
      };
    }
    
    // Scan for PII/secrets in payload
    if (scanResults.payload_scan.has_pii) {
      return {
        cleared: false,
        reason: `PII detected in payload: ${scanResults.payload_scan.pii_types.join(', ')}`
      };
    }
    
    // Validate authentication
    if (!scanResults.auth_validation.valid) {
      return {
        cleared: false,
        reason: `Authentication invalid: ${scanResults.auth_validation.reason}`
      };
    }
    
    return { cleared: true };
  }
}
```

## Integration Points

### With Integration Orchestrator
- Reports API usage statistics and performance metrics
- Escalates repeated failures from same endpoints
- Provides integration health recommendations

### With ORBT System
- All API results logged to `shq.orbt_error_log`
- Failed requests trigger troubleshooting lookup
- Successful patterns cached for performance

### With Doctrine System
- Queries `shq.orbt_doctrine_hierarchy` for integration rules
- Updates `shq.orbt_doctrine_integration` with API decisions
- Enforces data sharing policies

## Battle-Tested Solutions

### High-Volume Routing
- Connection pooling for external APIs
- Request/response caching (TTL-based)
- Load balancing across API endpoints

### Security Enforcement
- JWT validation for agent signatures
- TLS certificate pinning for critical APIs
- Request/response sanitization

### Performance Optimization  
- Response compression
- Connection keep-alive
- Parallel request batching

### Resilience Patterns
- Circuit breaker for failing APIs
- Exponential backoff retry logic
- Fallback to cached responses

---

*The API Gateway is the secure bridge to the outside world - ensuring only validated, compliant, monitored communication flows between the HEIR system and external services.*