import  os
import cdsapi


#
ERA5_START_YEAR = 2011
ERA5_END_YEAR = 2024
ERA5_MONTHS = ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12']
ERA5_ID = "reanalysis-era5-land-monthly-means"

LON_MIN = 6
LON_MAX = 20
LAT_MIN = 32
LAT_MAX =49

OUTPUT_DIR = "./data/ERA5_hu_Monthly"
OUTPUT_FILE = "hu_IT_2011_2023_Monthly_ERA5.nc"

def get_cdsapi_client():
    client = cdsapi.Client()
    return client

def download_era5(target_file: str):
    client = get_cdsapi_client()

    request = {
        'product_type': 'monthly_averaged_reanalysis',
        'variable': ['2m_dewpoint_temperature', '2m_temperature'],
        'year': [str(year) for year in range(ERA5_START_YEAR, ERA5_END_YEAR)],
        'month': ERA5_MONTHS,
        'time': ["00:00"],
        'area': [LAT_MAX, LON_MIN, LAT_MIN, LON_MAX],  # N, W, S, E
        "data_format": "netcdf",
        "download_format": "unarchived",
    }
    client.retrieve(ERA5_ID, request, target_file)

if __name__ == "__main__":
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    output_file = os.path.join(OUTPUT_DIR, OUTPUT_FILE)
    download_era5(output_file)
