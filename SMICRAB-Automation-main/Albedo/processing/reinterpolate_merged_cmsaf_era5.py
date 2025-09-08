#!/usr/bin/env python3
import os
import numpy as np
import xarray as xr
import pandas as pd

# File paths
INPUT_FILE = "./data/SAL_Monthly_2011-2023_CF_Compliant/SAL_IT_2011-2023_Monthly_CMSAF_ERA5_CF-1.8.nc"
OUTPUT_DIR = "./data/SAL_Monthly_2011-2023_CF_Compliant"
OUTPUT_FILE = "SAL_IT_2011-2023_Monthly_CMSAF_ERA5_CF-1.8_Reinterpolated.nc"


def reinterpolate(input_file, output_file):
    ds = xr.open_dataset(input_file)

    # Ensure time is sorted
    ds = ds.sortby("time")

    filled_ds = ds.interpolate_na(dim="time", method="linear")
    filled_ds.to_netcdf(output_file)


if __name__ == "__main__":

    os.makedirs(OUTPUT_DIR, exist_ok=True)
    output_file = os.path.join(OUTPUT_DIR, OUTPUT_FILE)
    reinterpolate(INPUT_FILE, output_file)