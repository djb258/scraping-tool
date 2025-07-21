-- Drop and recreate the function to fix column name conflict
DROP FUNCTION IF EXISTS marketing.get_processing_stats(TEXT);

CREATE OR REPLACE FUNCTION marketing.get_processing_stats(p_batch_id TEXT DEFAULT NULL)
RETURNS TABLE(
    total_records BIGINT,
    unprocessed_count BIGINT,
    processing_count BIGINT,
    processed_count BIGINT,
    failed_count BIGINT,
    skipped_count BIGINT,
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