import xarray as xr
import logging
from datetime import datetime
from typing import List

from common.dataset_dto import DatasetDTO
from common.base_homogenization import BaseHomogenization
from common.homogenization_result import BasicHomogenizationResult

logger = logging.getLogger(__name__)

class MinAirHomogenization(BaseHomogenization):
    """
    Homogenize minimum air temperature (minimum_air_temperature) by applying the
    adjustment derived from homogenized mean air temperature.
    """

    def __init__(
        self,
        eobs_file: str,
        era5_file: str,
        mean_homo_file: str,
        variable_name: str = "minimum_air_temperature",
        homo_variable_name: str = "mean_air_temperature"

    ):
        super().__init__(eobs_file, era5_file)
        self.variable_name   = variable_name
        self.homo_variable_name = homo_variable_name
        self.mean_homo_file  = mean_homo_file

        # load E‑OBS & ERA5 into DatasetDTOs
        self.eobs_data    = self.load_eobs(self.eobs_ds, variable_name)
        self.era5_data    = self.load_era5(self.era5_ds)
        self.common_times = self.get_common_times(self.eobs_data, self.era5_data)

        # dims
        self.len_times = len(self.common_times)
        self.len_lon   = len(self.eobs_data.lons)
        self.len_lat   = len(self.eobs_data.lats)


        # placeholders for mean‐temp correction arrays
        self.mean_orig = None
        self.mean_adj  = None

    def load_era5(self, ds: xr.Dataset) -> DatasetDTO:
        """Load ERA5 (for metadata/reference)."""
        lons = ds["longitude"].values
        lats = ds["latitude"].values
        time = ds["time"].values
        data = ds["t2m"].values  # unused here, but kept for consistency
        return DatasetDTO(lons=lons, lats=lats, time=time, data=data)

    def _load_homogenized_mean(self):
        """Read the homogenized mean‐air‐temperature NetCDF and pull out original & adjusted."""
        logger.info("Loading homogenized mean‐air‐temperature: %s", self.mean_homo_file)
        ds = xr.open_dataset(self.mean_homo_file, engine="netcdf4")

        # mean‐temp file should have <mean_air_temperature> and <mean_air_temperature_adjusted>
        self.mean_orig = ds[self.homo_variable_name] \
            .transpose("time","latitude","longitude") \
            .values
        self.mean_adj  = ds[f"{self.homo_variable_name}_adjusted"] \
            .transpose("time","latitude","longitude") \
            .values
        ds.close()

    def execute(
        self,
        output_path: str,
        monthly_span: List[float],
        uncertainty_var_name: str = "combined_uncertainty"
    ):
        """
        1) Load mean‐temp corrections
        2) Apply to TN
        3) Compute uncertainty
        4) Save CF‐compliant NetCDF
        """
        if uncertainty_var_name:
            self.uncertainty_var_name = uncertainty_var_name

        print("Loading mean‐temp corrections...")
        self._load_homogenized_mean()

        print("Applying minimum‐temperature adjustment...")
        self.homogenize()

        print("Calculating uncertainty...")
        self.calculate_uncertainty(
            monthly_span=monthly_span,
            common_times=self.common_times
        )

        print("Saving results...")
        self.save_results(output_path)
        print("Done.")

    def homogenize(self):
        """Add the mean‐temp adjustment to the E‑OBS TN series."""
        if self.mean_orig is None or self.mean_adj is None:
            raise RuntimeError("Mean‐temp corrections not loaded.")

        adjustment = self.mean_adj - self.mean_orig

        # store original & corrected
        self.original  = self.eobs_data.data.copy()
        self.corrected = self.eobs_data.data + adjustment

        self.results = BasicHomogenizationResult(
            original=self.original,
            corrected=self.corrected,
        )

    def save_results(self, output_path: str):
        """Write out original & adjusted TN to a CF‐compliant NetCDF."""
        coords = self.get_cf_coordinates(
            lon=self.eobs_data.lons,
            lat=self.eobs_data.lats,
            time=self.common_times
        )
        var_attrs = self.eobs_ds[self.variable_name].attrs.copy()

        self.save_homogenized_netcdf(
            variable_name=self.variable_name,
            original_data=self.original,
            adjusted_data=self.corrected,
            coordinates=coords,
            output_path=output_path,
            variable_attributes=var_attrs,
            global_attributes={
                "title":   "Homogenized Minimum Air Temperature Data",
                "history": f"{datetime.utcnow().isoformat()} adjusted by MinAirHomogenization"
            },
            compress=True
        )
