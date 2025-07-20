#!/bin/bash

# ==============================================================================
#                 SMICRAB Automated Deployment Script
# ==============================================================================
# This script automates the entire process of deploying the SMICRAB application
# on a new server using a private Docker registry.
# ==============================================================================

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
# The address of your private Docker registry.
REGISTRY_URL="131.175.206.80:5443"

# --- Helper Variables & Functions ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# --- Pre-flight Checks ---
info "Starting SMICRAB deployment script..."

if [ ! -f .env ]; then
    error "The .env file was not found. Please create it before running the script."
fi
if [ ! -d datasets ]; then
    error "The 'datasets' directory was not found. Please create it and populate it with dataset files."
fi
if [ ! -d tmp ]; then
    error "The 'tmp' directory was not found. Please create it."
fi

# --- STEP 1: Clean Up Previous Deployment ---
info "Cleaning up any previous deployments..."
docker stop smicrab_ui smicrab_backend postgres &> /dev/null || true
docker rm smicrab_ui smicrab_backend postgres &> /dev/null || true
docker network rm smicrab-net &> /dev/null || true
info "Cleanup complete."

# --- STEP 2: Login and Pull Images ---
info "Logging into private registry at ${REGISTRY_URL}..."
docker login "${REGISTRY_URL}"

info "Pulling latest images..."
docker pull "${REGISTRY_URL}/smicrab-backend:latest"
docker pull "${REGISTRY_URL}/smicrab-analysis:latest"
docker pull "${REGISTRY_URL}/smicrab-analysis-packages:latest"
docker pull "${REGISTRY_URL}/smicrab-ui:latest"
docker pull postgres:15-alpine
info "All images pulled successfully."

# --- STEP 3: Setup Network and Services ---
info "Creating Docker network 'smicrab-net'..."
docker network create smicrab-net

info "Starting PostgreSQL database..."
docker run -d --name postgres --network smicrab-net --env-file .env -v postgres_data:/var/lib/postgresql/data --restart unless-stopped postgres:15-alpine

info "Waiting for database to be ready..."
for i in {1..30}; do
    if docker exec postgres pg_isready -U smicrab_user -d smicrab &> /dev/null; then
        info "Database is ready!"
        break
    fi
    warn "Database not ready yet, waiting 2 seconds... (Attempt $i/30)"
    sleep 2
    if [ $i -eq 30 ]; then
        error "Database did not become ready in time."
    fi
done

info "Running database migrations..."
docker run --rm --network smicrab-net --env-file .env "${REGISTRY_URL}/smicrab-backend:latest" alembic upgrade head
info "Migrations completed successfully."

info "Starting main backend service..."
# Note: We use $(pwd) to get the current directory for volume mounts.
docker run -d \
  --name smicrab_backend \
  --network smicrab-net \
  --env-file .env \
  -p 8000:8000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$(pwd)/tmp:/tmp" \
  --restart unless-stopped \
  "${REGISTRY_URL}/smicrab-backend:latest"

info "Starting frontend service..."
docker run -d \
  --name smicrab_ui \
  --network smicrab-net \
  --env-file .env \
  -p 3000:3000 \
  --restart unless-stopped \
  "${REGISTRY_URL}/smicrab-ui:latest"

info "Seeding initial data..."
sleep 5 # Give the backend a moment to fully start
docker exec smicrab_backend python /app/resources/scripts/load_dataset_data.py
info "Data seeding complete."

# --- STEP 4: Final Verification ---
info "Deployment script completed successfully!"
echo ""
warn "Current status of running containers:"
docker ps
echo ""
info "You can access the application at:"
info "  - UI: http://<your_server_ip>:3000"
info "  - API Docs: http://<your_server_ip>:8000/docs"
echo ""