#!/usr/bin/env python3
import os
import xarray as xr
import numpy as np
from datetime import datetime, timezone

# File paths
INPUT_FILE = "./data/SAL_Monthly_2011-2023/SAL_IT_2011-2023_Monthly_CMSAF_ERA5.nc"
OUTPUT_DIR = "./data/SAL_Monthly_2011-2023_CF_Compliant"
OUTPUT_FILE = "SAL_IT_2011-2023_Monthly_CMSAF_ERA5_CF-1.8.nc"

def make_cf_compliant(ds, time_var='time', lat_var='latitude', lon_var='longitude'):
    """
    Ensure dataset complies with CF-1.8 conventions
    """
    current_time = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    # Standardize time variable
    if time_var in ds:
        ds[time_var].encoding.update({
            'units': 'seconds since 1970-01-01 00:00:00',
            'calendar': 'proleptic_gregorian',
            'dtype': 'int64'
        })
    ds[time_var].attrs.update({
        'standard_name': 'time',
        'long_name': 'time',
        'axis': 'T',
        'description': 'Time of measurement'
    })


    # Standardize data variables (albedo)
    albedo_vars = [var for var in ds.data_vars if 'albedo' in var]
    for var_name in albedo_vars:
        ds[var_name].encoding.update({
            'zlib': True,
            'complevel': 5,
            'chunksizes': (1,) + ds[var_name].shape[1:],
            '_FillValue': np.nan,
            'dtype': 'float32'
        })
        ds[var_name].attrs.update({
            'standard_name': 'surface_albedo',
            'long_name': f'{var_name} (merged with ERA5-Land)',
            'units': '(0 - 1)',  # CF-compliant dimensionless units
            'valid_range': [0.0, 1.0],
            'coordinates': f'{time_var} {lat_var} {lon_var}',
            # 'grid_mapping': 'crs',
            'grid_resolution': '0.1 deg × 0.1 deg'
        })

    # Add CRS information
    # if 'crs' not in ds:
    #     ds['crs'] = xr.DataArray(
    #         attrs={
    #             'grid_mapping_name': 'latitude_longitude',
    #             'longitude_of_prime_meridian': 0.0,
    #             'semi_major_axis': 6378137.0,
    #             'inverse_flattening': 298.257223563,
    #             'epsg_code': 'EPSG:4326',
    #             'proj4text': '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs'
    #         }
    #     )



    # Extract lat values (as raw data)
    lat_vals = ds[lat_var].values

    # Rebuild lat as a new DataArray without any attributes or _FillValue
    lat_clean = xr.DataArray(
        data=lat_vals.astype(np.float32),
        dims=[lat_var],
        coords={lat_var: lat_vals},
        attrs={  # Only essential attributes
            "standard_name": "latitude",
            "long_name": "latitude",
            "units": "degrees_north",
            "axis": "Y",
        }
    )

    # Replace in the dataset
    ds[lat_var] = lat_clean

    # Explicitly remove any _FillValue during encoding
    ds[lat_var].encoding = {
        "dtype": "float32",
        "zlib": False,
        "coordinates": None
    }


    # Extract lon values (as raw data)
    lon_vals = ds[lon_var].values

    # Rebuild lon as a new DataArray without any attributes or _FillValue
    lon_clean = xr.DataArray(
        data=lon_vals.astype(np.float32),
        dims=[lon_var],
        coords={lon_var: lon_vals},
        attrs={  # Only essential attributes
            "standard_name": "longitude",
            "long_name": "longitude",
            "units": "degrees_east",
            "axis": "X",
        }
    )

    # Replace in the dataset
    ds[lon_var] = lon_clean

    # Explicitly remove any _FillValue during encoding
    ds[lon_var].encoding = {
        "dtype": "float32",
        "zlib": False,
        "coordinates": None
    }


    # Update global attributes
    ds.attrs.update({
        'Conventions': 'CF-1.8',
        'date_created': current_time,
        'geospatial_lat_min': float(ds[lat_var].min()),
        'geospatial_lat_max': float(ds[lat_var].max()),
        'geospatial_lon_min': float(ds[lon_var].min()),
        'geospatial_lon_max': float(ds[lon_var].max()),
        'geospatial_lat_units': 'degrees_north',
        'geospatial_lon_units': 'degrees_east',
        'geospatial_lat_resolution': '0.1 degree',
        'geospatial_lon_resolution': '0.1 degree',
        'spatial_resolution': '0.1 deg × 0.1 deg'
    })

    return ds

def process_to_cf_compliant(input_file, output_path):
    """
    Open dataset, make CF-1.8 compliant, and save
    """
    # Open dataset
    ds = xr.open_dataset(input_file, decode_cf=True)

    # Rename lat and lon
    ds = ds.rename({"lat": 'latitude', "lon": 'longitude'})

    # Make CF-1.8 compliant
    ds_cf = make_cf_compliant(ds)

    # Create output directory if needed
    os.makedirs(os.path.dirname(output_path) or '.', exist_ok=True)

    encoding = {var: {"zlib": True, "complevel": 4} for var in ds.data_vars}

    # Save CF-compliant dataset
    ds_cf.to_netcdf(output_path, encoding=encoding)

    print(f"Successfully created CF-1.8 compliant file: {output_path}")
    print(f"Time coverage: {ds_cf.time.min().values} to {ds_cf.time.max().values}")

if __name__ == "__main__":
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    output_file = os.path.join(OUTPUT_DIR, OUTPUT_FILE)
    process_to_cf_compliant(INPUT_FILE, output_file)