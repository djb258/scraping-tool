-- Marketing Company ORBT/STAMPED Doctrine Compliance Setup
-- This script creates the metadata table and populates it with column information

-- Create the metadata table
CREATE TABLE IF NOT EXISTS marketing.marketing_company_column_metadata (
  column_name TEXT PRIMARY KEY,
  column_number TEXT NOT NULL,
  column_description TEXT NOT NULL,
  column_format TEXT NOT NULL
);

-- Insert metadata for typical marketing company columns
-- Note: Adjust column names and descriptions based on your actual Apollo export structure

INSERT INTO marketing.marketing_company_column_metadata (column_name, column_number, column_description, column_format) VALUES
-- Company Identification
('company_id', 'C001', 'Unique identifier for the company record', 'integer'),
('company_name', 'C002', 'Official registered name of the company', 'text'),
('legal_name', 'C003', 'Legal entity name as registered with authorities', 'text'),
('dba_name', 'C004', 'Doing Business As name if different from legal name', 'text'),

-- Contact Information
('website', 'C005', 'Primary company website URL', 'text'),
('phone', 'C006', 'Main company phone number', 'text'),
('email', 'C007', 'Primary company email address', 'text'),
('contact_email', 'C008', 'General contact email for inquiries', 'text'),

-- Address Information
('address', 'C009', 'Street address of company headquarters', 'text'),
('city', 'C010', 'City where company is located', 'text'),
('state', 'C011', 'State or province where company is located', 'text'),
('zip_code', 'C012', 'Postal/ZIP code for company location', 'text'),
('country', 'C013', 'Country where company is headquartered', 'text'),

-- Business Information
('industry', 'C014', 'Primary industry classification of the company', 'text'),
('sector', 'C015', 'Business sector or vertical market', 'text'),
('company_size', 'C016', 'Number of employees or company size category', 'text'),
('revenue', 'C017', 'Annual revenue or revenue range', 'text'),
('founded_year', 'C018', 'Year the company was founded', 'integer'),

-- Technology & Marketing
('technologies', 'C019', 'List of technologies used by the company', 'text'),
('marketing_channels', 'C020', 'Primary marketing channels used', 'text'),
('social_media', 'C021', 'Social media presence and handles', 'text'),

-- Apollo-specific fields
('apollo_id', 'C022', 'Unique identifier from Apollo database', 'text'),
('apollo_url', 'C023', 'Direct link to company profile in Apollo', 'text'),
('linkedin_url', 'C024', 'Company LinkedIn profile URL', 'text'),
('twitter_url', 'C025', 'Company Twitter/X profile URL', 'text'),
('facebook_url', 'C026', 'Company Facebook page URL', 'text'),

-- Timestamps
('created_at', 'C027', 'Timestamp when record was created', 'timestamp'),
('updated_at', 'C028', 'Timestamp when record was last updated', 'timestamp'),
('last_contacted', 'C029', 'Date when company was last contacted', 'timestamp'),

-- Lead Status
('lead_status', 'C030', 'Current status in the sales pipeline', 'text'),
('lead_score', 'C031', 'Numeric score indicating lead quality', 'integer'),
('lead_source', 'C032', 'Original source of the lead', 'text'),

-- Additional Metadata
('notes', 'C033', 'General notes and observations about the company', 'text'),
('tags', 'C034', 'Custom tags or labels for categorization', 'text'),
('priority', 'C035', 'Priority level for follow-up (High/Medium/Low)', 'text'),

-- ORBT/STAMPED Compliance Fields
('data_quality_score', 'C036', 'Overall quality score of the company data', 'integer'),
('last_verified', 'C037', 'Date when company information was last verified', 'timestamp'),
('verification_status', 'C038', 'Status of data verification (Verified/Unverified/Pending)', 'text'),
('compliance_status', 'C039', 'ORBT/STAMPED compliance status', 'text'),

-- Audit Fields
('created_by', 'C040', 'User or system that created the record', 'text'),
('modified_by', 'C041', 'User or system that last modified the record', 'text'),
('version', 'C042', 'Version number of the record for tracking changes', 'integer');

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_marketing_company_metadata_column_number 
ON marketing.marketing_company_column_metadata(column_number);

-- Create index for format-based queries
CREATE INDEX IF NOT EXISTS idx_marketing_company_metadata_format 
ON marketing.marketing_company_column_metadata(column_format);

-- Add comments to the table for documentation
COMMENT ON TABLE marketing.marketing_company_column_metadata IS 
'Metadata table for marketing_company table columns following ORBT and STAMPED doctrine compliance';

COMMENT ON COLUMN marketing.marketing_company_column_metadata.column_name IS 
'Primary key - name of the column in the marketing_company table';

COMMENT ON COLUMN marketing.marketing_company_column_metadata.column_number IS 
'Unique identifier for the column following C### format (C001, C002, etc.)';

COMMENT ON COLUMN marketing.marketing_company_column_metadata.column_description IS 
'Human and AI-readable description of what the column contains';

COMMENT ON COLUMN marketing.marketing_company_column_metadata.column_format IS 
'Data format type: text, integer, numeric, timestamp, boolean, etc.'; 