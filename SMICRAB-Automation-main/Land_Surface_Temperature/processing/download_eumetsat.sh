#!/bin/bash
# Determine the directory where this script is located
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
# Source the .env file from the project root (two directories up)
source "$SCRIPT_DIR/../../.env"

EUMETSAT_BASE_URL_ALBEDO="https://datalsasaf.lsasvcs.ipma.pt/PRODUCTS/MSG/MLST/NETCDF"
DOWNLOAD_DIR="./data/EUMETSAT_LST_hourly"  # Set your desired download directory here

for year in $(seq 2021 2023); do
    for month in 01 02 03 04 05 06 07 08 09 10 11 12; do
        url="${EUMETSAT_BASE_URL_ALBEDO}/$year/$month/"
        echo "Downloading from URL: $url"

        # Download files (flat structure)
        wget -nd -c --no-check-certificate -r -np -nH \
             --user="$EUMETSAT_USERNAME" --password="$EUMETSAT_PASSWORD" \
             -R "*15.nc, *30.nc, *45.nc, *.html, *.tmp" \
             -A "*00.nc" \
             -P "$DOWNLOAD_DIR" "$url"
    done
done
