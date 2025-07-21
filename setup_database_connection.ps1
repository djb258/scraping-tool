# PowerShell script to set up Neon database connection and ORBT/STAMPED compliance
# This script helps install PostgreSQL client and run the compliance setup

param(
    [string]$ConnectionString = "postgresql://Marketing%20DB_owner:npg_OsE4Z2oPCpiT@ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech/Marketing%20DB?sslmode=require&channel_binding=require"
)

Write-Host "=== Neon Database ORBT/STAMPED Compliance Setup ===" -ForegroundColor Green
Write-Host ""

# Check if psql is available
$psqlPath = Get-Command psql -ErrorAction SilentlyContinue
if ($psqlPath) {
    Write-Host "✓ PostgreSQL client (psql) is already installed" -ForegroundColor Green
    Write-Host "Location: $($psqlPath.Source)" -ForegroundColor Gray
} else {
    Write-Host "✗ PostgreSQL client (psql) is not installed" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install PostgreSQL client using one of these methods:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Using Chocolatey (if installed):" -ForegroundColor Cyan
    Write-Host "   choco install postgresql" -ForegroundColor White
    Write-Host ""
    Write-Host "2. Using Scoop (if installed):" -ForegroundColor Cyan
    Write-Host "   scoop install postgresql" -ForegroundColor White
    Write-Host ""
    Write-Host "3. Manual installation:" -ForegroundColor Cyan
    Write-Host "   - Download from: https://www.postgresql.org/download/windows/" -ForegroundColor White
    Write-Host "   - Install only the client tools" -ForegroundColor White
    Write-Host "   - Add to PATH" -ForegroundColor White
    Write-Host ""
    Write-Host "4. Alternative: Use Neon's web console at:" -ForegroundColor Cyan
    Write-Host "   https://console.neon.tech" -ForegroundColor White
    Write-Host ""
    
    $choice = Read-Host "Would you like to try installing with Chocolatey? (y/n)"
    if ($choice -eq "y" -or $choice -eq "Y") {
        Write-Host "Attempting to install PostgreSQL with Chocolatey..." -ForegroundColor Yellow
        try {
            choco install postgresql -y
            Write-Host "✓ PostgreSQL installed successfully!" -ForegroundColor Green
        } catch {
            Write-Host "✗ Chocolatey installation failed. Please install manually." -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "=== Database Connection Information ===" -ForegroundColor Green
Write-Host "Host: ep-ancient-waterfall-a42vy0du-pooler.us-east-1.aws.neon.tech" -ForegroundColor Gray
Write-Host "Database: Marketing DB" -ForegroundColor Gray
Write-Host "User: Marketing DB_owner" -ForegroundColor Gray
Write-Host "SSL: Required" -ForegroundColor Gray
Write-Host ""

# Check if setup files exist
$setupFile = "marketing_company_metadata_setup.sql"
if (Test-Path $setupFile) {
    Write-Host "✓ Setup script found: $setupFile" -ForegroundColor Green
} else {
    Write-Host "✗ Setup script not found: $setupFile" -ForegroundColor Red
    Write-Host "Please ensure the SQL setup file is in the current directory." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Next Steps ===" -ForegroundColor Green
Write-Host "1. Install PostgreSQL client if not already installed" -ForegroundColor White
Write-Host "2. Run the setup script using one of these methods:" -ForegroundColor White
Write-Host ""
Write-Host "   Method A - Command line:" -ForegroundColor Cyan
Write-Host "   psql '$ConnectionString' -f marketing_company_metadata_setup.sql" -ForegroundColor White
Write-Host ""
Write-Host "   Method B - Interactive psql:" -ForegroundColor Cyan
Write-Host "   psql '$ConnectionString'" -ForegroundColor White
Write-Host "   \i marketing_company_metadata_setup.sql" -ForegroundColor White
Write-Host ""
Write-Host "   Method C - Neon Web Console:" -ForegroundColor Cyan
Write-Host "   - Go to https://console.neon.tech" -ForegroundColor White
Write-Host "   - Open your Marketing DB project" -ForegroundColor White
Write-Host "   - Use the SQL Editor to run the setup script" -ForegroundColor White
Write-Host ""

# Offer to test connection if psql is available
$psqlPath = Get-Command psql -ErrorAction SilentlyContinue
if ($psqlPath) {
    $testConnection = Read-Host "Would you like to test the database connection? (y/n)"
    if ($testConnection -eq "y" -or $testConnection -eq "Y") {
        Write-Host "Testing database connection..." -ForegroundColor Yellow
        try {
            $testResult = psql "$ConnectionString" -c "SELECT version();" 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ Database connection successful!" -ForegroundColor Green
                Write-Host $testResult -ForegroundColor Gray
            } else {
                Write-Host "✗ Database connection failed:" -ForegroundColor Red
                Write-Host $testResult -ForegroundColor Red
            }
        } catch {
            Write-Host "✗ Error testing connection: $_" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "=== ORBT/STAMPED Compliance Benefits ===" -ForegroundColor Green
Write-Host "• Observable: Clear documentation of all data fields" -ForegroundColor White
Write-Host "• Repeatable: Consistent metadata structure" -ForegroundColor White
Write-Host "• Believable: Human and AI-readable descriptions" -ForegroundColor White
Write-Host "• Traceable: Unique identifiers and audit trails" -ForegroundColor White
Write-Host "• Structured: Organized metadata relationships" -ForegroundColor White
Write-Host "• Accessible: Easy to query and understand" -ForegroundColor White
Write-Host "• Measurable: Data quality tracking" -ForegroundColor White
Write-Host "• Persistent: Metadata stored in database" -ForegroundColor White
Write-Host "• Explainable: Detailed field descriptions" -ForegroundColor White
Write-Host "• Discoverable: Indexed and searchable" -ForegroundColor White 