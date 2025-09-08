import os
import xarray as xr
import numpy as np
from datetime import datetime, timezone

INPUT_FILE = "./data/LST_Monthly_Per_Hour_2011-2023/LST_IT_2011_2023_agg_Monthly_per_hour.nc"
OUTPUT_DIR = "./data/LST_Monthly_Per_Hour_2011-2023"
OUTPUT_FILE = "LST_IT_2011_2023_agg_Monthly_per_hour_grid_0.1_CF-1.8.nc"

def make_cf_compliant(ds, time_var='time', lat_var='latitude', lon_var='longitude', data_var='LST', error_var="LSTERROR_PMW"):
    """
    Ensure dataset complies with CF-1.8 conventions for 0.1°×0.1° grid
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

    # Standardize data variable
    if data_var in ds:
        ds[data_var].encoding.update({
            'zlib': True,
            'complevel': 5,
            'chunksizes': (1,) + ds[data_var].shape[1:],
            '_FillValue': np.nan,
            'dtype': 'float32'
        })
    ds[data_var].attrs.update({
        'standard_name': 'surface_temperature',
        'long_name': 'Land Surface Temperature',
        'units': 'K',
        'coordinates': f'{time_var} {lat_var} {lon_var}',
        # 'grid_mapping': 'crs',
        'cell_methods': 'time: mean',
        'grid_resolution': '0.1 deg × 0.1 deg'
    })

    if error_var in ds:
        # ds[error_var] = ds[error_var] + 273.15
        ds[error_var].attrs.update({
            'standard_name': 'surface_temperature_uncertainty',
            'long_name': 'Land Surface Temperature Uncertainty PMW',
            'units': 'K',
            'coordinates': f'{time_var} {lat_var} {lon_var}',
            'cell_methods': 'time: mean',
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
    #             'proj4text': '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs',
    #             'geospatial_resolution': '0.1 degree'
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
    ds = xr.open_dataset(input_file)

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
    # print(f"Time coverage: {ds_cf.time.min().values} to {ds_cf.time.max().values}")

if __name__ == "__main__":
    output_file = os.path.join(OUTPUT_DIR, OUTPUT_FILE)
    process_to_cf_compliant(INPUT_FILE, output_file)