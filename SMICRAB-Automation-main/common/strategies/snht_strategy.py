import numpy as np
import pandas as pd
from statsmodels.tsa.stattools import acf

class SNHTStrategy:
    """
    Strategy for applying the Standard Normal Homogeneity Test (SNHT) to homogenize time series data.

    This class implements the SNHT algorithm to detect and correct inhomogeneities (breakpoints)
    in a target time series using a reference time series. It is designed to be configurable
    with a window size for correction calculations and a scaling factor for the SNHT threshold.

    Attributes:
        window_size (int): Window size used for calculating means before and after breakpoints
                             when applying corrections. Default is 24.
        sd_factor (float): Scaling factor applied to the maximum SNHT value of the reference series
                           to determine the threshold for breakpoint detection in the anomaly series.
                           Default is 1.
    """
    def __init__(self, window_size=24, sd_factor=1):
        """
        Initializes the SNHTStrategy with a window size and standard deviation factor.

        Parameters:
            window_size (int, optional): Window size for correction calculations. Defaults to 24.
            sd_factor (float, optional): Scaling factor for SNHT threshold. Defaults to 1.
        """
        self.window_size = window_size
        self.sd_factor = sd_factor

    def homogenize(self, combined, reference):
        """
        Applies SNHT homogenization to a combined time series using a reference series.

        This method detects breakpoints in the anomaly series (difference between the combined
        and reference series) using the SNHT. If breakpoints are detected, it applies corrections
        to the combined series to reduce inhomogeneities.

        Parameters:
            combined (array-like): The target time series to be homogenized. This is typically a
                                   combination of the original data and data from another source
                                   used to fill gaps.
            reference (array-like): The reference time series used for comparison. This should be
                                    a homogeneous series, ideally derived from neighboring stations
                                    or a similar reliable dataset.

        Returns:
            dict: A dictionary containing the results of the homogenization process:
                'corrected_data' (np.ndarray): The homogenized (corrected) time series.
                'original_data' (np.ndarray): The original combined time series.
                'reference_series' (np.ndarray): The reference time series used.
                'breakpoints' (list): A list of indices indicating the detected breakpoints in the
                                      time series.
        """
        # Convert inputs to numpy arrays with explicit NaN handling
        ts = np.array(combined, dtype=np.float64)
        ref = np.array(reference, dtype=np.float64)

        # Early return for insufficient target data
        if np.sum(~np.isnan(ts)) <= self.window_size:
            return {
                "corrected_data": ts,
                "original_data": ts,
                "reference_series": ref,
                "breakpoints": []
            }

        # Validate reference series
        if np.sum(~np.isnan(ref)) < self.window_size or np.all(np.isnan(ref)):
            return {
                "corrected_data": ts,
                "original_data": ts,
                "reference_series": ref,
                "breakpoints": []
            }

        # Calculate anomaly series (difference between target and reference)
        anomaly = ts - ref
        valid_anomaly = anomaly[~np.isnan(anomaly)]

        # Calculate SNHT values for reference series to determine threshold
        ref_valid = ref[~np.isnan(ref)]
        snht_ref = self._calculate_snht(ref_valid)
        snht_ref_max = np.nanmax(snht_ref) if snht_ref.size > 0 else 0

        # Set threshold for breakpoint detection based on scaled max SNHT of reference
        threshold = self.sd_factor * snht_ref_max

        # Detect breakpoints in the anomaly series using the calculated threshold
        breakpoints = self._detect_breakpoints(valid_anomaly, threshold)

        # Apply corrections to the original time series based on detected breakpoints
        ts_corrected = self._apply_corrections(ts, ref, breakpoints)

        return {
            "corrected_data": ts_corrected,
            "original_data": ts,
            "reference_series": ref,
            "breakpoints": breakpoints
        }

    def _calculate_snht(self, ts_data):
        """
        Calculates the Standard Normal Homogeneity Test (SNHT) statistic for a time series.

        The SNHT statistic is calculated for each point in the time series, testing for a potential
        breakpoint at that point by comparing the means of the series before and after the point
        relative to the overall mean and standard deviation.

        Parameters:
            ts_data (np.ndarray): The time series data for which to calculate the SNHT statistic.

        Returns:
            np.ndarray: An array of SNHT statistic values, one for each point in the input time series.
                        Returns an array of NaNs if the input time series has fewer than 2 valid (non-NaN) points.
        """
        ts = np.array(ts_data, dtype=np.float64)
        n = len(ts)

        if n < 2:
            return np.full(n, np.nan)

        mean_total = np.mean(ts)
        sd_total = np.std(ts)

        if sd_total == 0:
            return np.zeros(n)

        Tn = np.zeros(n)
        for k in range(n):
            x1 = ts[:k+1]
            x2 = ts[k+1:]
            mean1 = np.nanmean(x1) if len(x1) > 0 else np.nan
            mean2 = np.nanmean(x2) if len(x2) > 0 else np.nan
            Tn[k] = (((mean1 - mean_total)**2)*(k+1) + ((mean2 - mean_total)**2)*(n-(k+1))) / (sd_total**2)

        return Tn

    def _detect_breakpoints(self, anomaly_data, threshold):
        """
        Detects breakpoints in the anomaly time series based on the SNHT statistic and a threshold.

        Breakpoints are identified as points where the SNHT statistic exceeds the given threshold.
        Consecutive exceedances are grouped, and the first point of each group is considered a
        candidate breakpoint. Breakpoints are then filtered to ensure a minimum separation of 12 time steps.

        Parameters:
            anomaly_data (np.ndarray): The anomaly time series for breakpoint detection.
            threshold (float): The threshold value for the SNHT statistic above which a point is
                               considered a potential breakpoint.

        Returns:
            list: A list of indices indicating the detected breakpoints in the anomaly series.
                   Returns an empty list if no breakpoints are detected or if an error occurs during detection.
        """
        breakpoints = []

        if threshold <= 0:
            return breakpoints

        try:
            snht_vals = self._calculate_snht(anomaly_data)
            exceeding = np.where(snht_vals > threshold)[0]

            if exceeding.size > 0:
                # Group consecutive indices of exceedances
                groups = np.split(exceeding, np.where(np.diff(exceeding) > 1)[0] + 1)
                candidate_bps = [g[0] for g in groups if g.size > 0]

                # Filter breakpoints to ensure minimum separation (12 time steps)
                for bp in candidate_bps:
                    if bp >= len(anomaly_data) - 1:
                        continue
                    if not breakpoints or (bp - breakpoints[-1] >= 12):
                        breakpoints.append(bp)
        except Exception as e:
            # Broad exception catch for robustness in various data scenarios.
            # In production, consider logging the exception for debugging if needed.
            # More specific exception handling could be implemented if particular error types are expected.
            return []

        # Adjust first breakpoint if too close to the start or insert one at the start if needed
        if breakpoints:
            if breakpoints[0] < 12:
                breakpoints[0] = 0 # Adjust first breakpoint to 0 if it's within the first 12 periods
            elif breakpoints[0] > 12:
                breakpoints.insert(0, 0) # Insert a breakpoint at 0 if the first detected is after the 12th period
            # This adjustment ensures that corrections can be applied from the beginning of the series if necessary
            # and handles cases where the first breakpoint is detected early in the series.

        return breakpoints

    def _apply_corrections(self, ts, ref, breakpoints):
        """
        Applies corrections to the original time series based on detected breakpoints.

        For each breakpoint, the method calculates the mean difference in anomalies (ts - ref)
        before and after the breakpoint within a defined window. This difference (innovation)
        is then added to the time series segment between the previous breakpoint (or start of series)
        and the current breakpoint, effectively adjusting the series to reduce the inhomogeneity.

        Parameters:
            ts (np.ndarray): The original time series to be corrected.
            ref (np.ndarray): The reference time series.
            breakpoints (list): A list of indices indicating the detected breakpoints.

        Returns:
            np.ndarray: The corrected time series.
        """
        ts_corrected = ts.copy()

        if not breakpoints:
            return ts_corrected

        for i in reversed(range(len(breakpoints))): # Iterate breakpoints in reverse for correct cumulative correction
            current_bp = breakpoints[i]
            prev_bp = breakpoints[i-1] if i > 0 else 0

            # Validate breakpoint positions to prevent index errors
            if current_bp >= len(ts) or prev_bp >= len(ts):
                continue

            correction_interval = slice(prev_bp, current_bp + 1)

            if prev_bp > 0 and current_bp < len(ts):
                # Calculate window boundaries for mean calculation before and after breakpoint
                win_prev_start = max(0, prev_bp - self.window_size) # Ensure window starts at or after the beginning
                win_prev = slice(win_prev_start, prev_bp)

                win_curr_end = min(len(ts), current_bp + self.window_size) # Ensure window ends at or before the end
                win_curr = slice(current_bp, win_curr_end)

                # Calculate means of (ts - ref) before and after the breakpoint, handling NaNs
                with np.errstate(invalid='ignore'): # Ignore NaN warnings during mean calculation
                    mean_before = np.nanmean(ts[win_prev] - ref[win_prev])
                    mean_after = np.nanmean(ts[win_curr] - ref[win_curr])

                innovation = mean_before - mean_after # Calculate the innovation (correction value)
                if not np.isnan(innovation): # Apply correction only if innovation is not NaN
                    ts_corrected[correction_interval] += innovation

        return ts_corrected