-- Drop old marketing tables from public schema
-- This should only be run after verifying successful migration to marketing schema

-- First, let's verify the tables exist in marketing schema before dropping from public
SELECT 'Verifying tables exist in marketing schema before dropping from public...' as info;

-- Drop tables from public schema (only if they exist in marketing schema)
DROP TABLE IF EXISTS public.marketing_company;
DROP TABLE IF EXISTS public.marketing_ceo;
DROP TABLE IF EXISTS public.marketing_cfo;
DROP TABLE IF EXISTS public.marketing_hr;
DROP TABLE IF EXISTS public.marketing_david_barton_company;
DROP TABLE IF EXISTS public.marketing_david_barton_people;
DROP TABLE IF EXISTS public.marketing_david_barton_prep_table;
DROP TABLE IF EXISTS public.marketing_david_barton_command_log;
DROP TABLE IF EXISTS public.marketing_david_barton_error_log;
DROP TABLE IF EXISTS public.marketing_shq_prep_table;
DROP TABLE IF EXISTS public.marketing_shq_command_log;
DROP TABLE IF EXISTS public.marketing_shq_error_log;

-- Verify cleanup
SELECT 'Cleanup complete. Remaining tables in public schema:' as info;
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name; 