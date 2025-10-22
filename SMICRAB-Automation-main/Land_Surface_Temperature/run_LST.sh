#!/bin/bash

# Default configuration
SKIP_EUMETSAT_DOWNLOAD=false
SKIP_CMSAF_DOWNLOAD=false
GENERATE_CSV=false # Default: do not generate CSV
DATA_DIR="data"  # Define the data directory
LOG_DIR="logs"  # Log directory inside the data directory

# Create the data and log directories if they don't exist
mkdir -p "$DATA_DIR"
mkdir -p "$LOG_DIR"

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --skip-eumetsat-download)
      SKIP_EUMETSAT_DOWNLOAD=true
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
      echo "  --skip-eumetsat-download    Skip the EUMETSAT download step"
      echo "  --skip-cmsaf-download       Skip the CMSAF download step"
      echo "  --generate-csv              Generate CSV files from processed data" # Help text for CSV option
      echo "  -h, --help                  Show this help message"
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
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_DIR/processing.log"
}

# Function to check directory existence
check_directory() {
    if [ ! -d "$DATA_DIR/$1" ]; then # Checks for directory inside data directory
        log "ERROR: Directory $1 does not exist inside $DATA_DIR."
        log "Usage Guide: Ensure the '$1' directory exists inside the '$DATA_DIR' directory."
        exit 1
    else
        log "Directory $1 found successfully inside $DATA_DIR."
    fi
}

# Function to check file existence
check_file() {
    if [ ! -f "$DATA_DIR/$1" ]; then # Checks for file inside data directory
        log "ERROR: File $1 does not exist inside $DATA_DIR."
        log "Usage Guide: Ensure the '$1' file exists inside the '$DATA_DIR' directory."
        exit 1
    else
        log "File $1 found successfully inside $DATA_DIR."
    fi
}

# Main processing script
main() {
    # Create log file
    touch "$LOG_DIR/processing.log"

    log "Starting Land Surface Temperature Data Processing Workflow"

    # Step 1: Download CMSAF LST zip file (optional)
    if [ "$SKIP_CMSAF_DOWNLOAD" = false ]; then
        log "Starting CMSAF LST Zip File Download from Google Drive"
        if ! python3 ./processing/cmsaf_lst_download.py "$DATA_DIR"; then
            log "ERROR: Failed to download CMSAF LST zip file from Google Drive."
            exit 1
        fi
        CMSAF_LST_ZIP_FILE="$DATA_DIR/LST_CMSAF_2011_2020.zip"
        log "CMSAF LST zip file downloaded successfully to $CMSAF_LST_ZIP_FILE"


        # Step 2: Extract CMSAF LST zip file
        log "Starting CMSAF LST Zip File Extraction"
        CMSAF_LST_EXTRACT_DIR="$DATA_DIR/CMSAF_LST_daily"

        # Check if CMSAF LST zip file exists
        if [ ! -f "$CMSAF_LST_ZIP_FILE" ]; then
            log "ERROR: CMSAF LST zip file $CMSAF_LST_ZIP_FILE does not exist"
            exit 1
        fi

        # Check if CMSAF LST extraction directory exists
        if [ ! -d "$CMSAF_LST_EXTRACT_DIR" ]; then
            log "Directory $CMSAF_LST_EXTRACT_DIR does not exist. Creating it now..."
            if ! mkdir -p "$CMSAF_LST_EXTRACT_DIR"; then
                log "ERROR: Failed to create CMSAF LST extraction directory: $CMSAF_LST_EXTRACT_DIR"
                exit 1
            fi
            log "Created CMSAF LST extraction directory: $CMSAF_LST_EXTRACT_DIR"
        else
            log "Directory $CMSAF_LST_EXTRACT_DIR already exists. Skipping creation."
        fi

        # Extract CMSAF LST zip file with progress
        log "Starting CMSAF LST Zip File Extraction..."
        if ! unzip -o "$CMSAF_LST_ZIP_FILE" -d "$CMSAF_LST_EXTRACT_DIR"; then
            log "ERROR: Failed to extract CMSAF LST zip file to $CMSAF_LST_EXTRACT_DIR"
            exit 1
        fi
        log "CMSAF LST zip file extracted successfully to $CMSAF_LST_EXTRACT_DIR"
    else
        log "CMSAF download step skipped"
    fi

    # Step 3: Check CMSAF_LST_DAILY directory
    check_directory "CMSAF_LST_daily"

    # Step 4: Run CMSAF Processing Script
    log "Starting CMSAF Processing Script"
    python3 ./processing/cmsaf_lst_processing.py
    if [ $? -eq 0 ]; then
        log "CMSAF Processing completed successfully"
    else
        log "ERROR: CMSAF Processing failed"
        exit 1
    fi

    # Step 5: Run EUMETSAT Download Script (optional)
    if [ "$SKIP_EUMETSAT_DOWNLOAD" = false ]; then
        log "Starting EUMETSAT Download Script"
        ./processing/download_eumetsat.sh
        if [ $? -eq 0 ]; then
            log "EUMETSAT Download completed successfully"
        else
            log "ERROR: EUMETSAT Download failed"
            exit 1
        fi
    else
        log "EUMETSAT Download step skipped"
    fi

    # Step 6: Check EUMETSAT_LST_hourly directory
    check_directory "EUMETSAT_LST_hourly"

    # Step 7: Run EUMETSAT Processing Script
    log "Starting EUMETSAT Processing Script"
    python3 ./processing/eumetsat_lst_processing.py
    if [ $? -eq 0 ]; then
        log "EUMETSAT Processing completed successfully"
    else
        log "ERROR: EUMETSAT Processing failed"
        exit 1
    fi

    # Step 8: Check required files for merging
    check_file "CMSAF_Monthly_Per_Hour/LST_IT_2011_2020_agg_monthly_per_hour.nc"
    check_file "EUMETSAT_Monthly_Per_Hour/LST_IT_2021_2023_agg_monthly_per_hour.nc"

    # Step 9: Run Merge Script
    log "Starting LST Datasets Merging"
    python3 ./processing/merge_lst_datasets.py
    if [ $? -eq 0 ]; then
        log "LST Datasets Merging completed successfully"
    else
        log "ERROR: LST Datasets Merging failed"
        exit 1
    fi

    # Step 10: Check merged file exists
    check_file "LST_Monthly_Per_Hour_2011-2023/LST_IT_2011_2023_agg_Monthly_per_hour.nc"

    # Step 11: Run CF Compliance Script
    log "Starting CF-1.8 Compliance Processing"
    python3 ./processing/make_lst_cf_compliant.py
    if [ $? -eq 0 ]; then
        check_file "LST_Monthly_Per_Hour_2011-2023/LST_IT_2011_2023_agg_Monthly_per_hour_grid_0.1_CF-1.8.nc"
        log "CF-1.8 Compliance Processing completed successfully"
    else
        log "ERROR: CF-1.8 Compliance Processing failed"
        exit 1
    fi

    # Step 12: Generate CSV files if requested
    if [ "$GENERATE_CSV" = true ]; then
        log "Starting CSV Generation from processed data"
        if ! python3 ./processing/lst_generate_csv.py; then # Assuming lst_generate_csv.py exists in processing dir
            log "ERROR: CSV Generation failed"
            exit 1
        fi
        log "CSV Generation completed successfully"
        check_file "LST_IT_2011_2023_agg_Monthly_per_hour_grid_0.1_CF-1.8.csv" # Adjust filename if needed
    else
        log "CSV Generation step skipped"
    fi

    # Step 13: Final Workflow Completion
    log "Entire Land Surface Temperature Data Processing Workflow Completed Successfully"
}

# Run the main function
main