# ORBT and STAMPED Doctrine Compliance for Marketing Company Table

This implementation provides ORBT (Observable, Repeatable, Believable, Traceable) and STAMPED (Structured, Traceable, Accessible, Measurable, Persistent, Explainable, Discoverable) doctrine compliance for the `marketing_company` table in your Neon database.

## Overview

The solution creates a companion metadata table `marketing_company_column_metadata` that stores comprehensive information about each column in the `marketing_company` table, enabling:

- **Observable**: Clear documentation of what each column contains
- **Repeatable**: Consistent metadata structure across all columns
- **Believable**: Human and AI-readable descriptions
- **Traceable**: Unique column identifiers and audit trails
- **Structured**: Organized metadata with clear relationships
- **Accessible**: Easy to query and understand
- **Measurable**: Quality scores and verification status
- **Persistent**: Metadata stored alongside the data
- **Explainable**: Detailed descriptions for each field
- **Discoverable**: Indexed and searchable metadata

## Files Included

1. **`marketing_company_metadata_setup.sql`** - Main setup script
2. **`customize_metadata.sql`** - Utility script for customization
3. **`README_ORBT_STAMPED_Compliance.md`** - This documentation

## Implementation Steps

### Step 1: Run the Setup Script

Execute the main setup script in your Neon database:

```sql
-- Connect to your Neon database and run:
\i marketing_company_metadata_setup.sql
```

### Step 2: Customize for Your Apollo Export

1. First, identify your actual column structure:
```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_schema = 'marketing' 
AND table_name = 'marketing_company'
ORDER BY ordinal_position;
```

2. Update the metadata table using the utility script:
```sql
-- Example: Update existing metadata
UPDATE marketing.marketing_company_column_metadata 
SET column_description = 'Your actual Apollo column description',
    column_format = 'your_actual_data_type'
WHERE column_name = 'your_actual_column_name';

-- Example: Add new columns from your Apollo export
INSERT INTO marketing.marketing_company_column_metadata 
(column_name, column_number, column_description, column_format) VALUES
('apollo_specific_field', 'C043', 'Description of Apollo-specific field', 'text');
```

### Step 3: Verify Compliance

Run these queries to ensure complete compliance:

```sql
-- Check for missing columns
SELECT c.column_name, c.data_type
FROM information_schema.columns c
LEFT JOIN marketing.marketing_company_column_metadata m ON c.column_name = m.column_name
WHERE c.table_schema = 'marketing' 
AND c.table_name = 'marketing_company'
AND m.column_name IS NULL;

-- View complete metadata
SELECT * FROM marketing.marketing_company_column_metadata 
ORDER BY column_number;
```

## Metadata Structure

Each column in the `marketing_company` table now has associated metadata:

| Field | Description | Example |
|-------|-------------|---------|
| `column_name` | Primary key - actual column name | `company_name` |
| `column_number` | Unique identifier | `C001`, `C002`, etc. |
| `column_description` | Human/AI-readable description | `Official registered name of the company` |
| `column_format` | Data type/format | `text`, `integer`, `timestamp` |

## ORBT/STAMPED Compliance Features

### Observable
- Clear column descriptions explain what each field contains
- Format specifications indicate data types
- Metadata is easily queryable

### Repeatable
- Consistent metadata structure across all columns
- Standardized column numbering system (C001, C002, etc.)
- Uniform format specifications

### Believable
- Human-readable descriptions
- AI-friendly metadata for automated processing
- Quality scores and verification status

### Traceable
- Unique column identifiers
- Audit fields (created_by, modified_by, version)
- Timestamps for tracking changes

### Structured
- Organized metadata table with clear relationships
- Indexed for performance
- Normalized structure

### Accessible
- Easy to query metadata
- Clear documentation
- Standard SQL interface

### Measurable
- Data quality scores
- Verification status tracking
- Compliance status indicators

### Persistent
- Metadata stored in database
- Survives data migrations
- Version-controlled structure

### Explainable
- Detailed descriptions for each field
- Context about data sources
- Business meaning explanations

### Discoverable
- Indexed metadata table
- Searchable descriptions
- Clear categorization

## Usage Examples

### Query Metadata for a Specific Column
```sql
SELECT * FROM marketing.marketing_company_column_metadata 
WHERE column_name = 'company_name';
```

### Get All Text Columns
```sql
SELECT column_name, column_description 
FROM marketing.marketing_company_column_metadata 
WHERE column_format = 'text';
```

### Find Columns by Description
```sql
SELECT column_name, column_number 
FROM marketing.marketing_company_column_metadata 
WHERE column_description ILIKE '%contact%';
```

### Audit Trail
```sql
SELECT column_name, created_by, modified_by, version 
FROM marketing.marketing_company_column_metadata 
WHERE modified_by IS NOT NULL;
```

## Maintenance

### Adding New Columns
When adding new columns to `marketing_company`, also add corresponding metadata:

```sql
INSERT INTO marketing.marketing_company_column_metadata 
(column_name, column_number, column_description, column_format) VALUES
('new_column', 'C043', 'Description of new column', 'text');
```

### Updating Descriptions
```sql
UPDATE marketing.marketing_company_column_metadata 
SET column_description = 'Updated description',
    modified_by = 'your_username',
    version = version + 1
WHERE column_name = 'target_column';
```

## Benefits

1. **Data Governance**: Clear documentation of all data fields
2. **AI Integration**: Machine-readable metadata for automation
3. **Compliance**: Meets ORBT and STAMPED doctrine requirements
4. **Maintainability**: Easy to update and extend
5. **Quality Assurance**: Built-in data quality tracking
6. **Audit Trail**: Complete change history
7. **Discovery**: Easy to find and understand data fields

## Next Steps

1. Run the setup script in your Neon database
2. Customize the metadata for your specific Apollo export columns
3. Verify all columns have proper metadata
4. Implement regular metadata maintenance procedures
5. Consider adding data quality validation rules
6. Set up automated metadata updates for new columns

This implementation provides a solid foundation for ORBT and STAMPED doctrine compliance while maintaining flexibility for your specific use case. 