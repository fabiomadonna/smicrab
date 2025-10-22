#!/usr/bin/env python3
import os
import glob
import numpy as np
import xarray as xr
import pandas as pd
import warnings

# Constants
LON_MIN, LON_MAX = 6, 20
LAT_MIN, LAT_MAX = 32, 49
NEW_RESOLUTION_LAT = 0.1
NEW_RESOLUTION_LON = 0.1
DATA_DIR = "./data/E_OBS_hu_Daily"  # Input data directory
SUBSET_DIR = "./data/E_OBS_hu_Daily_subset"  # Directory for subsetted files
OUTPUT_DIR = "./data/E_OBS_hu_Monthly"  # Directory for aggregated monthly files
VARS_TO_KEEP = ['time', 'longitude', 'latitude', 'hu']  # Variables to retain (using 'hu')

def convert_time_units(ds):
    """
    Convert time units from 'days since 1950-01-01' to 'seconds since 1970-01-01' and ensure DatetimeIndex
    """
    print("  Converting time units to seconds since 1970-01-01 and to DatetimeIndex...")
    # Get the current time values and units
    time_var = ds['time']

    # Convert the time values to datetime objects using xarray's functionality
    time_dt = pd.to_datetime(time_var.values)

    # Calculate seconds since 1970-01-01
    epoch = pd.Timestamp('1970-01-01')
    seconds_since_epoch = [(dt - epoch).total_seconds() for dt in time_dt]

    # Create a new time coordinate with the new units
    ds = ds.assign_coords(time=('time', seconds_since_epoch))

    # Update the time attributes
    ds['time'].attrs['standard_name'] = 'time'
    ds['time'].attrs['long_name'] = 'time'
    ds['time'].attrs['units'] = 'seconds since 1970-01-01 00:00:00'
    ds['time'].attrs['calendar'] = 'proleptic_gregorian'

    return ds

def find_nearest_index(coord_array, value):
    """Finds the index of the element in coord_array closest to value."""
    return int(np.abs(coord_array - value).argmin())

def subset_dataset(ds, input_file):
    """Subsets the dataset to Italy region."""
    print("  Subsetting to Italy region...")
    lats = ds['latitude'].values
    lons = ds['longitude'].values
    lat_start = find_nearest_index(lats, LAT_MIN)
    lat_end = find_nearest_index(lats, LAT_MAX)
    lon_start = find_nearest_index(lons, LON_MIN)
    lon_end = find_nearest_index(lons, LON_MAX)
    lat_start, lat_end = min(lat_start, lat_end), max(lat_start, lat_end)
    lon_start, lon_end = min(lon_start, lon_end), max(lon_start, lon_end)
    ds_subset = ds.isel(latitude=slice(lat_start, lat_end + 1),
                        longitude=slice(lon_start, lon_end + 1))
    ds_subset = ds_subset[VARS_TO_KEEP]
    subset_filename = os.path.basename(input_file).replace(".nc", "_subset.nc")
    subset_filepath = os.path.join(SUBSET_DIR, subset_filename)
    ds_subset.to_netcdf(subset_filepath)
    print(f"  Saved subset to {subset_filepath}")
    return ds_subset

def interpolate_dataset(ds, input_file):
    """Interpolates the dataset to the new lat/lon grid."""
    print("  Interpolating to 0.1 grid...")
    new_lat = np.round(np.arange(ds.latitude.min(), ds.latitude.max(), NEW_RESOLUTION_LAT), 1)
    new_lon = np.round(np.arange(ds.longitude.min(), ds.longitude.max(), NEW_RESOLUTION_LON), 1)
    ds_regrid = ds.interp(latitude=new_lat, longitude=new_lon, method="linear")
    # ds_regrid = ds_regrid.interp(latitude=new_lat, longitude=new_lon, method="nearest")
    return ds_regrid

def aggregate_to_monthly(ds):
    """Aggregates daily data to monthly."""
    print("  Aggregating to monthly...")
    with warnings.catch_warnings():
        warnings.simplefilter("ignore", category=RuntimeWarning)
        monthly_mean = ds['hu'].resample(time="MS").mean(skipna=True)
        monthly_std = ds['hu'].resample(time="MS").std(skipna=True)
        aggregated_ds = xr.Dataset({
            'mean_relative_humidity': monthly_mean,
            'std_relative_humidity': monthly_std
        })
        return aggregated_ds

def process_file(input_file):
    """Processes a single file through all steps."""
    print(f"\nProcessing {input_file}...")
    try:
        output_filename = os.path.basename(input_file).replace(".nc", "_monthly.nc")
        output_file = os.path.join(OUTPUT_DIR, output_filename)

        ds = xr.open_dataset(os.path.join(DATA_DIR, input_file))

        ds_subset = subset_dataset(ds, input_file)
        # ds_interp = interpolate_dataset(ds_subset, input_file)
        ds_aggregated = aggregate_to_monthly(ds_subset)

        converted_ds = convert_time_units(ds_aggregated)
        converted_ds.to_netcdf(output_file)

        print(f"  Saved monthly data to {output_file}")

        return converted_ds
    except Exception as e:
        print(f"Error processing {input_file}: {str(e)}")
        return None

def main():
    """Main processing function."""
    os.makedirs(SUBSET_DIR, exist_ok=True)
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    input_files = glob.glob(os.path.join(DATA_DIR, "*.nc"))
    for input_file in input_files:
        input_file = os.path.basename(input_file)
        aggregated_ds = process_file(input_file)
        if aggregated_ds is not None:
            aggregated_ds.close()
    print("\n=== Aggregation complete ===")

if __name__ == "__main__":
    main()