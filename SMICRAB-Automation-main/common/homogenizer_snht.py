import numpy as np
from typing import List, Tuple
from dataclasses import dataclass

@dataclass
class SnhtResult:
    """
    Container for homogenization results.

    Attributes:
        corrected: Corrected time series data
        original: Original input time series
        reference: Reference series used for correction
        breakpoints: 1-based indices of detected breakpoints
    """
    corrected: np.ndarray
    original: np.ndarray
    reference: np.ndarray
    breakpoints: List[int]


class SnhtHomogenizer:
    """
    Performs time series homogenization using neighbor reference series and
    the Standard Normal Homogeneity Test (SNHT).

    Args:
        window_size: Size of the window for calculating local means
        min_segment_length: Minimum length between breakpoints (in time units)
    """
    def __init__(self, window_size: int = 24, min_segment_length: int = 12):
        self.window_size = window_size
        self.min_segment_length = min_segment_length

    def homogenize(
        self,
        ts_data: np.ndarray,
        ref_data: np.ndarray,
        sd_factor: float,
        min_valid_points: int = 24,
    ) -> SnhtResult:
        ts_data, ref_data = self._prepare_inputs(ts_data, ref_data)
        valid_mask = self._get_valid_mask(ts_data, ref_data)
        if np.sum(valid_mask) < min_valid_points:
            return self._handle_insufficient_data(ts_data, ref_data)
        return self._process_valid_data(ts_data, ref_data, sd_factor)

    def _prepare_inputs(self, ts_data: np.ndarray, ref_data: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
        ts_data = np.asarray(ts_data, dtype=np.float64)
        ref_data = np.asarray(ref_data, dtype=np.float64)
        if ts_data.shape != ref_data.shape:
            raise ValueError(f"Shape mismatch: {ts_data.shape} vs {ref_data.shape}")
        return ts_data, ref_data

    def _get_valid_mask(self, ts_data: np.ndarray, ref_data: np.ndarray) -> np.ndarray:
        return ~np.isnan(ts_data) & ~np.isnan(ref_data)

    def _handle_insufficient_data(self, ts_data: np.ndarray, ref_data: np.ndarray) -> SnhtResult:
        return SnhtResult(
            corrected=ts_data.copy(),
            original=ts_data.copy(),
            reference=ref_data.copy(),
            breakpoints=[]
        )

    def _process_valid_data(
        self,
        ts_data: np.ndarray,
        ref_data: np.ndarray,
        sd_factor: float,
    ) -> SnhtResult:
        valid_mask = ~(np.isnan(ts_data) | np.isnan(ref_data))
        ts_valid = ts_data[valid_mask]
        ref_valid = ref_data[valid_mask]
        anomaly = ts_valid - ref_valid

        # print("anomaly: ", anomaly)
        # print("np.where(valid_mask)[0]: ", np.where(valid_mask)[0])

        # Compute SNHT on reference and threshold
        ref_snht_max = np.nanmax(self._snht(ref_valid))
        threshold = sd_factor * ref_snht_max

        # Detect breakpoints in anomaly (0-based positions within valid series)
        bps_valid = self._detect_breakpoints(anomaly, threshold)

        # Map valid-series positions to original indices, and convert to 1-based
        original_idx = np.where(valid_mask)[0]
        # breakpoints = (original_idx[bps_valid] - 1).tolist() if bps_valid.size > 0 else []
        breakpoints = original_idx[bps_valid].tolist() if bps_valid.size > 0 else []

        corrected = ts_data.copy()
        if breakpoints:
            corrected = self._apply_corrections(corrected, ref_data, breakpoints)

        return SnhtResult(
            corrected=corrected,
            original=ts_data,
            reference=ref_data,
            breakpoints=breakpoints
        )



    def _detect_breakpoints(self, anomaly: np.ndarray, threshold: float) -> np.ndarray:
        """Detect breakpoints in the anomaly series using SNHT."""
        stats = self._snht(anomaly)
        exceed = np.where(stats > threshold)[0]
        # print("SNHT stats:", stats)
        # print("Exceed indices:", exceed)

        if exceed.size == 0:
            return np.array([], dtype=int)

        groups = np.split(exceed, np.where(np.diff(exceed) > 1)[0] + 1)
        candidates = [grp[0] for grp in groups if grp.size > 0]  # Take first index without shift
        # print("Candidate breakpoints:", candidates)

        bps = []
        n = len(anomaly)
        for bp in candidates:
            if bp == n - 1:  # Exclude last time point, like R
                continue
            if not bps or (bp - bps[-1] >= self.min_segment_length):  # Ensure 12-month gap
                bps.append(bp)
        # print("Selected breakpoints:", bps)

        # Add logic for first breakpoint like in R code
        if bps:
            if bps[0] < self.min_segment_length:
                bps[0] = 0
            elif bps[0] >= self.min_segment_length:
                bps.insert(0, 0)  # Add breakpoint at start

        return np.array(bps, dtype=int)


    def _apply_corrections(
            self,
            ts_data: np.ndarray,
            ref_data: np.ndarray,
            breakpoints: List[int],
    ) -> np.ndarray:
        corrected = ts_data.copy()
        bps0 = [bp for bp in breakpoints]

        for i in range(len(bps0) - 1, -1, -1):
            bp = bps0[i]
            prev = bps0[i - 1] if i > 0 else 0

            if prev > 0:
                innov = self._calculate_innovation(ts_data, ref_data, prev, bp)
            else:
                innov = 0.0

            # print(f"Innovation for segment {prev}-{bp}: {innov}")
            # print(f"Before correction: {corrected[prev:bp + 1]}")

            corrected[prev:bp + 1] += innov

        return corrected


    def _calculate_innovation(
            self,
            ts_data: np.ndarray,
            ref_data: np.ndarray,
            bp_before: int,
            bp_after: int
    ) -> float:
        start_prev = max(0, bp_before - self.window_size - 1)
        end_prev = bp_before - 1  # up to the index before bp_before

        before_segment = ts_data[start_prev:end_prev]
        before_ref = ref_data[start_prev:end_prev]

        # After period: from bp_after - 1 (R equivalent) to (bp_after + window_size - 1)
        start_after = bp_after - 1
        end_after = min(len(ts_data), bp_after + self.window_size - 1)

        after_segment = ts_data[start_after:end_after + 1]  # +1 because end is exclusive in Python
        after_ref = ref_data[start_after:end_after + 1]

        # Calculate innovation
        mean_before = np.nanmean(before_segment) - np.nanmean(before_ref)
        mean_after = np.nanmean(after_segment) - np.nanmean(after_ref)

        return mean_before - mean_after


    def _snht(self, ts_data):
        data = np.asarray(ts_data)
        valid = data[~np.isnan(data)]
        n = len(valid)
        Tn = np.zeros(n)
        if n < 2:
            return np.full(len(data), np.nan)
        mean_tot = np.mean(valid)
        var_tot = np.var(valid, ddof=1)
        for k in range(n):
            x1 = valid[:k] if k > 0 else valid[:1]
            x2 = valid[k:] if k < n else valid[-1:]
            Tn[k] = (k * (np.mean(x1) - mean_tot) ** 2 + (n - k) * (
                        np.mean(x2) - mean_tot) ** 2) / var_tot if k > 0 and k < n else 0
        return Tn


