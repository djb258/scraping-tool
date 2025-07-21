@echo off
echo ========================================
echo VERIFYING APOLLO RAW TABLE CREATION
echo ========================================
echo.
echo 1. Checking table exists...
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT 'Apollo raw table exists: ' || EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema = 'marketing' AND table_name = 'marketing_apollo_raw');"
echo.
echo 2. Table structure...
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "\d marketing.marketing_apollo_raw"
echo.
echo 3. Checking indexes created...
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT indexname FROM pg_indexes WHERE schemaname = 'marketing' AND tablename = 'marketing_apollo_raw' ORDER BY indexname;"
echo.
echo 4. Checking functions created...
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT proname FROM pg_proc WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'marketing') AND proname LIKE '%%apollo%%' OR proname LIKE '%%processing%%' OR proname LIKE '%%audit%%';"
echo.
echo 5. Checking triggers created...
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT triggername FROM pg_trigger WHERE tgrelid = 'marketing.marketing_apollo_raw'::regclass;"
echo.
echo 6. Testing processing stats function...
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT * FROM marketing.get_processing_stats();"
echo.
echo 7. Checking constraints...
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT conname, contype FROM pg_constraint WHERE conrelid = 'marketing.marketing_apollo_raw'::regclass;"
echo.
echo ========================================
echo VERIFICATION COMPLETE
echo ========================================
pause 