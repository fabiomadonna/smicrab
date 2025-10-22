import xarray as xr
import numpy as np
import argparse

def print_missing_values(ds):
    """
    Print missing values for each variable in the dataset.

    This function uses two methods:

    1. For xarray datasets: it uses the isnull() method to count NaN values.
    2. For netCDF4 datasets (or similar): it checks for the '_FillValue' attribute
       and counts entries matching that fill value.

    Parameters:
    -----------
    ds : xarray.Dataset or netCDF4.Dataset
        The dataset loaded from a NetCDF file.
    """

    for var in ds.data_vars:
        try:
            # This works if the variable is an xarray DataArray
            missing_values = ds[var].isnull().sum().item()
            print(f"Missing values in {var}: {missing_values}")
        except AttributeError:
            # If isnull() is not available, skip this method for the variable.
            print(f"Variable {var} does not support isnull() method.")

    for var_name in ds.data_vars:
        var = ds.data_vars[var_name]
        if hasattr(var, '_FillValue'):
            fill_value = var._FillValue
            # Ensure the data is a numpy array; for masked arrays, .data can be used.
            data = var[:]
            missing_count = np.sum(data == fill_value)
            print(f"Missing values in {var_name} (FillValue={fill_value}): {missing_count}")


if __name__ == "__main__":
    # Set up argument parser
    parser = argparse.ArgumentParser(description='Check for missing values in a NetCDF file.')
    parser.add_argument('file_path', help='Path to the NetCDF file to analyze')
    args = parser.parse_args()

    # Open the NetCDF file
    ds = xr.open_dataset(args.file_path)
    print_missing_values(ds)