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

echo "🚀 Building SMICRAB Analysis Docker Images"
echo "=" * 50

# Step 1: Build analysis packages base image
log "Building analysis packages base image (smicrab-analysis-packages)..."
docker build -f Dockerfile.analysis_packages -t smicrab-analysis-packages:latest . || error "Failed to build analysis packages image."
success "Analysis packages base image built."

# Step 2: Build analysis runner image
log "Building analysis runner image (smicrab-analysis)..."
docker build -f Dockerfile.analysis -t smicrab-analysis:latest . || error "Failed to build analysis runner image."
success "Analysis runner image built."

# Step 3: List created images
log "Listing created analysis images..."
docker images | grep -E "(smicrab-analysis-packages|smicrab-analysis)"

success "🎉 All analysis Docker images built successfully!"
echo ""
echo "You can now:"
echo "  - Tag and push smicrab-analysis-packages to Docker Hub"
echo "  - Run analysis containers using smicrab-analysis:latest"
echo "  - Start the main application with './startup.sh'" 