-- Migration script to move all marketing tables from public to marketing schema
-- This ensures consistent organization and ORBT/STAMPED doctrine compliance

-- First, let's see what marketing tables exist in public schema
-- SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name LIKE 'marketing_%';

-- Step 1: Create the tables in marketing schema with same structure
-- We'll use CREATE TABLE AS SELECT to preserve data and structure

-- marketing_company table
CREATE TABLE IF NOT EXISTS marketing.marketing_company AS 
SELECT * FROM public.marketing_company;

-- marketing_ceo table  
CREATE TABLE IF NOT EXISTS marketing.marketing_ceo AS 
SELECT * FROM public.marketing_ceo;

-- marketing_cfo table
CREATE TABLE IF NOT EXISTS marketing.marketing_cfo AS 
SELECT * FROM public.marketing_cfo;

-- marketing_hr table
CREATE TABLE IF NOT EXISTS marketing.marketing_hr AS 
SELECT * FROM public.marketing_hr;

-- marketing_david_barton_company table
CREATE TABLE IF NOT EXISTS marketing.marketing_david_barton_company AS 
SELECT * FROM public.marketing_david_barton_company;

-- marketing_david_barton_people table
CREATE TABLE IF NOT EXISTS marketing.marketing_david_barton_people AS 
SELECT * FROM public.marketing_david_barton_people;

-- marketing_david_barton_prep_table table
CREATE TABLE IF NOT EXISTS marketing.marketing_david_barton_prep_table AS 
SELECT * FROM public.marketing_david_barton_prep_table;

-- marketing_david_barton_command_log table
CREATE TABLE IF NOT EXISTS marketing.marketing_david_barton_command_log AS 
SELECT * FROM public.marketing_david_barton_command_log;

-- marketing_david_barton_error_log table
CREATE TABLE IF NOT EXISTS marketing.marketing_david_barton_error_log AS 
SELECT * FROM public.marketing_david_barton_error_log;

-- marketing_shq_prep_table table
CREATE TABLE IF NOT EXISTS marketing.marketing_shq_prep_table AS 
SELECT * FROM public.marketing_shq_prep_table;

-- marketing_shq_command_log table
CREATE TABLE IF NOT EXISTS marketing.marketing_shq_command_log AS 
SELECT * FROM public.marketing_shq_command_log;

-- marketing_shq_error_log table
CREATE TABLE IF NOT EXISTS marketing.marketing_shq_error_log AS 
SELECT * FROM public.marketing_shq_error_log;

-- Step 2: Copy all indexes, constraints, and sequences
-- Note: This is a simplified approach. For production, you'd want to script out exact DDL

-- Step 3: Verify data was copied correctly
-- SELECT 'marketing_company' as table_name, COUNT(*) as record_count FROM marketing.marketing_company
-- UNION ALL
-- SELECT 'marketing_ceo', COUNT(*) FROM marketing.marketing_ceo
-- UNION ALL
-- SELECT 'marketing_cfo', COUNT(*) FROM marketing.marketing_cfo
-- UNION ALL
-- SELECT 'marketing_hr', COUNT(*) FROM marketing.marketing_hr
-- UNION ALL
-- SELECT 'marketing_david_barton_company', COUNT(*) FROM marketing.marketing_david_barton_company
-- UNION ALL
-- SELECT 'marketing_david_barton_people', COUNT(*) FROM marketing.marketing_david_barton_people
-- UNION ALL
-- SELECT 'marketing_david_barton_prep_table', COUNT(*) FROM marketing.marketing_david_barton_prep_table
-- UNION ALL
-- SELECT 'marketing_david_barton_command_log', COUNT(*) FROM marketing.marketing_david_barton_command_log
-- UNION ALL
-- SELECT 'marketing_david_barton_error_log', COUNT(*) FROM marketing.marketing_david_barton_error_log
-- UNION ALL
-- SELECT 'marketing_shq_prep_table', COUNT(*) FROM marketing.marketing_shq_prep_table
-- UNION ALL
-- SELECT 'marketing_shq_command_log', COUNT(*) FROM marketing.marketing_shq_command_log
-- UNION ALL
-- SELECT 'marketing_shq_error_log', COUNT(*) FROM marketing.marketing_shq_error_log;

-- Step 4: Create a backup verification script
-- This will be run after migration to ensure data integrity

-- Step 5: After verification, drop the old tables from public schema
-- WARNING: Only uncomment these after verifying data migration was successful!

-- DROP TABLE IF EXISTS public.marketing_company;
-- DROP TABLE IF EXISTS public.marketing_ceo;
-- DROP TABLE IF EXISTS public.marketing_cfo;
-- DROP TABLE IF EXISTS public.marketing_hr;
-- DROP TABLE IF EXISTS public.marketing_david_barton_company;
-- DROP TABLE IF EXISTS public.marketing_david_barton_people;
-- DROP TABLE IF EXISTS public.marketing_david_barton_prep_table;
-- DROP TABLE IF EXISTS public.marketing_david_barton_command_log;
-- DROP TABLE IF EXISTS public.marketing_david_barton_error_log;
-- DROP TABLE IF EXISTS public.marketing_shq_prep_table;
-- DROP TABLE IF EXISTS public.marketing_shq_command_log;
-- DROP TABLE IF EXISTS public.marketing_shq_error_log;

-- Add comments to migrated tables for documentation
COMMENT ON TABLE marketing.marketing_company IS 'Marketing company data - migrated from public schema for organizational consistency';
COMMENT ON TABLE marketing.marketing_ceo IS 'CEO contact data - migrated from public schema';
COMMENT ON TABLE marketing.marketing_cfo IS 'CFO contact data - migrated from public schema';
COMMENT ON TABLE marketing.marketing_hr IS 'HR contact data - migrated from public schema';
COMMENT ON TABLE marketing.marketing_david_barton_company IS 'David Barton company data - migrated from public schema';
COMMENT ON TABLE marketing.marketing_david_barton_people IS 'David Barton people data - migrated from public schema';
COMMENT ON TABLE marketing.marketing_david_barton_prep_table IS 'David Barton prep table - migrated from public schema';
COMMENT ON TABLE marketing.marketing_david_barton_command_log IS 'David Barton command log - migrated from public schema';
COMMENT ON TABLE marketing.marketing_david_barton_error_log IS 'David Barton error log - migrated from public schema';
COMMENT ON TABLE marketing.marketing_shq_prep_table IS 'SHQ prep table - migrated from public schema';
COMMENT ON TABLE marketing.marketing_shq_command_log IS 'SHQ command log - migrated from public schema';
COMMENT ON TABLE marketing.marketing_shq_error_log IS 'SHQ error log - migrated from public schema'; 