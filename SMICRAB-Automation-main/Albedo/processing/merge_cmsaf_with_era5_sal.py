#!/usr/bin/env python3
import os
import numpy as np
import xarray as xr
import pandas as pd

# File paths
CMSAF_FILE = "./data/CMSAF_SAL_Monthly/SAL_IT_2011_2023_Monthly_CMSAF.nc"
ERA5_FILE = "./data/ERA5_SAL_Monthly/SAL_IT_2011_2023_Monthly_ERA5.nc"
OUTPUT_DIR = "./data/SAL_Monthly_2011-2023"
OUTPUT_FILE = "SAL_IT_2011-2023_Monthly_CMSAF_ERA5.nc"


def merge_albedo_datasets(cmsaf_file, era5land_file, output_file):
    """
    Merges CMSAF albedo data with ERA5-Land forecast albedo (variable "fal")
    without CF compliance processing.
    """
    # --- 1. Load datasets ---
    print(f"Loading CMSAF albedo data from: {cmsaf_file}")
    ds_cmsaf = xr.open_dataset(cmsaf_file)

    print(f"Loading ERA5-Land albedo data from: {era5land_file}")
    ds_era5land = xr.open_dataset(era5land_file)

    # --- 2. Process ERA5-Land data ---
    ds_era5land = ds_era5land.rename({'valid_time': 'time', 'longitude': 'lon', 'latitude': 'lat'})

    # --- 3. Process CMSAF albedo ---
    # Convert percent (0-100) to 0-1 scale
    albedo_vars = [var for var in ds_cmsaf.data_vars if 'albedo' in var]
    for var_name in albedo_vars:
        ds_cmsaf[var_name] = ds_cmsaf[var_name] / 100.0

    # --- 4. Spatial alignment ---
    ds_era5land = ds_era5land.interp(
        lon=ds_cmsaf.lon,
        lat=ds_cmsaf.lat,
        method='linear'
    )

    # --- 5. Time synchronization ---
    ds_cmsaf['time'] = pd.to_datetime(ds_cmsaf.time.values)
    ds_era5land['time'] = pd.to_datetime(ds_era5land.time.values)

    # Find common time range
    time_min = max(ds_cmsaf.time.min(), ds_era5land.time.min())
    time_max = min(ds_cmsaf.time.max(), ds_era5land.time.max())

    ds_cmsaf = ds_cmsaf.sel(time=slice(time_min, time_max))
    ds_era5land = ds_era5land.sel(time=slice(time_min, time_max))

    # --- 6. Merge datasets ---
    ds_merged = ds_cmsaf.copy()
    era5_albedo = ds_era5land['fal'].rename('era5land_albedo')

    for var_name in albedo_vars:
        # Merge data
        merged_data = ds_cmsaf[var_name].fillna(era5_albedo)
        ds_merged[var_name] = merged_data

    # --- 7. Cleanup ---
    # Remove unnecessary variables
    ds_merged = ds_merged.drop_vars(['expver', 'number'], errors='ignore')

    # --- 8. Save merged dataset ---
    print(f"Saving merged dataset to: {output_file}")
    encoding = {
        var: {'zlib': True, 'complevel': 6} for var in ds_merged.data_vars
    }
    ds_merged.to_netcdf(output_file, encoding=encoding)
    print("Merging complete.")


if __name__ == "__main__":
    if not os.path.exists(CMSAF_FILE):
        print(f"Error: CMSAF file not found: {CMSAF_FILE}")
    elif not os.path.exists(ERA5_FILE):
        print(f"Error: ERA5-Land file not found: {ERA5_FILE}")
    else:
        os.makedirs(OUTPUT_DIR, exist_ok=True)
        output_file = os.path.join(OUTPUT_DIR, OUTPUT_FILE)
        merge_albedo_datasets(CMSAF_FILE, ERA5_FILE, output_file)