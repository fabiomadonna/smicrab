import os
import xarray as xr
import numpy as np
from datetime import datetime, timezone

CMSAF_FILE = "./data/CMSAF_Monthly_Per_Hour/LST_IT_2011_2020_agg_monthly_per_hour.nc"
EUMETSAT_FILE = "./data/EUMETSAT_Monthly_Per_Hour/LST_IT_2021_2023_agg_monthly_per_hour.nc"
MERGED_DIR = "./data/LST_Monthly_Per_Hour_2011-2023"
OUTPUT_FILE = "LST_IT_2011_2023_agg_Monthly_per_hour.nc"

def merge_lst_datasets(file1, file2, output_path):
    """
    Merge two LST datasets on 0.1°×0.1° grid
    """
    current_time = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    # Open datasets with CF decoding
    ds1 = xr.open_dataset(file1, decode_cf=True, engine='netcdf4')
    ds2 = xr.open_dataset(file2, decode_cf=True, engine='netcdf4')

    # Standardize variable names if necessary
    if 'LST_PMW' in ds1:
        ds1 = ds1.rename({'LST_PMW': 'LST'})

    # Ensure units are in Kelvin (convert from Celsius if needed)
    for ds in [ds1, ds2]:
        if ds['LST'].attrs.get('units', 'K').lower() in ['°c', 'c']:
            ds['LST'] = ds['LST'] + 273.15
            ds['LST'].attrs['units'] = 'K'

    # Handle coordinate differences with interpolation if needed
    if not np.allclose(ds1.lat.values, ds2.lat.values, atol=1e-4):
        print("Interpolating to match latitude coordinates...")
        ds1 = ds1.interp(lat=ds2.lat, method='nearest')

    if not np.allclose(ds1.lon.values, ds2.lon.values, atol=1e-4):
        print("Interpolating to match longitude coordinates...")
        ds1 = ds1.interp(lon=ds2.lon, method='nearest')

    # Combine datasets along the time dimension and sort by time
    combined = xr.concat([ds1, ds2], dim='time').sortby('time')

    # Keep only essential variables
    combined = combined[['time', 'lat', 'lon', 'LST', 'LSTERROR_PMW']]

    # Option: Use actual global min and max from the merged data.
    global_min = float(combined['LST'].min().values)
    global_max = float(combined['LST'].max().values)
    combined['LST'].attrs['valid_min'] = global_min
    combined['LST'].attrs['valid_max'] = global_max

    # Create output directory if needed
    os.makedirs(os.path.dirname(output_path) or '.', exist_ok=True)

    # Save the merged dataset in NETCDF4 format
    combined.to_netcdf(output_path, format='NETCDF4')

    print(f"Successfully created merged file: {output_path}")
    print(f"Time coverage: {combined.time.min().values} to {combined.time.max().values}")
    print(f"Grid resolution: 0.1°×0.1°")
    print(f"Data dimensions: {combined.sizes}")
    print(f"Global LST range (K): {global_min} to {global_max}")

if __name__ == "__main__":
    input_file1 = CMSAF_FILE
    input_file2 = EUMETSAT_FILE
    output_file = os.path.join(MERGED_DIR, OUTPUT_FILE)

    merge_lst_datasets(input_file1, input_file2, output_file)
