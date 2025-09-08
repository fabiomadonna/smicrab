from mean_air_homogenizer import MeanAirHomogenization
import os
import warnings

if __name__ == "__main__":
    with warnings.catch_warnings():
        warnings.simplefilter("ignore", category=RuntimeWarning)
        eobs_file = "./data/E_OBS_air_temp_Monthly/tg_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly_CF-1.8.nc"
        era5_file = "./data/ERA5_air_temp_Monthly/air_temp_IT_2011_2023_Monthly_ERA5.nc"
        output_dir = "./data/air_temp_IT_2011_2023_Monthly"
        output_file = "tg_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly_CF-1.8_corrected.nc"

        os.makedirs(output_dir, exist_ok=True)
        output_file = os.path.join(output_dir, output_file)

        monthly_span = [0.5, 0.45, 0.5, 0.5, 0.45, 0.4, 0.4, 0.4, 0.4, 0.5, 0.45, 0.45]

        mean_air_homogenization = MeanAirHomogenization(eobs_file, era5_file)


        mean_air_homogenization.execute(
            output_path=output_file,
            monthly_span=monthly_span
        )
