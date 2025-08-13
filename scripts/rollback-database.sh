#!/bin/bash
# HEIR System - Database Rollback Script  
# Phase 1: Remove schema version and optionally drop schema

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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

# Usage information
usage() {
    echo "Usage: $0 <version> [--full-drop]"
    echo ""
    echo "Arguments:"
    echo "  version     Schema version to rollback (e.g., 1.0.0)"
    echo ""
    echo "Options:"
    echo "  --full-drop     Drop entire SHQ schema (DESTRUCTIVE!)"
    echo ""
    echo "Examples:"
    echo "  $0 1.0.0                    # Remove version record only"  
    echo "  $0 1.0.0 --full-drop        # Drop entire schema"
    echo ""
}

# Check requirements
check_requirements() {
    log "Checking rollback requirements..."
    
    if [ -z "$DATABASE_URL" ]; then
        error "DATABASE_URL environment variable is required"
        error "Example: export DATABASE_URL='postgresql://user:pass@host:5432/dbname'"
        exit 1
    fi
    
    if ! command -v psql &> /dev/null; then
        error "psql command not found. Please install PostgreSQL client."
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

# Verify version exists
verify_version() {
    local version="$1"
    log "Verifying version $version exists..."
    
    # Check if version table exists
    VERSION_TABLE_EXISTS=$(psql "$DATABASE_URL" -t -c "
        SELECT EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'shq' 
            AND table_name = 'doctrine_schema_version'
        );
    " 2>/dev/null | tr -d '[:space:]' || echo "f")
    
    if [ "$VERSION_TABLE_EXISTS" = "f" ]; then
        warn "No schema version table found - nothing to rollback"
        exit 0
    fi
    
    # Check if specific version exists
    VERSION_EXISTS=$(psql "$DATABASE_URL" -t -c "
        SELECT EXISTS (
            SELECT 1 FROM shq.doctrine_schema_version 
            WHERE version = '$version'
        );
    " 2>/dev/null | tr -d '[:space:]' || echo "f")
    
    if [ "$VERSION_EXISTS" = "f" ]; then
        warn "Version $version not found in database"
        
        # Show available versions
        log "Available versions:"
        psql "$DATABASE_URL" -c "
            SELECT version, applied_at, applied_by 
            FROM shq.doctrine_schema_version 
            ORDER BY applied_at DESC;
        " 2>/dev/null || echo "No versions found"
        exit 1
    fi
    
    log "Version $version verified ✓"
}

# Create rollback backup
create_rollback_backup() {
    log "Creating rollback backup..."
    mkdir -p "$BACKUP_DIR"
    
    BACKUP_FILE="${BACKUP_DIR}/rollback-backup-$(date '+%Y%m%d-%H%M%S').sql"
    
    # Export current schema structure and data
    pg_dump "$DATABASE_URL" \
        --schema=shq \
        --data-only \
        --file="$BACKUP_FILE" \
        2>/dev/null || warn "Backup creation had warnings"
    
    log "Rollback backup created: $BACKUP_FILE"
}

# Remove version record
remove_version() {
    local version="$1"
    log "Removing version record: $version"
    
    # Get version info before removal
    VERSION_INFO=$(psql "$DATABASE_URL" -t -c "
        SELECT applied_at, applied_by 
        FROM shq.doctrine_schema_version 
        WHERE version = '$version';
    " | tr -s '[:space:]' | sed 's/^ *//')
    
    # Remove version record
    psql "$DATABASE_URL" -c "
        DELETE FROM shq.doctrine_schema_version 
        WHERE version = '$version';
    " > /dev/null
    
    log "Version $version removed (was applied: $VERSION_INFO)"
}

# Full schema drop
full_schema_drop() {
    warn "⚠️  DESTRUCTIVE OPERATION: Dropping entire SHQ schema!"
    warn "This will permanently delete all HEIR system data."
    
    read -p "Are you absolutely sure? Type 'DROP SCHEMA' to confirm: " -r
    
    if [ "$REPLY" = "DROP SCHEMA" ]; then
        log "Dropping SHQ schema..."
        
        psql "$DATABASE_URL" -c "
            DROP SCHEMA IF EXISTS shq CASCADE;
        " > /dev/null
        
        log "SHQ schema dropped successfully"
    else
        log "Schema drop cancelled - confirmation not received"
        exit 1
    fi
}

# Verify rollback
verify_rollback() {
    local version="$1"
    local full_drop="$2"
    
    if [ "$full_drop" = true ]; then
        # Verify schema is gone
        SCHEMA_EXISTS=$(psql "$DATABASE_URL" -t -c "
            SELECT EXISTS (
                SELECT 1 FROM information_schema.schemata 
                WHERE schema_name = 'shq'
            );
        " | tr -d '[:space:]')
        
        if [ "$SCHEMA_EXISTS" = "f" ]; then
            log "✓ SHQ schema successfully removed"
        else
            error "✗ SHQ schema still exists"
            exit 1
        fi
    else
        # Verify version record is gone
        VERSION_EXISTS=$(psql "$DATABASE_URL" -t -c "
            SELECT EXISTS (
                SELECT 1 FROM shq.doctrine_schema_version 
                WHERE version = '$version'
            );
        " 2>/dev/null | tr -d '[:space:]' || echo "f")
        
        if [ "$VERSION_EXISTS" = "f" ]; then
            log "✓ Version $version successfully removed"
        else
            error "✗ Version $version still exists"
            exit 1
        fi
        
        # Show remaining versions
        REMAINING=$(psql "$DATABASE_URL" -t -c "
            SELECT COUNT(*) FROM shq.doctrine_schema_version;
        " 2>/dev/null | tr -d '[:space:]' || echo "0")
        
        if [ "$REMAINING" -gt 0 ]; then
            log "Remaining versions in database:"
            psql "$DATABASE_URL" -c "
                SELECT version, applied_at, applied_by 
                FROM shq.doctrine_schema_version 
                ORDER BY applied_at DESC;
            " 2>/dev/null
        else
            log "No schema versions remaining"
        fi
    fi
}

# Main rollback process
main() {
    local version="$1"
    local full_drop=false
    
    # Parse arguments
    if [ "$#" -eq 0 ]; then
        usage
        exit 1
    fi
    
    if [ "$2" = "--full-drop" ]; then
        full_drop=true
    fi
    
    log "🔄 HEIR System Database Rollback Starting..."
    log "Target version: $version"
    [ "$full_drop" = true ] && warn "Mode: FULL SCHEMA DROP"
    
    check_requirements
    test_connection
    verify_version "$version"
    create_rollback_backup
    
    if [ "$full_drop" = true ]; then
        full_schema_drop
    else
        remove_version "$version"
    fi
    
    verify_rollback "$version" "$full_drop"
    
    log "🎉 HEIR System Database Rollback Complete!"
    log ""
    if [ "$full_drop" = true ]; then
        log "✅ Entire SHQ schema removed"
        log "✅ All HEIR system data deleted"
    else
        log "✅ Version $version record removed"
        log "✅ Schema structure preserved"
    fi
    log ""
    log "To redeploy:"
    log "bash scripts/deploy-database.sh"
}

# Execute main function
main "$@"