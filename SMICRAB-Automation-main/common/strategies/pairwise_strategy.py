import numpy as np

class PairwiseStrategy:
    def __init__(self, radius=15, threshold_factor=3, window_size=24):
        """
        Initialize the PairwiseStrategy with desired parameters.

        Parameters:
            radius (int): The search radius (in grid cells) for valid neighbors.
            threshold_factor (float): Factor to multiply the standard deviation
                                      of differences for thresholding.
            window_size (int): Number of time steps to consider on each side for
                               computing local means.
        """
        self.radius = radius
        self.threshold_factor = threshold_factor
        self.window_size = window_size

    def find_valid_neighbors(self, data_e, i, j, lon, lat, expected_length):
        """
        Find neighbor time series within a given radius (grid cells).

        Parameters:
            data_e (np.array): The reference data array with shape (lon, lat, time).
            i (int): The longitude index of the target grid cell.
            j (int): The latitude index of the target grid cell.
            lon (np.array): The longitude coordinates.
            lat (np.array): The latitude coordinates.
            expected_length (int): Expected length of the time series.

        Returns:
            list: A list of neighbor time series arrays.
        """
        lon_len = len(lon)
        lat_len = len(lat)
        lon_indices = range(max(0, i - self.radius), min(lon_len, i + self.radius + 1))
        lat_indices = range(max(0, j - self.radius), min(lat_len, j + self.radius + 1))

        neighbors = []
        for ii in lon_indices:
            for jj in lat_indices:
                if not (ii == i and jj == j):
                    neighbor_series = data_e[ii, jj, :]
                    if not np.isnan(neighbor_series).all() and len(neighbor_series) == expected_length:
                        neighbors.append(neighbor_series)
        return neighbors

    def compute_pairwise_correction(self, series, neighbors):
        """
        Compute pairwise correction for a time series based on its neighbors.

        Parameters:
            series (np.array): The target time series.
            neighbors (list): List of neighbor time series.

        Returns:
            dict: A dictionary with the following keys:
                  - corrections: the computed corrections.
                  - corrected_series: the adjusted time series.
                  - original_series: the input time series.
                  - neighbor_means: the computed mean of neighbors at each time step.
                  - breakpoints: the detected breakpoints.
        """
        corrections = np.zeros(len(series))
        neighbor_means = np.zeros(len(series))

        # Compute neighbor means at each time step.
        for t in range(len(series)):
            neighbor_values = [n[t] for n in neighbors if not np.isnan(n[t])]
            neighbor_means[t] = np.mean(neighbor_values) if neighbor_values else np.nan

        differences = series - neighbor_means
        sd_differences = np.nanstd(differences)
        threshold = self.threshold_factor * sd_differences

        # Identify indices where difference exceeds threshold.
        exceeding_indices = np.where((np.abs(differences) > threshold) & (~np.isnan(differences)))[0]
        breakpoints = []
        if len(exceeding_indices) > 0:
            intervals = np.split(exceeding_indices, np.where(np.diff(exceeding_indices) > 1)[0] + 1)
            candidate_breakpoints = [group[0] for group in intervals]
            for current_bp in candidate_breakpoints:
                if current_bp == len(series):
                    continue
                if not breakpoints or (current_bp - breakpoints[-1] >= 12):
                    if breakpoints:
                        previous_bp = breakpoints[-1]
                        subset_differences = differences[previous_bp:current_bp]
                        if len(subset_differences) > 0 and np.any((~np.isnan(subset_differences)) &
                                                                  (np.abs(subset_differences) < threshold)):
                            breakpoints.append(current_bp)
                    else:
                        breakpoints.append(current_bp)
        if breakpoints:
            if breakpoints[0] < 12:
                breakpoints[0] = 0
            elif breakpoints[0] > 12:
                breakpoints.insert(0, 0)

        corrected_series = series.copy()
        if len(breakpoints) > 1:
            for idx in reversed(range(1, len(breakpoints))):
                current_bp = breakpoints[idx]
                previous_bp = breakpoints[idx - 1]
                correction_interval = slice(previous_bp, current_bp)
                if previous_bp > 0:
                    start_prev = max(0, previous_bp - self.window_size)
                    mean_before = np.nanmean(series[start_prev:previous_bp])
                    mean_ref_before = np.nanmean(neighbor_means[start_prev:previous_bp])
                    end_curr = min(len(series), current_bp + self.window_size)
                    mean_after = np.nanmean(series[current_bp:end_curr])
                    mean_ref_after = np.nanmean(neighbor_means[current_bp:end_curr])
                    innovation = (mean_before - mean_ref_before) - (mean_after - mean_ref_after)
                else:
                    innovation = 0
                corrected_series[correction_interval] += innovation

        corrections = corrected_series - series
        return {
            "corrections": corrections,
            "corrected_series": corrected_series,
            "original_series": series,
            "neighbor_means": neighbor_means,
            "breakpoints": breakpoints
        }

    def execute(self, series, data_e, i, j, lon, lat, expected_length):
        """
        Execute the pairwise homogenization strategy:
          1. Identify valid neighbors for the grid cell at indices (i, j).
          2. Compute the correction for the provided time series.

        Parameters:
            series (np.array): The target time series at grid cell (i, j).
            data_e (np.array): The reference data array (e.g., ERA5 interpolated data).
            i (int): The longitude index of the target grid cell.
            j (int): The latitude index of the target grid cell.
            lon (np.array): The longitude coordinates.
            lat (np.array): The latitude coordinates.
            expected_length (int): The expected length of the time series.

        Returns:
            dict: Correction result from compute_pairwise_correction().
        """
        neighbors = self.find_valid_neighbors(data_e, i, j, lon, lat, expected_length)
        return self.compute_pairwise_correction(series, neighbors)
