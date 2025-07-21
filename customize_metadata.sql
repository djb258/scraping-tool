-- Utility script to customize marketing_company_column_metadata
-- Use this script to update the metadata based on your actual Apollo export structure

-- First, let's see what columns actually exist in your marketing_company table
-- Run this query to get the actual column names:
/*
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_schema = 'marketing' 
AND table_name = 'marketing_company'
ORDER BY ordinal_position;
*/

-- Example: Update metadata for specific columns based on your Apollo export
-- Replace the column names and descriptions with your actual Apollo export columns

-- Example updates (uncomment and modify as needed):
/*
UPDATE marketing.marketing_company_column_metadata 
SET column_description = 'Updated description based on Apollo export',
    column_format = 'updated_format'
WHERE column_name = 'your_actual_column_name';

-- Add new columns that exist in your Apollo export but not in the template:
INSERT INTO marketing.marketing_company_column_metadata (column_name, column_number, column_description, column_format) VALUES
('apollo_specific_column', 'C043', 'Description of Apollo-specific column', 'text'),
('another_apollo_column', 'C044', 'Description of another Apollo column', 'integer');
*/

-- Query to view current metadata:
-- SELECT * FROM marketing.marketing_company_column_metadata ORDER BY column_number;

-- Query to find missing columns (columns in marketing_company but not in metadata):
/*
SELECT c.column_name, c.data_type
FROM information_schema.columns c
LEFT JOIN marketing.marketing_company_column_metadata m ON c.column_name = m.column_name
WHERE c.table_schema = 'marketing' 
AND c.table_name = 'marketing_company'
AND m.column_name IS NULL
ORDER BY c.ordinal_position;
*/

-- Query to find orphaned metadata (metadata for columns that don't exist):
/*
SELECT m.column_name, m.column_number
FROM marketing.marketing_company_column_metadata m
LEFT JOIN information_schema.columns c ON m.column_name = c.column_name
WHERE c.column_name IS NULL
ORDER BY m.column_number;
*/ 