import xarray as xr
import numpy as np
from typing import List, Optional
import warnings

from common.dataset_dto import DatasetDTO
from common.base_homogenization import BaseHomogenization
from common.homogenizer_pairwise import PairwiseHomogenizer, PairwiseResult
from common.homogenization_result import PairwiseHomogenizationResult

class WindSpeedHomogenization(BaseHomogenization):

    def __init__(self, eobs_file: str, era5_file: str, variable_name: str = "mean_wind_speed"):
        super().__init__(eobs_file, era5_file)
        self.variable_name = variable_name
        self.eobs_data = self.load_eobs(self.eobs_ds, variable_name)
        self.era5_data = self.load_era5(self.era5_ds)
        self.common_times = self.get_common_and_unique_times(self.eobs_data, self.era5_data)
        self.subset_to_common_times()
        self.len_times = len(self.common_times)
        self.len_lon = len(self.eobs_data.lons)
        self.len_lat = len(self.eobs_data.lats)
        self.radius = 15
        self.window_size = 24
        self.threshold_factor = 3

    def load_era5(self, era5_ds: xr.Dataset) -> DatasetDTO:
        lons = era5_ds['longitude'].values
        lats = era5_ds['latitude'].values
        time = era5_ds['time'].values

        u10 = era5_ds['u10'].values
        v10 = era5_ds['v10'].values
        wind_speed = np.sqrt(np.square(u10) + np.square(v10))
        
        return DatasetDTO(
            lons=lons,
            lats=lats,
            time=time,
            data=wind_speed
        )
    
    
    def execute(self, monthly_span: List[float], output_path: str, uncertainty_var_name: Optional[str] = "combined_uncertainty"):
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
        self._reverse_era5_data_latitudes()
        self.eobs_data.data = self.fill_missing_values(self.eobs_data.data, self.era5_data.data)
                
        homogenized_data = self.eobs_data.data.copy()

        for lon_idx in range(self.len_lon):
            self.print_homo_progress(lon_idx, self.len_lon)
            for lat_idx in range(self.len_lat):
                current_series = self.eobs_data.data[:, lat_idx, lon_idx]

                if not np.isreal(current_series).all():
                    warnings.warn(f"Non-numeric series at position ({lon_idx},{lat_idx})")
                    continue

                neighbors = self.find_valid_neighbors(self.era5_data.data, lon_idx, lat_idx)


                if len(neighbors) > 0:
                    homogenizer = PairwiseHomogenizer(threshold_factor=self.threshold_factor, window_size=self.window_size)
                    correction_result = homogenizer.homogenize(current_series, neighbors)

                    if isinstance(correction_result, PairwiseResult):
                        correction = correction_result.corrections  # Access as attribute, not dict key
                    else:
                        warnings.warn(f"Correzione non valida per posizione ({lon_idx}, {lat_idx})")
                        continue

                    if len(correction) == len(current_series) and isinstance(correction, np.ndarray):
                        homogenized_data[:, lat_idx, lon_idx] = current_series - correction
                    else:
                        warnings.warn(f"Correzione incompatibile con la serie per posizione ({lon_idx}, {lat_idx})")



        self.results = PairwiseHomogenizationResult(
            original=self.eobs_data.data,
            corrected=homogenized_data
        )
                
                

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
            global_attributes={"title": "Homogenized Wind Speed Data"},
            compress=True
        )
        



    def get_common_and_unique_times(self, eobs_data, era5_data):
        """Find intersecting timestamps between datasets (time alignment)"""
        unique_times = self.get_common_times(eobs_data, era5_data)
        common_times = np.intersect1d(unique_times, era5_data.time, assume_unique=True)
        return np.sort(common_times)



    def subset_to_common_times(self):
        """Subset datasets to common timestamps"""
        eobs_time_mask = np.isin(self.eobs_data.time, self.common_times)
        self.eobs_data.data = self.eobs_data.data[eobs_time_mask, ...]
        self.eobs_data.time = self.eobs_data.time[eobs_time_mask]
        
        era5_time_mask = np.isin(self.era5_ds.time, self.common_times)
        self.era5_data.data = self.era5_data.data[era5_time_mask, ...]
        self.era5_data.time = self.era5_data.time[era5_time_mask]
        
    def _reverse_era5_data_latitudes(self) -> None:
        """Reverse the latitude orientation of ERA5 data."""
        self.era5_data.data = self._reverse_era5_data_by_latitudes(self.era5_data.data)
        self.era5_data.lats = self._reverse_era5_latitude(self.era5_data.lats)
        
    
    def _reverse_era5_latitude(self, era5_latitude):
        """Reverse latitude dimension of ERA5 latitude"""
        return era5_latitude[::-1]

    def _reverse_era5_data_by_latitudes(self, era5_data):
        """Reverse latitude dimension of ERA5 data"""
        return era5_data[:, ::-1, :]
    
    def set_window_size(self, window_size: int):
        self.window_size = window_size
    
    def set_radius(self, radius: int):
        self.radius = radius
        
    def set_threshold_factor(self, threshold_factor: int):
        self.threshold_factor = threshold_factor

    def find_valid_neighbors(self, data, i, j):
        """
        Finds valid neighboring time series around a given grid cell (i, j) within a specified radius.

        Parameters:
        - data: 3D numpy array (lon × lat × time)
        - i, j: Target grid cell indices (longitude, latitude)

        Returns:
        - List of valid neighboring time series (non-NA entries)
        """

        # Define search window (handling grid edges)
        lon_indices = range(max(0, i - self.radius), min(self.len_lon, i + self.radius + 1))
        lat_indices = range(max(0, j - self.radius), min(self.len_lat, j + self.radius + 1))

        neighbors = []
        for ii in lon_indices:
            for jj in lat_indices:
                if not (ii == i and jj == j):  # Exclude the center cell
                    neighbor_series = data[ii, jj, :]
                    if np.any(~np.isnan(neighbor_series)):  # Check for non-NA values
                        neighbors.append(neighbor_series)
        return neighbors


    

