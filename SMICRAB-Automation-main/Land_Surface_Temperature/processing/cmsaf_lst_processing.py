#!/usr/bin/env python3
import os
import glob
import numpy as np
import xarray as xr
from scipy.ndimage import distance_transform_edt, zoom


# Constants
LON_MIN, LON_MAX = 6, 20
LAT_MIN, LAT_MAX = 32, 49
NEW_RESOLUTION_LAT = 0.1
NEW_RESOLUTION_LON = 0.1

DATA_DIR = "./data/CMSAF_LST_daily"
SUBSET_DIR = "./data/CMSAF_LST_daily_subset"
OUTPUT_DIR = "./data/CMSAF_Monthly_Per_Hour"
OUTPUT_FILE = "LST_IT_2011_2020_agg_monthly_per_hour.nc"
LAND_MASKS = "./processing/land_mask.npy"
VARS_TO_KEEP = ['time', 'lon', 'lat', 'LST_PMW', 'LSTERROR_PMW']


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
    # print(f"Subsetted file created: {subset_filepath}")

    return ds_subset

def hybrid_interpolate(ds):
    """
    Perform your original two-step interpolation:
      1) Bilinear (slinear) interpolation.
      2) Fill boundaries with nearest-neighbor.
    The new grid is built explicitly from LAT_MIN, LAT_MAX, LON_MIN, and LON_MAX.
    """
    var_name = "LST_PMW"
    # Create a new grid using your fixed domain
    new_lat = np.round(np.arange(LAT_MIN, LAT_MAX + NEW_RESOLUTION_LAT, NEW_RESOLUTION_LAT), 1)
    new_lon = np.round(np.arange(LON_MIN, LON_MAX + NEW_RESOLUTION_LON, NEW_RESOLUTION_LON), 1)

    ds_bilinear = ds.interp(lat=new_lat, lon=new_lon, method="slinear")
    still_missing = np.isnan(ds_bilinear[var_name])
    ds_nearest = ds.interp(lat=new_lat, lon=new_lon, method="nearest")
    ds_filled = ds_bilinear.fillna(ds_nearest)
    result = ds_bilinear.copy()
    result[var_name] = ds_bilinear[var_name].where(~still_missing, ds_filled[var_name])
    return result

def fill_missing_on_land_only(ds):
    """
    Loads the land mask (land_mask.npy), inverts its binary values so that
    1 = land and 0 = sea, and then fills NaNs ONLY where the mask equals 1.
    Sea pixels remain untouched.
    """
    try:
        land_mask = np.load(LAND_MASKS)
    except Exception as e:
        print("Could not load land_mask.npy; skipping fill:", e)
        return ds

    # Invert the mask values (if your file is reversed)
    land_mask = 1 - land_mask

    # Resize the land mask if necessary.
    nlat = ds.sizes['lat']
    nlon = ds.sizes['lon']
    if land_mask.shape != (nlat, nlon):
        print("Resizing land_mask from", land_mask.shape, "to", (nlat, nlon))
        scale_lat = nlat / land_mask.shape[0]
        scale_lon = nlon / land_mask.shape[1]
        # Use nearest-neighbor interpolation (order=0) for binary data.
        land_mask = zoom(land_mask, (scale_lat, scale_lon), order=0)

    def fill_missing_land(array2d):
        # Missing values on land are where NaN and mask==1.
        missing_land = np.isnan(array2d) & (land_mask == 1)
        valid_land   = (~np.isnan(array2d)) & (land_mask == 1)
        if not missing_land.any() or not valid_land.any():
            return array2d
        # Compute nearest valid land cell indices using distance transform.
        inds = distance_transform_edt(~valid_land, return_distances=False, return_indices=True)
        filled = array2d.copy()
        filled[missing_land] = array2d[inds[0][missing_land], inds[1][missing_land]]
        return filled

    # For each data variable (excluding coordinates) fill only land NaNs.
    for var in ds.data_vars:
        if var in ['lat', 'lon']:
            continue
        da = ds[var]
        if 'time' in da.dims:
            filled_slices = []
            for t in range(len(da.time)):
                slice_2d = da.isel(time=t).values
                slice_filled = fill_missing_land(slice_2d)
                filled_slices.append(
                    xr.DataArray(slice_filled,
                                 dims=['lat', 'lon'],
                                 coords={'lat': da['lat'].values, 'lon': da['lon'].values})
                )
            ds[var] = xr.concat(filled_slices, dim='time').assign_coords(time=da.time.values)
        else:
            ds[var].data = fill_missing_land(da.values)
    return ds


def process_file(input_file):
    """Opens, subsets, and interpolates a NetCDF file."""
    print(f"Processing file: {input_file}")
    try:
        ds = xr.open_dataset(os.path.join(DATA_DIR, input_file))
        ds_subset = subset_dataset(ds, input_file)
        ds_interpolated = hybrid_interpolate(ds_subset)
        ds_filled = fill_missing_on_land_only(ds_interpolated)
        ds.close()
        return ds_filled
    except Exception as e:
        print(f"Error processing {input_file}: {e}")
        if 'ds' in locals():
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