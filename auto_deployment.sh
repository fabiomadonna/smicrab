#!/bin/bash

# ==============================================================================
#                 SMICRAB Cross-Platform Deployment Script
# ==============================================================================
# This script works on both Linux and Windows (Git Bash/MINGW64)
# It automates the entire process of deploying the SMICRAB application
# using a private Docker registry.
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

# Detect the operating system
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Check if running in WSL
        if grep -qEi "(Microsoft|WSL)" /proc/version 2>/dev/null; then
            OS_TYPE="wsl"
        else
            OS_TYPE="linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="mac"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        OS_TYPE="windows"
    else
        OS_TYPE="unknown"
    fi
    
    info "Detected OS: $OS_TYPE"
}

# Set cross-platform paths and commands
setup_platform_specific() {
    detect_os
    
    case $OS_TYPE in
        "windows")
            # Prevent Git Bash path conversion issues
            export MSYS_NO_PATHCONV=1

            # Use current directory for volume mounting
            CURRENT_DIR="$(pwd)"
            # Docker socket path for Windows
            DOCKER_SOCK_PATH="//var/run/docker.sock"
            ;;
        "wsl")
            # WSL specific handling
            CURRENT_DIR="$(pwd)"
            DOCKER_SOCK_PATH="/var/run/docker.sock"
            # Convert Windows paths to WSL paths if needed
            if [[ "$CURRENT_DIR" == /mnt/c/* ]]; then
                warn "Running from WSL with Windows path. Consider copying files to WSL home directory."
            fi
            ;;
        "linux"|"mac")

            CURRENT_DIR="$(pwd)"
            DOCKER_SOCK_PATH="/var/run/docker.sock"
            ;;
        *)
            warn "Unknown OS type. Assuming Linux-like behavior."

            CURRENT_DIR="$(pwd)"
            DOCKER_SOCK_PATH="/var/run/docker.sock"
            ;;
    esac
}

# Function to run docker with platform-specific environment
run_docker_with_env() {
    if [[ "$OS_TYPE" == "windows" ]]; then
        MSYS_NO_PATHCONV=1 docker "$@"
    else
        docker "$@"
    fi
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

wait_for_api_ready() {
    local max_attempts="${1:-30}"
    local sleep_time="${2:-3}"
    
    info "Waiting for API to be ready..."
    for i in $(seq 1 $max_attempts); do
        if docker exec smicrab_backend curl -f http://localhost:8000/health &> /dev/null; then
            info "API is ready!"
            return 0
        fi
        warn "API not ready yet, waiting ${sleep_time} seconds... (Attempt $i/$max_attempts)"
        sleep $sleep_time
    done
    
    error "API did not become ready in time."
    return 1
}

create_default_user() {
    info "Creating default user..."
    
    # Wait a bit more to ensure API is fully ready
    sleep 5
    
    # Try to create the user using curl inside the backend container
    if docker exec smicrab_backend curl -X 'POST' \
        'http://localhost:8000/api/v1/user/create' \
        -H 'accept: application/json' \
        -H 'Content-Type: application/json' \
        -d '{
            "email": "user@smicrab.com",
            "password": "user123"
        }' &> /dev/null; then
        info "Default user created successfully (user@smicrab.com)"
    else
        warn "Failed to create default user - this might be expected if user already exists"
    fi
}

get_server_ip() {
    local server_ip=""
    
    # Try to get IP from .env file first
    if [ -f .env ] && grep -q "^SERVER_PUBLIC_ADDRESS=" .env; then
        server_ip=$(grep "^SERVER_PUBLIC_ADDRESS=" .env | cut -d'=' -f2 | tr -d ' ')
        if [ -n "$server_ip" ] && [ "$server_ip" != "" ]; then
            echo "$server_ip"
            return 0
        fi
    fi
    
    # Try platform-specific IP detection
    case $OS_TYPE in
        "linux")
            if command -v hostname >/dev/null 2>&1 && hostname -I >/dev/null 2>&1; then
                server_ip=$(hostname -I | awk '{print $1}' 2>/dev/null)
            elif command -v ip >/dev/null 2>&1; then
                server_ip=$(ip route get 1 | awk '{print $NF;exit}' 2>/dev/null)
            fi
            ;;
        "mac")
            if command -v ipconfig >/dev/null 2>&1; then
                server_ip=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)
            fi
            ;;
        "windows")
            # For Windows, use localhost as default since IP detection is unreliable
            server_ip="localhost"
            ;;
    esac
    
    # Default fallback
    if [ -z "$server_ip" ] || [ "$server_ip" = "" ]; then
        server_ip="localhost"
    fi
    
    echo "$server_ip"
}

# --- Pre-flight Checks ---
info "Starting SMICRAB cross-platform deployment script..."

# Setup platform-specific variables
setup_platform_specific

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

echo "[INFO] Removing existing network: smicrab-net"
if ! docker network rm smicrab-net; then
  echo "[WARN] Failed to remove network (active endpoints?), disconnecting them…"
  for c in $(docker network inspect smicrab-net -f '{{range .Containers}}{{.Name}} {{end}}'); do
    echo "[INFO]   └ Disconnecting container: $c"
    docker network disconnect -f smicrab-net "$c" 2>/dev/null || true
  done
  echo "[INFO] Retrying network removal"
  docker network rm smicrab-net
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


# Create alias tag for analysis images
docker tag ${REGISTRY_URL}/smicrab-analysis:latest smicrab-analysis:latest
docker tag ${REGISTRY_URL}/smicrab-analysis-packages:latest smicrab-analysis-packages:latest


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
if ! run_docker_with_env run --rm \
    --network smicrab-net \
    --env-file .env \
    "${REGISTRY_URL}/smicrab-backend:latest" \
    alembic upgrade head; then
    error "Database migrations failed"
fi
info "Migrations completed successfully."

# Create tmp directory if it doesn't exist
mkdir -p "${CURRENT_DIR}/tmp"

info "Starting main backend service..."
# Try with Docker socket first, fallback without if it fails (common on some Windows setups)
if ! run_docker_with_env run -d \
    --name smicrab_backend \
    --network smicrab-net \
    --env-file .env \
    -p 8000:8000 \
    -v "${DOCKER_SOCK_PATH}:/var/run/docker.sock" \
    -v "${CURRENT_DIR}/tmp:/tmp" \
    --restart unless-stopped \
    "${REGISTRY_URL}/smicrab-backend:latest"; then
    
    warn "Failed to mount Docker socket, trying without it..."
    if ! run_docker_with_env run -d \
        --name smicrab_backend \
        --network smicrab-net \
        --env-file .env \
        -p 8000:8000 \
        -v "${CURRENT_DIR}/tmp:/tmp" \
        --restart unless-stopped \
        "${REGISTRY_URL}/smicrab-backend:latest"; then
        error "Failed to start backend service"
    fi
fi

# Wait for backend to be running
wait_for_container_health "smicrab_backend" 30 2

info "Starting frontend service..."
if ! run_docker_with_env run -d \
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
if ! docker exec smicrab_backend python /app/resources/scripts/load_dataset_data.py; then
    warn "Data seeding failed - this might be expected if data already exists"
fi
info "Data seeding complete."

# Wait for API to be ready before creating user
wait_for_api_ready 30 3

# Create default user
create_default_user

# --- STEP 4: Final Verification ---
info "Performing health checks..."

# Check if all containers are still running
containers=("postgres" "smicrab_backend" "smicrab_ui")
for container in "${containers[@]}"; do
    if ! docker ps --filter "name=$container" --filter "status=running" | grep -q "$container"; then
        error "Container '$container' is not running!"
    fi
done

# Get server IP for display
SERVER_IP=$(get_server_ip)

info "Deployment script completed successfully!"
echo ""
warn "Current status of running containers:"
docker ps --filter "name=smicrab" --filter "name=postgres"
echo ""
info "🎉 SMICRAB is now running!"
info "You can access the application at:"
info "  🌐 UI: http://${SERVER_IP}:3000"
info "  📚 API Docs: http://${SERVER_IP}:8000/api/v1/docs"
if [ "$OS_TYPE" = "windows" ] && [ "$SERVER_IP" != "localhost" ]; then
    info "  🔗 Local: http://localhost:3000 (alternative)"
fi
echo ""
info "🔐 Default login credentials:"
info "  📧 Email: user@smicrab.com"
info "  🔑 Password: user123"
echo ""
info "📋 Management commands:"
info "  - Check backend logs: docker logs smicrab_backend"
info "  - Check frontend logs: docker logs smicrab_ui"
info "  - Check database logs: docker logs postgres"
info "  - Stop all services: docker stop smicrab_ui smicrab_backend postgres"
info "  - Remove all data: docker volume rm postgres_data"
echo ""
info "✅ Deployment completed on $OS_TYPE"
