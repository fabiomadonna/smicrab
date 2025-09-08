# Sea Level Pressure Processing Guide

## Overview
This module handles the downloading, extraction, and processing of sea level pressure data from the E-OBS dataset. The workflow is managed by a shell script (`run_pressure.sh`) that automates the process using Python scripts.

## Directory Structure
```
sea_level_pressure/
│-- data/                 # Stores downloaded and processed datasets
│-- logs/                 # Stores log files for debugging
│-- processing/           # Contains Python scripts for data processing
│-- run_pressure.sh       # Main execution script
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
The script supports optional flags for skipping specific steps.

### Usage:
```sh
bash run_pressure.sh [OPTIONS]
```

### Options:
- `--skip-eobs-download` : Skip the Sea Level Pressure (E‑OBS) dataset download step.
- `--skip-unzip` : Skip the extraction of the E-OBS zip file.
- `--generate-csv` : Generate CSV files from processed data.
- `-h, --help` : Show help message.

### Example:
Run the script without skipping any steps:
```sh
bash run_pressure.sh
```

Skip downloading the E-OBS dataset:
```sh
bash run_pressure.sh --skip-eobs-download
```

## Processing Steps

### 1. CDSAPI Configuration Check
The script verifies the presence of a `~/.cdsapirc` file required for downloading climate data. If missing, it attempts to generate the file using `generate_cdsapirc.sh` script located in the `common/scripts/` directory relative to the project root.

### 2. Download Sea Level Pressure (E‑OBS) Dataset
- Downloads daily sea level pressure data from the E‑OBS dataset.
- Uses `pp_e_obs_download.py` to retrieve data and save it in ZIP format.

### 3. Extract E‑OBS Dataset
- Unzips the downloaded file into the `data/` directory.

### 4. Aggregate E‑OBS Data
- Processes the extracted data into a monthly format.
- Uses `pp_e_obs_processing.py` for subsetting, interpolation, and aggregation.

### 5. Make E-OBS Data CF-Compliant
- Converts the aggregated E-OBS monthly data to be CF-1.8 compliant.
- Uses `pp_make_cf_compliant.py` and saves the CF-compliant file.

### 6. CSV Generation (Optional)
- Generates CSV versions of processed data files when `--generate-csv` flag is used
- Uses `pp_generate_csv.py` to create comma-separated versions of the data

## Output Files
After execution, the following files will be available:
```
data/
│-- E_OBS_pp_Daily/pp_ens_mean_0.1deg_reg_2011-2023_v29.0e.nc
│-- E_OBS_pp_Daily_subset/pp_ens_mean_0.1deg_reg_2011-2023_v29.0e_subset.nc
│-- E_OBS_pp_Monthly/pp_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly.nc
│-- E_OBS_pp_Monthly/pp_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly_CF-1.8.nc
│-- pp_2011_2023_Daily_E_OBS.zip
```

## Troubleshooting

- **Permission Issues**:
  ```sh
  chmod +x run_pressure.sh
  ```
  Ensure the script has execution permissions.

- **Missing Dependencies**:
  ```sh
  pip install -r requirements.txt
  ```
  Install any missing Python packages.

- **Download Failures**:
  Check network connectivity and ensure your CDSAPI key is correctly configured in `~/.cdsapirc`. Rerun the script.

- **Script Errors**:
  If the script fails, check the log file for detailed error messages.

## Logs
Logs for execution are stored in `logs/sea_level_pressure_processing.log`. Review this file for debugging if errors occur.
```
