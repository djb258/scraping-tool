@echo off
echo ========================================
echo CREATING APOLLO RAW STAGING TABLE
echo ========================================
echo.
echo Applying ORBT/STAMPED compliant staging table...
"C:\Program Files\PostgreSQL\17\bin\psql.exe" "postgresql://Marketing%%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%%20DB?sslmode=require&channel_binding=require" -f create_apollo_raw_table.sql
echo.
echo ========================================
echo APOLLO RAW TABLE CREATION COMPLETE
echo ========================================
pause 