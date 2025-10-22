# Wind Speed Processing Guide

## Overview
This module automates the downloading, extraction, processing, and homogenization of wind speed data from different sources. The workflow is managed by a shell script (`run_wind_speed.sh`) that automates the process using Python scripts.

## Directory Structure
```
wind_speed/
│-- data/                   # Stores downloaded and processed datasets
│-- logs/                   # Stores log files for debugging
│-- processing/             # Contains Python scripts for data processing
│-- run_wind_speed.sh       # Main execution script
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

## Running the Script
The script supports several optional flags for skipping specific steps.

### Usage:
```sh
bash run_wind_speed.sh [OPTIONS]
```

### Options:
- `--skip-eobs-download` : Skip the Wind Speed (E‑OBS) dataset download step.
- `--skip-era5-download` : Skip the ERA5 dataset download step.
- `--skip-unzip` : Skip the extraction of the E-OBS zip file.
- `--generate-csv` : Generate CSV files from processed data.
- `-h, --help` : Show help message.

### Example:
Run the script without skipping any steps:
```sh
bash run_wind_speed.sh
```

Skip downloading the ERA5 dataset:
```sh
bash run_wind_speed.sh --skip-era5-download
```

## Processing Steps

### 1. CDSAPI Configuration Check
The script verifies the presence of a `~/.cdsapirc` file required for downloading climate data. If missing, it attempts to generate the file using `generate_cdsapirc.sh` script located in the `common/scripts/` directory relative to the project root.

### 2. Download ERA5 Dataset
- Downloads ERA5 monthly wind speed data derived from 10m U and V wind components.
- Uses `fg_era5_download.py` to fetch and store the dataset.

### 3. Download Wind Speed (E‑OBS) Dataset
- Downloads daily wind speed data from the E‑OBS dataset.
- Uses `fg_e_obs_download.py` to retrieve data and save it in ZIP format.

### 4. Extract E‑OBS Dataset
- Unzips the downloaded file into the `data/` directory.

### 5. Aggregate E‑OBS Data
- Processes the extracted daily data into a monthly format.
- Uses `fg_e_obs_processing.py` for subsetting, interpolation and aggregation.

### 6. Make E-OBS Data CF-Compliant
- Converts the aggregated E-OBS monthly data to be CF-1.8 compliant.
- Uses `fg_make_cf_compliant.py` and saves the CF-compliant file.

### 7. Homogenization
- Applies corrections to ensure data consistency using a pairwise homogenization approach on the CF-compliant E-OBS monthly data.
- Uses `fg_homogenization.py` to generate a corrected dataset.

### 8. CSV Generation (Optional)
- Generates CSV versions of processed data files when `--generate-csv` flag is used
- Uses `fg_generate_csv.py` to create comma-separated versions of the data

## Output Files
After execution, the following files will be available:
```
data/
│-- E_OBS_fg_Daily/fg_ens_mean_0.1deg_reg_2011-2023_v28.0e.nc
│-- E_OBS_fg_Daily_subset/fg_ens_mean_0.1deg_reg_2011-2023_v28.0e_subset.nc
│-- E_OBS_fg_Monthly/fg_ens_mean_0.1deg_reg_2011-2023_v28.0e_monthly.nc
│-- E_OBS_fg_Monthly/fg_ens_mean_0.1deg_reg_2011-2023_v28.0e_monthly_CF-1.8.nc
│-- ERA5_fg_Monthly/fg_IT_2011_2023_Monthly_ERA5.nc
│-- fg_IT_2011_2023_Monthly/fg_ens_mean_0.1deg_reg_2011-2023_v28.0e_monthly_CF-1.8_corrected.nc
│-- fg_2011_2023_Daily_E_OBS.zip
```

## Troubleshooting

- **Permission Issues**:
  ```sh
  chmod +x run_wind_speed.sh
  ```
  Ensure the script has execution permissions.

- **Missing Dependencies**:
  ```sh
  pip install -r requirements.txt
  ```
  Install any missing Python packages from the **root** directory.

- **Download Failures**:
  Check network connectivity and ensure your CDSAPI key is correctly configured in `~/.cdsapirc`. Rerun the script.

- **Script Errors**:
  If the script fails, check the log file for detailed error messages.

## Logs
Logs for execution are stored in `logs/wind_speed_processing.log`. Review this file for debugging if errors occur.