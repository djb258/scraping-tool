#!/bin/bash
# HEIR System - Database Deployment Script
# Phase 1: Deploy complete schema to target database

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEMA_FILE="${SCRIPT_DIR}/../database/complete-heir-schema.sql"
BACKUP_DIR="${SCRIPT_DIR}/../backups"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" >&2
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

# Check requirements
check_requirements() {
    log "Checking deployment requirements..."
    
    if [ -z "$DATABASE_URL" ]; then
        error "DATABASE_URL environment variable is required"
        error "Example: export DATABASE_URL='postgresql://user:pass@host:5432/dbname'"
        exit 1
    fi
    
    if ! command -v psql &> /dev/null; then
        error "psql command not found. Please install PostgreSQL client."
        exit 1
    fi
    
    if [ ! -f "$SCHEMA_FILE" ]; then
        error "Schema file not found: $SCHEMA_FILE"
        exit 1
    fi
    
    log "Requirements check passed ✓"
}

# Test database connection
test_connection() {
    log "Testing database connection..."
    
    if ! psql "$DATABASE_URL" -c "SELECT version();" > /dev/null 2>&1; then
        error "Cannot connect to database. Please check DATABASE_URL"
        exit 1
    fi
    
    log "Database connection successful ✓"
}

# Create backup directory
setup_backup() {
    mkdir -p "$BACKUP_DIR"
    log "Backup directory ready: $BACKUP_DIR"
}

# Check current schema version
check_current_version() {
    log "Checking current schema version..."
    
    # Check if version table exists
    VERSION_EXISTS=$(psql "$DATABASE_URL" -t -c "
        SELECT EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'shq' 
            AND table_name = 'doctrine_schema_version'
        );
    " 2>/dev/null | tr -d '[:space:]' || echo "f")
    
    if [ "$VERSION_EXISTS" = "t" ]; then
        CURRENT_VERSION=$(psql "$DATABASE_URL" -t -c "
            SELECT version FROM shq.doctrine_schema_version 
            ORDER BY applied_at DESC LIMIT 1;
        " 2>/dev/null | tr -d '[:space:]' || echo "none")
        
        if [ "$CURRENT_VERSION" = "1.0.0" ]; then
            warn "Schema version 1.0.0 already deployed"
            read -p "Continue with redeployment? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log "Deployment cancelled by user"
                exit 0
            fi
        fi
        log "Current version: $CURRENT_VERSION"
    else
        log "No existing schema found - fresh deployment"
    fi
}

# Backup existing data
create_backup() {
    if [ "$VERSION_EXISTS" = "t" ]; then
        log "Creating backup of existing data..."
        BACKUP_FILE="${BACKUP_DIR}/heir-backup-$(date '+%Y%m%d-%H%M%S').sql"
        
        psql "$DATABASE_URL" -c "
            SELECT 'Backing up SHQ schema...' as status;
            \copy (SELECT * FROM shq.orbt_error_log) TO '${BACKUP_FILE}.error_log.csv' CSV HEADER;
            \copy (SELECT * FROM shq.orbt_project_todos) TO '${BACKUP_FILE}.todos.csv' CSV HEADER;
        " 2>/dev/null || warn "Backup creation had warnings (may be expected for fresh install)"
        
        log "Backup created: $BACKUP_FILE"
    else
        log "No existing data to backup"
    fi
}

# Deploy schema
deploy_schema() {
    log "Deploying HEIR schema..."
    
    # Execute schema file with transaction
    if psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$SCHEMA_FILE" > /dev/null 2>&1; then
        log "Schema deployment successful ✓"
    else
        error "Schema deployment failed. Check database logs."
        exit 1
    fi
}

# Verify deployment
verify_deployment() {
    log "Verifying deployment..."
    
    # Check critical tables exist
    TABLES=(
        "shq.doctrine_schema_version"
        "shq.orbt_error_log" 
        "shq.orbt_troubleshooting_guide"
        "shq.orbt_resolution_library"
        "shq.orbt_project_todos"
        "shq.orbt_doctrine_hierarchy"
    )
    
    for table in "${TABLES[@]}"; do
        if psql "$DATABASE_URL" -t -c "SELECT EXISTS (SELECT 1 FROM $table LIMIT 1);" > /dev/null 2>&1; then
            log "✓ Table verified: $table"
        else
            error "✗ Table verification failed: $table"
            exit 1
        fi
    done
    
    # Verify version was recorded
    DEPLOYED_VERSION=$(psql "$DATABASE_URL" -t -c "
        SELECT version FROM shq.doctrine_schema_version 
        WHERE version = '1.0.0';
    " | tr -d '[:space:]')
    
    if [ "$DEPLOYED_VERSION" = "1.0.0" ]; then
        log "✓ Schema version 1.0.0 recorded successfully"
    else
        error "✗ Schema version not properly recorded"
        exit 1
    fi
}

# Test ORBT functionality
test_orbt() {
    log "Testing ORBT system functionality..."
    
    # Insert test error
    TEST_ERROR_ID="TEST-$(date +%s)"
    psql "$DATABASE_URL" -c "
        INSERT INTO shq.orbt_error_log 
        (error_id, agent_id, agent_hierarchy, error_type, error_message, orbt_status) 
        VALUES 
        ('$TEST_ERROR_ID', 'deploy-test', 'specialist', 'test', 'Deployment verification test', 'GREEN');
    " > /dev/null
    
    # Verify test error exists
    if psql "$DATABASE_URL" -t -c "SELECT error_id FROM shq.orbt_error_log WHERE error_id = '$TEST_ERROR_ID';" | grep -q "$TEST_ERROR_ID"; then
        log "✓ ORBT error logging functional"
        
        # Clean up test data
        psql "$DATABASE_URL" -c "DELETE FROM shq.orbt_error_log WHERE error_id = '$TEST_ERROR_ID';" > /dev/null
    else
        error "✗ ORBT error logging test failed"
        exit 1
    fi
}

# Main deployment process
main() {
    log "🏗️ HEIR System Database Deployment Starting..."
    
    check_requirements
    test_connection
    setup_backup
    check_current_version
    create_backup
    deploy_schema
    verify_deployment  
    test_orbt
    
    log "🎉 HEIR System Database Deployment Complete!"
    log ""
    log "✅ Schema version 1.0.0 deployed successfully"
    log "✅ All critical tables verified"  
    log "✅ ORBT system functional"
    log ""
    log "Next steps:"
    log "1. Update heir-drop-in.js to connect to this database"
    log "2. Run: node heir-drop-in.js to verify connection"
    log "3. Optional: Run shq.migrate_dpr_doctrine_exact() to import existing doctrine"
    log ""
    log "Rollback command if needed:"
    log "bash scripts/rollback-database.sh 1.0.0"
}

# Execute main function
main "$@"