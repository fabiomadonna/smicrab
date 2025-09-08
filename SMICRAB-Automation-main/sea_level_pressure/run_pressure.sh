#!/bin/bash

# Default configuration
SKIP_E_OBS_DOWNLOAD=false
SKIP_UNZIP=false
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"  # Get project root
AP_DIR="$PROJECT_ROOT/sea_level_pressure"
DATA_DIR="$AP_DIR/data"    # Data directory under sea_level_pressure
LOG_DIR="$AP_DIR/logs"     # Log directory under sea_level_pressure

# Create the data and log directories if they don't exist
mkdir -p "$DATA_DIR"
mkdir -p "$LOG_DIR"

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --skip-eobs-download)
      SKIP_E_OBS_DOWNLOAD=true
      shift
      ;;
    --skip-unzip)
      SKIP_UNZIP=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo "Options:"
      echo "  --skip-eobs-download    Skip the Sea_Level_Pressure (E‑OBS) download step"
      echo "  --skip-unzip            Skip the extraction of E-OBS zip file"
      echo "  -h, --help              Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help to see available options"
      exit 1
      ;;
  esac
done

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_DIR/sea_level_pressure_processing.log"
}

# Function to check directory existence
check_directory() {
    if [ ! -d "$1" ]; then
        log "ERROR: Directory $1 does not exist."
        exit 1
    else
        log "Directory $1 found successfully."
    fi
}

# Function to check file existence
check_file() {
    if [ ! -f "$1" ]; then
        log "ERROR: File $1 does not exist."
        exit 1
    else
        log "File $1 found successfully."
    fi
}

# Main processing script
main() {
    # Create (or touch) the log file
    touch "$LOG_DIR/sea_level_pressure_processing.log"
    log "Starting Sea_Level_Pressure Data Processing Workflow"

    # Step 1: CDSAPI Configuration Check
    log "Checking CDSAPI configuration in \$HOME/.cdsapirc"
    if [ ! -f "$HOME/.cdsapirc" ]; then
        log "CDSAPI configuration not found, generating new one"
        if [ ! -f "$PROJECT_ROOT/common/scripts/generate_cdsapirc.sh" ]; then
            log "ERROR: generate_cdsapirc.sh script not found at $PROJECT_ROOT/common/scripts/"
            exit 1
        fi
        if ! "$PROJECT_ROOT/common/scripts/generate_cdsapirc.sh"; then
            log "ERROR: Failed to generate CDSAPI configuration"
            exit 1
        fi
        log "CDSAPI configuration generated successfully at $HOME/.cdsapirc"
    else
        log "CDSAPI configuration already exists at $HOME/.cdsapirc, skipping generation"
    fi

    # Step 2: Download Sea_Level_Pressure (E‑OBS) dataset (if not skipped)
    if [ "$SKIP_E_OBS_DOWNLOAD" = false ]; then
        log "Starting Sea_Level_Pressure (E‑OBS) Download"
        export PYTHONPATH="$PROJECT_ROOT:$PYTHONPATH"
        if ! python3 "$AP_DIR/processing/pp_e_obs_download.py"; then
            log "ERROR: Sea_Level_Pressure (E‑OBS) Download failed"
            exit 1
        fi
        log "Sea_Level_Pressure (E‑OBS) Download completed successfully"
        check_file "$DATA_DIR/pp_2011_2023_Daily_E_OBS.zip"
    else
        log "Sea_Level_Pressure (E‑OBS) Download step skipped"
    fi

    # Step 3: Extract downloaded datasets (if not skipped)
    if [ "$SKIP_UNZIP" = false ]; then
        log "Extracting Sea_Level_Pressure (E‑OBS) dataset"
        ZIP_FILE="$DATA_DIR/pp_2011_2023_Daily_E_OBS.zip"
        TARGET_FOLDER="$DATA_DIR/E_OBS_pp_Daily"

        # Check if zip file exists
        if [ ! -f "$ZIP_FILE" ]; then
            log "ERROR: Zip file $ZIP_FILE does not exist"
            exit 1
        fi

        # Check and create directory if it doesn't exist
        if [ ! -d "$TARGET_FOLDER" ]; then
            log "Directory $TARGET_FOLDER does not exist. Creating it now..."
            mkdir -p "$TARGET_FOLDER"
        fi

        # Extract the zip file with progress
        log "Starting extraction..."
        if ! unzip -o "$ZIP_FILE" -d "$TARGET_FOLDER" | awk 'BEGIN {ORS=" "} {if(NR%10==0)print "."}'; then
            log "ERROR: Extraction failed for $ZIP_FILE"
            exit 1
        fi
        echo ""  # Add newline after progress dots
        log "Extraction of Sea_Level_Pressure dataset completed successfully"
    else
        log "Extraction step skipped"
    fi

    # Step 4: Run Aggregation Script for E-OBS Sea_Level_Pressure
    log "Starting Sea_Level_Pressure E-OBS Dataset Aggregation"
    if ! python3 "$AP_DIR/processing/pp_e_obs_processing.py"; then
        log "ERROR: Sea_Level_Pressure Aggregation failed"
        exit 1
    fi
    log "Sea_Level_Pressure Aggregation completed successfully"
    check_file "$DATA_DIR/E_OBS_pp_Monthly/pp_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly.nc"

    # Step 5: Make Sea_Level_Pressure E-OBS CF-Compliant
    log "Starting Sea_Level_Pressure E-OBS Dataset CF Compliance Conversion"
    if ! python3 "$AP_DIR/processing/pp_make_cf_compliant.py"; then
        log "ERROR: Sea_Level_Pressure CF Compliance Conversion failed"
        exit 1
    fi
    log "Sea_Level_Pressure CF Compliance Conversion completed successfully"
    check_file "$DATA_DIR/E_OBS_pp_Monthly/pp_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly_CF-1.8.nc"

    # Step 6: Generate CSV files if requested
    if [ "$GENERATE_CSV" = true ]; then
        log "Starting CSV Generation from processed data"
        export PYTHONPATH="$PROJECT_ROOT:$PYTHONPATH"
        if ! python3 "$AP_DIR/processing/pp_generate_csv.py"; then
            log "ERROR: CSV Generation failed"
            exit 1
        fi
        log "CSV Generation completed successfully"
        check_file "$DATA_DIR/pp_IT_2011_2023_Monthly/pp_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly_CF-1.8_corrected.csv"

    else
        log "CSV Generation step skipped"
    fi

    log "Entire Sea_Level_Pressure Data Processing Workflow Completed Successfully"
}

# Run the main function
main