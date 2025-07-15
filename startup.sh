#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log() { echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}" >&2; exit 1; }
success() { echo -e "${GREEN}[SUCCESS] $1${NC}"; }

# Step 1: Build the backend image
log "Building backend image..."
docker-compose build backend || error "Failed to build backend image."
success "Backend image built."

# Step 2: Make R setup script executable
log "Making R setup script executable..."
chmod +x ./r_scripts/project_setup/generate_csv.R || error "Failed to make R script executable."
success "R setup script made executable."

# Step 3: Validate datasets and run R setup
log "Validating datasets and running R setup..."
if [ ! -d "./datasets" ] || [ -z "$(ls -A ./datasets)" ] || [ $(find ./datasets -name "*.nc" -o -name "*.NC" | wc -l) -eq 0 ]; then
    error "Invalid or empty datasets directory"
fi
cd ./r_scripts/project_setup && Rscript generate_csv.R && cd ../.. || error "Dataset validation or R setup failed."
success "Dataset validation and R setup done."

# Step 4: Start Postgres
log "Starting Postgres service..."
docker-compose up -d postgres || error "Failed to start Postgres."
success "Postgres service started."

# Wait for Postgres to be healthy
log "Waiting for Postgres to be ready..."
until docker-compose exec postgres pg_isready -U smicrab_user -d smicrab; do
    log "Waiting for Postgres..."
    sleep 2
done
success "Postgres is ready."

# Step 5: Start backend (and ensure it's running)
log "Starting backend service..."
docker-compose up -d backend || error "Failed to start backend."
success "Backend service started."

# Step 6: Run Alembic migrations
log "Running Alembic migrations..."
docker exec -t smicrab_backend bash -c "alembic upgrade head" || error "Alembic migrations failed."
success "Alembic migrations completed."

# Step 7: Run dataset loader
log "Checking dataset loader script..."
docker exec -t smicrab_backend bash -c "[ -f /app/resources/scripts/load_dataset_data.py ]" || error "Dataset loader script not found."
log "Running dataset loader script..."
docker exec -t smicrab_backend bash -c "python /app/resources/scripts/load_dataset_data.py" || error "Dataset loader failed."
success "Dataset loader completed."

# Step 8: Start pgAdmin
log "Starting pgAdmin service..."
docker-compose up -d pgadmin || error "Failed to start pgAdmin."
success "pgAdmin service started."

success "🎉 Project setup and startup completed."