import xarray as xr
import numpy as np
import pandas as pd
from common.dataset_dto import DatasetDTO
from common.base_homogenization import BaseHomogenization
from common.homogenization_result import SNHTHomogenizationResult
from common.homogenizer_snht import SnhtHomogenizer
from statsmodels.tsa.stattools import acf
from typing import List, Optional


class PrecipitationHomogenization(BaseHomogenization):

    def __init__(self, eobs_file: str, era5_file: str, variable_name: str = "accumulated_precipitation"):
        super().__init__(eobs_file, era5_file)
        self.variable_name = variable_name
        self.eobs_data = self.load_eobs(self.eobs_ds, variable_name)
        self.era5_data = self.load_era5(self.era5_ds)
        self.common_times = self.get_common_times(self.eobs_data, self.era5_data)
        self.len_times = len(self.common_times)
        self.len_lon = len(self.eobs_data.lons)
        self.len_lat = len(self.eobs_data.lats)
        self.acf_lag_max = 12
        self.window_size = 15
        # self.mv_window = 156
        self.mv_window = 12
        self.sd_factor = 1

    def load_era5(self, era5_ds: xr.Dataset) -> DatasetDTO:
        lons = era5_ds['longitude'].values
        lats = era5_ds['latitude'].values
        time = era5_ds['time'].values

        tp = era5_ds['tp'].values
        data = tp * 1000

        return DatasetDTO(
            lons=lons,
            lats=lats,
            time=time,
            data=data
        )

    def execute(self, monthly_span: List[float], output_path: str,
                uncertainty_var_name: Optional[str] = "combined_uncertainty"):
        if uncertainty_var_name is not None:
            self.uncertainty_var_name = uncertainty_var_name

        print('Starting homogenization process...')
        self.homogenize()
        print('Homogenization completed.')
        print('\nCalculating uncertainty...')
        self.calculate_uncertainty(monthly_span=monthly_span, common_times=self.common_times)
        print('Uncertainty calculation completed.')
        print('\nSaving results...')
        self.save_results(output_path=output_path)
        print('Results saved successfully.')


    def homogenize(self):
        grid_results = []
        for lon_idx in range(self.len_lon):
            lat_results = []
            self.print_homo_progress(lon_idx, self.len_lon)
            for lat_idx in range(self.len_lat):

                eobs_ts = self.eobs_data.data[:, lat_idx, lon_idx]
                era5_ts = self.era5_data.data[:, self.len_lat - 1 - lat_idx, lon_idx]  # Flip latitude index
                filled_eobs = self.fill_missing_values(eobs_ts=eobs_ts, era5_ts=era5_ts)

                refrence_avarage_series = self.get_neighbor_average_series(
                    data_3d=self.era5_data.data,
                    lat_idx=lat_idx,
                    lon_idx=lon_idx,
                    window_size=self.window_size
                )

                homogenizer = SnhtHomogenizer(min_segment_length=self.acf_lag_max)
                homo_result = homogenizer.homogenize(filled_eobs, refrence_avarage_series, sd_factor=self.sd_factor)

                moving_variance = self.calculate_moving_variance(homo_result.corrected, homo_result.original)

                acf_original = self.calculate_acf(homo_result.original)
                acf_corrected = self.calculate_acf(homo_result.corrected)


                processed_point = {
                    "corrected_data": homo_result.corrected[:self.len_times],
                    "original_data": homo_result.original[:self.len_times],
                    "moving_variance": moving_variance[:self.len_times],
                    "acf_original": acf_original,
                    "acf_corrected": acf_corrected
                }

                lat_results.append(processed_point)
            grid_results.append(lat_results)

        self.results = self.combine_results_to_arrays(grid_results=grid_results)


    def save_results(self, output_path: str):
        print('original result shape: ', self.results.original.shape)
        print('adjusted result shape: ', self.results.corrected.shape)

        # Prepare coordinates
        coords = self.get_cf_coordinates(
            lon=self.eobs_data.lons,
            lat=self.eobs_data.lats,
            time=self.common_times
        )

        original_attrs = self.eobs_ds[self.variable_name].attrs.copy()
        self.save_homogenized_netcdf(
            variable_name=self.variable_name,
            original_data=self.results.original,
            adjusted_data=self.results.corrected,
            coordinates=coords,
            output_path=output_path,
            variable_attributes=original_attrs,
            global_attributes={"title": "Homogenized Accumulated Precipitation Data"},
            compress=True
        )

    def _calc_rh_wexler(self, d2m_values, t2m_values):
        e_d2m = self._e_wexler(d2m_values)
        e_t2m = self._e_wexler(t2m_values)
        return 100 * (e_d2m / e_t2m)

    def _e_wexler(self, T):
        return 610.78 * np.exp((17.27 * T) / (T + 237.3))

    def set_acf_lag_max(self, acf_lag_max: int):
        self.acf_lag_max = acf_lag_max

    def set_window_size(self, window_size: int):
        self.window_size = window_size

    def set_sd_factor(self, sd_factor: int):
        self.sd_factor = sd_factor

    def get_neighbor_average_series(self, data_3d: np.ndarray, lon_idx: int, lat_idx: int,
                                    window_size: int) -> np.ndarray:
        """
        Calculate neighbor-averaged time series from a 3D array (time, lat, lon).

        Args:
            data_3d (np.ndarray): 3D array of shape (time, lat, lon)
            lon_idx (int): Longitude index (0-based)
            lat_idx (int): Latitude index (0-based)
            window_size (int): Number of neighboring grid points in each direction

        Returns:
            np.ndarray: 1D time series of neighbor averages
        """
        # Get valid neighbor ranges
        lon_min = max(0, lon_idx - window_size)
        lon_max = min(data_3d.shape[2], lon_idx + window_size + 1)
        lat_min = max(0, lat_idx - window_size)
        lat_max = min(data_3d.shape[1], lat_idx + window_size + 1)

        # Extract neighbor series (excluding target cell)
        neighbor_series = [
            data_3d[:, lat, lon]
            for lon in range(lon_min, lon_max)
            for lat in range(lat_min, lat_max)
            if not (lon == lon_idx and lat == lat_idx)
        ]

        if not neighbor_series:
            return np.full(data_3d.shape[0], np.nan)

        return np.nanmean(np.column_stack(neighbor_series), axis=1)


    def calculate_moving_variance(self, time_series: np.ndarray, time_series1: np.ndarray) -> np.ndarray:
        ts = pd.Series(time_series)
        ts1 = pd.Series(time_series1)

        if ts.isna().all():
            return np.array([np.nan] * len(ts))

        mv = ts.rolling(window=self.mv_window, center=True, min_periods=1).var(ddof=1)
        mv1 = ts1.rolling(window=self.mv_window, center=True, min_periods=1).var(ddof=1)
        mvd = mv - mv1

        return mvd.values

    def calculate_acf(self, time_series: np.ndarray) -> np.ndarray:
        if np.all(np.isnan(time_series)):
            return np.full(self.acf_lag_max, np.nan)

        time_series = np.round(time_series, 7)
        acf_values = acf(time_series, nlags=self.acf_lag_max, fft=True, missing="conservative")
        return acf_values[1:]


    def combine_results_to_arrays(self, grid_results) -> SNHTHomogenizationResult:
        """Convert grid results to numpy arrays."""

        time_length = self.len_times
        n_lat = self.len_lat
        n_lon = self.len_lon
        acf_leg = self.acf_lag_max

        combined_data = np.full((time_length, n_lat, n_lon), np.nan)
        combined_data_o = np.full((time_length, n_lat, n_lon), np.nan)
        moving_variance_array = np.full((time_length, n_lat, n_lon), np.nan)
        acf_array = np.full((acf_leg, n_lat, n_lon), np.nan)
        acf_array1 = np.full((acf_leg, n_lat, n_lon), np.nan)

        for lat_idx in range(n_lat):
            for lon_idx in range(n_lon):
                result = grid_results[lon_idx][lat_idx]
                ts_len = min(time_length, len(result["corrected_data"]))

                combined_data[:ts_len, lat_idx, lon_idx] = result["corrected_data"][:ts_len]
                combined_data_o[:ts_len, lat_idx, lon_idx] = result["original_data"][:ts_len]
                moving_variance_array[:ts_len, lat_idx, lon_idx] = result["moving_variance"][:ts_len]
                acf_array[:, lat_idx, lon_idx] = result["acf_original"][:acf_leg]
                acf_array1[:, lat_idx, lon_idx] = result["acf_corrected"][:acf_leg]

        return SNHTHomogenizationResult(
            corrected=combined_data,
            original=combined_data_o,
            moving_variance=moving_variance_array,
            acf_original=acf_array,
            acf_corrected=acf_array1
        )
