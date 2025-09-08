# Air Temperature Processing Guide

## Overview
This module automates the downloading, extraction, processing, and homogenization of air temperature data from different sources. The workflow is driven by a shell script (`run_air_temperature.sh`) that automates the process using Python scripts.

## Directory Structure
```
air_temperature/
│-- data/                         # Stores downloaded and processed datasets
│-- logs/                         # Stores log files for debugging
│-- processing/                   # Contains Python scripts for data processing
│-- run_air_temperature.sh        # Main execution script
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
The script provides options to skip specific steps, allowing for flexible execution.

### Usage:
```sh
bash run_air_temperature.sh [OPTIONS]
```

### Options:
- `--skip-eobs-download` : Skip the Air_Temperature (E‑OBS) dataset download step.
- `--skip-era5-download` : Skip the ERA5 dataset download step.
- `--skip-unzip` : Skip the extraction of the E-OBS zip file.
- `--generate-csv` : Generate CSV files from processed data
- `-h, --help` : Show help message.

### Example:
Run the script without skipping any steps:
```sh
bash run_air_temperature.sh
```

Skip downloading the E-OBS dataset:
```sh
bash run_air_temperature.sh --skip-eobs-download
```

## Processing Steps

### 1. CDSAPI Configuration Check
The script checks for the `~/.cdsapirc` file, required for downloading climate data. If missing, it attempts to generate it using `generate_cdsapirc.sh` script located in the `common/scripts/` directory relative to the project root.

### 2. Download ERA5 Dataset
- Downloads ERA5 monthly averaged reanalysis 2m temperature data.
- Uses `2m_temp_era5_download.py` to fetch and store the dataset.

### 3. Download Air Temperature (E‑OBS) Dataset
- Downloads daily mean, minimum, and maximum temperature data from the E‑OBS dataset.
- Uses `air_temp_e_obs_download.py` to retrieve data and save it in ZIP format.

### 4. Extract E‑OBS Dataset
- Unzips the downloaded file into the `data/` directory.

### 5. Aggregate E‑OBS Data
- Processes the extracted daily data into a monthly format.
- Uses `air_temp_e_obs_processing.py` for subsetting, interpolation, and aggregation.

### 6. Make E-OBS Data CF-Compliant
- Converts the aggregated E-OBS monthly data to be CF-1.8 compliant.
- Uses `air_temp_make_cf_compliant.py` and saves the CF-compliant files.

### 7. Homogenization of Mean Air Temperature (tg)
- Applies homogenization to the monthly mean air temperature dataset that is CF-1.8 compliant.
- Uses `tg_homogenization.py` to generate a corrected dataset.

### 8. Homogenization of Minimum Air Temperature (tn)
- Applies homogenization to the monthly minimum air temperature dataset that is CF-1.8 compliant.
- Uses `tn_homogenization.py` to generate a corrected dataset.

### 9. Homogenization of Maximum Air Temperature (tx)
- Applies homogenization to the monthly maximum air temperature dataset that is CF-1.8 compliant.
- Uses `tx_homogenization.py` to generate a corrected dataset.

### 10. CSV Generation (Optional)
- Generates CSV versions of processed data files when `--generate-csv` flag is used

## Output Files
After successful execution, the following key output files will be generated:
```
data/
│-- E_OBS_air_temp_Daily/
│   │-- ... (daily E-OBS netCDF files)
│-- E_OBS_air_temp_Daily_subset/
│   │-- tg_ens_mean_0.1deg_reg_2011-2023_v29.0e_subset.nc
│   │-- tn_ens_mean_0.1deg_reg_2011-2023_v29.0e_subset.nc
│   │-- tx_ens_mean_0.1deg_reg_2011-2023_v29.0e_subset.nc
│-- E_OBS_air_temp_Monthly/
│   │-- tg_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly.nc
│   │-- tn_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly.nc
│   │-- tx_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly.nc
│   │-- tg_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly_CF-1.8.nc
│   │-- tn_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly_CF-1.8.nc
│   │-- tx_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly_CF-1.8.nc
│-- ERA5_air_temp_Monthly/
│   │-- air_temp_IT_2011_2023_Monthly_ERA5.nc
│-- air_temp_IT_2011_2023_Monthly/
│   │-- tg_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly_CF-1.8_corrected.nc  # Homogenized Mean Air Temperature
│   │-- tn_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly_CF-1.8_corrected.nc  # Homogenized Minimum Air Temperature
│   │-- tx_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly_CF-1.8_corrected.nc  # Homogenized Maximum Air Temperature
│-- air_temp_2011_2023_Daily_E_OBS.zip
```

## Troubleshooting

- **Permission Issues**:
  ```sh
  chmod +x run_air_temperature.sh
  ```
  If you encounter permission denied errors, ensure the script has execute permissions.

- **Missing Dependencies**:
  ```sh
  pip install -r requirements.txt
  ```
  Install any missing Python packages reported during script execution.

- **Download Failures**:
  Check your internet connection and verify your CDSAPI configuration (`~/.cdsapirc`) if downloads from CDS fail. Rerun the script to attempt download again.

## Logs
Execution logs are stored in `logs/air_temperature_processing.log`. Review this file for detailed information about each processing step and for debugging any issues.
```