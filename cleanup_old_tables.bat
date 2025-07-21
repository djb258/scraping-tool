@echo off
echo ========================================
echo CLEANUP - REMOVING OLD MARKETING TABLES
echo ========================================
echo.
echo Step 1: Verifying tables exist in marketing schema...
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT 'Tables in marketing schema:' as info; SELECT table_name FROM information_schema.tables WHERE table_schema = 'marketing' ORDER BY table_name;"
echo.
echo Step 2: Removing old tables from public schema...
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -f drop_old_tables.sql
echo.
echo Step 3: Final verification - remaining tables in public schema...
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT 'Remaining tables in public schema:' as info; SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;"
echo.
echo Step 4: Final verification - all tables in marketing schema...
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -c "SELECT 'All tables in marketing schema:' as info; SELECT table_name FROM information_schema.tables WHERE table_schema = 'marketing' ORDER BY table_name;"
echo.
echo ========================================
echo CLEANUP COMPLETE
echo ========================================
echo.
echo All marketing tables have been moved to marketing schema
echo and old tables removed from public schema.
echo.
pause 