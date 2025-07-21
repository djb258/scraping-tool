@echo off
echo ========================================
echo CHECKING CURRENT NEON DATABASE STATE
echo ========================================
echo.
echo 1. Checking all schemas...
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT schema_name FROM information_schema.schemata WHERE schema_name NOT IN ('information_schema', 'pg_catalog', 'pg_toast') ORDER BY schema_name;"
echo.
echo 2. Checking all tables in marketing schema...
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'marketing' ORDER BY table_name;"
echo.
echo 3. Checking if marketing_apollo_raw table exists...
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT 'marketing_apollo_raw exists: ' || EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema = 'marketing' AND table_name = 'marketing_apollo_raw');"
echo.
echo 4. Checking if marketing_company_column_metadata table exists...
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT 'marketing_company_column_metadata exists: ' || EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema = 'marketing' AND table_name = 'marketing_company_column_metadata');"
echo.
echo 5. Checking all functions in marketing schema...
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT proname FROM pg_proc WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'marketing');"
echo.
echo 6. Testing database connection...
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT 'Connection successful - Database: ' || current_database() || ', User: ' || current_user;"
echo.
echo ========================================
echo CURRENT STATE CHECK COMPLETE
echo ========================================
pause 