from datetime import datetime, timezone
from typing import List
import os
import shutil
import pandas as pd
import xarray as xr

from app.Models.dataset import Dataset

from app.domain.dataset.dataset_dto import Raster, Covariate
from app.domain.load_module.load_module_dto import VariableConfiguration
from app.infrastructure.repositories.dataset_repository import DatasetRepository
from app.utils.logger import Logger


class DatasetService:
    def __init__(self, repository: DatasetRepository):
        self.repository = repository

    async def get_all(self) -> List[Raster]:
        try:
            datasets: List[Dataset] = await self.repository.get_all()
            rasters = [self.get_as_raster(dataset) for dataset in datasets]
            return rasters

        except Exception as e:
            Logger.error(
                "Failed to get all datasets: {}".format(e),
                context={"task": "handle_get_all_datasets", "message": str(e)},
            )
            raise e

    async def get_by_id(self, dataset_id: str) -> Raster:
        try:
            dataset = await self.repository.get_by_id(dataset_id)
            return self.get_as_raster(dataset)
        except Exception as e:
            Logger.error(
                "Failed to get dataset by id: {}".format(e),
                context={"task": "handle_get_dataset_by_id", "message": str(e)},
            )

    def get_as_raster(self, dataset: Dataset) -> Raster:
        csv_file_path = self.get_csv_path(dataset.file_path, dataset.variable_name)
        return Raster(
            id=dataset.id,
            name=dataset.name,
            variable_name=dataset.variable_name,
            from_date=dataset.from_timestamp,
            to_date=dataset.to_timestamp,
            frequency=dataset.frequency,
            file_path=self.get_dataset_file_path(dataset.file_path),
            csv_file_path=self.get_dataset_file_path(csv_file_path),
        )

    def get_csv_path(self, file_path: str, variable_name: str) -> str:
        csv_dir = file_path.replace("/datasets/", "/datasets_csv/")
        csv_dir = os.path.dirname(csv_dir)
        return os.path.join(csv_dir, f"{variable_name}.csv")

    def get_from_to_date(self, datasets: List[Raster]):
        if len(datasets) == 0:
            return datetime.now(timezone.utc), datetime.now(timezone.utc)
        all_from_dates = [dataset.from_date for dataset in datasets]
        all_to_dates = [dataset.to_date for dataset in datasets]
        return min(all_from_dates), max(all_to_dates)

    async def get_endogenous_variable(self, endogenous_id) -> Raster:
        try:
            dataset: Dataset = await self.repository.get_by_id(endogenous_id)
            return self.get_as_raster(dataset)
        except Exception as e:
            Logger.error(
                "Failed to get endogenous variable: {}".format(e),
                context={"task": "handle_get_endogenous_variable", "message": str(e)},
            )

    async def get_covariate_variable(self, covariates_id, x_leg) -> Covariate:
        try:
            dataset: Dataset = await self.repository.get_by_id(covariates_id)
            raster = self.get_as_raster(dataset)
            return Covariate(**raster.model_dump(), x_leg=x_leg)
        except Exception as e:
            Logger.error(
                "Failed to get covariate variable: {}".format(e),
                context={"task": "handle_get_covariate_variable", "message": str(e)},
            )

    async def get_covariate_variables(
        self, cov_configs: List[VariableConfiguration]
    ) -> List[Covariate]:
        try:

            covariate_variables = [
                await self.get_covariate_variable(cov_config.id, cov_config.x_leg)
                for cov_config in cov_configs
            ]
            return covariate_variables
        except Exception as e:
            Logger.error(
                "Failed to get covariate variables: {}".format(e),
                context={"task": "handle_get_covariate_variables", "message": str(e)},
            )

    async def get_list_of_rasters_by_id(self, ids: List[str]) -> List[Raster]:
        datasets = [await self.repository.get_by_id(dataset_id) for dataset_id in ids]
        rasters = [self.get_as_raster(ds) for ds in datasets]
        return rasters

    def get_dataset_file_path(self, file_path: str) -> str:
        # Strip `/app` from start if it exists
        if file_path.startswith("/app/"):
            return file_path[4:]  # removes "/app"
        return file_path
