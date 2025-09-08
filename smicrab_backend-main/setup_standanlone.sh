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

check_docker() {
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed or not in PATH"
    fi
    
    if ! docker info &> /dev/null; then
        error "Docker daemon is not running or not accessible"
    fi
}

wait_for_container_health() {
    local container_name="$1"
    local max_attempts="${2:-30}"
    local sleep_time="${3:-2}"
    
    info "Waiting for container '$container_name' to be healthy..."
    for i in $(seq 1 $max_attempts); do
        if docker ps --filter "name=$container_name" --filter "status=running" | grep -q "$container_name"; then
            info "Container '$container_name' is running!"
            return 0
        fi
        warn "Container not ready yet, waiting ${sleep_time} seconds... (Attempt $i/$max_attempts)"
        sleep $sleep_time
    done
    
    error "Container '$container_name' did not start successfully in time."
    return 1
}

# --- Pre-flight Checks ---
info "Starting SMICRAB deployment script..."

# Check if Docker is available
check_docker

# Check if .env file exists
if [ ! -f .env ]; then
    error "The .env file was not found. Please create it before running the script."
fi

# Validate .env file has required variables
info "Validating .env file..."
required_vars=("POSTGRES_DB" "POSTGRES_USER" "POSTGRES_PASSWORD")
for var in "${required_vars[@]}"; do
    if ! grep -q "^${var}=" .env; then
        warn "Required variable '$var' not found in .env file"
    fi
done

# --- STEP 1: Clean Up Previous Deployment ---
info "Cleaning up any previous deployments..."

# Stop containers gracefully first
for container in smicrab_ui smicrab_backend postgres; do
    if docker ps -q --filter "name=$container" | grep -q .; then
        info "Stopping container: $container"
        docker stop "$container" || warn "Failed to stop $container"
    fi
done

# Remove containers
for container in smicrab_ui smicrab_backend postgres; do
    if docker ps -aq --filter "name=$container" | grep -q .; then
        info "Removing container: $container"
        docker rm "$container" || warn "Failed to remove $container"
    fi
done

# Remove network if it exists
if docker network ls --filter "name=smicrab-net" | grep -q "smicrab-net"; then
    info "Removing existing network: smicrab-net"
    docker network rm smicrab-net || warn "Failed to remove network"
fi

info "Cleanup complete."

# --- STEP 2: Login and Pull Images ---
info "Logging into private registry at ${REGISTRY_URL}..."
if ! docker login "${REGISTRY_URL}"; then
    error "Failed to login to registry ${REGISTRY_URL}"
fi

info "Pulling latest images..."
images=(
    "${REGISTRY_URL}/smicrab-backend:latest"
    "${REGISTRY_URL}/smicrab-analysis:latest"
    "${REGISTRY_URL}/smicrab-analysis-packages:latest"
    "${REGISTRY_URL}/smicrab-ui:latest"
    "postgres:15-alpine"
)

for image in "${images[@]}"; do
    info "Pulling $image..."
    if ! docker pull "$image"; then
        error "Failed to pull image: $image"
    fi
done
info "All images pulled successfully."

# --- STEP 3: Setup Network and Services ---
info "Creating Docker network 'smicrab-net'..."
if ! docker network create smicrab-net; then
    error "Failed to create Docker network"
fi

# Create volume for PostgreSQL data if it doesn't exist
info "Creating PostgreSQL data volume..."
docker volume create postgres_data || warn "Volume postgres_data may already exist"

info "Starting PostgreSQL database..."
if ! docker run -d \
    --name postgres \
    --network smicrab-net \
    --env-file .env \
    -v postgres_data:/var/lib/postgresql/data \
    --restart unless-stopped \
    postgres:15-alpine; then
    error "Failed to start PostgreSQL container"
fi

# Wait for container to be running
wait_for_container_health "postgres" 30 2

# Wait specifically for PostgreSQL to accept connections
info "Waiting for PostgreSQL to accept connections..."
for i in {1..30}; do
    if docker exec postgres pg_isready -U "${POSTGRES_USER:-smicrab_user}" -d "${POSTGRES_DB:-smicrab}" &> /dev/null; then
        info "PostgreSQL is ready!"
        break
    fi
    warn "PostgreSQL not ready yet, waiting 2 seconds... (Attempt $i/30)"
    sleep 2
    if [ $i -eq 30 ]; then
        error "PostgreSQL did not become ready in time."
    fi
done

info "Running database migrations..."
if ! docker run --rm \
    --network smicrab-net \
    --env-file .env \
    "${REGISTRY_URL}/smicrab-backend:latest" \
    alembic upgrade head; then
    error "Database migrations failed"
fi
info "Migrations completed successfully."

# Create tmp directory if it doesn't exist
mkdir -p "$(pwd)/tmp"

# Fix Windows path issues for Docker volume mounts
CURRENT_DIR="$(pwd)"
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    # Convert MINGW64/Git Bash path to Windows Docker path
    CURRENT_DIR="$(cygpath -w "$(pwd)" | sed 's|\\|/|g')"
    DOCKER_SOCK_PATH="//var/run/docker.sock"
else
    DOCKER_SOCK_PATH="/var/run/docker.sock"
fi

info "Starting main backend service..."
if ! docker run -d \
    --name smicrab_backend \
    --network smicrab-net \
    --env-file .env \
    -p 8000:8000 \
    -v "${DOCKER_SOCK_PATH}:/var/run/docker.sock" \
    -v "${CURRENT_DIR}/tmp:/tmp" \
    --restart unless-stopped \
    "${REGISTRY_URL}/smicrab-backend:latest"; then
    error "Failed to start backend service"
fi

# Wait for backend to be running
wait_for_container_health "smicrab_backend" 30 2

info "Starting frontend service..."
if ! docker run -d \
    --name smicrab_ui \
    --network smicrab-net \
    --env-file .env \
    -p 3000:3000 \
    --restart unless-stopped \
    "${REGISTRY_URL}/smicrab-ui:latest"; then
    error "Failed to start frontend service"
fi

# Wait for frontend to be running
wait_for_container_health "smicrab_ui" 30 2

info "Waiting for backend service to be fully ready..."
sleep 10

info "Seeding initial data..."
if ! MSYS_NO_PATHCONV=1 docker exec smicrab_backend python /app/resources/scripts/load_dataset_data.py; then
    warn "Data seeding failed - this might be expected if data already exists"
fi
info "Data seeding complete."

# --- STEP 4: Final Verification ---
info "Performing health checks..."

# Check if all containers are still running
containers=("postgres" "smicrab_backend" "smicrab_ui")
for container in "${containers[@]}"; do
    if ! docker ps --filter "name=$container" --filter "status=running" | grep -q "$container"; then
        error "Container '$container' is not running!"
    fi
done

# Try to get server IP for display
if command -v hostname >/dev/null 2>&1 && hostname -I >/dev/null 2>&1; then
    SERVER_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
else
    # Use the IP from .env file if available, otherwise use localhost
    SERVER_IP=$(grep "^SERVER_PUBLIC_ADDRESS=" .env 2>/dev/null | cut -d'=' -f2 || echo "localhost")
fi

info "Deployment script completed successfully!"
echo ""
warn "Current status of running containers:"
docker ps --filter "name=smicrab" --filter "name=postgres"
echo ""
info "You can access the application at:"
info "  - UI: http://${SERVER_IP}:3000"
info "  - API Docs: http://${SERVER_IP}:8000/docs"
echo ""
info "To check logs if something isn't working:"
info "  - Backend logs: docker logs smicrab_backend"
info "  - Frontend logs: docker logs smicrab_ui"
info "  - Database logs: docker logs postgres"
echo ""
info "To stop all services: docker stop smicrab_ui smicrab_backend postgres"