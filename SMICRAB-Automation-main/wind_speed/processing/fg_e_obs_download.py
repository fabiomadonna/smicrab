# fg_e_obs_download.py
import os
import cdsapi


E_OBS_ID = "insitu-gridded-observations-europe"

LON_MIN = 6
LON_MAX = 20
LAT_MIN = 32
LAT_MAX = 49

OUTPUT_DIR = "./data"
OUTPUT_FILE = "fg_2011_2023_Daily_E_OBS.zip"  # Changed filename

def get_cdsapi_client():
    client = cdsapi.Client()
    return client

def download_era5(target_file: str):
    client = get_cdsapi_client()

    request = {
        "product_type": "ensemble_mean",
        "variable": ["wind_speed"], # Changed variable name here
        "grid_resolution": "0_1deg",
        "period": "2011_2024",
        "version": ["30_0e"]
    }

    client.retrieve(E_OBS_ID, request, target_file)

if __name__ == "__main__":
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    output_file = os.path.join(OUTPUT_DIR, OUTPUT_FILE)
    download_era5(output_file)