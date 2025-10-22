#!/usr/bin/env python3
import os
import xarray as xr

# Constants
INPUT_FILE = "./data/E_OBS_qq_Monthly/qq_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly.nc"
OUTPUT_DIR = "./data/E_OBS_qq_Monthly"
OUTPUT_FILE = "qq_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly_CF-1.8.nc"

LON_MIN = 6
LAT_MIN = 32

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

def make_cf_compliant(ds):
    """
    Fix attributes of the aggregated dataset to ensure CF-1.8 compliance.
    This includes updating variable long names and global attributes.
    """
    print("  Fixing dataset attributes for CF-1.8 compliance...")

    # Update solar irradiance variables
    if "qq_monthly_mean" in ds.variables:
        ds["qq_monthly_mean"].attrs["standard_name"] = "surface_downwelling_shortwave_flux_in_air"
        ds["qq_monthly_mean"].attrs["long_name"] = "Monthly ensemble mean surface downwelling shortwave flux in air"
        ds["qq_monthly_mean"].attrs["units"] = "W/m2"
        ds["qq_monthly_mean"].attrs["cell_methods"] = "time: mean"
    if "qq_monthly_std" in ds.variables:
        ds["qq_monthly_std"].attrs["standard_name"] = "surface_downwelling_shortwave_flux_in_air"
        ds["qq_monthly_std"].attrs["long_name"] = "Monthly ensemble surface downwelling shortwave flux in air standard deviation"
        ds["qq_monthly_std"].attrs["units"] = "W/m2"
        ds["qq_monthly_std"].attrs["cell_methods"] = "time: std"

    # Ensure coordinate variables have appropriate attributes
    if "latitude" in ds.variables:
        ds["latitude"].attrs.setdefault("standard_name", "latitude")
        ds["latitude"].attrs.setdefault("long_name", "Latitude")
        ds["latitude"].attrs.setdefault("units", "degrees_north")
        ds["latitude"].attrs.setdefault("axis", "Y")
    if "longitude" in ds.variables:
        ds["longitude"].attrs.setdefault("standard_name", "longitude")
        ds["longitude"].attrs.setdefault("long_name", "Longitude")
        ds["longitude"].attrs.setdefault("units", "degrees_east")
        ds["longitude"].attrs.setdefault("axis", "X")

    # Update or add global attributes for CF compliance
    ds.attrs["Conventions"] = "CF-1.8"
    ds.attrs.setdefault("title", "Monthly Aggregated Ensemble Mean Surface Downwelling Shortwave Flux in Air") # More descriptive title
    ds.attrs.setdefault("institution", "Your Institution")
    ds.attrs.setdefault("source", "E-OBS")
    ds.attrs.setdefault("history",
                        "Processed to subset, regrid, change time units, and aggregate to monthly data, made CF-compliant")
    ds.attrs.setdefault("comment", "Surface downwelling shortwave radiation")

    return ds


def main():
    """Main function for making monthly files CF-compliant."""
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    ds = xr.open_dataset(INPUT_FILE)

    print(f"\nProcessing for CF compliance: {INPUT_FILE}...")

    try:
        shifted_ds = fix_shift_coords(ds)
        ds_cf_compliant = make_cf_compliant(shifted_ds)

        encoding = {
            "time": {"dtype": "float64"},  # Keep time encoding consistent
            "qq_monthly_mean": {"dtype": "float32", "zlib": True, "complevel": 4},
            "qq_monthly_std": {"dtype": "float32", "zlib": True,
                               "complevel": 4} if "qq_monthly_std" in ds.variables else None
        }

        output_file = os.path.join(OUTPUT_DIR, OUTPUT_FILE)
        ds_cf_compliant.to_netcdf(output_file, encoding={k: v for k, v in encoding.items() if v is not None})

        print(f"  Saved CF-compliant file to {output_file}")

    except Exception as e:
        print(f"Error processing {INPUT_FILE} for CF compliance: {str(e)}")
        return None
    finally:
        if 'ds' in locals():  # Ensure dataset is closed even if errors occur
            ds.close()


if __name__ == "__main__":
    main()