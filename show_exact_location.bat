@echo off
echo ========================================
echo SHOWING EXACT TABLE LOCATIONS
echo ========================================
echo.
echo 1. All schemas in the database:
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT schema_name FROM information_schema.schemata ORDER BY schema_name;"
echo.
echo 2. All tables in marketing schema:
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'marketing' ORDER BY table_name;"
echo.
echo 3. All tables in public schema:
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;"
echo.
echo 4. How to query the tables (examples):
echo.
echo To query marketing_apollo_raw:
echo SELECT * FROM marketing.marketing_apollo_raw LIMIT 5;
echo.
echo To query marketing_company_column_metadata:
echo SELECT * FROM marketing.marketing_company_column_metadata LIMIT 5;
echo.
echo 5. Testing direct queries:
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT 'marketing_apollo_raw count: ' || COUNT(*) FROM marketing.marketing_apollo_raw;"
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT 'marketing_company_column_metadata count: ' || COUNT(*) FROM marketing.marketing_company_column_metadata;"
echo.
echo ========================================
echo LOCATION CHECK COMPLETE
echo ========================================
pause 