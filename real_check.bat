@echo off
echo ========================================
echo REAL CHECK - WHAT'S ACTUALLY IN NEON
echo ========================================
echo.
echo 1. What schemas exist?
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT schema_name FROM information_schema.schemata;"
echo.
echo 2. What tables exist in public schema?
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';"
echo.
echo 3. What tables exist in marketing schema (if it exists)?
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'marketing';"
echo.
echo 4. Can we create a simple test table?
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "CREATE TABLE IF NOT EXISTS test_table (id SERIAL PRIMARY KEY, name TEXT);"
echo.
echo 5. Did the test table get created?
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT 'test_table exists: ' || EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'test_table');"
echo.
echo ========================================
echo REAL CHECK COMPLETE
echo ========================================
pause 