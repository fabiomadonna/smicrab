#!/usr/bin/env python3
import os
import xarray as xr

# Constants
INPUT_FILE = "./data/E_OBS_qq_Monthly/qq_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly_CF-1.8.nc"
OUTPUT_DIR = "./data"
OUTPUT_FILE = "E_OBS_qq_Monthly/qq_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly_CF-1.8.csv"


def main():
    """Main function for Generating CSV File."""
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    output_file = os.path.join(OUTPUT_DIR, OUTPUT_FILE)

    ds = xr.open_dataset(INPUT_FILE)

    # Convert to DataFrame - this creates a row for each combination
    df = ds.to_dataframe().reset_index()

    # Reorder the columns and sort values to match your desired structure
    df = df[['time', 'latitude', 'longitude'] + [v for v in ds.data_vars]]
    df = df.sort_values(['longitude', 'latitude', 'time'])

    # Save to CSV
    df.to_csv(output_file, index=False)

    print(f'CSV files Saved in {output_file}')


if __name__ == "__main__":
    main()