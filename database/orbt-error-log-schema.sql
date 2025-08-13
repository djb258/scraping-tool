-- ORBT Global Error Logging System
-- Database Schema for Command Ops Integration

-- Global Error Log Table (Universal Rule 4: Centralized error routing)
CREATE TABLE IF NOT EXISTS orbt_error_log (
    -- Primary identification
    id SERIAL PRIMARY KEY,
    error_id VARCHAR(50) UNIQUE NOT NULL, -- Your 6-position format: [DB].[SUBHIVE].[MICROPROCESS].[TOOL].[ALTITUDE].[STEP]
    
    -- ORBT Status Classification  
    orbt_status VARCHAR(10) NOT NULL CHECK (orbt_status IN ('GREEN', 'YELLOW', 'RED')),
    
    -- Timestamps
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_timestamp TIMESTAMPTZ NULL,
    
    -- Agent Context
    agent_id VARCHAR(100) NOT NULL,
    agent_hierarchy VARCHAR(20) NOT NULL CHECK (agent_hierarchy IN ('orchestrator', 'manager', 'specialist')),
    
    -- Error Details
    error_type VARCHAR(50) NOT NULL, -- connection, validation, doctrine, escalation
    error_message TEXT NOT NULL,
    error_stack TEXT NULL,
    
    -- DPR Doctrine Integration
    doctrine_violated VARCHAR(50) NULL, -- Section number if doctrine violation
    section_number VARCHAR(50) NULL,   -- [database].[subhive].[subsubhive].[section].[sequence]
    
    -- Escalation Tracking (Universal Rule 5: 2+ occurrences escalate)
    occurrence_count INTEGER NOT NULL DEFAULT 1,
    escalation_level INTEGER NOT NULL DEFAULT 0, -- 0=first, 1=second, 2=escalated
    requires_human BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- System Context
    project_context VARCHAR(100) NULL,
    render_endpoint VARCHAR(200) NULL, -- Which database endpoint
    
    -- Resolution Tracking
    resolved BOOLEAN NOT NULL DEFAULT FALSE,
    resolution_method VARCHAR(50) NULL, -- auto-retry, alternative-method, human-intervention
    resolution_notes TEXT NULL,
    
    -- Performance Impact
    downtime_seconds INTEGER NULL,
    affected_users INTEGER NULL,
    
    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Agent Performance Metrics Table
CREATE TABLE IF NOT EXISTS orbt_agent_metrics (
    id SERIAL PRIMARY KEY,
    metric_id VARCHAR(50) UNIQUE NOT NULL, -- Your 6-position format
    
    -- Agent Identification
    agent_id VARCHAR(100) NOT NULL,
    agent_type VARCHAR(20) NOT NULL CHECK (agent_type IN ('orchestrator', 'manager', 'specialist')),
    
    -- Performance Metrics
    execution_time_ms INTEGER NOT NULL,
    token_usage INTEGER NULL,
    memory_usage_mb DECIMAL(10,2) NULL,
    cpu_usage_percent DECIMAL(5,2) NULL,
    
    -- Success Metrics
    success BOOLEAN NOT NULL,
    error_count INTEGER NOT NULL DEFAULT 0,
    retry_count INTEGER NOT NULL DEFAULT 0,
    
    -- Context
    project_context VARCHAR(100) NULL,
    render_endpoint VARCHAR(200) NULL,
    operation_type VARCHAR(50) NOT NULL, -- build, repair, operation, training
    
    -- Timestamps
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ORBT System Status Table (Real-time system overview)
CREATE TABLE IF NOT EXISTS orbt_system_status (
    id SERIAL PRIMARY KEY,
    status_id VARCHAR(50) UNIQUE NOT NULL,
    
    -- System Overview
    overall_status VARCHAR(10) NOT NULL CHECK (overall_status IN ('GREEN', 'YELLOW', 'RED')),
    active_agents INTEGER NOT NULL DEFAULT 0,
    
    -- Error Counts (last 24 hours)
    green_count INTEGER NOT NULL DEFAULT 0,
    yellow_count INTEGER NOT NULL DEFAULT 0, 
    red_count INTEGER NOT NULL DEFAULT 0,
    
    -- Performance Metrics (averages)
    avg_execution_time_ms DECIMAL(10,2) NULL,
    avg_token_usage DECIMAL(10,2) NULL,
    avg_memory_usage_mb DECIMAL(10,2) NULL,
    
    -- System Health
    uptime_seconds INTEGER NOT NULL DEFAULT 0,
    last_error_timestamp TIMESTAMPTZ NULL,
    escalation_pending INTEGER NOT NULL DEFAULT 0,
    
    -- Timestamps
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Training Log Table (Universal Rule 6: Training logs for live apps)
CREATE TABLE IF NOT EXISTS orbt_training_log (
    id SERIAL PRIMARY KEY,
    training_id VARCHAR(50) UNIQUE NOT NULL,
    
    -- Intervention Details
    intervention_type VARCHAR(50) NOT NULL, -- manual_fix, auto_repair, escalation, learning
    agent_id VARCHAR(100) NOT NULL,
    
    -- Learning Context
    problem_description TEXT NOT NULL,
    solution_applied TEXT NOT NULL,
    resolution_time_seconds INTEGER NULL,
    
    -- Effectiveness Tracking
    success BOOLEAN NOT NULL,
    recurring_issue BOOLEAN NOT NULL DEFAULT FALSE,
    pattern_recognized BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- Documentation
    before_state TEXT NULL,
    after_state TEXT NULL,
    lessons_learned TEXT NULL,
    
    -- Context
    project_context VARCHAR(100) NULL,
    error_id VARCHAR(50) NULL, -- Reference to orbt_error_log if applicable
    
    -- Timestamps
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Error Pattern Recognition Table
CREATE TABLE IF NOT EXISTS orbt_error_patterns (
    id SERIAL PRIMARY KEY,
    pattern_id VARCHAR(50) UNIQUE NOT NULL,
    
    -- Pattern Details
    error_signature VARCHAR(500) NOT NULL, -- Unique pattern identifier
    occurrence_count INTEGER NOT NULL DEFAULT 1,
    first_seen TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_seen TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Pattern Analysis
    pattern_type VARCHAR(50) NOT NULL, -- recurring, escalating, resolved
    confidence_score DECIMAL(5,2) NOT NULL DEFAULT 0.0, -- 0.0 to 1.0
    
    -- Associated Errors
    related_error_ids TEXT[], -- Array of related error_ids
    
    -- Resolution Information
    known_solution TEXT NULL,
    auto_resolution_available BOOLEAN NOT NULL DEFAULT FALSE,
    manual_intervention_required BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Escalation Queue Table
CREATE TABLE IF NOT EXISTS orbt_escalation_queue (
    id SERIAL PRIMARY KEY,
    escalation_id VARCHAR(50) UNIQUE NOT NULL,
    
    -- Escalation Details
    priority VARCHAR(10) NOT NULL CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    status VARCHAR(20) NOT NULL CHECK (status IN ('PENDING', 'IN_PROGRESS', 'RESOLVED', 'DISMISSED')),
    
    -- Related Error
    error_id VARCHAR(50) NOT NULL REFERENCES orbt_error_log(error_id),
    
    -- Assignment
    assigned_to VARCHAR(100) NULL,
    escalated_by VARCHAR(100) NOT NULL,
    
    -- Timing
    escalated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    due_at TIMESTAMPTZ NULL,
    resolved_at TIMESTAMPTZ NULL,
    
    -- Resolution
    resolution_notes TEXT NULL,
    resolution_method VARCHAR(50) NULL,
    
    -- Follow-up
    follow_up_required BOOLEAN NOT NULL DEFAULT FALSE,
    follow_up_date TIMESTAMPTZ NULL,
    
    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for Performance
CREATE INDEX IF NOT EXISTS idx_error_log_timestamp ON orbt_error_log(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_error_log_status ON orbt_error_log(orbt_status);
CREATE INDEX IF NOT EXISTS idx_error_log_agent ON orbt_error_log(agent_id);
CREATE INDEX IF NOT EXISTS idx_error_log_escalation ON orbt_error_log(requires_human, escalation_level);

CREATE INDEX IF NOT EXISTS idx_agent_metrics_timestamp ON orbt_agent_metrics(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_agent_metrics_agent ON orbt_agent_metrics(agent_id);
CREATE INDEX IF NOT EXISTS idx_agent_metrics_success ON orbt_agent_metrics(success);

CREATE INDEX IF NOT EXISTS idx_training_log_timestamp ON orbt_training_log(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_training_log_agent ON orbt_training_log(agent_id);
CREATE INDEX IF NOT EXISTS idx_training_log_recurring ON orbt_training_log(recurring_issue);

CREATE INDEX IF NOT EXISTS idx_error_patterns_signature ON orbt_error_patterns(error_signature);
CREATE INDEX IF NOT EXISTS idx_error_patterns_count ON orbt_error_patterns(occurrence_count DESC);

CREATE INDEX IF NOT EXISTS idx_escalation_status ON orbt_escalation_queue(status);
CREATE INDEX IF NOT EXISTS idx_escalation_priority ON orbt_escalation_queue(priority);

-- Functions for Error ID Generation (Your 6-position format)
CREATE OR REPLACE FUNCTION generate_error_id() 
RETURNS VARCHAR(50) AS $$
DECLARE
    db_code VARCHAR(2) := '01';           -- HEIR system database
    subhive_code VARCHAR(2) := '99';      -- Monitoring subhive
    microprocess_code VARCHAR(2) := '01'; -- Error logging microprocess  
    tool_code VARCHAR(2) := '00';         -- Generic tool
    altitude_code VARCHAR(5) := '25000';  -- Repair system altitude
    step_code VARCHAR(3);                 -- Sequential step
    next_step INTEGER;
BEGIN
    -- Get next sequential step number
    SELECT COALESCE(MAX(CAST(SUBSTRING(error_id FROM 15 FOR 3) AS INTEGER)), 0) + 1
    INTO next_step
    FROM orbt_error_log
    WHERE error_id LIKE '01.99.01.00.25000.%';
    
    step_code := LPAD(next_step::TEXT, 3, '0');
    
    RETURN db_code || '.' || subhive_code || '.' || microprocess_code || '.' || 
           tool_code || '.' || altitude_code || '.' || step_code;
END;
$$ LANGUAGE plpgsql;

-- Function for Automatic Escalation (Universal Rule 5)
CREATE OR REPLACE FUNCTION check_error_escalation()
RETURNS TRIGGER AS $$
BEGIN
    -- Count occurrences of this error pattern
    UPDATE orbt_error_log 
    SET occurrence_count = (
        SELECT COUNT(*) 
        FROM orbt_error_log 
        WHERE error_message = NEW.error_message 
        AND agent_id = NEW.agent_id
    )
    WHERE error_id = NEW.error_id;
    
    -- Apply Universal Rule 5: 2+ occurrences = escalation
    IF (SELECT occurrence_count FROM orbt_error_log WHERE error_id = NEW.error_id) >= 2 THEN
        UPDATE orbt_error_log 
        SET 
            escalation_level = 2,
            requires_human = TRUE,
            orbt_status = 'RED'
        WHERE error_id = NEW.error_id;
        
        -- Create escalation queue entry
        INSERT INTO orbt_escalation_queue (
            escalation_id, error_id, priority, status, escalated_by
        ) VALUES (
            'ESC-' || NEW.error_id,
            NEW.error_id,
            'HIGH',
            'PENDING',
            'SYSTEM_AUTO'
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for Automatic Escalation
CREATE TRIGGER trigger_error_escalation
    AFTER INSERT ON orbt_error_log
    FOR EACH ROW
    EXECUTE FUNCTION check_error_escalation();

-- Function to Update System Status
CREATE OR REPLACE FUNCTION update_system_status()
RETURNS VOID AS $$
DECLARE
    current_status VARCHAR(10);
    error_counts RECORD;
BEGIN
    -- Calculate error counts for last 24 hours
    SELECT 
        COUNT(CASE WHEN orbt_status = 'GREEN' THEN 1 END) as green_count,
        COUNT(CASE WHEN orbt_status = 'YELLOW' THEN 1 END) as yellow_count,
        COUNT(CASE WHEN orbt_status = 'RED' THEN 1 END) as red_count
    INTO error_counts
    FROM orbt_error_log 
    WHERE timestamp >= NOW() - INTERVAL '24 hours';
    
    -- Determine overall system status (Universal Rule 3: Green unless flagged)
    IF error_counts.red_count > 0 THEN
        current_status := 'RED';
    ELSIF error_counts.yellow_count > 0 THEN
        current_status := 'YELLOW';
    ELSE
        current_status := 'GREEN';
    END IF;
    
    -- Update or insert system status
    INSERT INTO orbt_system_status (
        status_id, overall_status, green_count, yellow_count, red_count, 
        active_agents, last_error_timestamp, escalation_pending
    ) VALUES (
        'SYSTEM_STATUS_' || TO_CHAR(NOW(), 'YYYY_MM_DD'),
        current_status,
        error_counts.green_count,
        error_counts.yellow_count,
        error_counts.red_count,
        (SELECT COUNT(DISTINCT agent_id) FROM orbt_agent_metrics WHERE timestamp >= NOW() - INTERVAL '1 hour'),
        (SELECT MAX(timestamp) FROM orbt_error_log),
        (SELECT COUNT(*) FROM orbt_escalation_queue WHERE status = 'PENDING')
    )
    ON CONFLICT (status_id) DO UPDATE SET
        overall_status = EXCLUDED.overall_status,
        green_count = EXCLUDED.green_count,
        yellow_count = EXCLUDED.yellow_count,
        red_count = EXCLUDED.red_count,
        active_agents = EXCLUDED.active_agents,
        last_error_timestamp = EXCLUDED.last_error_timestamp,
        escalation_pending = EXCLUDED.escalation_pending,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- Scheduled job to update system status (run every 5 minutes)
-- Note: This would typically be handled by your application or cron job
-- SELECT cron.schedule('update-orbt-status', '*/5 * * * *', 'SELECT update_system_status();');

-- Sample Data for Testing
INSERT INTO orbt_error_log (
    error_id, orbt_status, agent_id, agent_hierarchy, error_type, 
    error_message, project_context, render_endpoint
) VALUES 
    ('01.99.01.00.25000.001', 'GREEN', 'system-orchestrator', 'orchestrator', 'info', 'System initialized successfully', 'HEIR-SYSTEM', 'render-command-ops-connection.onrender.com'),
    ('01.99.01.00.25000.002', 'YELLOW', 'render-database-specialist', 'specialist', 'connection', 'Database connection timeout - retrying', 'TEST-PROJECT', 'render-marketing-db.onrender.com');

-- Grant permissions (adjust as needed for your setup)
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO your_api_user;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO your_api_user;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO your_api_user;