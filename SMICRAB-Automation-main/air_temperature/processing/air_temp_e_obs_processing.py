#!/usr/bin/env python3
import os
import glob
import numpy as np
import xarray as xr
import pandas as pd
import  warnings

# Constants
LON_MIN, LON_MAX = 6, 20
LAT_MIN, LAT_MAX = 32, 49
NEW_RESOLUTION_LAT = 0.1
NEW_RESOLUTION_LON = 0.1
DATA_DIR = "./data/E_OBS_air_temp_Daily"  # Input data directory
SUBSET_DIR = "./data/E_OBS_air_temp_Daily_subset"  # Directory for subsetted files
OUTPUT_DIR = "./data/E_OBS_air_temp_Monthly"  # Directory for aggregated monthly files


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


def get_temp_var_from_filename(filename):
    """Extracts temperature variable from filename (tg, tn, or tx)."""
    basename = os.path.basename(filename)
    return basename.split('_')[0]  # Filename format: tg_ens_mean_0.1deg_reg_2011-2023_v29.0e.nc


def subset_dataset(ds, input_file, temp_var):
    """Subsets the dataset to Italy region."""
    print(f"  Subsetting {temp_var} to Italy region...")
    lats = ds['latitude'].values
    lons = ds['longitude'].values

    lat_start = find_nearest_index(lats, LAT_MIN)
    lat_end = find_nearest_index(lats, LAT_MAX)
    lon_start = find_nearest_index(lons, LON_MIN)
    lon_end = find_nearest_index(lons, LON_MAX)

    lat_start, lat_end = min(lat_start, lat_end), max(lat_start, lat_end)
    lon_start, lon_end = min(lon_start, lon_end), max(lon_start, lon_end)

    vars_to_keep = ['time', 'longitude', 'latitude', temp_var]
    ds_subset = ds.isel(latitude=slice(lat_start, lat_end + 1),
                        longitude=slice(lon_start, lon_end + 1))
    ds_subset = ds_subset[vars_to_keep]

    subset_filename = os.path.basename(input_file).replace(".nc", "_subset.nc")
    subset_filepath = os.path.join(SUBSET_DIR, subset_filename)
    ds_subset.to_netcdf(subset_filepath)
    print(f"  Saved subset to {subset_filepath}")
    return ds_subset


def interpolate_dataset(ds, input_file, temp_var):
    """Interpolates the dataset to the new lat/lon grid."""
    print(f"  Interpolating {temp_var} to 0.1 grid...")
    new_lat = np.round(np.arange(ds.latitude.min(), ds.latitude.max(), NEW_RESOLUTION_LAT), 1)
    new_lon = np.round(np.arange(ds.longitude.min(), ds.longitude.max(), NEW_RESOLUTION_LON), 1)
    ds_regrid = ds.interp(latitude=new_lat, longitude=new_lon, method="linear")
    return ds_regrid


def aggregate_to_monthly(ds, temp_var):
    """Aggregates daily data to monthly."""
    print(f"  Aggregating {temp_var} to monthly...")
    with warnings.catch_warnings():
        warnings.simplefilter("ignore", category=RuntimeWarning)
        monthly_mean = ds[temp_var].resample(time="MS").mean(skipna=True)
        monthly_std = ds[temp_var].resample(time="MS").std(skipna=True)

        var_name = get_correct_var_name(temp_var)

        aggregated_ds = xr.Dataset({
            f'{var_name}': monthly_mean,
            f'{var_name}_std': monthly_std
        })
        return aggregated_ds

def get_correct_var_name(temp_var):
    if temp_var == "tg":
        return "mean_air_temperature"
    elif temp_var == "tn":
        return "minimum_air_temperature"
    elif temp_var == "tx":
        return "maximum_air_temperature"
    return "mean_air_temperature"


def convert_to_kelvin(ds, temp_var):
    ds[temp_var] = ds[temp_var] + 273.15
    ds[temp_var].attrs['units'] = 'Kelvin'
    return ds


def process_file(input_file):
    """Processes a single file through all steps."""
    temp_var = get_temp_var_from_filename(input_file)
    print(f"\nProcessing {temp_var} from {input_file}...")

    try:
        output_filename = os.path.basename(input_file).replace(".nc", "_monthly.nc")
        output_file = os.path.join(OUTPUT_DIR, output_filename)

        ds = xr.open_dataset(os.path.join(DATA_DIR, input_file))
        ds_subset = subset_dataset(ds, input_file, temp_var)
        ds_kelvin = convert_to_kelvin(ds_subset, temp_var)

        # ds_interp = interpolate_dataset(ds_subset, input_file, temp_var)
        ds_aggregated = aggregate_to_monthly(ds_kelvin, temp_var)

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

    print("\n=== Aggregation complete for all temperature files ===")


if __name__ == "__main__":
    main()