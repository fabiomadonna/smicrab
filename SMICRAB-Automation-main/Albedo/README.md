# Albedo Processing Guide

## Overview
This module automates the processing of Surface Albedo (SAL) data. It downloads and processes data from CMSAF daily Albedo and merges it with ERA5 data. The workflow is managed by a shell script (`run_Albedo.sh`) that automates the process using Python and bash scripts

## Directory Structure
```
Albedo/

│-- logs/                         # Stores log files for debugging
│-- processing/                   # Contains Python scripts for data processing
│-- run_SAL.sh                    # Main execution script
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
**Important**: Download the CMSAF Surface Albedo Daily data and place the NetCDF files in the `data/CMSAF_SAL_daily/` directory before running the script. This module **does not** download the CMSAF data automatically.

### EUMETSAT Credentials
To enable the EUMETSAT data download, you need to set up EUMETSAT credentials in the `.env` file at the project root. The script uses `EUMETSAT_USERNAME` and `EUMETSAT_PASSWORD` environment variables for authentication. If you skip the download step, EUMETSAT data will not be processed.

## Running the Script
The script supports optional flags for skipping specific steps.

### Usage:
```sh
bash run_SAL.sh [OPTIONS]
```

### Options:
- `--skip-era5-download ` : Skip the ERA5 dataset download step.
- `--skip-cmsaf-download` : Skip the CMSAF download step
- `--generate-csv` : Generate CSV files from processed data.
- `-h, --help` : Show help message.

### Example:
Run the script without skipping any steps:
```sh
bash run_SAL.sh
```

Skip downloading the ERA5 dataset:
```sh
bash run_SAL.sh --skip-download
```

## Processing Steps

### 1. CDSAPI Configuration Check
The script checks for the `~/.cdsapirc` file, required for downloading datasets. If missing, it generates it using a helper script.

### 2. Download ERA5 Dataset
- downloads ERA5 monthly averaged reanalysis forecast albedo data. This step is skipped if `--skip-download` flag is used.
- Uses `era5_sal_download.py` to fetch and store the dataset in the `data/ERA5_SAL_Monthly/` directory.

### 3. CMSAF Albedo Download
- Automatically downloads CMSAF Albedo data from Google Drive
- Uses `cmsaf_sal_download.py` with Google Drive file ID

### 4. CMSAF Data Extraction
- Extracts downloaded zip file to `data/CMSAF_SAL_daily/` directory.

### 5. Check CMSAF Input Directory
- Verifies that the `data/CMSAF_SAL_daily/` directory exists and contains the pre-downloaded CMSAF daily NetCDF files. **Ensure CMSAF data is placed here before running the script.**

### 6. Run CMSAF Processing Script
- Processes the daily CMSAF data to a monthly format.
- Uses `cmsaf_sal_processing.py` to:
    - Subset the CMSAF data to the geographical extent of Italy.
    - Interpolate the dataset to a 0.1 degree grid resolution.
    - Concatenate daily files into a monthly dataset.
- The resulting monthly dataset is stored in `data/CMSAF_SAL_Monthly/SAL_IT_2011_2023_Monthly_CMSAF.nc`.

### 7. Check Required Files for Merging
- Checks if the processed CMSAF monthly file exists.
- If ERA5 download was not skipped, it also checks for the ERA5 monthly file.

### 8. Run Merge Script
- Merges the processed CMSAF monthly albedo data with the ERA5 monthly albedo data.
- Uses `merge_cmsaf_with_era5_sal.py` to combine the datasets, filling missing values in CMSAF data with ERA5 data where available.
- The merged dataset is saved as `data/SAL_Monthly_2011-2023/SAL_IT_2011-2023_Monthly_CMSAF_ERA5.nc`.

### 9. Run CF Compliance Script
- Makes the merged albedo dataset CF-1.8 compliant for better interoperability.
- Uses `make_sal_cf_compliant.py` to add metadata and ensure CF-1.8 conventions are followed.
- The CF-compliant dataset is saved as `data/SAL_Monthly_2011-2023_CF_Compliant/SAL_IT_2011-2023_Monthly_CMSAF_ERA5_CF-1.8.nc`.

### 10. Run Reinterpolation Script
- Performs linear interpolation to fill any remaining missing time steps in the CF-compliant merged dataset.
- Uses `reinterpolate_merged_cmsaf_era5.py` to perform the reinterpolation.
- The final reinterpolated and CF-compliant dataset is saved as `data/SAL_Monthly_2011-2023_CF_Compliant/SAL_IT_2011-2023_Monthly_CMSAF_ERA5_CF-1.8_Reinterpolated.nc`.

### 11. CSV Generation (Optional)
- Generates CSV versions of processed data files when `--generate-csv` flag is used
- Uses `sal_generate_csv.py` to create comma-separated versions of the data

## Output Files
After successful execution, the following key output files will be generated:
```
data/
│-- CMSAF_SAL_Monthly/
│   │-- SAL_IT_2011_2023_Monthly_CMSAF.nc                             # Monthly aggregated CMSAF Albedo
│-- ERA5_SAL_Monthly/
│   │-- SAL_IT_2011_2023_Monthly_ERA5.nc                              # Monthly ERA5 Albedo
│-- SAL_Monthly_2011-2023/
│   │-- SAL_IT_2011-2023_Monthly_CMSAF_ERA5.nc                        # Merged CMSAF and ERA5 Albedo
│-- SAL_Monthly_2011-2023_CF_Compliant/
│   │-- SAL_IT_2011-2023_Monthly_CMSAF_ERA5_CF-1.8.nc                 # CF-1.8 Compliant Merged Albedo
│   │-- SAL_IT_2011-2023_Monthly_CMSAF_ERA5_CF-1.8_Reinterpolated.nc  # Reinterpolated and CF-1.8 Compliant Merged Albedo
```

## Troubleshooting

- **Directory/File Not Found Errors**:
    - Ensure the CMSAF daily data files are correctly placed in the `data/CMSAF_SAL_daily/` directory.
    - Check the log file for specific file or directory paths that are missing and verify their existence.
- **Missing Dependencies**:
  ```sh
  pip install -r requirements.txt
  ```
  Install any missing Python packages reported during script execution.
- **CDSAPI Configuration Issues**:
  - Check your internet connection and verify your CDSAPI configuration (`~/.cdsapirc`) if downloads from CDS fail.
- **CMSAF Data Issues**:
    - Verify that the CMSAF data files are in NetCDF format and are not corrupted.

## Logs
Execution logs are stored in `logs/albedo_processing.log`. Review this file for detailed information about each processing step and for debugging any issues.
```
