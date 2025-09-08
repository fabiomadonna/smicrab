#!/bin/bash

# Directory-to-script mapping
declare -A dir_scripts=(
    ["accumulated_precipitation"]="run_precipitation.sh"
    ["air_temperature"]="run_air_temperature.sh"
    ["Albedo"]="run_SAL.sh"
    ["Land_Surface_Temperature"]="run_LST.sh"
    ["relative_humidity"]="run_relative_humidity.sh"
    ["sea_level_pressure"]="run_pressure.sh"
    ["solar_irradiance"]="run_solar_irradiance.sh"
    ["wind_speed"]="run_wind_speed.sh"
)

# Loop through each directory and execute the corresponding script
for dir in "${!dir_scripts[@]}"; do
    script="${dir_scripts[$dir]}"

    echo "Entering directory: $dir"
    cd "$dir" || { echo "❌ Error: Failed to enter directory $dir"; exit 1; }

    echo "Running script: $script"
    bash "$script" || { echo "❌ Error: Failed to run $script"; exit 1; }

    echo "Returning to parent directory"
    cd .. || { echo "❌ Error: Failed to return to parent directory"; exit 1; }

    echo "----------------------------------------"
done

echo "✅ All scripts executed successfully!"