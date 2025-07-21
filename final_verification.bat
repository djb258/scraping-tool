@echo off
echo ========================================
echo FINAL VERIFICATION - NEON DATABASE UPDATE
echo ========================================
echo.
echo 1. Checking marketing schema exists...
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT 'Marketing schema exists: ' || EXISTS(SELECT 1 FROM information_schema.schemata WHERE schema_name = 'marketing');"
echo.
echo 2. Checking metadata table exists...
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT 'Metadata table exists: ' || EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema = 'marketing' AND table_name = 'marketing_company_column_metadata');"
echo.
echo 3. Total metadata entries...
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT 'Total metadata entries: ' || COUNT(*) FROM marketing.marketing_company_column_metadata;"
echo.
echo 4. Checking indexes were created...
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT indexname FROM pg_indexes WHERE schemaname = 'marketing' AND tablename = 'marketing_company_column_metadata';"
echo.
echo 5. Sample metadata entries (first 5)...
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT column_name, column_number, column_format, LEFT(column_description, 50) || '...' as description_preview FROM marketing.marketing_company_column_metadata ORDER BY column_number LIMIT 5;"
echo.
echo 6. Checking table comments were added...
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT 'Table comment exists: ' || (obj_description('marketing.marketing_company_column_metadata'::regclass) IS NOT NULL);"
echo.
echo ========================================
echo VERIFICATION COMPLETE
echo ========================================
pause 