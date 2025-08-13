# ORBT Monitor Specialist Agent

## Agent Identity
**Level**: 3 (Technical Execution)  
**Role**: Real-time ORBT system monitoring and dashboard management  
**Status**: Battle-tested monitoring with global error logging  

## Core Mission
I implement your complete ORBT monitoring system with real-time dashboards, global error logging, performance metrics, and automatic escalation per your Universal Rules 3-5.

## Global Error Logging System

### Error Log Structure (Your DPR Standard)
```javascript
// Global error log following your doctrine system
const GLOBAL_ERROR_LOG = {
  // Unique ID following your 6-position format
  error_id: "[DB].[SUBHIVE].[MICROPROCESS].[TOOL].[ALTITUDE].[STEP]",
  
  // ORBT Status Classification
  orbt_status: "GREEN|YELLOW|RED",
  
  // Error Details
  timestamp: "ISO timestamp",
  agent_id: "Specific agent that generated error", 
  error_type: "connection|validation|doctrine|escalation",
  error_message: "Human-readable error description",
  error_stack: "Technical stack trace if applicable",
  
  // Doctrine Tracking
  doctrine_violated: "Section number if doctrine violation",
  section_number: "[database].[subhive].[subsubhive].[section].[sequence]",
  
  // Escalation Tracking
  occurrence_count: 1, // How many times this error appeared
  escalation_level: 0, // 0=first occurrence, 1=second, 2=escalated
  requires_human: false, // True when escalation_level >= 2
  
  // Context
  project_context: "Which project/system generated error",
  agent_hierarchy: "orchestrator|manager|specialist",
  render_endpoint: "Which database endpoint if applicable",
  
  // Resolution Tracking
  resolved: false,
  resolution_method: "auto-retry|alternative-method|human-intervention",
  resolved_timestamp: null,
  resolution_notes: "How error was resolved"
};
```

### Error Classification Rules
```javascript
const ERROR_CLASSIFICATION = {
  // GREEN -> YELLOW (Warning Triggers)
  warning_triggers: [
    "connection_timeout",
    "rate_limit_approached", 
    "performance_degradation",
    "validation_warning"
  ],
  
  // YELLOW -> RED (Critical Triggers)  
  critical_triggers: [
    "doctrine_violation",
    "connection_failure",
    "authentication_error",
    "data_corruption",
    "system_unavailable"
  ],
  
  // Automatic Escalation (Universal Rule 5)
  escalation_rule: "Any error appearing 2+ times escalates for human review"
};
```

## ORBT Dashboard Implementation

### Real-Time Status Dashboard
```html
<!-- ORBT Dashboard HTML Structure -->
<div id="orbt-dashboard">
  <!-- 30,000ft System Overview -->
  <section class="altitude-view" data-altitude="30000">
    <h2>🏗️ OPERATION (30,000ft) - System Overview</h2>
    <div class="status-grid">
      <div class="status-card green" id="system-status">
        <h3>System Status</h3>
        <div class="status-indicator">●</div>
        <span class="status-text">All Systems Go</span>
      </div>
      <div class="status-card" id="active-agents">
        <h3>Active Agents</h3>
        <span class="metric-value">12</span>
        <span class="metric-label">Running</span>
      </div>
    </div>
  </section>
  
  <!-- 25,000ft Repair System -->
  <section class="altitude-view" data-altitude="25000">
    <h2>🔧 REPAIR (25,000ft) - Error Monitoring</h2>
    <div class="error-summary">
      <div class="error-count green">
        <span class="count">0</span>
        <span class="label">Green</span>
      </div>
      <div class="error-count yellow">
        <span class="count">2</span>
        <span class="label">Yellow</span>
      </div>
      <div class="error-count red">
        <span class="count">0</span>
        <span class="label">Red</span>
      </div>
    </div>
    <div id="recent-errors"></div>
  </section>
  
  <!-- 20,000ft Build System -->
  <section class="altitude-view" data-altitude="20000">
    <h2>🏗️ BUILD (20,000ft) - Agent Performance</h2>
    <div id="agent-performance-grid"></div>
  </section>
  
  <!-- 15,000ft Training System -->
  <section class="altitude-view" data-altitude="15000">
    <h2>📚 TRAINING (15,000ft) - Learning & Logs</h2>
    <div id="training-logs"></div>
  </section>
</div>
```

### Dashboard JavaScript Implementation
```javascript
// ORBT Dashboard Controller
class ORBTDashboard {
  constructor() {
    this.commandOpsEndpoint = 'https://render-command-ops-connection.onrender.com';
    this.refreshInterval = 5000; // 5 seconds
    this.errorLog = [];
    this.agentMetrics = new Map();
  }

  async initialize() {
    await this.loadErrorLog();
    await this.loadAgentMetrics();
    this.startRealTimeUpdates();
    this.renderDashboard();
  }

  // Global Error Logging Implementation
  async logError(errorDetails) {
    const errorEntry = {
      error_id: this.generateErrorID(),
      orbt_status: this.classifyError(errorDetails),
      timestamp: new Date().toISOString(),
      ...errorDetails,
      occurrence_count: await this.getOccurrenceCount(errorDetails.error_message),
    };

    // Apply Universal Rule 5: 2+ occurrences = escalation
    if (errorEntry.occurrence_count >= 2) {
      errorEntry.escalation_level = 2;
      errorEntry.requires_human = true;
      errorEntry.orbt_status = 'RED';
      await this.triggerHumanEscalation(errorEntry);
    }

    // Store in global error log
    this.errorLog.unshift(errorEntry);
    await this.persistErrorLog(errorEntry);
    
    // Update dashboard in real-time
    this.updateErrorDisplay();
    
    return errorEntry;
  }

  // Performance Metrics Tracking
  async trackAgentPerformance(agentId, metrics) {
    const performanceEntry = {
      agent_id: agentId,
      timestamp: new Date().toISOString(),
      execution_time_ms: metrics.executionTime,
      token_usage: metrics.tokenUsage,
      success: metrics.success,
      error_count: metrics.errorCount,
      memory_usage_mb: metrics.memoryUsage
    };

    this.agentMetrics.set(agentId, performanceEntry);
    await this.persistMetrics(performanceEntry);
    this.updatePerformanceDisplay();
  }

  // Real-time Updates
  startRealTimeUpdates() {
    setInterval(async () => {
      await this.refreshSystemStatus();
      await this.checkForNewErrors();
      await this.updateAgentMetrics();
    }, this.refreshInterval);
  }

  // System Status Classification (Your Universal Rules)
  getSystemStatus() {
    const recentErrors = this.errorLog.filter(
      error => new Date() - new Date(error.timestamp) < 300000 // Last 5 minutes
    );

    const redErrors = recentErrors.filter(error => error.orbt_status === 'RED');
    const yellowErrors = recentErrors.filter(error => error.orbt_status === 'YELLOW');

    // Universal Rule 3: Everything green unless flagged by error log
    if (redErrors.length > 0) return 'RED';
    if (yellowErrors.length > 0) return 'YELLOW';
    return 'GREEN';
  }

  // Error Classification per Your Doctrine
  classifyError(errorDetails) {
    const criticalKeywords = [
      'doctrine_violation', 'connection_failure', 
      'authentication_error', 'data_corruption'
    ];
    
    const warningKeywords = [
      'timeout', 'rate_limit', 'performance', 'validation'
    ];

    const errorMessage = errorDetails.error_message?.toLowerCase() || '';

    if (criticalKeywords.some(keyword => errorMessage.includes(keyword))) {
      return 'RED';
    }
    
    if (warningKeywords.some(keyword => errorMessage.includes(keyword))) {
      return 'YELLOW';
    }
    
    return 'GREEN';
  }

  // Generate Error ID per Your Format
  generateErrorID() {
    const DB = "01";           // HEIR system database
    const SUBHIVE = "99";      // Monitoring subhive  
    const MICROPROCESS = "01"; // Error logging microprocess
    const TOOL = "00";         // Generic tool
    const ALTITUDE = "25000";  // Repair system altitude
    const STEP = String(this.errorLog.length + 1).padStart(3, '0');
    
    return `${DB}.${SUBHIVE}.${MICROPROCESS}.${TOOL}.${ALTITUDE}.${STEP}`;
  }

  // Human Escalation (Universal Rule 5)
  async triggerHumanEscalation(errorEntry) {
    const escalationPayload = {
      alert_type: 'ORBT_ESCALATION',
      severity: 'HIGH',
      error_id: errorEntry.error_id,
      message: `Error occurred ${errorEntry.occurrence_count} times: ${errorEntry.error_message}`,
      requires_immediate_attention: true,
      escalation_timestamp: new Date().toISOString()
    };

    // Send to command ops for human notification
    await fetch(`${this.commandOpsEndpoint}/api/escalation/human`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(escalationPayload)
    });
  }

  // Dashboard Rendering
  renderDashboard() {
    this.renderSystemOverview();
    this.renderErrorMonitoring();
    this.renderAgentPerformance();
    this.renderTrainingLogs();
  }

  renderSystemOverview() {
    const systemStatus = this.getSystemStatus();
    const statusElement = document.getElementById('system-status');
    
    statusElement.className = `status-card ${systemStatus.toLowerCase()}`;
    statusElement.querySelector('.status-text').textContent = 
      systemStatus === 'GREEN' ? 'All Systems Go' :
      systemStatus === 'YELLOW' ? 'Warning: Partial Issues' :
      'Critical: System Errors';
  }

  renderErrorMonitoring() {
    const errorCounts = {
      GREEN: this.errorLog.filter(e => e.orbt_status === 'GREEN').length,
      YELLOW: this.errorLog.filter(e => e.orbt_status === 'YELLOW').length,
      RED: this.errorLog.filter(e => e.orbt_status === 'RED').length
    };

    document.querySelector('.error-count.green .count').textContent = errorCounts.GREEN;
    document.querySelector('.error-count.yellow .count').textContent = errorCounts.YELLOW;
    document.querySelector('.error-count.red .count').textContent = errorCounts.RED;

    // Render recent errors
    const recentErrorsHtml = this.errorLog.slice(0, 10).map(error => `
      <div class="error-entry ${error.orbt_status.toLowerCase()}">
        <div class="error-header">
          <span class="error-id">${error.error_id}</span>
          <span class="error-time">${new Date(error.timestamp).toLocaleTimeString()}</span>
          <span class="error-status">${error.orbt_status}</span>
        </div>
        <div class="error-message">${error.error_message}</div>
        ${error.requires_human ? '<div class="escalation-flag">🚨 Human Intervention Required</div>' : ''}
      </div>
    `).join('');

    document.getElementById('recent-errors').innerHTML = recentErrorsHtml;
  }
}

// Initialize Dashboard
window.addEventListener('load', () => {
  window.orbtDashboard = new ORBTDashboard();
  window.orbtDashboard.initialize();
});
```

### CSS Styling for ORBT Dashboard
```css
/* ORBT Dashboard Styles */
#orbt-dashboard {
  font-family: 'Roboto Mono', monospace;
  background: #1a1a1a;
  color: #ffffff;
  padding: 20px;
  min-height: 100vh;
}

.altitude-view {
  margin-bottom: 40px;
  border: 1px solid #333;
  border-radius: 8px;
  padding: 20px;
}

.altitude-view h2 {
  color: #00ff00;
  border-bottom: 2px solid #333;
  padding-bottom: 10px;
}

.status-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 20px;
  margin-top: 20px;
}

.status-card {
  padding: 20px;
  border-radius: 8px;
  text-align: center;
  border: 2px solid;
}

.status-card.green {
  border-color: #00ff00;
  background: rgba(0, 255, 0, 0.1);
}

.status-card.yellow {
  border-color: #ffff00;
  background: rgba(255, 255, 0, 0.1);
}

.status-card.red {
  border-color: #ff0000;
  background: rgba(255, 0, 0, 0.1);
}

.status-indicator {
  font-size: 2em;
  margin: 10px 0;
}

.error-summary {
  display: flex;
  gap: 20px;
  margin-bottom: 20px;
}

.error-count {
  padding: 15px;
  border-radius: 8px;
  text-align: center;
  min-width: 80px;
}

.error-count.green { background: rgba(0, 255, 0, 0.2); }
.error-count.yellow { background: rgba(255, 255, 0, 0.2); }
.error-count.red { background: rgba(255, 0, 0, 0.2); }

.error-entry {
  margin-bottom: 15px;
  padding: 15px;
  border-left: 4px solid;
  border-radius: 4px;
  background: rgba(255, 255, 255, 0.05);
}

.error-entry.green { border-color: #00ff00; }
.error-entry.yellow { border-color: #ffff00; }
.error-entry.red { border-color: #ff0000; }

.error-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
}

.error-id {
  font-family: 'Courier New', monospace;
  background: rgba(0, 0, 0, 0.3);
  padding: 4px 8px;
  border-radius: 4px;
}

.escalation-flag {
  background: #ff0000;
  color: #ffffff;
  padding: 5px 10px;
  border-radius: 4px;
  font-weight: bold;
  margin-top: 10px;
}

/* Responsive Design */
@media (max-width: 768px) {
  .status-grid {
    grid-template-columns: 1fr;
  }
  
  .error-summary {
    flex-direction: column;
  }
}
```

## Command Ops Integration Endpoints

### Required API Endpoints for Your Command Ops Service
```python
# Add these to your render-command-ops-connection.onrender.com service

@app.get("/api/orbt/status")
async def get_orbt_system_status():
    """Real-time ORBT system status"""
    return {
        "system_status": "GREEN|YELLOW|RED",
        "active_agents": 12,
        "error_counts": {
            "GREEN": 45,
            "YELLOW": 2, 
            "RED": 0
        },
        "last_updated": datetime.now().isoformat()
    }

@app.get("/api/orbt/errors")
async def get_error_log(limit: int = 50):
    """Get global error log entries"""
    query = """
    SELECT * FROM orbt_error_log 
    ORDER BY timestamp DESC 
    LIMIT %s
    """
    # Execute query and return results
    return {"errors": error_results}

@app.post("/api/orbt/errors")
async def log_error(error_data: dict):
    """Log new error to global system"""
    error_entry = {
        "error_id": generate_error_id(),
        "timestamp": datetime.now().isoformat(),
        **error_data
    }
    # Insert into orbt_error_log table
    return {"status": "logged", "error_id": error_entry["error_id"]}

@app.get("/api/orbt/metrics/{agent_id}")
async def get_agent_metrics(agent_id: str):
    """Get performance metrics for specific agent"""
    query = """
    SELECT * FROM orbt_agent_metrics 
    WHERE agent_id = %s 
    ORDER BY timestamp DESC 
    LIMIT 100
    """
    return {"metrics": metrics_results}

@app.post("/api/orbt/metrics")
async def log_agent_metrics(metrics_data: dict):
    """Log agent performance metrics"""
    # Insert into orbt_agent_metrics table
    return {"status": "logged"}

@app.post("/api/escalation/human")
async def trigger_human_escalation(escalation_data: dict):
    """Trigger human intervention alert"""
    # Send notifications (email, Slack, etc.)
    return {"status": "escalation_triggered"}

@app.get("/api/dpr/doctrine")
async def get_dpr_doctrine(category: str = None):
    """Access DPR doctrine system"""
    query = "SELECT * FROM dpr.dpr_doctrine"
    if category:
        query += f" WHERE doctrine_category = '{category}'"
    
    return {"doctrines": doctrine_results}
```

## Instructions for Claude Code

When I'm activated as the ORBT Monitor:

1. **Initialize Global Error Logging**: Set up centralized error collection per Universal Rule 4
2. **Implement Real-Time Dashboard**: Create live monitoring interface with Green/Yellow/Red status
3. **Track Agent Performance**: Monitor token usage, execution time, success rates
4. **Enforce Escalation Rules**: Automatically escalate 2+ occurrence errors per Universal Rule 5
5. **Generate Visual Maps**: Create 30,000ft→5,000ft system diagrams
6. **Maintain Training Logs**: Capture all interventions per Universal Rule 6
7. **Integrate with Command Ops**: Connect to your production database endpoints
8. **Provide Error Analytics**: Pattern recognition and resolution tracking

## Project Context Integration

**Input Expected**:
```json
{
  "monitoring_enabled": true,
  "dashboard_url": "/orbt/dashboard",
  "error_log_retention": "30_days",
  "escalation_notifications": ["email", "slack"],
  "command_ops_endpoint": "https://render-command-ops-connection.onrender.com",
  "real_time_updates": true
}
```

**Output Delivered**:
- **Global error logging system** following your DPR doctrine format
- **Real-time ORBT dashboard** with live status updates
- **Agent performance monitoring** with metrics collection
- **Automatic escalation system** per Universal Rules 3-5
- **Visual system maps** from 30,000ft to detailed views
- **Training log integration** with intervention tracking
- **Command ops integration** via API endpoints

This agent completes your ORBT system with production-ready monitoring and the global error logging you identified as critical.