#!/usr/bin/env python3
import os
import glob
import numpy as np
import xarray as xr

# Constants
LON_MIN, LON_MAX = 6, 20
LAT_MIN, LAT_MAX = 32, 49
NEW_RESOLUTION_LAT = 0.1
NEW_RESOLUTION_LON = 0.1

DATA_DIR = "./data/CMSAF_SAL_daily"
SUBSET_DIR = "./data/CMSAF_SAL_daily_subset"
OUTPUT_DIR = "./data/CMSAF_SAL_Monthly"
OUTPUT_FILE = "SAL_IT_2011_2023_Monthly_CMSAF.nc"
VARS_TO_KEEP = ['time', 'lon', 'lat', 'black_sky_albedo_all_mean', 'black_sky_albedo_all_std']


def find_nearest_index(coord_array, value):
    """Finds the index of the element in coord_array closest to value."""
    return int(np.abs(coord_array - value).argmin())


def subset_dataset(ds, input_file):
    """Subsets the dataset and saves the subset to SUBSET_DIR."""
    lats = ds['lat'].values
    lons = ds['lon'].values

    lat_start = find_nearest_index(lats, LAT_MIN)
    lat_end = find_nearest_index(lats, LAT_MAX)
    lon_start = find_nearest_index(lons, LON_MIN)
    lon_end = find_nearest_index(lons, LON_MAX)

    lat_start, lat_end = min(lat_start, lat_end), max(lat_start, lat_end)
    lon_start, lon_end = min(lon_start, lon_end), max(lon_start, lon_end)

    ds_subset = ds.isel(lat=slice(lat_start, lat_end + 1),
                        lon=slice(lon_start, lon_end + 1))

    ds_subset = ds_subset[VARS_TO_KEEP]

    subset_filename = os.path.basename(input_file).replace(".nc", "_subset.nc")
    subset_filepath = os.path.join(SUBSET_DIR, subset_filename)
    ds_subset.to_netcdf(subset_filepath)
    print(f"Subset file created: {subset_filepath}")

    return ds_subset


def interpolate_dataset(ds):
    """Interpolates the dataset to the new lat/lon grid."""
    original_lat = ds['lat']
    original_lon = ds['lon']

    new_lat = np.round(np.arange(original_lat.min(), original_lat.max(), NEW_RESOLUTION_LAT), 1)
    new_lon = np.round(np.arange(original_lon.min(), original_lon.max(), NEW_RESOLUTION_LON), 1)

    ds_regrid = ds.interp(lat=new_lat, lon=new_lon, method="linear")
    return ds_regrid


def process_file(input_file):
    """Opens, subsets, and interpolates a NetCDF file."""
    print(f"Processing file: {input_file}")
    try:
        ds = xr.open_dataset(os.path.join(DATA_DIR, input_file))
        ds_subset = subset_dataset(ds, input_file)
        ds_regrid = interpolate_dataset(ds_subset)
        ds.close()  # Close the original dataset after subsetting
        return ds_regrid
    except Exception as e:
        print(f"Error processing {input_file}: {e}")
        if 'ds' in locals(): #Check if ds is defined before attempting to close
            ds.close()
        return None


def main():
    """Main processing function."""
    os.makedirs(SUBSET_DIR, exist_ok=True)
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    interpolated_datasets = []

    for input_file in glob.glob(os.path.join(DATA_DIR, "*.nc")):
        input_file = os.path.basename(input_file)
        interpolated_ds = process_file(input_file)
        if interpolated_ds is not None:
            interpolated_datasets.append(interpolated_ds)

    if interpolated_datasets:
        try:
            ds_concat = xr.concat(interpolated_datasets, dim='time')
            output_filepath = os.path.join(OUTPUT_DIR, OUTPUT_FILE)
            ds_concat.to_netcdf(output_filepath)
            ds_concat.close()

            print(f"Output file created: {output_filepath}")
            print(f"Output file size: {os.path.getsize(output_filepath)} bytes")
        except Exception as e:
            print(f"Error concatenating and saving: {e}")
        finally:  # Ensure datasets are closed even if concatenation fails
            for ds in interpolated_datasets:
                ds.close()
    else:
        print("No files to concatenate found or errors occurred during processing.")


if __name__ == "__main__":
    main()