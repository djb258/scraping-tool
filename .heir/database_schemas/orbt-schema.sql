
-- ORBT Automatic Error Logging Schema
-- This gets deployed automatically with every HEIR system

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Create SHQ schema for system headquarters
CREATE SCHEMA IF NOT EXISTS shq;

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

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_error_log_timestamp ON shq.orbt_error_log(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_error_log_status ON shq.orbt_error_log(orbt_status);
CREATE INDEX IF NOT EXISTS idx_error_log_agent ON shq.orbt_error_log(agent_id);
CREATE INDEX IF NOT EXISTS idx_troubleshooting_lookup ON shq.orbt_troubleshooting_guide(lookup_key);
CREATE INDEX IF NOT EXISTS idx_resolution_library_pattern ON shq.orbt_resolution_library(error_signature);
CREATE INDEX IF NOT EXISTS idx_escalation_status ON shq.orbt_escalation_queue(status);

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

CREATE TRIGGER trigger_error_escalation
    AFTER INSERT ON shq.orbt_error_log
    FOR EACH ROW
    EXECUTE FUNCTION shq.check_error_escalation();

-- DOCTRINE INTEGRATION SYSTEM (Granular by Subhive and Process)
CREATE SEQUENCE IF NOT EXISTS doctrine_integration_seq;
CREATE SEQUENCE IF NOT EXISTS doctrine_hierarchy_seq;

-- Hierarchical doctrine table (using your exact DPR numbering system)
CREATE TABLE IF NOT EXISTS shq.orbt_doctrine_hierarchy (
    id SERIAL PRIMARY KEY,
    
    -- Your Existing Section Number Format: [database].[subhive].[subsubhive].[section].[sequence]
    section_number VARCHAR(20) NOT NULL UNIQUE,
    section_title VARCHAR(200) NOT NULL,
    
    -- Your Existing Unique ID Format: [DB].[SUBHIVE].[MICROPROCESS].[TOOL].[ALTITUDE].[STEP]
    unique_id_pattern VARCHAR(30) NULL,
    
    -- Parsed Components (for efficient lookup)
    database_id VARCHAR(2) NOT NULL,
    subhive_id VARCHAR(2) NOT NULL,
    subsubhive_id VARCHAR(2) NULL,
    section_id VARCHAR(2) NOT NULL,
    sequence_number VARCHAR(3) NOT NULL,
    
    -- Content from your dpr_doctrine
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

-- Auto-classification function
CREATE OR REPLACE FUNCTION shq.classify_doctrine_by_subhive(doctrine_content TEXT)
RETURNS VARCHAR(2) AS $$
BEGIN
    IF doctrine_content ILIKE ANY(ARRAY['%system coordination%', '%master orchestrator%', '%escalation%', '%overall system%']) THEN
        RETURN '01';
    ELSIF doctrine_content ILIKE ANY(ARRAY['%customer%', '%client%', '%user experience%', '%support%', '%service%']) THEN
        RETURN '02';
    ELSIF doctrine_content ILIKE ANY(ARRAY['%database%', '%data%', '%query%', '%storage%', '%backup%', '%sql%']) THEN
        RETURN '03';
    ELSIF doctrine_content ILIKE ANY(ARRAY['%payment%', '%billing%', '%invoice%', '%refund%', '%transaction%', '%financial%']) THEN
        RETURN '04';
    ELSIF doctrine_content ILIKE ANY(ARRAY['%integration%', '%api%', '%external%', '%webhook%', '%third party%']) THEN
        RETURN '05';
    ELSIF doctrine_content ILIKE ANY(ARRAY['%infrastructure%', '%deployment%', '%hosting%', '%server%', '%platform%']) THEN
        RETURN '06';
    ELSIF doctrine_content ILIKE ANY(ARRAY['%monitoring%', '%analytics%', '%metrics%', '%logging%', '%reporting%']) THEN
        RETURN '07';
    ELSIF doctrine_content ILIKE ANY(ARRAY['%security%', '%compliance%', '%audit%', '%privacy%', '%encryption%']) THEN
        RETURN '08';
    ELSIF doctrine_content ILIKE ANY(ARRAY['%communication%', '%notification%', '%email%', '%messaging%', '%alert%']) THEN
        RETURN '09';
    ELSIF doctrine_content ILIKE ANY(ARRAY['%artificial intelligence%', '%machine learning%', '%ai%', '%automation%']) THEN
        RETURN '10';
    ELSE
        RETURN '01';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Doctrine lookup function
CREATE OR REPLACE FUNCTION shq.get_process_doctrine(
    p_unique_id VARCHAR(50),
    p_decision_context TEXT DEFAULT NULL
) RETURNS TABLE(
    doctrine_level VARCHAR(20),
    doctrine_title VARCHAR(200),
    behavioral_rules TEXT[],
    decision_criteria TEXT[],
    enforcement_level VARCHAR(20),
    escalation_required BOOLEAN,
    approval_required BOOLEAN,
    applicable_rules TEXT[]
) AS $$
DECLARE
    v_subhive VARCHAR(2);
    v_process VARCHAR(3);
    v_step VARCHAR(3);
BEGIN
    SELECT 
        SPLIT_PART(p_unique_id, '.', 2),
        SPLIT_PART(p_unique_id, '.', 3), 
        SPLIT_PART(p_unique_id, '.', 6)
    INTO v_subhive, v_process, v_step;
    
    RETURN QUERY
    WITH doctrine_hierarchy AS (
        SELECT 'STEP' as doctrine_level, d.*
        FROM shq.orbt_doctrine_hierarchy d
        WHERE d.subhive_code = v_subhive 
        AND d.process_code = v_process 
        AND d.step_code = v_step
        
        UNION ALL
        
        SELECT 'PROCESS' as doctrine_level, d.*
        FROM shq.orbt_doctrine_hierarchy d
        WHERE d.subhive_code = v_subhive 
        AND d.process_code = v_process 
        AND d.step_code IS NULL
        
        UNION ALL
        
        SELECT 'SUBHIVE' as doctrine_level, d.*
        FROM shq.orbt_doctrine_hierarchy d
        WHERE d.subhive_code = v_subhive 
        AND d.process_code IS NULL 
        AND d.step_code IS NULL
    )
    SELECT 
        dh.doctrine_level,
        dh.doctrine_title,
        dh.behavioral_rules,
        dh.decision_criteria,
        dh.enforcement_level,
        (array_length(dh.escalation_triggers, 1) > 0) as escalation_required,
        dh.requires_approval,
        dh.behavioral_rules as applicable_rules
    FROM doctrine_hierarchy dh
    ORDER BY 
        CASE dh.doctrine_level 
            WHEN 'STEP' THEN 1 
            WHEN 'PROCESS' THEN 2 
            WHEN 'SUBHIVE' THEN 3 
        END;
        
    UPDATE shq.orbt_doctrine_hierarchy 
    SET reference_count = reference_count + 1,
        last_referenced = NOW()
    WHERE subhive_code = v_subhive;
END;
$$ LANGUAGE plpgsql;

-- Doctrine migration using your exact DPR numbering system
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
        -- Parse your section_number format: [database].[subhive].[subsubhive].[section].[sequence]
        SELECT 
            SPLIT_PART(doctrine_record.section_number, '.', 1)::VARCHAR(2),
            LPAD(SPLIT_PART(doctrine_record.section_number, '.', 2), 2, '0'),
            LPAD(SPLIT_PART(doctrine_record.section_number, '.', 3), 2, '0'),
            LPAD(SPLIT_PART(doctrine_record.section_number, '.', 4), 2, '0'),
            LPAD(SPLIT_PART(doctrine_record.section_number, '.', 5), 3, '0')
        INTO v_database_id, v_subhive_id, v_subsubhive_id, v_section_id, v_sequence_number;
        
        -- Insert using your exact format
        INSERT INTO shq.orbt_doctrine_hierarchy (
            section_number,
            section_title,
            database_id,
            subhive_id,
            subsubhive_id,
            section_id,
            sequence_number,
            doctrine_text,
            doctrine_type,
            enforcement_level,
            doctrine_category,
            sub_hive,
            enforcement_target,
            enforcement_scope,
            original_dpr_id,
            behavioral_rules,
            escalation_triggers
        ) VALUES (
            doctrine_record.section_number,
            COALESCE(doctrine_record.section_title, 'Section ' || doctrine_record.section_number),
            v_database_id,
            v_subhive_id,
            v_subsubhive_id,
            v_section_id,
            v_sequence_number,
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

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_doctrine_hierarchy_subhive ON shq.orbt_doctrine_hierarchy(subhive_code);
CREATE INDEX IF NOT EXISTS idx_doctrine_hierarchy_process ON shq.orbt_doctrine_hierarchy(subhive_code, process_code);
CREATE INDEX IF NOT EXISTS idx_doctrine_integration_agent ON shq.orbt_doctrine_integration(agent_id);
CREATE INDEX IF NOT EXISTS idx_doctrine_integration_subhive ON shq.orbt_doctrine_integration(subhive_code);
