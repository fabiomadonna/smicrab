import abc
import xarray as xr
import pandas as pd
import numpy as np
from statsmodels.nonparametric.smoothers_lowess import lowess
from typing import Optional, List

from common.dataset_dto import DatasetDTO
from common.homogenization_result import SNHTHomogenizationResult, PairwiseHomogenizationResult, BasicHomogenizationResult


class BaseHomogenization(abc.ABC):

    def __init__(self, eobs_file: str, era5_file: str):
        self.eobs_ds: xr.Dataset = xr.open_dataset(eobs_file, decode_times=False)
        self.era5_ds: xr.Dataset = xr.open_dataset(era5_file, decode_times=False)
        # self.era5_ds = self.era5_ds.isel(longitude=slice(20, 141))
        # self.era5_ds = self.era5_ds.isel(valid_time=slice(0, 150), longitude=slice(20, 141))
        # self.eobs_ds = self.eobs_ds.isel(longitude=slice(20, 141))
        # self.eobs_ds = self.eobs_ds.isel(time=slice(0, 150), longitude=slice(20, 141))
        # self.era5_ds = self.era5_ds.isel(valid_time=slice(0, 150), longitude=slice(20, 80), latitude=slice(30, 120))
        # self.eobs_ds = self.eobs_ds.isel(longitude=slice(20, 80), latitude=slice(30, 120))


        self.eobs_data: DatasetDTO = None
        self.era5_data: DatasetDTO = None
        self.uncertainty_data: np.ndarray = None
        
        self.variable_suffix = "_adjusted"
        self.uncertainty_var_name = "combined_uncertainty"
        self.epoch = pd.Timestamp('1970-01-01')
        self.base_date = pd.Timestamp('2011-01-01')
        self.results: SNHTHomogenizationResult | PairwiseHomogenizationResult | BasicHomogenizationResult | None = None

        self._align_eobs_times()
        self._align_era5_times()


    @abc.abstractmethod
    def load_era5(self, era5_ds: xr.Dataset) -> DatasetDTO:
        pass
    
    @abc.abstractmethod
    def homogenize(self):
        pass
    
    @abc.abstractmethod
    def save_results(self, output_path: str) -> None:
        pass

    @abc.abstractmethod
    def execute(self, monthly_span: List[float], output_path: str, uncertainty_var_name: Optional[str]):
        pass

    def load_eobs(self, eobs_ds: xr.Dataset, variable_name: str) -> DatasetDTO:
        lons = eobs_ds['longitude'].values
        lats = eobs_ds['latitude'].values
        time = eobs_ds['time'].values
        data = eobs_ds[variable_name].values
        return DatasetDTO(lons=lons, lats=lats, time=time, data=data)
    
    def _align_eobs_times(self):
        # Convert days since 2011-01-01 → Unix seconds
        days_since_2011 = self.eobs_ds.time.values # [0, 31, 59, 90, ..., 700]
        seconds_from_2011 = days_since_2011 * 24 * 60 * 60  # days → seconds
        seconds_to_2011 = (self.base_date - self.epoch).total_seconds()  # 1293840000.0
        unix_timestamps = seconds_to_2011 + seconds_from_2011
        self.eobs_ds = self.eobs_ds.assign_coords(time=unix_timestamps)
        self.eobs_ds["time"].attrs['units'] = 'seconds since 1970-01-01 00:00:00'


    def _align_era5_times(self):
        self.era5_ds = self.era5_ds.rename({'valid_time': 'time'})
        seconds = pd.to_datetime(self.era5_ds.time.values, unit='s')
        unix_timestamps = seconds.astype('int64') // 10**9
        self.era5_ds = self.era5_ds.assign_coords(time=unix_timestamps)
        self.era5_ds["time"].attrs['units'] = 'seconds since 1970-01-01 00:00:00'
    
    def get_common_times(self, eobs_data: DatasetDTO, era5_data:  DatasetDTO):
        common_times = np.sort(np.intersect1d(eobs_data.time, era5_data.time))
        return common_times
    
    def fill_missing_values(self, eobs_ts: np.ndarray, era5_ts: np.ndarray) -> np.ndarray:
        mask = ~np.isfinite(eobs_ts)
        filled = eobs_ts.copy()
        filled[mask] = era5_ts[mask]
        return filled


    def save_homogenized_netcdf(
        self,
        variable_name: str,
        original_data: np.ndarray,
        adjusted_data: np.ndarray,
        coordinates: dict,
        output_path: str,
        variable_attributes: Optional[dict] = None,
        global_attributes: Optional[dict] = None,
        compress: bool = True,
        homogenization_method: str = "SNHT",
    ) -> None:
        """
        Save homogenized climate data to a CF-1.8 compliant NetCDF file.

        Parameters
        ----------
        variable_name : str
            Base name of the variable (e.g., "mean_relative_humidity")
        original_data : np.ndarray
            Original data array (3D: time × lat × lon)
        adjusted_data : np.ndarray
            Homogenized data array (same shape as original_data)
        coordinates : dict
            Coordinate dictionary from get_cf_coordinates()
        output_path : str
            Output file path
        variable_attributes : dict, optional
            Variable attributes (units, standard_name etc.)
        global_attributes : dict, optional
            Global dataset attributes
        compress : bool
            Enable NetCDF compression (default: True)
        homogenization_method : str
            Homogenization method used (default: "SNHT")
        """

        # 1. Initialize Dataset with Coordinates
        dataset = xr.Dataset(coords=coordinates)

        # 2. Prepare Variable Names
        original_var = f"{variable_name}"
        adjusted_var = f"{variable_name}_adjusted"

        # 3. Add Variables to Dataset
        dataset[original_var] = (("time", "latitude", "longitude"), original_data)
        dataset[adjusted_var] = (("time", "latitude", "longitude"), adjusted_data)

        # 4. Set Variable Attributes
        base_attrs = {
            "source": "Original observational data"
        }

        # Apply user-provided attributes (excluding _FillValue)
        if variable_attributes:
            user_attrs = {k: v for k, v in variable_attributes.items()
                          if k != "_FillValue"}
            base_attrs.update(user_attrs)

        dataset[original_var].attrs.update(base_attrs)
        dataset[adjusted_var].attrs.update({
            **base_attrs,
            # "long_name": f"Adjusted {base_attrs['long_name']}",
            "processing": f"{homogenization_method} homogenization with ERA5 reference"
        })

        if self.uncertainty_data is not None:
            uncertainty_var = self.uncertainty_var_name
            dataset[uncertainty_var] = (("time", "latitude", "longitude"), self.uncertainty_data)
            dataset[uncertainty_var].attrs.update({
                'units': variable_attributes.get('units', '') if variable_attributes else '',
                'long_name': f"Combined uncertainty of {variable_name}_adjusted using LOESS residuals"
            })

        # 5. Set Global Attributes
        default_globals = {
            "Conventions": "CF-1.8",
            "history": f"Created on {np.datetime64('now')}",
            "processing": "Pairwise homogenization",
            "variable": variable_name
        }
        if global_attributes:
            default_globals.update(global_attributes)
        dataset.attrs.update(default_globals)

        # 6. Configure Encoding
        encoding = {
            original_var: {
                "zlib": compress,
                "complevel": 4 if compress else 0,
                "_FillValue": np.nan
            },
            adjusted_var: {
                "zlib": compress,
                "complevel": 4 if compress else 0,
                "_FillValue": np.nan
            }
        }

        # Add encoding for uncertainty if it exists
        if self.uncertainty_data is not None:
            encoding[self.uncertainty_var_name] = {
                "zlib": compress,
                "complevel": 4 if compress else 0,
                "_FillValue": np.nan
            }

        # Coordinate encoding
        for coord in coordinates:
            encoding[coord] = {"_FillValue": None}

        # 7. Save to File
        dataset.to_netcdf(output_path, encoding=encoding)
        print(f"Saved homogenized {variable_name} to: {output_path}")


    def get_cf_coordinates(self, lon, lat, time, time_units="seconds since 1970-01-01 00:00:00"):
        """
        Returns CF-1.8 compliant coordinate definitions for NetCDF files.
        
        Parameters:
        - lon: Longitude (degrees_east)
        - lat: Latitude (degrees_north)
        - time: Time (numeric values matching time_units)
        - time_units: CF-compliant time unit string (default: seconds since 1970)
        
        Returns:
        Dictionary ready for xarray.Dataset coords parameter
        """
        return {
            "longitude": ("longitude", lon, {
                "standard_name": "longitude",
                "long_name": "longitude",
                "units": "degrees_east",
                "axis": "X",
                "_CoordinateAxisType": "Lon"
            }),
            "latitude": ("latitude", lat, {
                "standard_name": "latitude",
                "long_name": "latitude",
                "units": "degrees_north",
                "axis": "Y",
                "_CoordinateAxisType": "Lat"
            }),
            "time": ("time", time, {
                "standard_name": "time",
                "long_name": "Time",
                "units": time_units,
                "calendar": "proleptic_gregorian",
                "axis": "T",
                "_CoordinateAxisType": "Time"
            })
        }


    def calculate_uncertainty(self, monthly_span: List[float], common_times:np.ndarray) -> None:
        try:
            time_vals = common_times
            time_months, time_dates = self.convert_time_to_months(time_vals)

            data = self.results.corrected
            self.uncertainty_data = np.full_like(data, np.nan)

            # Process each grid point
            for lat_idx in range(data.shape[1]):
                for lon_idx in range(data.shape[2]):
                    data_subset = data[: , lat_idx, lon_idx]

                    if np.all(np.isnan(data_subset)):
                        continue

                    try:
                        self.uncertainty_data[: , lat_idx, lon_idx] = self.apply_loess_and_residuals(
                            data=data_subset,
                            months=time_months,
                            spans=monthly_span
                        )
                    except Exception as e:
                        print(f"    Error for lat_idx={lat_idx}, lon_idx={lon_idx}: {str(e)}")
                        self.uncertainty_data[: , lat_idx, lon_idx] = np.nan
        except Exception as e:
            print(f"Error calculating uncertainties: {str(e)}")



    def apply_loess_and_residuals(self, data: np.ndarray, months: np.ndarray, spans: List[float]) -> np.ndarray:
        """
        Apply LOESS smoothing and calculate absolute residuals for each month separately

        Args:
            data: 1D array of data values
            months: 1D array of time values
            spans: List of 12 smoothing parameters (one for each month)

        Returns:
            1D array of residuals (absolute differences between data and smoothed values)
        """
        if np.all(np.isnan(data)):
            return np.full_like(data, np.nan)

        residuals = np.full_like(data, np.nan)

        for i in range(12):  # For each month (0-11)
            # Get indices for this month
            month_indices = np.arange(i, len(data), 12)
            data_subset = data[month_indices]
            time_subset = months[month_indices]

            # Skip if all values are NaN
            if np.all(np.isnan(data_subset)):
                continue

            # Remove NaN values for LOESS fitting
            valid_mask = ~np.isnan(data_subset)
            valid_data = data_subset[valid_mask]
            valid_time = time_subset[valid_mask]

            if len(valid_data) < 3:  # Need at least 3 points for meaningful smoothing
                continue

            # Apply LOESS smoothing
            smoothed_valid = lowess(
                valid_data,
                valid_time,
                frac=spans[i],
                it=1,  # Number of iterations
                return_sorted=False
            )

            # Calculate absolute residuals for valid points
            valid_residuals = np.abs(valid_data - smoothed_valid)

            # Put residuals back in the original array
            residuals[month_indices[valid_mask]] = valid_residuals

        return residuals



    def convert_time_to_months(self, time_vals: np.ndarray):
        """Convert time values to months since first time point."""


        date_times = pd.to_datetime(time_vals, unit='s', origin=self.epoch)
        first_date = date_times[0]

        time_months = np.array(
            [(date.year - first_date.year) * 12 + (date.month - first_date.month) for date in date_times]
        )

        return time_months, date_times


    def print_homo_progress(self, index, total):
        if index % 20 == 0:
            lons = self.eobs_data.lons
            print(f'homogenization for lat [{np.round(lons[index], 1)} - {np.round(lons[min(total-1, index + 20)])}]')