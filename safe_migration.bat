@echo off
echo ========================================
echo SAFE MIGRATION - MARKETING TABLES
echo ========================================
echo.
echo Step 1: Checking current state...
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT 'Tables in public schema:' as info; SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name LIKE 'marketing_%%' ORDER BY table_name;"
echo.
echo Step 2: Checking marketing schema...
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT 'Tables in marketing schema:' as info; SELECT table_name FROM information_schema.tables WHERE table_schema = 'marketing' ORDER BY table_name;"
echo.
echo Step 3: Starting migration (this will take a moment)...
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -f migrate_marketing_tables.sql
echo.
echo Step 4: Verifying migration...
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT 'Migration verification - Record counts:' as info; SELECT 'marketing_company' as table_name, COUNT(*) as record_count FROM marketing.marketing_company UNION ALL SELECT 'marketing_ceo', COUNT(*) FROM marketing.marketing_ceo UNION ALL SELECT 'marketing_cfo', COUNT(*) FROM marketing.marketing_cfo UNION ALL SELECT 'marketing_hr', COUNT(*) FROM marketing.marketing_hr ORDER BY table_name;"
echo.
echo Step 5: Final state check...
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT 'All tables in marketing schema:' as info; SELECT table_name FROM information_schema.tables WHERE table_schema = 'marketing' ORDER BY table_name;"
echo.
echo ========================================
echo MIGRATION COMPLETE
echo ========================================
echo.
echo Next steps:
echo 1. Verify all data migrated correctly
echo 2. Test your applications with new schema
echo 3. When ready, drop old tables from public schema
echo.
pause 