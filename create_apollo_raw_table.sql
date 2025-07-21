-- Create marketing_apollo_raw staging table for Apollo data
-- ORBT/STAMPED Doctrine Compliant ETL Staging Area

-- Create the staging table
CREATE TABLE IF NOT EXISTS marketing.marketing_apollo_raw (
    id SERIAL PRIMARY KEY,
    raw_data JSONB NOT NULL,
    file_name TEXT NOT NULL,
    source TEXT DEFAULT 'Apollo',
    blueprint_id TEXT NOT NULL,
    status TEXT DEFAULT 'unprocessed' CHECK (status IN ('unprocessed', 'processing', 'processed', 'failed', 'skipped')),
    inserted_at TIMESTAMP DEFAULT NOW(),
    processed_at TIMESTAMP,
    error_message TEXT,
    
    -- Audit fields for ORBT/STAMPED compliance
    created_by TEXT DEFAULT current_user,
    modified_by TEXT,
    version INTEGER DEFAULT 1,
    data_quality_score INTEGER CHECK (data_quality_score >= 0 AND data_quality_score <= 100),
    verification_status TEXT DEFAULT 'unverified' CHECK (verification_status IN ('unverified', 'verified', 'failed_verification')),
    compliance_status TEXT DEFAULT 'pending' CHECK (compliance_status IN ('pending', 'compliant', 'non_compliant')),
    
    -- Metadata for traceability
    batch_id TEXT,
    processing_attempts INTEGER DEFAULT 0,
    last_processing_attempt TIMESTAMP,
    
    -- Constraints for data integrity
    CONSTRAINT valid_blueprint_id CHECK (blueprint_id ~ '^[A-Za-z0-9_-]+$'),
    CONSTRAINT valid_file_name CHECK (file_name ~ '^[A-Za-z0-9._-]+$'),
    CONSTRAINT valid_status_transition CHECK (
        (status = 'unprocessed' AND processed_at IS NULL) OR
        (status IN ('processing', 'processed', 'failed', 'skipped') AND processed_at IS NOT NULL)
    )
);

-- Create indexes for performance and queryability
CREATE INDEX IF NOT EXISTS idx_apollo_raw_status ON marketing.marketing_apollo_raw(status);
CREATE INDEX IF NOT EXISTS idx_apollo_raw_blueprint_id ON marketing.marketing_apollo_raw(blueprint_id);
CREATE INDEX IF NOT EXISTS idx_apollo_raw_inserted_at ON marketing.marketing_apollo_raw(inserted_at);
CREATE INDEX IF NOT EXISTS idx_apollo_raw_processed_at ON marketing.marketing_apollo_raw(processed_at);
CREATE INDEX IF NOT EXISTS idx_apollo_raw_batch_id ON marketing.marketing_apollo_raw(batch_id);
CREATE INDEX IF NOT EXISTS idx_apollo_raw_source ON marketing.marketing_apollo_raw(source);
CREATE INDEX IF NOT EXISTS idx_apollo_raw_file_name ON marketing.marketing_apollo_raw(file_name);

-- Create GIN index for JSONB queries
CREATE INDEX IF NOT EXISTS idx_apollo_raw_jsonb ON marketing.marketing_apollo_raw USING GIN (raw_data);

-- Create composite indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_apollo_raw_status_blueprint ON marketing.marketing_apollo_raw(status, blueprint_id);
CREATE INDEX IF NOT EXISTS idx_apollo_raw_batch_status ON marketing.marketing_apollo_raw(batch_id, status);
CREATE INDEX IF NOT EXISTS idx_apollo_raw_source_file ON marketing.marketing_apollo_raw(source, file_name);

-- Add table and column comments for documentation
COMMENT ON TABLE marketing.marketing_apollo_raw IS 
'Staging table for raw Apollo data before ETL processing. Supports ORBT/STAMPED doctrine compliance with full audit trail and data quality tracking.';

COMMENT ON COLUMN marketing.marketing_apollo_raw.id IS 
'Primary key - unique identifier for each raw data record';

COMMENT ON COLUMN marketing.marketing_apollo_raw.raw_data IS 
'Complete unmapped row data as JSONB from CSV or API source';

COMMENT ON COLUMN marketing.marketing_apollo_raw.file_name IS 
'Name of the uploaded file containing the raw data';

COMMENT ON COLUMN marketing.marketing_apollo_raw.source IS 
'System source identifier (default: Apollo)';

COMMENT ON COLUMN marketing.marketing_apollo_raw.blueprint_id IS 
'Reference to mapping blueprint for ETL processing';

COMMENT ON COLUMN marketing.marketing_apollo_raw.status IS 
'Processing status: unprocessed, processing, processed, failed, skipped';

COMMENT ON COLUMN marketing.marketing_apollo_raw.inserted_at IS 
'Timestamp when the raw data was uploaded to staging';

COMMENT ON COLUMN marketing.marketing_apollo_raw.processed_at IS 
'Timestamp when the row was successfully mapped and inserted';

COMMENT ON COLUMN marketing.marketing_apollo_raw.error_message IS 
'Error details if mapping or insertion fails';

COMMENT ON COLUMN marketing.marketing_apollo_raw.created_by IS 
'User or system that created the record';

COMMENT ON COLUMN marketing.marketing_apollo_raw.modified_by IS 
'User or system that last modified the record';

COMMENT ON COLUMN marketing.marketing_apollo_raw.version IS 
'Version number for tracking changes';

COMMENT ON COLUMN marketing.marketing_apollo_raw.data_quality_score IS 
'Quality score (0-100) for the raw data';

COMMENT ON COLUMN marketing.marketing_apollo_raw.verification_status IS 
'Data verification status: unverified, verified, failed_verification';

COMMENT ON COLUMN marketing.marketing_apollo_raw.compliance_status IS 
'ORBT/STAMPED compliance status: pending, compliant, non_compliant';

COMMENT ON COLUMN marketing.marketing_apollo_raw.batch_id IS 
'Batch identifier for grouping related records';

COMMENT ON COLUMN marketing.marketing_apollo_raw.processing_attempts IS 
'Number of processing attempts made';

COMMENT ON COLUMN marketing.marketing_apollo_raw.last_processing_attempt IS 
'Timestamp of the last processing attempt';

-- Create a trigger function for automatic audit trail
CREATE OR REPLACE FUNCTION marketing.update_audit_trail()
RETURNS TRIGGER AS $$
BEGIN
    NEW.modified_by = current_user;
    NEW.version = OLD.version + 1;
    NEW.last_processing_attempt = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for audit trail
CREATE TRIGGER trigger_apollo_raw_audit
    BEFORE UPDATE ON marketing.marketing_apollo_raw
    FOR EACH ROW
    EXECUTE FUNCTION marketing.update_audit_trail();

-- Create a function to update processing status
CREATE OR REPLACE FUNCTION marketing.update_processing_status(
    p_id INTEGER,
    p_status TEXT,
    p_error_message TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE marketing.marketing_apollo_raw
    SET 
        status = p_status,
        processed_at = CASE WHEN p_status IN ('processed', 'failed', 'skipped') THEN NOW() ELSE processed_at END,
        error_message = p_error_message,
        processing_attempts = processing_attempts + 1,
        last_processing_attempt = NOW()
    WHERE id = p_id;
END;
$$ LANGUAGE plpgsql;

-- Create a function to get processing statistics
CREATE OR REPLACE FUNCTION marketing.get_processing_stats(p_batch_id TEXT DEFAULT NULL)
RETURNS TABLE(
    total_records BIGINT,
    unprocessed BIGINT,
    processing BIGINT,
    processed BIGINT,
    failed BIGINT,
    skipped BIGINT,
    success_rate NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    WITH stats AS (
        SELECT 
            COUNT(*) as total,
            COUNT(*) FILTER (WHERE status = 'unprocessed') as unprocessed,
            COUNT(*) FILTER (WHERE status = 'processing') as processing,
            COUNT(*) FILTER (WHERE status = 'processed') as processed,
            COUNT(*) FILTER (WHERE status = 'failed') as failed,
            COUNT(*) FILTER (WHERE status = 'skipped') as skipped
        FROM marketing.marketing_apollo_raw
        WHERE (p_batch_id IS NULL OR batch_id = p_batch_id)
    )
    SELECT 
        total,
        unprocessed,
        processing,
        processed,
        failed,
        skipped,
        CASE 
            WHEN total = 0 THEN 0 
            ELSE ROUND((processed::NUMERIC / total::NUMERIC) * 100, 2)
        END as success_rate
    FROM stats;
END;
$$ LANGUAGE plpgsql;

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON marketing.marketing_apollo_raw TO "Marketing DB_owner";
GRANT USAGE, SELECT ON SEQUENCE marketing.marketing_apollo_raw_id_seq TO "Marketing DB_owner";
GRANT EXECUTE ON FUNCTION marketing.update_processing_status(INTEGER, TEXT, TEXT) TO "Marketing DB_owner";
GRANT EXECUTE ON FUNCTION marketing.get_processing_stats(TEXT) TO "Marketing DB_owner";

-- Insert metadata for the new table into the metadata table
INSERT INTO marketing.marketing_company_column_metadata (column_name, column_number, column_description, column_format) VALUES
('apollo_raw_id', 'C043', 'Primary key identifier for raw Apollo staging data', 'integer'),
('apollo_raw_data', 'C044', 'Complete unmapped JSONB data from Apollo CSV or API', 'jsonb'),
('apollo_file_name', 'C045', 'Name of the uploaded Apollo data file', 'text'),
('apollo_source', 'C046', 'Data source system identifier (default: Apollo)', 'text'),
('apollo_blueprint_id', 'C047', 'Reference to ETL mapping blueprint for processing', 'text'),
('apollo_status', 'C048', 'Processing status: unprocessed, processing, processed, failed, skipped', 'text'),
('apollo_inserted_at', 'C049', 'Timestamp when raw data was uploaded to staging', 'timestamp'),
('apollo_processed_at', 'C050', 'Timestamp when data was successfully processed', 'timestamp'),
('apollo_error_message', 'C051', 'Error details if processing fails', 'text'),
('apollo_batch_id', 'C052', 'Batch identifier for grouping related records', 'text'),
('apollo_processing_attempts', 'C053', 'Number of processing attempts made', 'integer'),
('apollo_last_processing_attempt', 'C054', 'Timestamp of last processing attempt', 'timestamp')
ON CONFLICT (column_name) DO UPDATE SET
    column_description = EXCLUDED.column_description,
    column_format = EXCLUDED.column_format; 