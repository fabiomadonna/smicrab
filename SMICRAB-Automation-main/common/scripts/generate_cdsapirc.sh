#!/bin/bash

# Determine the directory where this script is located
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
# Source the .env file from the project root (two directories up)
source "$SCRIPT_DIR/../../.env"

# Create the .cdsapirc file using environment variables provided at runtime.
echo "url: ${CDS_API_URL}" > ~/.cdsapirc
echo "key: ${CDS_API_KEY}" >> ~/.cdsapirc
chmod 600 ~/.cdsapirc

# Execute the container's main command (passed as CMD or via docker run)
exec "$@"
