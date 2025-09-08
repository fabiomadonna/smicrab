#!/bin/bash

# Default configuration
SKIP_ERA5_DOWNLOAD=false
SKIP_CMSAF_DOWNLOAD=false
GENERATE_CSV=false # Default: do not generate CSV
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"  # Get project root
ALBEDO_DIR="$PROJECT_ROOT/Albedo"
DATA_DIR="$ALBEDO_DIR/data"  # Data directory under Albedo
LOG_DIR="$ALBEDO_DIR/logs"   # Log directory under Albedo

# Create the data and log directories if they don't exist
mkdir -p "$DATA_DIR"
mkdir -p "$LOG_DIR"

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --skip-era5-download)
      SKIP_ERA5_DOWNLOAD=true
      shift
      ;;
    --skip-cmsaf-download)
      SKIP_CMSAF_DOWNLOAD=true
      shift
      ;;
    --generate-csv) # Option to generate CSV
      GENERATE_CSV=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo "Options:"
      echo "  --skip-era5-download    Skip the ERA5 download step"
      echo "  --skip-cmsaf-download   Skip the CMSAF download step"
      echo "  --generate-csv          Generate CSV files from processed data" # Help text for CSV option
      echo "  -h, --help              Show this help message"
      exit 0
      ;;
    *)
      # Unknown option
      echo "Unknown option: $1"
      echo "Use --help to see available options"
      exit 1
      ;;
  esac
done

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_DIR/albedo_processing.log"
}

# Function to check directory existence
check_directory() {
    if [ ! -d "$1" ]; then
        log "ERROR: Directory $1 does not exist."
        log "Usage Guide: Ensure the directory exists: $1"
        exit 1
    else
        log "Directory $1 found successfully."
    fi
}

# Function to check file existence
check_file() {
    if [ ! -f "$1" ]; then
        log "ERROR: File $1 does not exist."
        log "Usage Guide: Ensure the file exists: $1"
        exit 1
    else
        log "File $1 found successfully."
    fi
}

# Function to check missing values in NetCDF files
check_missing_values() {
    local file_path="$1"
    log "Checking missing values in $file_path"
    if ! python3 "$ALBEDO_DIR/processing/check_missing_values.py" "$file_path" | tee -a "$LOG_DIR/albedo_processing.log"; then
        log "ERROR: Failed to check missing values in $file_path"
        exit 1
    fi
}

# Main processing script
main() {
    # Create log file
    touch "$LOG_DIR/albedo_processing.log"

    log "Starting Albedo Data Processing Workflow"

    # Step 1: Add CDSAPI config if not exists in home directory
    log "Checking CDSAPI configuration in $HOME/.cdsapirc"
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


    # Step 2: Download ERA5 dataset (optional)
    if [ "$SKIP_ERA5_DOWNLOAD" = false ]; then
        log "Starting ERA5 Download"
        export PYTHONPATH="$PROJECT_ROOT:$PYTHONPATH"
        if ! python3 "$ALBEDO_DIR/processing/era5_sal_download.py"; then
            log "ERROR: ERA5 Download failed"
            exit 1
        fi
        log "ERA5 Download completed successfully"
        check_file "$DATA_DIR/ERA5_SAL_Monthly/SAL_IT_2011_2023_Monthly_ERA5.nc"
    else
        log "ERA5 Download step skipped"
    fi

    # Step 3: Download CMSAF Albedo data (optional)
    if [ "$SKIP_CMSAF_DOWNLOAD" = false ]; then
        log "Starting CMSAF Albedo Download from Google Drive"
        if ! python3 "$ALBEDO_DIR/processing/cmsaf_sal_download.py" "$DATA_DIR"; then
            log "ERROR: Failed to download CMSAF Albedo data from Google Drive"
            exit 1
        fi
        CMSAF_ZIP_FILE="$DATA_DIR/Albedo_CMSAF_2011_2023.zip"
        log "CMSAF Albedo data downloaded successfully to $CMSAF_ZIP_FILE"


        # Step 4: Extract CMSAF zip file
        log "Starting CMSAF Zip File Extraction"
        CMSAF_EXTRACT_DIR="$DATA_DIR/CMSAF_SAL_daily"

        # Check if CMSAF zip file exists
        if [ ! -f "$CMSAF_ZIP_FILE" ]; then
            log "ERROR: CMSAF zip file $CMSAF_ZIP_FILE does not exist"
            exit 1
        fi

        # Check if CMSAF extraction directory exists
        if [ ! -d "$CMSAF_EXTRACT_DIR" ]; then
            log "Directory $CMSAF_EXTRACT_DIR does not exist. Creating it now..."
            if ! mkdir -p "$CMSAF_EXTRACT_DIR"; then
                log "ERROR: Failed to create CMSAF extraction directory: $CMSAF_EXTRACT_DIR"
                exit 1
            fi
            log "Created CMSAF extraction directory: $CMSAF_EXTRACT_DIR"
        else
            log "Directory $CMSAF_EXTRACT_DIR already exists. Skipping creation."
        fi

        # Extract CMSAF zip file with progress
        log "Starting CMSAF Zip File Extraction..."
        if ! unzip -o "$CMSAF_ZIP_FILE" -d "$CMSAF_EXTRACT_DIR"; then
            log "ERROR: Failed to extract CMSAF zip file to $CMSAF_EXTRACT_DIR"
            exit 1
        fi
        log "CMSAF zip file extracted successfully to $CMSAF_EXTRACT_DIR"
    else
        log "CMSAF Download step skipped"
    fi


    # Step 5: Check CMSAF input directory exists
    check_directory "$DATA_DIR/CMSAF_SAL_daily"

    # Step 6: Run CMSAF Processing Script
    log "Starting CMSAF Processing Script"
    if ! python3 "$ALBEDO_DIR/processing/cmsaf_sal_processing.py"; then
        log "ERROR: CMSAF Processing failed"
        exit 1
    fi
    log "CMSAF Processing completed successfully"
    check_file "$DATA_DIR/CMSAF_SAL_Monthly/SAL_IT_2011_2023_Monthly_CMSAF.nc"

    # Step 7: Check required files for merging
    check_file "$DATA_DIR/CMSAF_SAL_Monthly/SAL_IT_2011_2023_Monthly_CMSAF.nc"
    if [ "$SKIP_ERA5_DOWNLOAD" = false ]; then
        check_file "$DATA_DIR/ERA5_SAL_Monthly/SAL_IT_2011_2023_Monthly_ERA5.nc"
    fi

    # Step 8: Run Merge Script
    log "Starting Albedo Datasets Merging"
    if ! python3 "$ALBEDO_DIR/processing/merge_cmsaf_with_era5_sal.py"; then
        log "ERROR: Albedo Datasets Merging failed"
        exit 1
    fi
    log "Albedo Datasets Merging completed successfully"
    check_file "$DATA_DIR/SAL_Monthly_2011-2023/SAL_IT_2011-2023_Monthly_CMSAF_ERA5.nc"

    # Step 9: Run CF Compliance Script
    log "Starting CF-1.8 Compliance Processing"
    if ! python3 "$ALBEDO_DIR/processing/make_sal_cf_compliant.py"; then
        log "ERROR: CF-1.8 Compliance Processing failed"
        exit 1
    fi
    log "CF-1.8 Compliance Processing completed successfully"
    check_directory "$DATA_DIR/SAL_Monthly_2011-2023_CF_Compliant"
    check_file "$DATA_DIR/SAL_Monthly_2011-2023_CF_Compliant/SAL_IT_2011-2023_Monthly_CMSAF_ERA5_CF-1.8.nc"

    # Step 10: Run Reinterpolation Script
    log "Starting Reinterpolation Processing"
    if ! python3 "$ALBEDO_DIR/processing/reinterpolate_merged_cmsaf_era5.py"; then
        log "ERROR: Reinterpolation Processing failed"
        exit 1
    fi
    log "Reinterpolation Processing completed successfully"
    check_file "$DATA_DIR/SAL_Monthly_2011-2023_CF_Compliant/SAL_IT_2011-2023_Monthly_CMSAF_ERA5_CF-1.8_Reinterpolated.nc"

    # Step 11: Generate CSV files if requested
    if [ "$GENERATE_CSV" = true ]; then
        log "Starting CSV Generation from processed data"
        export PYTHONPATH="$PROJECT_ROOT:$PYTHONPATH"
        if ! python3 "$ALBEDO_DIR/processing/albedo_generate_csv.py"; then # Assuming albedo_generate_csv.py exists
            log "ERROR: CSV Generation failed"
            exit 1
        fi
        log "CSV Generation completed successfully"
        check_file "$DATA_DIR/SAL_IT_2011-2023_Monthly_CMSAF_ERA5_CF-1.8_Reinterpolated.csv" # Adjust filename if needed
    else
        log "CSV Generation step skipped"
    fi

    # Step 12: Final Workflow Completion
    log "Entire Albedo Data Processing Workflow Completed Successfully"

    # Check missing values in final files
    log ""
    log "=== Starting Missing Values Check ==="
    log ""
    check_missing_values "$DATA_DIR/CMSAF_SAL_Monthly/SAL_IT_2011_2023_Monthly_CMSAF.nc"
    log ""
    check_missing_values "$DATA_DIR/SAL_Monthly_2011-2023_CF_Compliant/SAL_IT_2011-2023_Monthly_CMSAF_ERA5_CF-1.8.nc"
    log ""
    check_missing_values "$DATA_DIR/SAL_Monthly_2011-2023_CF_Compliant/SAL_IT_2011-2023_Monthly_CMSAF_ERA5_CF-1.8_Reinterpolated.nc"
    log "=== Missing Values Check Completed ==="
}

# Run the main function
main