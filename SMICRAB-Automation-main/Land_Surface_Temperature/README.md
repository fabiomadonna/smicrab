# Land Surface Temperature Processing Guide

## Overview
This module automates the processing of Land Surface Temperature (LST) data. It processes data from CMSAF daily LST and merges it with EUMETSAT hourly LST data. The workflow is managed by a shell script (`run_LST.sh`) that automates the process using Python and bash scripts. **Note that CMSAF dataset must be downloaded and placed in the input directory (`data/CMSAF_LST_daily`) before running this module.**

## Directory Structure
```
Land_Surface_Temperature/
│-- data/                        # Stores downloaded and processed datasets
│-- logs/                        # Stores log files for debugging
│-- processing/                  # Contains Python and bash scripts for data processing
│-- run_LST.sh                   # Main execution script
```

## Prerequisites
Ensure you have the following dependencies installed before running the script:

### System Dependencies
```sh
sudo apt update && sudo apt install -y wget unzip
```

### Python Dependencies
Install required Python packages from the **root** directory:
```sh
pip install -r requirements.txt
```

### CMSAF Data
**Important**: Download the CMSAF Land Surface Temperature Daily data and place the NetCDF files in the `data/CMSAF_LST_daily/` directory before running the script. This module **does not** download the CMSAF data automatically.

### EUMETSAT Credentials
To enable the EUMETSAT data download, you need to set up EUMETSAT credentials in the `.env` file at the project root. The script uses `EUMETSAT_USERNAME` and `EUMETSAT_PASSWORD` environment variables for authentication. If you skip the download step, EUMETSAT data will not be processed.

## Running the Script
The script provides options to skip the EUMETSAT download step.

### Usage:
```sh
bash run_LST.sh [OPTIONS]
```

### Options:
- `--skip-eumetsat-download` : Skip the EUMETSAT dataset download step.
- `--skip-cmsaf-download` : Skip the CMSAF download step.
- `--generate-csv` : Generate CSV files from processed data.
- `-h, --help` : Show help message.

### Example:
Run the script without skipping any steps (including EUMETSAT download if credentials are set):
```sh
bash run_LST.sh
```

Skip downloading the EUMETSAT dataset:
```sh
bash run_LST.sh --skip-download
```

## Processing Steps


### 1. Download CMSAF LST Data
- Automatically downloads CMSAF Land Surface Temperature Daily data using cmsaf_lst_download.py
- Downloads zip file from Google Drive to data/LST_CMSAF_2011_2020.zip

### 2. Extract CMSAF LST Zip File
- Extracts the downloaded zip file to  `data/CMSAF_LST_daily/` directory.

### 3. Check CMSAF_LST_DAILY Directory
- Verifies that the `data/CMSAF_LST_daily/` directory exists and contains the pre-downloaded CMSAF daily LST NetCDF files. **Ensure CMSAF data is placed here before running the script.**

### 4. Run CMSAF Processing Script
- Processes the daily CMSAF LST data to a monthly per hour format.
- Uses `cmsaf_lst_processing.py` to:
    - Subset the CMSAF data to the geographical extent of Italy.
    - Interpolate the dataset to a 0.1 degree grid resolution.
    - Concatenate daily files and aggregate to monthly means per hour.
- The resulting monthly per hour dataset is stored in `data/CMSAF_Monthly_Per_Hour/LST_IT_2011_2020_agg_monthly_per_hour.nc`.

### 5. Run EUMETSAT Download Script
- downloads EUMETSAT hourly LST data for the years 2021-2023. This step is skipped if `--skip-download` flag is used.
- Uses `download_eumetsat.sh` script, which requires EUMETSAT credentials to be set as environment variables.
- Downloads data into the `data/EUMETSAT_LST_hourly/` directory.

### 6. Check EUMETSAT_LST_hourly Directory
- Verifies that the `data/EUMETSAT_LST_hourly/` directory exists, especially if the download step was intended to be run.

### 7. Run EUMETSAT Processing Script
- Processes the hourly EUMETSAT LST data to a monthly per hour format, similar to CMSAF processing.
- Uses `eumetsat_lst_processing.py` to:
    - Subset the EUMETSAT data to the geographical extent of Italy.
    - Interpolate the dataset to a 0.1 degree grid resolution.
    - Aggregate hourly data to monthly means per hour.
- The resulting monthly per hour dataset is stored in `data/EUMETSAT_Monthly_Per_Hour/LST_IT_2021_2023_agg_monthly_per_hour.nc`.

### 8. Run Merge Script
- Merges the processed CMSAF and EUMETSAT monthly per hour LST datasets.
- Uses `merge_lst_datasets.py` to combine the datasets, creating a continuous time series from 2011 to 2023.
- The merged dataset is saved as `data/LST_Monthly_Per_Hour_2011-2023/LST_IT_2011_2023_agg_Monthly_per_hour.nc`.

### 9. Run CF Compliance Script
- Makes the merged LST dataset CF-1.8 compliant for better interoperability.
- Uses `make_lst_cf_compliant.py` to add metadata and ensure CF-1.8 conventions are followed.
- The CF-compliant dataset is saved as `data/LST_Monthly_Per_Hour_2011-2023_CF_Compliant/LST_IT_2011_2023_agg_Monthly_per_hour_grid_0.1_CF-1.8.nc`.

### 10. CSV Generation (Optional)
- Generates CSV versions of processed data files when `--generate-csv` flag is used
- Uses `lst_generate_csv.py` to create comma-separated versions of the data

## Output Files
After successful execution, the following key output files will be generated:
```
data/
│-- CMSAF_Monthly_Per_Hour/
│   │-- LST_IT_2011_2020_agg_monthly_per_hour.nc                  # Monthly per hour aggregated CMSAF LST
│-- EUMETSAT_Monthly_Per_Hour/
│   │-- LST_IT_2021_2023_agg_monthly_per_hour.nc                  # Monthly per hour aggregated EUMETSAT LST
│-- LST_Monthly_Per_Hour_2011-2023/
│   │-- LST_IT_2011_2023_agg_Monthly_per_hour.nc                  # Merged CMSAF and EUMETSAT LST
│-- LST_Monthly_Per_Hour_2011-2023_CF_Compliant/
│   │-- LST_IT_2011_2023_agg_Monthly_per_hour_grid_0.1_CF-1.8.nc  # CF-1.8 Compliant Merged LST
```

## Troubleshooting

- **Directory/File Not Found Errors**:
    - Ensure the CMSAF daily LST data files are correctly placed in the `data/CMSAF_LST_daily/` directory.
    - If using EUMETSAT data, verify the `data/EUMETSAT_LST_hourly/` directory structure and downloaded files if download step was not skipped.
    - Check the log file for specific file or directory paths that are missing and verify their existence.
- **Missing Dependencies**:
  ```sh
  pip install -r requirements.txt
  ```
  Install any missing Python packages reported during script execution.
- **EUMETSAT Download Failures**:
    - Check your internet connection and EUMETSAT credentials in the `.env` file.
    - Verify that `wget` is correctly installed and functioning.
- **CMSAF Data Issues**:
    - Verify that the downloaded CMSAF zip file exists in the `data/` directory.
    - Ensure the files cover the expected time range (2011-2020 for CMSAF in this workflow).

## Logs
Execution logs are stored in `logs/processing.log`. Review this file for detailed information about each processing step and for debugging any issues.
```