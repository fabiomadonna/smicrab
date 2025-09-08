#!/usr/bin/env python3
import os
import xarray as xr

# Constants
INPUT_DIR = "./data/E_OBS_air_temp_Monthly"
OUTPUT_DIR = "./data/E_OBS_air_temp_Monthly"

LON_MIN = 6
LAT_MIN = 32

# File patterns
FILES_TO_PROCESS = {
    "mean_air_temperature": "tg_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly.nc",
    "minimum_air_temperature": "tn_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly.nc",
    "maximum_air_temperature": "tx_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly.nc"
}

def fix_shift_coords(ds):
    lon0 = float(ds["longitude"].min())  # e.g. 32.04986
    lat0 = float(ds["latitude"].min())  # e.g. 32.04986
    lon_shift = lon0 - LON_MIN
    lat_shift = lat0 - LAT_MIN

    ds = ds.assign_coords(longitude=ds.longitude - lon_shift)
    ds = ds.assign_coords(latitude=ds.latitude - lat_shift)
    ds = ds.interp(
        longitude=ds.longitude,
        latitude= ds.latitude,
        method='nearest'
    )
    return ds

def make_cf_compliant(ds, var_name):
    """
    Fix attributes of the aggregated dataset to ensure CF-1.8 compliance.
    """
    print(f"  Fixing {var_name} dataset attributes for CF-1.8 compliance...")

    # Update temperature variables
    var_name = f"{var_name}"
    if var_name in ds.data_vars:
        ds[var_name].attrs["standard_name"] = var_name

        if var_name == "mean_air_temperature":
            ds[var_name].attrs["long_name"] = "Monthly mean of daily mean air temperature measured near the surface, usually at 2 metres above the surface"
        elif var_name == "minimum_air_temperature":
            ds[var_name].attrs["long_name"] = "Monthly mean of daily minimum air temperature measured near the surface, usually at 2 metres above the surface"
        elif var_name == "maximum_air_temperature":
            ds[var_name].attrs["long_name"] = "Monthly mean of daily maximum air temperature measured near the surface, usually at 2 metres above the surface"
        ds[var_name].attrs["units"] = "degree_Celsius"
        ds[var_name].attrs["cell_methods"] = "time: mean"

    std_var_name = f"{var_name}_std"
    if std_var_name in ds.data_vars:
        ds[std_var_name].attrs["standard_name"] = f"{var_name}_std"
        if var_name == "mean_air_temperature":
            ds[std_var_name].attrs["long_name"] = "Monthly Standard Deviation of Mean Air Temperature"
        elif var_name == "minimum_air_temperature":
            ds[std_var_name].attrs["long_name"] = "Monthly Standard Deviation of Minimum Air Temperature"
        elif var_name == "maximum_air_temperature":
            ds[std_var_name].attrs["long_name"] = "Monthly Standard Deviation of Maximum Air Temperature"
        ds[std_var_name].attrs["units"] = "degree_Celsius"
        ds[std_var_name].attrs["cell_methods"] = "time: std"


    # Ensure coordinate variables have appropriate attributes
    for coord in ["latitude", "longitude", "time"]:
        if coord in ds.variables:
            if coord == "latitude":
                ds[coord].attrs.setdefault("standard_name", "latitude")
                ds[coord].attrs.setdefault("long_name", "Latitude")
                ds[coord].attrs.setdefault("units", "degrees_north")
                ds[coord].attrs.setdefault("axis", "Y")
            elif coord == "longitude":
                ds[coord].attrs.setdefault("standard_name", "longitude")
                ds[coord].attrs.setdefault("long_name", "Longitude")
                ds[coord].attrs.setdefault("units", "degrees_east")
                ds[coord].attrs.setdefault("axis", "X")
            elif coord == "time":
                ds[coord].attrs.setdefault("standard_name", "time")
                ds[coord].attrs.setdefault("long_name", "time")

    # Update global attributes
    ds.attrs["Conventions"] = "CF-1.8"
    ds.attrs.setdefault("title", f"Monthly Aggregated Ensemble Mean {var_name.upper()} Air Temperature")
    ds.attrs.setdefault("institution", "Your Institution")
    ds.attrs.setdefault("source", "E-OBS")
    ds.attrs.setdefault("history",
                        "Processed to subset, regrid, change time units, and aggregate to monthly data, made CF-compliant")
    ds.attrs.setdefault("comment", "2m air temperature at height of 2m above surface")

    return ds


def process_file(var_name, input_file, output_file):
    """Process a single file to make it CF-compliant"""
    print(f"\nProcessing {var_name} for CF compliance: {input_file}...")
    ds = xr.open_dataset(input_file)

    try:
        shifted_ds = fix_shift_coords(ds)
        ds_cf = make_cf_compliant(shifted_ds, var_name)
        encoding = {
            "time": {"dtype": "float64"},
            f"{var_name}": {"dtype": "float32", "zlib": True, "complevel": 4},
            f"{var_name}_std": {"dtype": "float32", "zlib": True,
                                        "complevel": 4} if f"{var_name}_std" in ds.variables else None
        }

        ds_cf.to_netcdf(output_file, encoding={k: v for k, v in encoding.items() if v is not None})
        print(f"  Saved CF-compliant file to {output_file}")
    except Exception as e:
        print(f"Error processing {input_file} for CF compliance: {str(e)}")
        raise
    finally:
        ds.close()


def main():
    """Main function for making monthly files CF-compliant"""
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    for var_name, input_file in FILES_TO_PROCESS.items():
        input_path = os.path.join(INPUT_DIR, input_file)
        output_path = os.path.join(OUTPUT_DIR, input_file.replace(".nc", "_CF-1.8.nc"))

        if os.path.exists(input_path):
            process_file(var_name, input_path, output_path)
        else:
            print(f"Warning: Input file not found: {input_path}")


if __name__ == "__main__":
    main()