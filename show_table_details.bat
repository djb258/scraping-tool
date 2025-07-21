@echo off
echo ========================================
echo DETAILED TABLE STRUCTURE VERIFICATION
echo ========================================
echo.
echo 1. marketing_apollo_raw table structure:
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "\d marketing.marketing_apollo_raw"
echo.
echo 2. marketing_company_column_metadata table structure:
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "\d marketing.marketing_company_column_metadata"
echo.
echo 3. Sample data from marketing_company_column_metadata:
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT COUNT(*) as total_metadata_entries FROM marketing.marketing_company_column_metadata;"
echo.
echo 4. Testing insert into marketing_apollo_raw:
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "INSERT INTO marketing.marketing_apollo_raw (raw_data, file_name, blueprint_id, batch_id) VALUES ('{\"test\": \"data\"}'::jsonb, 'test_file.csv', 'test_blueprint', 'test_batch') RETURNING id, status, inserted_at;"
echo.
echo 5. Testing processing stats function:
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT * FROM marketing.get_processing_stats();"
echo.
echo ========================================
echo VERIFICATION COMPLETE
echo ========================================
pause 