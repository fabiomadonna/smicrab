#!/usr/bin/env python3
"""
SMICRAB Dataset Table Creator
=============================

This script reads NetCDF files from the datasets directory and inserts 
metadata into the PostgreSQL datasets table.

Usage:
    python scripts/create_datasets_table.py

Required Environment Variables:
    - POSTGRES_URL (optional, defaults to local PostgreSQL)

Author: SMICRAB Team
Date: 2025
"""

import os
import sys
import logging
import re
from pathlib import Path
from typing import Dict, List, Any, Optional, Tuple
from datetime import datetime
import numpy as np
import pandas as pd
import xarray as xr
import psycopg2
from psycopg2.extras import RealDictCursor, Json
from sqlalchemy import create_engine, text
import uuid
from dotenv import load_dotenv

load_dotenv()

# Setup logging
log_level = os.getenv("LOG_LEVEL", "INFO").upper()
log_file = os.getenv("LOG_FILE", "dataset_processor.log")

logging.basicConfig(
    level=getattr(logging, log_level),
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler(sys.stdout), logging.FileHandler(log_file)],
)
logger = logging.getLogger(__name__)

# Database configuration
DATABASE_CONFIG = {
    "host": os.getenv("POSTGRES_HOST", "postgres"),
    "port": int(os.getenv("POSTGRES_PORT", 5432)),
    "database": os.getenv("POSTGRES_DB", "smicrab"),
    "user": os.getenv("POSTGRES_USER", "smicrab_user"),
    "password": os.getenv("POSTGRES_PASSWORD", "smicrab_password"),
}

# Dataset directory
DATASETS_DIR = Path(__file__).parent.parent.parent / "datasets"


class DatasetProcessor:
    """Processes NetCDF datasets and populates PostgreSQL database."""

    def __init__(self):
        self.db_url = self._build_db_url()
        self.engine = None
        self.datasets_metadata = []

    def _build_db_url(self) -> str:
        """Build PostgreSQL connection URL."""
        return (
            f"postgresql://{DATABASE_CONFIG['user']}:{DATABASE_CONFIG['password']}@"
            f"{DATABASE_CONFIG['host']}:{DATABASE_CONFIG['port']}/{DATABASE_CONFIG['database']}"
        )

    def connect_database(self) -> bool:
        """Connect to PostgreSQL database."""
        try:
            self.engine = create_engine(self.db_url)
            # Test connection
            with self.engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            logger.info("Successfully connected to PostgreSQL database")
            return True
        except Exception as e:
            logger.error(f"Failed to connect to PostgreSQL: {e}")
            return False

def insert_datasets_to_db(self) -> bool:
    """Insert processed datasets metadata into PostgreSQL."""
    import numpy as np
    from psycopg2.extras import Json

    def sanitize_json(data):
        """Convert NumPy types to native Python types for JSON serialization"""
        if isinstance(data, dict):
            return {k: sanitize_json(v) for k, v in data.items()}
        elif isinstance(data, list):
            return [sanitize_json(v) for v in data]
        elif isinstance(data, np.generic):
            return data.item()
        else:
            return data

    try:
        if not self.datasets_metadata:
            logger.warning("WARNING: No datasets metadata to insert")
            return False

        insert_query = """
        INSERT INTO datasets (
            id, name, raster, variable_name, from_timestamp, to_timestamp,
            longitude_from, longitude_to, latitude_from, latitude_to,
            frequency, grid_resolution, file_path, file_size_mb,
            dimensions, data_vars, time_coords
        ) VALUES (
            %(id)s, %(name)s, %(raster)s, %(variable_name)s, %(from_timestamp)s, %(to_timestamp)s,
            %(longitude_from)s, %(longitude_to)s, %(latitude_from)s, %(latitude_to)s,
            %(frequency)s, %(grid_resolution)s, %(file_path)s, %(file_size_mb)s,
            %(dimensions)s, %(data_vars)s, %(time_coords)s
        )
        ON CONFLICT (variable_name) DO NOTHING
        """

        conn = psycopg2.connect(**DATABASE_CONFIG)
        conn.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT)
        cur = conn.cursor()

        inserted_count = 0
        skipped_count = 0

        for metadata in self.datasets_metadata:
            try:
                metadata['grid_resolution'] = str(metadata.get('grid_resolution', '0.1'))

                for ts_key in ['from_timestamp', 'to_timestamp']:
                    if not isinstance(metadata[ts_key], datetime):
                        metadata[ts_key] = pd.to_datetime(metadata[ts_key]).to_pydatetime()

                metadata_copy = metadata.copy()
                metadata_copy["dimensions"] = Json(sanitize_json(metadata["dimensions"]))
                metadata_copy["data_vars"] = Json(sanitize_json(metadata["data_vars"]))
                metadata_copy["time_coords"] = Json(sanitize_json(metadata["time_coords"]))

                try:
                    cur.execute(insert_query, metadata_copy)
                    if cur.rowcount > 0:
                        inserted_count += 1
                        logger.debug(f"Inserted: {metadata['variable_name']} from {metadata['name']}")
                    else:
                        skipped_count += 1
                        logger.debug(f"Skipped (already exists): {metadata['variable_name']} from {metadata['name']}")
                except psycopg2.Error as db_error:
                    logger.error(f"Database error for {metadata.get('variable_name', 'unknown')}: {db_error}")
                    continue

            except Exception as var_error:
                logger.error(f"Error processing variable {metadata.get('variable_name', 'unknown')}: {var_error}")
                continue

        cur.close()
        conn.close()

        logger.info(f"Database operation completed: {inserted_count} variables processed, {skipped_count} skipped")
        logger.info(f"Successfully processed {len(self.datasets_metadata)} data variables")
        return True

    except Exception as e:
        logger.error(f"Failed to insert datasets into database: {e}")
        return False


    def extract_dataset_metadata(self, file_path: Path) -> List[Dict[str, Any]]:
        """Extract metadata from a NetCDF file using xarray, creating one record per data variable."""
        try:
            logger.info(f"Processing: {file_path.name}")

            # Open dataset with xarray
            with xr.open_dataset(file_path, decode_times=True) as ds:
                # Get file size in MB
                file_size_mb = file_path.stat().st_size / (1024 * 1024)

                # Extract coordinate information
                coords = self._extract_coordinates(ds, file_path.name)

                # Extract time information as timestamps
                time_info = self._extract_time_info(ds, file_path.name)

                # Extract data variables (excluding coordinates)
                data_vars = list(ds.data_vars.keys())
                main_variable_from_filename = self._identify_main_variable(
                    ds, data_vars, file_path.name
                )

                # Determine grid resolution
                grid_resolution = self._calculate_grid_resolution(ds)

                # Use detected frequency from time coordinate or fallback to filename
                frequency = time_info["time_coords"].get(
                    "frequency_detected", self._determine_frequency(ds, file_path.name)
                )

                # Extract raster identifier
                raster_id = self._extract_raster_id(file_path.name)

                # Create one record per data variable
                variable_records = []

                for var_name in ds.data_vars:
                    var_data = ds[var_name]

                    # Convert any numpy arrays in attributes to lists for JSON serialization
                    clean_attrs = {}
                    for k, v in var_data.attrs.items():
                        if isinstance(v, np.ndarray):
                            clean_attrs[k] = v.tolist()
                        else:
                            clean_attrs[k] = v

                    # Handle combined_uncertainty renaming
                    processed_var_name = self._process_variable_name(
                        var_name, ds, main_variable_from_filename
                    )

                    # Create variable-specific metadata
                    var_metadata = {
                        "name": var_name,
                        "dims": list(var_data.dims),
                        "shape": list(var_data.shape),
                        "dtype": str(var_data.dtype),
                        "attributes": clean_attrs,
                        "long_name": var_data.attrs.get("long_name", var_name),
                        "standard_name": var_data.attrs.get("standard_name", ""),
                        "units": var_data.attrs.get("units", ""),
                        "description": var_data.attrs.get("description", ""),
                    }

                    record = {
                        "id": str(uuid.uuid4()),
                        "name": file_path.stem,
                        "raster": raster_id,
                        "variable_name": processed_var_name,
                        "from_timestamp": time_info["from_timestamp"],
                        "to_timestamp": time_info["to_timestamp"],
                        "longitude_from": coords["longitude_from"],
                        "longitude_to": coords["longitude_to"],
                        "latitude_from": coords["latitude_from"],
                        "latitude_to": coords["latitude_to"],
                        "frequency": frequency,
                        "grid_resolution": grid_resolution,
                        "file_path": str(file_path),
                        "file_size_mb": round(file_size_mb, 2),
                        "dimensions": dict(ds.sizes),
                        "data_vars": {
                            var_name: var_metadata
                        },  # Single variable metadata
                        "time_coords": time_info["time_coords"],
                    }

                    variable_records.append(record)
                    logger.info(
                        f"   Extracted variable: {processed_var_name} (original: {var_name})"
                    )

                logger.info(
                    f"Successfully processed: {file_path.name} with {len(variable_records)} variables"
                )
                logger.info(
                    f"   Time range: {time_info['from_timestamp']} to {time_info['to_timestamp']}"
                )
                return variable_records

        except Exception as e:
            logger.error(f"Failed to process {file_path.name}: {e}")
            return []

    def _extract_coordinates(self, ds: xr.Dataset, filename: str) -> Dict[str, float]:
        """Extract coordinate bounds from dataset."""
        coords = {
            "longitude_from": 0.0,
            "longitude_to": 0.0,
            "latitude_from": 0.0,
            "latitude_to": 0.0,
        }

        # Extract longitude
        for lon_name in ["longitude", "lon", "x"]:
            if lon_name in ds.coords:
                lon_values = ds.coords[lon_name].values
                coords["longitude_from"] = float(np.min(lon_values))
                coords["longitude_to"] = float(np.max(lon_values))
                break

        # Extract latitude
        for lat_name in ["latitude", "lat", "y"]:
            if lat_name in ds.coords:
                lat_values = ds.coords[lat_name].values
                coords["latitude_from"] = float(np.min(lat_values))
                coords["latitude_to"] = float(np.max(lat_values))
                break

        return coords

    def _extract_time_info(self, ds: xr.Dataset, filename: str) -> Dict[str, Any]:
        """Extract time range information from dataset as timestamps."""
        try:
            time_coord = None
            for coord in ["time", "Time", "TIME", "t"]:
                if coord in ds.coords:
                    time_coord = coord
                    break

            if time_coord:
                time_values = ds.coords[time_coord]
                # Convert to pandas datetime for easier handling
                time_pd = pd.to_datetime(time_values.values)

                # Get actual timestamps
                from_timestamp = time_pd.min()
                to_timestamp = time_pd.max()

                # Store additional time coordinate info
                time_coords_info = {
                    "coordinate_name": time_coord,
                    "total_timesteps": len(time_values),
                    "time_units": getattr(time_values, "units", "unknown"),
                    "calendar": getattr(time_values, "calendar", "standard"),
                    "first_value": str(time_pd.min()),
                    "last_value": str(time_pd.max()),
                    "frequency_detected": self._detect_time_frequency(time_pd),
                }

                logger.info(
                    f"   Time range: {from_timestamp} to {to_timestamp} ({len(time_values)} timesteps)"
                )

            else:
                # Fallback to filename parsing if no time coordinate
                logger.warning(
                    f"No time coordinate found in {filename}, using filename dates"
                )
                from_date_str, to_date_str = self._extract_dates_from_filename(filename)
                from_timestamp = pd.to_datetime(from_date_str)
                to_timestamp = pd.to_datetime(to_date_str)

                time_coords_info = {
                    "coordinate_name": "none",
                    "source": "filename",
                    "from_filename": from_date_str,
                    "to_filename": to_date_str,
                }

            return {
                "from_timestamp": from_timestamp,
                "to_timestamp": to_timestamp,
                "time_coords": time_coords_info,
            }

        except Exception as e:
            logger.error(f"Could not extract time info from {filename}: {e}")
            # Return default timestamps
            default_from = pd.to_datetime("2011-01-01")
            default_to = pd.to_datetime("2023-12-31")
            return {
                "from_timestamp": default_from,
                "to_timestamp": default_to,
                "time_coords": {"error": str(e), "source": "default"},
            }

    def _extract_dates_from_filename(self, filename: str) -> Tuple[str, str]:
        """Extract date range from filename."""
        date_pattern = r"(\d{4})[-_](\d{4})"
        match = re.search(date_pattern, filename)

        if match:
            start_year, end_year = match.groups()
            return f"{start_year}-01-01", f"{end_year}-12-31"

        return "2011-01-01", "2023-12-31"

    def _identify_main_variable(
        self, ds: xr.Dataset, data_vars: List[str], filename: str
    ) -> str:
        """Identify the main data variable."""
        if not data_vars:
            return "unknown_variable"

        variable_mapping = {
            "LST": "land_surface_temperature",
            "SAL": "surface_solar_radiation",
            "fg": "wind_speed_mean",
            "tx": "air_temperature_max",
            "tn": "air_temperature_min",
            "tg": "air_temperature_mean",
            "rr": "precipitation_amount",
            "hu": "relative_humidity",
            "qq": "specific_humidity",
            "pp": "surface_air_pressure",
        }

        filename_lower = filename.lower()
        for key, var_name in variable_mapping.items():
            if key.lower() in filename_lower:
                return var_name

        return data_vars[0]

    def _calculate_grid_resolution(self, ds: xr.Dataset) -> float:
        """Calculate grid resolution from coordinates."""
        try:
            for coord_name in ["longitude", "lon"]:
                if coord_name in ds.coords:
                    coord_vals = ds.coords[coord_name].values
                    if len(coord_vals) > 1:
                        return round(float(np.abs(coord_vals[1] - coord_vals[0])), 6)

            for coord_name in ["latitude", "lat"]:
                if coord_name in ds.coords:
                    coord_vals = ds.coords[coord_name].values
                    if len(coord_vals) > 1:
                        return round(float(np.abs(coord_vals[1] - coord_vals[0])), 6)

            return 0.1
        except:
            return 0.1

    def _determine_frequency(self, ds: xr.Dataset, filename: str) -> str:
        """Determine data frequency."""
        filename_lower = filename.lower()

        if "monthly_per_hour" in filename_lower or "per_hour" in filename_lower:
            return "monthly_per_hour"
        elif "monthly" in filename_lower:
            return "monthly"
        elif "daily" in filename_lower:
            return "daily"
        elif "hourly" in filename_lower:
            return "hourly"
        else:
            return "monthly"

    def _extract_raster_id(self, filename: str) -> str:
        """Extract raster identifier from filename."""
        return filename.replace(".nc", "").replace(".NC", "")

    def _process_variable_name(
        self, var_name: str, ds: xr.Dataset, main_variable_from_filename: str
    ) -> str:
        """Process variable name, handling special cases like combined_uncertainty."""
        if var_name == "combined_uncertainty":
            # Find the main data variable to create uncertainty name
            main_var_in_dataset = None

            # Look for the main variable in the dataset
            for dataset_var in ds.data_vars:
                if dataset_var != "combined_uncertainty":
                    # Get the actual variable name from the dataset
                    var_standard_name = ds[dataset_var].attrs.get("standard_name", "")
                    var_long_name = ds[dataset_var].attrs.get("long_name", "")

                    # Try to match with filename-based main variable or use first non-uncertainty variable
                    if (
                        main_variable_from_filename in var_standard_name.lower()
                        or main_variable_from_filename in var_long_name.lower()
                        or main_var_in_dataset is None
                    ):
                        main_var_in_dataset = dataset_var
                        break

            if main_var_in_dataset:
                return f"{main_var_in_dataset}_uncertainty"
            else:
                # Fallback to filename-based naming
                filename_to_var = {
                    "tn": "minimum_air_temperature",
                    "tx": "maximum_air_temperature",
                    "tg": "mean_air_temperature",
                    "rr": "precipitation",
                    "hu": "relative_humidity",
                    "pp": "air_pressure",
                    "qq": "specific_humidity",
                    "fg": "wind_speed",
                }

                for key, var_name_part in filename_to_var.items():
                    if key in main_variable_from_filename:
                        return f"{var_name_part}_uncertainty"

                return f"{main_variable_from_filename}_uncertainty"

        return var_name

    def _detect_time_frequency(self, time_pd: pd.DatetimeIndex) -> str:
        """Detect time frequency from pandas datetime index."""
        try:
            if len(time_pd) < 2:
                return "single_timestep"

            # Calculate time differences
            time_diffs = pd.Series(time_pd).diff().dropna()
            avg_diff = time_diffs.mean()

            # Get unique hours and days to detect monthly_per_hour pattern
            unique_hours = set(t.hour for t in time_pd)
            unique_days = set(t.day for t in time_pd)
            unique_months = set(t.month for t in time_pd)

            # Detect monthly_per_hour pattern (multiple hours within each month)
            if (
                avg_diff <= pd.Timedelta(hours=2)
                and len(unique_months) > 1
                and len(unique_hours) > 1
            ):
                return "monthly_per_hour"

            # Detect frequency based on average difference
            if avg_diff <= pd.Timedelta(hours=1):
                return "hourly"
            elif avg_diff <= pd.Timedelta(days=1):
                return "daily"
            elif avg_diff <= pd.Timedelta(days=7):
                return "weekly"
            elif avg_diff <= pd.Timedelta(days=32):
                return "monthly"
            elif avg_diff <= pd.Timedelta(days=95):
                return "quarterly"
            else:
                return "yearly"

        except Exception as e:
            logger.warning(f"Could not detect time frequency: {e}")
            return "unknown"

    def process_all_datasets(self) -> bool:
        """Process all NetCDF files in the datasets directory."""
        try:
            if not DATASETS_DIR.exists():
                logger.error(f"ERROR: Datasets directory not found: {DATASETS_DIR}")
                return False

            nc_files = list(DATASETS_DIR.glob("*.nc")) + list(DATASETS_DIR.glob("*.NC"))

            if not nc_files:
                logger.warning("WARNING: No NetCDF files found in datasets directory")
                return False

            logger.info(f"Found {len(nc_files)} NetCDF files to process")

            for nc_file in nc_files:
                variable_records = self.extract_dataset_metadata(nc_file)
                if variable_records:
                    self.datasets_metadata.extend(variable_records)

            logger.info(
                f"Successfully processed {len(self.datasets_metadata)} data variables from {len(nc_files)} NetCDF files"
            )
            return True

        except Exception as e:
            logger.error(f"Failed to process datasets: {e}")
            return False

    def verify_data(self) -> bool:
        """Verify inserted data by querying the database."""
        try:
            with self.engine.connect() as conn:
                result = conn.execute(text("SELECT COUNT(*) as count FROM datasets"))
                count = result.fetchone()[0]

                if count > 0:
                    logger.info(
                        f"Database verification successful: {count} data variables found"
                    )

                    sample_query = """
                    SELECT name, variable_name, frequency, grid_resolution, 
                           from_timestamp, to_timestamp, file_size_mb
                    FROM datasets 
                    ORDER BY name 
                    LIMIT 5
                    """
                    result = conn.execute(text(sample_query))

                    logger.info("Sample data variables:")
                    for row in result:
                        logger.info(
                            f"   {row[0]} | {row[1]} | {row[2]} | {row[3]}° | {row[4]} to {row[5]} | {row[6]}MB"
                        )

                    return True
                else:
                    logger.error("No data variables found in database")
                    return False
        except Exception as e:
            logger.error(f"Database verification failed: {e}")
            return False

    def run(self) -> bool:
        """Run the complete dataset processing pipeline."""
        logger.info("Starting SMICRAB Dataset Processor")
        logger.info("=" * 60)
        logger.info(
            f"Database: {DATABASE_CONFIG['database']}@{DATABASE_CONFIG['host']}:{DATABASE_CONFIG['port']}"
        )
        logger.info(f"User: {DATABASE_CONFIG['user']}")
        logger.info(f"Datasets directory: {DATASETS_DIR}")

        if not self.connect_database():
            return False

        if not self.process_all_datasets():
            return False

        if not self.insert_datasets_to_db():
            return False

        if not self.verify_data():
            return False

        logger.info("=" * 60)
        logger.info("Dataset processing completed successfully!")
        return True


def main():
    """Main function."""
    processor = DatasetProcessor()
    success = processor.run()

    if success:
        logger.info("All operations completed successfully")
        sys.exit(0)
    else:
        logger.error("Processing failed")
        sys.exit(1)


if __name__ == "__main__":
    main()
