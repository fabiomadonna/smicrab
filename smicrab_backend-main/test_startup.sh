#!/bin/bash

# Test script for SMICRAB Backend startup validation
# This script helps test the startup process components individually

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[TEST] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

log "🧪 SMICRAB Backend Startup Test"
log "==============================="

# Test 1: Check datasets directory
log "Test 1: Checking datasets directory..."
if [ -d "./datasets" ]; then
    NC_FILES=$(find "./datasets" -name "*.nc" -o -name "*.NC" 2>/dev/null | wc -l)
    if [ "$NC_FILES" -gt 0 ]; then
        success "Found $NC_FILES NetCDF files in datasets directory"
    else
        error "No NetCDF files found in datasets directory"
        echo "Please add .nc files to the datasets/ directory"
    fi
else
    error "Datasets directory not found"
    echo "Please create a datasets/ directory and add .nc files"
fi

# Test 2: Check R setup script
log "Test 2: Checking R setup script..."
if [ -f "./r_scripts/project_setup/generate_csv.R" ]; then
    success "R setup script found"
else
    error "R setup script not found at ./r_scripts/project_setup/generate_csv.R"
fi

# Test 3: Check startup script
log "Test 3: Checking startup script..."
if [ -f "./startup.sh" ]; then
    if [ -x "./startup.sh" ]; then
        success "Startup script found and executable"
    else
        warning "Startup script found but not executable"
        echo "Run: chmod +x startup.sh"
    fi
else
    error "Startup script not found"
fi

# Test 4: Check Docker files
log "Test 4: Checking Docker configuration..."
if [ -f "./Dockerfile" ]; then
    success "Dockerfile found"
else
    error "Dockerfile not found"
fi

if [ -f "./docker-compose.yml" ]; then
    success "docker-compose.yml found"
else
    error "docker-compose.yml not found"
fi

# Test 5: Check R packages file
log "Test 5: Checking R packages configuration..."
if [ -f "./r_packages.R" ]; then
    success "R packages file found"
else
    error "r_packages.R not found"
fi

# Test 6: Check Python requirements
log "Test 6: Checking Python requirements..."
if [ -f "./requirements.txt" ]; then
    if grep -q "psycopg2" "./requirements.txt"; then
        success "Python requirements include database drivers"
    else
        warning "psycopg2 not found in requirements.txt"
    fi
else
    error "requirements.txt not found"
fi

# Test 7: Check alembic configuration
log "Test 7: Checking Alembic configuration..."
if [ -f "./alembic.ini" ]; then
    success "Alembic configuration found"
else
    error "alembic.ini not found"
fi

if [ -d "./migrations" ]; then
    MIGRATION_FILES=$(find "./migrations/versions" -name "*.py" 2>/dev/null | wc -l)
    if [ "$MIGRATION_FILES" -gt 0 ]; then
        success "Found $MIGRATION_FILES migration files"
    else
        warning "No migration files found in migrations/versions/"
    fi
else
    error "Migrations directory not found"
fi

# Test 8: Check .env configuration
log "Test 8: Checking environment configuration..."
if [ -f "./.env.example" ]; then
    success ".env.example template found"
else
    warning "No .env.example file found. Consider creating one for configuration guidance."
fi

# Check critical environment variables
REQUIRED_VARS=("POSTGRES_HOST" "POSTGRES_PORT" "POSTGRES_DB" "POSTGRES_USER" "POSTGRES_PASSWORD")
MISSING_VARS=()

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -eq 0 ]; then
    success "All critical environment variables are set"
else
    warning "Missing environment variables: ${MISSING_VARS[*]}"
    echo "You can set these in a .env file or as environment variables"
fi

log "==============================="
log "Test completed!"
log "If all tests passed, you can run: docker-compose up --build" 