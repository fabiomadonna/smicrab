#!/usr/bin/env python3
import os
import xarray as xr

# Constants
INPUT_FILE = "./data/LST_Monthly_Per_Hour_2011-2023/LST_IT_2011_2023_agg_Monthly_per_hour_grid_0.1_CF-1.8.nc"
OUTPUT_DIR = "./data"
OUTPUT_FILE = "LST_IT_2011_2023_agg_Monthly_per_hour_grid_0.1_CF-1.8.csv"


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