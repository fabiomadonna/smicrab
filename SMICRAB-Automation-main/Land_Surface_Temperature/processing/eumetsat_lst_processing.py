import os
import glob
import numpy as np
import pandas as pd
import xarray as xr
from scipy.ndimage import distance_transform_edt, zoom

# Constants
LON_MIN, LON_MAX = 6, 20
LAT_MIN, LAT_MAX = 32, 49
NEW_RESOLUTION_LAT = 0.1
NEW_RESOLUTION_LON = 0.1

# DATA_DIR = "../data/_eumetsat"
DATA_DIR = "./data/EUMETSAT_LST_hourly"
SUBSET_HOURLY_DIR = "./data/EUMETSAT_LST_hourly_Subset"
OUTPUT_DIR = "./data/EUMETSAT_Monthly_Per_Hour"
OUTPUT_FILE = "LST_IT_2021_2023_agg_monthly_per_hour.nc"
LAND_MASKS = "./processing/land_mask.npy"
VARS_TO_KEEP = ['time', 'lon', 'lat', 'LST']


def find_nearest_index(coord_array, value):
    """Finds the index of the element in coord_array closest to value."""
    return int(np.abs(coord_array - value).argmin())

def subset_dataset(ds, input_file):
    """Subsets the dataset and saves the subset to SUBSET_HOURLY_DIR."""
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
    # Convert LST from Celsius to Kelvin
    ds_subset['LST'] = ds_subset['LST'] + 273.15
    ds_subset['LST'].attrs['units'] = 'K'
    ds_subset['LST'].attrs['long_name'] = 'Land Surface Temperature (LST)'

    subset_filename = os.path.basename(input_file).replace(".nc", "_subset.nc")
    subset_filepath = os.path.join(SUBSET_HOURLY_DIR, subset_filename)
    ds_subset.to_netcdf(subset_filepath)
    # print(f"Subset file created: {subset_filepath}")

    return ds_subset


def hybrid_interpolate(ds):
    """
    Perform your original two-step interpolation:
      1) Bilinear (slinear) interpolation.
      2) Fill boundaries with nearest-neighbor.
    The new grid is built explicitly from LAT_MIN, LAT_MAX, LON_MIN, and LON_MAX.
    """
    var_name = "LST"
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
        # print("Resizing land_mask from", land_mask.shape, "to", (nlat, nlon))
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
        ds = xr.open_dataset(os.path.join(DATA_DIR, input_file), engine="netcdf4")
        ds_subset = subset_dataset(ds, input_file)
        ds_interpolated = hybrid_interpolate(ds_subset)
        ds.close()
        return ds_interpolated
    except Exception as e:
        print(f"Error processing {input_file}: {e}")
        if 'ds' in locals():
            ds.close()
        return None

def main():
    os.makedirs(SUBSET_HOURLY_DIR, exist_ok=True)
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    interpolated_datasets = []
    for input_file in glob.glob(os.path.join(DATA_DIR, "*.nc")):
        input_file = os.path.basename(input_file)
        interpolated_ds = process_file(input_file)
        if interpolated_ds is not None:
            interpolated_datasets.append(interpolated_ds)

    if interpolated_datasets:
        try:
            # Concatenate along time and sort chronologically
            ds_concat = xr.concat(interpolated_datasets, dim='time')
            ds_concat = ds_concat.sortby('time')

            # -----------------------------------------------------------
            # Create a new time coordinate: For each timestamp, create a new datetime
            # with the same year and month, day fixed to 01, and the original hour (minute/second = 00)
            # This new time coordinate represents the monthly mean for that hour.
            # -----------------------------------------------------------
            time_index = pd.to_datetime(ds_concat.time.values)
            new_times = [np.datetime64(pd.Timestamp(t.year, t.month, 1, t.hour, 0, 0))
                         for t in time_index]
            ds_concat = ds_concat.assign_coords(new_time=("time", new_times))

            # Group by the new time coordinate and compute the mean over the original time dimension.
            ds_agg = ds_concat.groupby("new_time").mean("time", skipna=True).rename({"new_time": "time"})
            ds_agg = ds_agg.sortby("time")

            # Fill missing on land only
            ds_filled = fill_missing_on_land_only(ds_agg)

            # -----------------------------------------------------------
            # Optional: Rebase the time coordinate to "seconds since 1970-01-01" if required
            # -----------------------------------------------------------
            original_times = ds_filled['time'].values.astype('datetime64[s]')
            reference_time = np.datetime64('1970-01-01T00:00:00')
            time_seconds = (original_times - reference_time).astype('float64')
            ds_filled['time'] = ('time', time_seconds)
            ds_filled['time'].attrs.update({
                'units': 'seconds since 1970-01-01 00:00:00',
                'calendar': 'standard'
            })


            # Save the aggregated dataset
            output_filepath = os.path.join(OUTPUT_DIR, OUTPUT_FILE)
            ds_filled.to_netcdf(output_filepath)
            ds_filled.close()

            print(f"Monthly per hour aggregated file created: {output_filepath}")
        except Exception as e:
            print(f"Error aggregating and saving: {e}")
        finally:
            for ds in interpolated_datasets:
                ds.close()
    else:
        print("No files to concatenate found.")

if __name__ == "__main__":
    main()
