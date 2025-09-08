import xarray as xr
import logging
from datetime import datetime
from typing import List

from common.dataset_dto import DatasetDTO
from common.base_homogenization import BaseHomogenization
from common.homogenization_result import BasicHomogenizationResult

logger = logging.getLogger(__name__)

class MaxAirHomogenization(BaseHomogenization):
    """
    Homogenize maximum air temperature (maximum_air_temperature) by applying the
    adjustment derived from homogenized mean air temperature.
    """

    def __init__(
        self,
        eobs_file: str,
        era5_file: str,
        mean_homo_file: str,
        variable_name: str = "maximum_air_temperature",
        homo_variable_name: str = "mean_air_temperature"

    ):
        super().__init__(eobs_file, era5_file)
        self.variable_name = variable_name
        self.homo_variable_name = homo_variable_name
        self.mean_homo_file = mean_homo_file

        # load E‑OBS & ERA5 into DatasetDTOs
        self.eobs_data = self.load_eobs(self.eobs_ds, variable_name)
        self.era5_data = self.load_era5(self.era5_ds)
        # determine the overlapping time axis
        self.common_times = self.get_common_times(self.eobs_data, self.era5_data)

        # dims
        self.len_times = len(self.common_times)
        self.len_lon = len(self.eobs_data.lons)
        self.len_lat = len(self.eobs_data.lats)

        # will hold the raw and adjusted mean‑temp arrays
        self.mean_orig = None
        self.mean_adj = None

    def load_era5(self, ds: xr.Dataset) -> DatasetDTO:
        """Load ERA5 (for metadata/reference)."""
        lons = ds["longitude"].values
        lats = ds["latitude"].values
        time = ds["time"].values
        data = ds["t2m"].values  # we won’t actually use it here
        return DatasetDTO(lons=lons, lats=lats, time=time, data=data)

    def _load_homogenized_mean(self):
        """Read in the already‐homogenized mean‐air‐temperature NetCDF."""
        logger.info("Loading homogenized mean‐air‐temperature file: %s", self.mean_homo_file)
        ds = xr.open_dataset(self.mean_homo_file, engine="netcdf4")
        # assume your mean‐temp file has two vars: original and adjusted
        self.mean_orig = ds[f"{self.homo_variable_name}"].transpose("time","latitude","longitude").values
        self.mean_adj = ds[f"{self.homo_variable_name}_adjusted"].transpose("time","latitude","longitude").values
        ds.close()

    def execute(self, output_path: str,  monthly_span: List[float], uncertainty_var_name: str = "combined_uncertainty"):
        """
        Entry point: loads mean‐temp corrections, applies them, and writes out NetCDF.
        """
        if uncertainty_var_name is not None:
            self.uncertainty_var_name = uncertainty_var_name


        print("Loading homogenized mean‐air‐temperature...")
        self._load_homogenized_mean()
        print("Applying max‐air‐temperature adjustment...")
        self.homogenize()
        print('\nCalculating uncertainty...')
        self.calculate_uncertainty(monthly_span=monthly_span, common_times=self.common_times)
        print("Saving max‐air‐temperature results...")
        self.save_results(output_path)
        print("Done.")

    def homogenize(self):
        """
        Apply the mean‐temp adjustment to the original E‑OBS max‐temp series.
        """
        if self.mean_orig is None or self.mean_adj is None:
            raise RuntimeError("Mean‐temp corrections not loaded.")

        # compute adjustment array [time, lat, lon]
        adj = self.mean_adj - self.mean_orig

        # apply to E‑OBS max‐temp
        # self.eobs_data.data is [time, lat, lon]
        self.original  = self.eobs_data.data.copy()
        self.corrected = self.eobs_data.data + adj

        self.results = BasicHomogenizationResult(
            original=self.original,
            corrected=self.corrected,
        )


    def save_results(self, output_path: str):
        """
        Save original and adjusted max‐temp to a CF‐compliant NetCDF.
        """
        coords = self.get_cf_coordinates(
            lon=self.eobs_data.lons,
            lat=self.eobs_data.lats,
            time=self.common_times
        )
        orig_attrs = self.eobs_ds[self.variable_name].attrs.copy()

        # write using BaseHomogenization helper
        self.save_homogenized_netcdf(
            variable_name=self.variable_name,
            original_data=self.original,
            adjusted_data=self.corrected,
            coordinates=coords,
            output_path=output_path,
            variable_attributes=orig_attrs,
            global_attributes={
                "title": "Homogenized Maximum Air Temperature Data",
                "history": f"{datetime.utcnow().isoformat()} adjusted by MaxAirHomogenization"
            },
            compress=True
        )
