@echo off
echo ========================================
echo PROVING TABLES EXIST IN NEON
echo ========================================
echo.
echo 1. marketing_apollo_raw table structure:
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "\d marketing.marketing_apollo_raw"
echo.
echo 2. marketing_company_column_metadata table structure:
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "\d marketing.marketing_company_column_metadata"
echo.
echo 3. Count records in marketing_company_column_metadata:
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT COUNT(*) as metadata_count FROM marketing.marketing_company_column_metadata;"
echo.
echo 4. Sample metadata records:
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT column_name, column_number, column_format FROM marketing.marketing_company_column_metadata ORDER BY column_number LIMIT 5;"
echo.
echo 5. Test insert into marketing_apollo_raw:
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "INSERT INTO marketing.marketing_apollo_raw (raw_data, file_name, blueprint_id) VALUES ('{\"test\": \"data\"}'::jsonb, 'test.csv', 'test_blueprint') RETURNING id, status, inserted_at;"
echo.
echo ========================================
echo PROOF COMPLETE
echo ========================================
pause 