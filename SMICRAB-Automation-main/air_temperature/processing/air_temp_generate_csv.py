#!/usr/bin/env python3
import os
import xarray as xr

# Constants
INPUT_DIR = "./data/air_temp_IT_2011_2023_Monthly"
OUTPUT_DIR = "./data"
VARIABLES = ['tg', 'tn', 'tx']  # The three subvariables to process


def process_variable(variable):
    """Process a single air temperature variable and save to CSV."""
    input_file = os.path.join(INPUT_DIR, f"{variable}_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly_CF-1.8_corrected.nc")
    output_file = os.path.join(OUTPUT_DIR, f"{variable}_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly_CF-1.8_corrected.csv")

    ds = xr.open_dataset(input_file)

    # Convert to DataFrame - this creates a row for each combination
    df = ds.to_dataframe().reset_index()

    # Reorder the columns and sort values to match your desired structure
    df = df[['time', 'latitude', 'longitude'] + [v for v in ds.data_vars]]
    df = df.sort_values(['longitude', 'latitude', 'time'])

    # Save to CSV
    df.to_csv(output_file, index=False)
    print(f'CSV file saved: {output_file}')


def main():
    """Main function for Generating CSV File for air temperature variables."""
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    for variable in VARIABLES:
        print(f'Generating CSV for {variable} variable...')
        process_variable(variable)


if __name__ == "__main__":
    main()