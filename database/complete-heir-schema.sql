-- HEIR Agent System - Complete Database Schema
-- Phase 1: Consolidated schema for production deployment
-- Idempotent DDL with proper error handling and rollback support

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create SHQ schema for system headquarters
CREATE SCHEMA IF NOT EXISTS shq;

-- Schema version tracking
CREATE TABLE IF NOT EXISTS shq.doctrine_schema_version (
    version VARCHAR(20) NOT NULL,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    applied_by VARCHAR(100) NOT NULL,
    rollback_sql TEXT NULL,
    notes TEXT NULL,
    PRIMARY KEY (version)
);

-- =============================================================================
-- ORBT ERROR LOGGING SYSTEM
-- =============================================================================

-- Master error logging table (automatically used by all agents)
CREATE TABLE IF NOT EXISTS shq.orbt_error_log (
    id SERIAL PRIMARY KEY,
    error_id VARCHAR(50) UNIQUE NOT NULL,
    orbt_status VARCHAR(10) NOT NULL CHECK (orbt_status IN ('GREEN', 'YELLOW', 'RED')),
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_timestamp TIMESTAMPTZ NULL,
    agent_id VARCHAR(100) NOT NULL,
    agent_hierarchy VARCHAR(20) NOT NULL CHECK (agent_hierarchy IN ('orchestrator', 'manager', 'specialist')),
    error_type VARCHAR(50) NOT NULL,
    error_message TEXT NOT NULL,
    error_stack TEXT NULL,
    doctrine_violated VARCHAR(50) NULL,
    section_number VARCHAR(50) NULL,
    occurrence_count INTEGER NOT NULL DEFAULT 1,
    escalation_level INTEGER NOT NULL DEFAULT 0,
    requires_human BOOLEAN NOT NULL DEFAULT FALSE,
    project_context VARCHAR(100) NULL,
    render_endpoint VARCHAR(200) NULL,
    resolved BOOLEAN NOT NULL DEFAULT FALSE,
    resolution_method VARCHAR(50) NULL,
    resolution_notes TEXT NULL,
    downtime_seconds INTEGER NULL,
    affected_users INTEGER NULL,
    troubleshooting_key VARCHAR(100) NULL,
    auto_fix_attempted BOOLEAN DEFAULT FALSE,
    auto_fix_success BOOLEAN DEFAULT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Escalation queue table (human intervention tracking)
CREATE TABLE IF NOT EXISTS shq.orbt_escalation_queue (
    id SERIAL PRIMARY KEY,
    escalation_id VARCHAR(50) UNIQUE NOT NULL,
    priority VARCHAR(10) NOT NULL CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    status VARCHAR(20) NOT NULL CHECK (status IN ('PENDING', 'IN_PROGRESS', 'RESOLVED', 'DISMISSED')),
    error_id VARCHAR(50) NOT NULL,
    assigned_to VARCHAR(100) NULL,
    escalated_by VARCHAR(100) NOT NULL,
    escalated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    due_at TIMESTAMPTZ NULL,
    resolved_at TIMESTAMPTZ NULL,
    resolution_notes TEXT NULL,
    resolution_method VARCHAR(50) NULL,
    follow_up_required BOOLEAN NOT NULL DEFAULT FALSE,
    follow_up_date TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- System status table (real-time monitoring)
CREATE TABLE IF NOT EXISTS shq.orbt_system_status (
    id SERIAL PRIMARY KEY,
    status_id VARCHAR(50) UNIQUE NOT NULL,
    overall_status VARCHAR(10) NOT NULL CHECK (overall_status IN ('GREEN', 'YELLOW', 'RED')),
    active_agents INTEGER NOT NULL DEFAULT 0,
    green_count INTEGER NOT NULL DEFAULT 0,
    yellow_count INTEGER NOT NULL DEFAULT 0,
    red_count INTEGER NOT NULL DEFAULT 0,
    avg_execution_time_ms DECIMAL(10,2) NULL,
    avg_token_usage DECIMAL(10,2) NULL,
    avg_memory_usage_mb DECIMAL(10,2) NULL,
    uptime_seconds INTEGER NOT NULL DEFAULT 0,
    last_error_timestamp TIMESTAMPTZ NULL,
    escalation_pending INTEGER NOT NULL DEFAULT 0,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- TROUBLESHOOTING GUIDE SYSTEM
-- =============================================================================

-- Troubleshooting guide table (instant error resolution)
CREATE TABLE IF NOT EXISTS shq.orbt_troubleshooting_guide (
    id SERIAL PRIMARY KEY,
    lookup_key VARCHAR(100) UNIQUE NOT NULL,
    unique_id_pattern VARCHAR(50) NOT NULL,
    process_id VARCHAR(50) NOT NULL,
    error_code VARCHAR(20) NOT NULL,
    error_type VARCHAR(50) NOT NULL,
    error_title VARCHAR(200) NOT NULL,
    error_description TEXT NOT NULL,
    business_impact VARCHAR(100) NOT NULL,
    urgency_level VARCHAR(20) NOT NULL,
    immediate_action TEXT NOT NULL,
    diagnostic_steps TEXT[] NOT NULL,
    resolution_steps TEXT[] NOT NULL,
    escalation_criteria TEXT NOT NULL,
    common_causes TEXT[] NOT NULL,
    prevention_tips TEXT[] NOT NULL,
    related_errors VARCHAR(50)[] NULL,
    affected_agents VARCHAR(50)[] NOT NULL,
    affected_domains VARCHAR(50)[] NOT NULL,
    system_components TEXT[] NOT NULL,
    auto_resolvable BOOLEAN NOT NULL DEFAULT FALSE,
    success_rate DECIMAL(5,2) NOT NULL DEFAULT 0.0,
    avg_resolution_time_minutes INTEGER NOT NULL DEFAULT 0,
    requires_human_expertise BOOLEAN NOT NULL DEFAULT FALSE,
    documentation_links TEXT[] NULL,
    code_examples TEXT NULL,
    monitoring_queries TEXT[] NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_seen TIMESTAMPTZ NULL,
    version VARCHAR(10) NOT NULL DEFAULT '1.0.0'
);

-- =============================================================================
-- RESOLUTION LIBRARY SYSTEM  
-- =============================================================================

-- Resolution library table (never start from scratch)
CREATE TABLE IF NOT EXISTS shq.orbt_resolution_library (
    id SERIAL PRIMARY KEY,
    resolution_id VARCHAR(50) UNIQUE NOT NULL,
    error_signature VARCHAR(500) NOT NULL,
    error_type VARCHAR(50) NOT NULL,
    error_code VARCHAR(20) NOT NULL,
    unique_id_pattern VARCHAR(50) NOT NULL,
    process_id VARCHAR(50) NOT NULL,
    fix_title VARCHAR(200) NOT NULL,
    fix_description TEXT NOT NULL,
    fix_category VARCHAR(50) NOT NULL,
    diagnostic_commands TEXT[] NOT NULL,
    fix_commands TEXT[] NOT NULL,
    verification_commands TEXT[] NOT NULL,
    rollback_commands TEXT[] NOT NULL,
    affected_systems TEXT[] NOT NULL,
    prerequisites TEXT[] NULL,
    side_effects TEXT[] NULL,
    environment_type VARCHAR(20) NOT NULL,
    fixed_by VARCHAR(100) NOT NULL,
    fixed_by_type VARCHAR(20) NOT NULL,
    original_error_id VARCHAR(50) NOT NULL,
    resolution_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolution_time_minutes INTEGER NOT NULL,
    success_rate DECIMAL(5,2) NOT NULL DEFAULT 100.0,
    application_count INTEGER NOT NULL DEFAULT 1,
    last_applied TIMESTAMPTZ NULL,
    lessons_learned TEXT NOT NULL,
    improvement_suggestions TEXT NULL,
    related_resolutions VARCHAR(50)[] NULL,
    documentation_created TEXT[] NULL,
    code_changes_required BOOLEAN DEFAULT FALSE,
    config_changes_required BOOLEAN DEFAULT FALSE,
    infrastructure_changes_required BOOLEAN DEFAULT FALSE,
    peer_reviewed BOOLEAN DEFAULT FALSE,
    peer_reviewer VARCHAR(100) NULL,
    review_notes TEXT NULL,
    approved_for_automation BOOLEAN DEFAULT FALSE,
    automation_confidence DECIMAL(5,2) DEFAULT 0.0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    version VARCHAR(10) NOT NULL DEFAULT '1.0.0'
);

-- =============================================================================
-- TODO SYSTEM TABLES
-- =============================================================================

-- Project todo tracking table
CREATE TABLE IF NOT EXISTS shq.orbt_project_todos (
    id SERIAL PRIMARY KEY,
    todo_id VARCHAR(50) UNIQUE NOT NULL,
    
    -- Project Context
    project_name VARCHAR(100) NOT NULL,
    project_session VARCHAR(50) NOT NULL,
    agent_id VARCHAR(100) NOT NULL,
    
    -- Todo Details
    todo_title VARCHAR(200) NOT NULL,
    todo_description TEXT NULL,
    todo_category VARCHAR(50) NOT NULL,
    priority VARCHAR(20) NOT NULL DEFAULT 'MEDIUM',
    
    -- Status Tracking
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'blocked', 'cancelled')),
    completion_percentage INTEGER DEFAULT 0 CHECK (completion_percentage >= 0 AND completion_percentage <= 100),
    
    -- Dependencies
    depends_on_todo_ids VARCHAR(50)[] NULL,
    blocks_todo_ids VARCHAR(50)[] NULL,
    
    -- Time Tracking
    estimated_minutes INTEGER NULL,
    actual_minutes INTEGER NULL,
    started_at TIMESTAMPTZ NULL,
    completed_at TIMESTAMPTZ NULL,
    due_date TIMESTAMPTZ NULL,
    
    -- Assignment & Ownership
    assigned_to VARCHAR(100) NULL,
    created_by VARCHAR(100) NOT NULL,
    
    -- HEIR Integration
    related_doctrine_sections VARCHAR(20)[] NULL,
    unique_id_pattern VARCHAR(30) NULL,
    orbt_stage VARCHAR(20) NULL,
    
    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Todo progress tracking
CREATE TABLE IF NOT EXISTS shq.orbt_todo_progress (
    id SERIAL PRIMARY KEY,
    progress_id VARCHAR(50) UNIQUE NOT NULL,
    
    todo_id VARCHAR(50) NOT NULL REFERENCES shq.orbt_project_todos(todo_id),
    
    -- Progress Update
    progress_update TEXT NOT NULL,
    completion_percentage_change INTEGER NOT NULL,
    status_change VARCHAR(50) NULL,
    
    -- Context
    updated_by VARCHAR(100) NOT NULL,
    update_type VARCHAR(50) NOT NULL,
    
    -- Time Tracking
    time_spent_minutes INTEGER NULL,
    
    -- Issues & Notes
    blocking_issues TEXT[] NULL,
    next_steps TEXT[] NULL,
    notes TEXT NULL,
    
    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Auto todo generation rules
CREATE TABLE IF NOT EXISTS shq.orbt_todo_generation_rules (
    id SERIAL PRIMARY KEY,
    rule_id VARCHAR(50) UNIQUE NOT NULL,
    
    -- Rule Definition
    rule_name VARCHAR(100) NOT NULL,
    rule_description TEXT NOT NULL,
    
    -- Trigger Conditions
    trigger_keywords TEXT[] NOT NULL,
    project_types VARCHAR(50)[] NULL,
    complexity_threshold VARCHAR(20) NULL,
    
    -- Auto-Generated Todo Template
    todo_template JSONB NOT NULL,
    
    -- Rule Settings
    enabled BOOLEAN DEFAULT TRUE,
    auto_assign BOOLEAN DEFAULT FALSE,
    priority_override VARCHAR(20) NULL,
    
    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- DOCTRINE INTEGRATION SYSTEM
-- =============================================================================

-- Create sequences for doctrine integration
CREATE SEQUENCE IF NOT EXISTS doctrine_integration_seq;
CREATE SEQUENCE IF NOT EXISTS doctrine_hierarchy_seq;
CREATE SEQUENCE IF NOT EXISTS todo_sequence;
CREATE SEQUENCE IF NOT EXISTS progress_sequence;

-- Hierarchical doctrine table (using DPR numbering system)
CREATE TABLE IF NOT EXISTS shq.orbt_doctrine_hierarchy (
    id SERIAL PRIMARY KEY,
    
    -- DPR Section Number Format: [database].[subhive].[subsubhive].[section].[sequence]
    section_number VARCHAR(20) NOT NULL UNIQUE,
    section_title VARCHAR(200) NOT NULL,
    
    -- DPR Unique ID Format: [DB].[SUBHIVE].[MICROPROCESS].[TOOL].[ALTITUDE].[STEP]
    unique_id_pattern VARCHAR(30) NULL,
    
    -- Parsed Components (for efficient lookup)
    database_id VARCHAR(2) NOT NULL,
    subhive_id VARCHAR(2) NOT NULL,
    subsubhive_id VARCHAR(2) NULL,
    section_id VARCHAR(2) NOT NULL,
    sequence_number VARCHAR(3) NOT NULL,
    
    -- Content from dpr_doctrine
    doctrine_text TEXT NOT NULL,
    doctrine_type VARCHAR(50) NOT NULL,
    enforcement_level VARCHAR(20) NOT NULL,
    doctrine_category VARCHAR(50) NOT NULL,
    sub_hive VARCHAR(50) NOT NULL,
    enforcement_target VARCHAR(100) NULL,
    enforcement_scope VARCHAR(100) NULL,
    
    -- Additional HEIR fields
    behavioral_rules TEXT[] NULL,
    escalation_triggers TEXT[] NULL,
    
    -- Original DPR reference
    original_dpr_id UUID NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_referenced TIMESTAMPTZ NULL,
    reference_count INTEGER DEFAULT 0
);

-- Doctrine integration tracking
CREATE TABLE IF NOT EXISTS shq.orbt_doctrine_integration (
    id SERIAL PRIMARY KEY,
    integration_id VARCHAR(50) UNIQUE NOT NULL,
    error_id VARCHAR(50) NULL,
    resolution_id VARCHAR(50) NULL,
    agent_id VARCHAR(100) NOT NULL,
    doctrine_section VARCHAR(100) NOT NULL,
    doctrine_subsection VARCHAR(100) NULL,
    subhive_code VARCHAR(2) NOT NULL,
    decision_type VARCHAR(50) NOT NULL,
    decision_made TEXT NOT NULL,
    doctrine_compliance VARCHAR(20) NOT NULL CHECK (doctrine_compliance IN ('COMPLIANT', 'EXCEPTION', 'UNCLEAR')),
    exception_reason TEXT NULL,
    doctrine_query TEXT NOT NULL,
    doctrine_response TEXT NOT NULL,
    confidence_score DECIMAL(5,2) NOT NULL DEFAULT 0.0,
    consulted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    decision_outcome VARCHAR(50) NULL,
    human_review_required BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- GATEKEEPER SECURITY (RLS Example)
-- =============================================================================

-- Example vault table with Row Level Security
CREATE TABLE IF NOT EXISTS shq.vault_events (
    id SERIAL PRIMARY KEY,
    event_id VARCHAR(50) UNIQUE NOT NULL,
    agent_id VARCHAR(100) NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    event_data JSONB NOT NULL,
    gatekeeper_signature VARCHAR(200) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS on vault_events
ALTER TABLE shq.vault_events ENABLE ROW LEVEL SECURITY;

-- Policy: Only database-gatekeeper can write
CREATE POLICY IF NOT EXISTS vault_gatekeeper_write ON shq.vault_events
    FOR INSERT
    WITH CHECK (gatekeeper_signature LIKE 'database-gatekeeper:%');

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_error_log_timestamp ON shq.orbt_error_log(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_error_log_status ON shq.orbt_error_log(orbt_status);
CREATE INDEX IF NOT EXISTS idx_error_log_agent ON shq.orbt_error_log(agent_id);
CREATE INDEX IF NOT EXISTS idx_troubleshooting_lookup ON shq.orbt_troubleshooting_guide(lookup_key);
CREATE INDEX IF NOT EXISTS idx_resolution_library_pattern ON shq.orbt_resolution_library(error_signature);
CREATE INDEX IF NOT EXISTS idx_escalation_status ON shq.orbt_escalation_queue(status);
CREATE INDEX IF NOT EXISTS idx_todos_project ON shq.orbt_project_todos(project_name);
CREATE INDEX IF NOT EXISTS idx_todos_status ON shq.orbt_project_todos(status);
CREATE INDEX IF NOT EXISTS idx_todos_priority ON shq.orbt_project_todos(priority);
CREATE INDEX IF NOT EXISTS idx_doctrine_hierarchy_subhive ON shq.orbt_doctrine_hierarchy(subhive_id);
CREATE INDEX IF NOT EXISTS idx_doctrine_hierarchy_process ON shq.orbt_doctrine_hierarchy(subhive_id, section_id);
CREATE INDEX IF NOT EXISTS idx_doctrine_integration_agent ON shq.orbt_doctrine_integration(agent_id);
CREATE INDEX IF NOT EXISTS idx_doctrine_integration_subhive ON shq.orbt_doctrine_integration(subhive_code);

-- =============================================================================
-- TRIGGERS AND FUNCTIONS
-- =============================================================================

-- Auto-escalation trigger (2+ occurrences = human escalation)
CREATE OR REPLACE FUNCTION shq.check_error_escalation()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE shq.orbt_error_log 
    SET occurrence_count = (
        SELECT COUNT(*) 
        FROM shq.orbt_error_log 
        WHERE error_message = NEW.error_message 
        AND agent_id = NEW.agent_id
    )
    WHERE error_id = NEW.error_id;
    
    IF (SELECT occurrence_count FROM shq.orbt_error_log WHERE error_id = NEW.error_id) >= 2 THEN
        UPDATE shq.orbt_error_log 
        SET escalation_level = 2, requires_human = TRUE, orbt_status = 'RED'
        WHERE error_id = NEW.error_id;
        
        INSERT INTO shq.orbt_escalation_queue (
            escalation_id, error_id, priority, status, escalated_by
        ) VALUES (
            'ESC-' || NEW.error_id, NEW.error_id, 'HIGH', 'PENDING', 'SYSTEM_AUTO'
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger if not exists
DROP TRIGGER IF EXISTS trigger_error_escalation ON shq.orbt_error_log;
CREATE TRIGGER trigger_error_escalation
    AFTER INSERT ON shq.orbt_error_log
    FOR EACH ROW
    EXECUTE FUNCTION shq.check_error_escalation();

-- Doctrine migration function using exact DPR numbering system
CREATE OR REPLACE FUNCTION shq.migrate_dpr_doctrine_exact()
RETURNS TEXT AS $$
DECLARE
    doctrine_record RECORD;
    v_migrated_count INTEGER := 0;
    v_database_id VARCHAR(2);
    v_subhive_id VARCHAR(2);
    v_subsubhive_id VARCHAR(2);
    v_section_id VARCHAR(2);
    v_sequence_number VARCHAR(3);
BEGIN
    -- Check if dpr_doctrine table exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'dpr_doctrine') THEN
        RETURN 'dpr_doctrine table not found - skipping migration';
    END IF;
    
    FOR doctrine_record IN 
        SELECT * FROM dpr_doctrine 
        ORDER BY section_number
        LIMIT 500  -- Process in batches
    LOOP
        -- Parse section_number format: [database].[subhive].[subsubhive].[section].[sequence]
        SELECT 
            SPLIT_PART(doctrine_record.section_number, '.', 1)::VARCHAR(2),
            LPAD(SPLIT_PART(doctrine_record.section_number, '.', 2), 2, '0'),
            LPAD(SPLIT_PART(doctrine_record.section_number, '.', 3), 2, '0'),
            LPAD(SPLIT_PART(doctrine_record.section_number, '.', 4), 2, '0'),
            LPAD(SPLIT_PART(doctrine_record.section_number, '.', 5), 3, '0')
        INTO v_database_id, v_subhive_id, v_subsubhive_id, v_section_id, v_sequence_number;
        
        -- Insert using exact format
        INSERT INTO shq.orbt_doctrine_hierarchy (
            section_number, section_title, database_id, subhive_id, subsubhive_id,
            section_id, sequence_number, doctrine_text, doctrine_type, enforcement_level,
            doctrine_category, sub_hive, enforcement_target, enforcement_scope,
            original_dpr_id, behavioral_rules, escalation_triggers
        ) VALUES (
            doctrine_record.section_number,
            COALESCE(doctrine_record.section_title, 'Section ' || doctrine_record.section_number),
            v_database_id, v_subhive_id, v_subsubhive_id, v_section_id, v_sequence_number,
            doctrine_record.doctrine_text,
            COALESCE(doctrine_record.doctrine_type, 'general'),
            COALESCE(doctrine_record.enforcement_level, 'informational'),
            COALESCE(doctrine_record.doctrine_category, 'general'),
            COALESCE(doctrine_record.sub_hive, 'unknown'),
            doctrine_record.enforcement_target,
            doctrine_record.enforcement_scope,
            doctrine_record.id::UUID,
            -- Extract behavioral rules
            string_to_array(
                regexp_replace(doctrine_record.doctrine_text, '.*?((?:must|shall|required)[^.]*\.)', '\1', 'gi'),
                '.'
            ),
            -- Extract escalation triggers
            string_to_array(
                regexp_replace(doctrine_record.doctrine_text, '.*?((?:escalate|notify|alert)[^.]*\.)', '\1', 'gi'),
                '.'
            )
        ) ON CONFLICT (section_number) DO UPDATE SET
            doctrine_text = EXCLUDED.doctrine_text,
            updated_at = NOW();
        
        v_migrated_count := v_migrated_count + 1;
    END LOOP;
    
    RETURN 'Successfully migrated ' || v_migrated_count || ' doctrine records using exact DPR numbering format';
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- DEFAULT DATA
-- =============================================================================

-- Default troubleshooting entries
INSERT INTO shq.orbt_troubleshooting_guide (
    lookup_key, unique_id_pattern, process_id, error_code, error_type,
    error_title, error_description, business_impact, urgency_level,
    immediate_action, diagnostic_steps, resolution_steps, escalation_criteria,
    common_causes, prevention_tips, affected_agents, affected_domains, system_components,
    auto_resolvable, success_rate, avg_resolution_time_minutes
) VALUES 
(
    'ProcessData:CONN_TIMEOUT',
    '*.03.*.DB.*.*',
    'ProcessData',
    'CONN_TIMEOUT',
    'connection',
    'Database Connection Timeout',
    'Cannot connect to database within timeout period',
    'Data operations blocked, users cannot access features',
    'HIGH',
    'Retry connection, check database status endpoint',
    ARRAY['ping database_host', 'SELECT 1 FROM pg_stat_activity', 'Check connection pool'],
    ARRAY['Restart connection pool', 'Scale database if CPU > 80%', 'Clear pool if > 90% utilized'],
    'If 3 retries fail OR database unresponsive OR >100 affected users',
    ARRAY['Database overload', 'Connection pool exhaustion', 'Network issues'],
    ARRAY['Monitor pool utilization', 'Set up auto-scaling', 'Implement circuit breaker'],
    ARRAY['database-gatekeeper'],
    ARRAY['data', 'platform'],
    ARRAY['PostgreSQL', 'Connection Pool', 'Neon Database'],
    true, 85.0, 5
) ON CONFLICT (lookup_key) DO NOTHING;

-- Record schema deployment
INSERT INTO shq.doctrine_schema_version (version, applied_by, notes)
VALUES ('1.0.0', 'deploy-database.sh', 'Initial HEIR system schema deployment')
ON CONFLICT (version) DO NOTHING;

-- Grant permissions for gatekeepers
GRANT USAGE ON SCHEMA shq TO postgres;
GRANT SELECT ON ALL TABLES IN SCHEMA shq TO postgres;
GRANT INSERT, UPDATE ON shq.orbt_error_log TO postgres;
GRANT INSERT ON shq.vault_events TO postgres;