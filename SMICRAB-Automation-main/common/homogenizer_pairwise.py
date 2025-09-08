import numpy as np
from typing import List, Union
import logging
from dataclasses import dataclass

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

@dataclass
class PairwiseResult:
    """Class for storing the results of pairwise time series homogenization."""
    corrections: np.ndarray
    corrected_series: np.ndarray
    original_series: np.ndarray
    neighbor_means: np.ndarray
    breakpoints: List[int]


class PairwiseHomogenizer:
    """
    Class for homogenizing time series data using pairwise comparison with neighboring series.
    
    This homogenizer identifies breakpoints where a series significantly deviates from 
    neighbor means, then applies corrections to segments between breakpoints to adjust for
    systematic differences.
    """
    
    def __init__(self, threshold_factor: float = 3, window_size: int = 24):
        """
        Initialize the homogenizer with parameters.
        
        Parameters:
        -----------
        threshold_factor : float, default=3
            Factor to multiply standard deviation for threshold calculation
        window_size : int, default=24
            Size of the window used for calculating means before/after breakpoints
        """
        self.threshold_factor = threshold_factor
        self.window_size = window_size
        self.logger = logger
    
    def homogenize(self, 
                  series: Union[List[float], np.ndarray], 
                  neighbors: List[Union[List[float], np.ndarray]]) -> PairwiseResult:
        """
        Homogenize a time series using information from neighboring series.
        
        Parameters:
        -----------
        series : array-like
            The main time series to be corrected
        neighbors : list of array-like
            List of neighboring time series used as reference
            
        Returns:
        --------
        PairwiseResult
            Object containing corrected series and metadata
        """
        # Convert inputs to numpy arrays for consistency
        series = np.array(series, dtype=float)
        n = len(series)
        
        # Calculate neighbor means
        neighbor_means = self._calculate_neighbor_means(series, neighbors)
        
        # Identify breakpoints
        breakpoints = self._identify_breakpoints(series, neighbor_means)
        
        # Apply corrections based on breakpoints
        corrected_series, corrections = self._apply_corrections(
            series, neighbor_means, breakpoints
        )
        
        # Create and return result object
        result = PairwiseResult(
            corrections=corrections,
            corrected_series=corrected_series,
            original_series=series,
            neighbor_means=neighbor_means,
            breakpoints=breakpoints
        )
        
        # self.logger.info(f"Homogenization complete. Found {len(breakpoints)} breakpoints.")
        return result
    
    def _calculate_neighbor_means(self, 
                                 series: np.ndarray, 
                                 neighbors: List[Union[List[float], np.ndarray]]) -> np.ndarray:
        """
        Calculate mean values of neighbors for each time point.
        
        Parameters:
        -----------
        series : np.ndarray
            The main time series
        neighbors : list of array-like
            List of neighboring time series
            
        Returns:
        --------
        np.ndarray
            Array of neighbor mean values at each time point
        """
        n = len(series)
        neighbor_means = np.full(n, np.nan)

        for t in range(n):
            # Get the t-th element from each neighbor, skipping out-of-bounds and NaNs
            neighbor_values = []
            for nbs in neighbors:
                if t < len(nbs) and not np.isnan(nbs[t]):
                    neighbor_values.append(nbs[t])
            
            neighbor_values = np.array(neighbor_values)
            if neighbor_values.size > 0:
                neighbor_means[t] = np.mean(neighbor_values)
        
        return neighbor_means
    
    def _identify_breakpoints(self, 
                             series: np.ndarray, 
                             neighbor_means: np.ndarray) -> List[int]:
        """
        Identify breakpoints where series significantly deviates from neighbor means.
        
        Parameters:
        -----------
        series : np.ndarray
            The main time series
        neighbor_means : np.ndarray
            Mean values of neighbors at each time point
            
        Returns:
        --------
        list
            List of identified breakpoint indices
        """
        n = len(series)
        differences = series - neighbor_means
        sd_differences = np.nanstd(differences)
        threshold = self.threshold_factor * sd_differences
        
        # Find indices exceeding threshold
        exceeding_indices = np.where((np.abs(differences) > threshold) & 
                                    (~np.isnan(differences)))[0]
        
        breakpoints = []
        if exceeding_indices.size > 0:
            # Group consecutive indices
            groups = self._group_consecutive_indices(exceeding_indices)
            
            # Get first index of each group as candidate breakpoint
            candidate_breakpoints = [group[0] for group in groups]
            
            # Evaluate candidates
            breakpoints = self._evaluate_breakpoint_candidates(
                candidate_breakpoints, differences, threshold, n
            )
        
        # Ensure there's always at least one breakpoint at the beginning
        if not breakpoints:
            breakpoints = [0]
        elif min(breakpoints) < 12:
            breakpoints[0] = 0
        elif min(breakpoints) > 12:
            breakpoints = [0] + breakpoints
        
        # self.logger.info(f"Identified breakpoints: {breakpoints}")
        return breakpoints
    
    def _group_consecutive_indices(self, indices: np.ndarray) -> List[List[int]]:
        """Group consecutive indices together."""
        if len(indices) == 0:
            return []
            
        groups = []
        current_group = [indices[0]]
        
        for idx in indices[1:]:
            if idx - current_group[-1] > 1:
                groups.append(current_group)
                current_group = [idx]
            else:
                current_group.append(idx)
        
        groups.append(current_group)
        return groups
    
    def _evaluate_breakpoint_candidates(self,
                                       candidates: List[int], 
                                       differences: np.ndarray, 
                                       threshold: float, 
                                       n: int) -> List[int]:
        """Evaluate candidate breakpoints based on criteria."""
        breakpoints = []
        
        for current_bp in candidates:
            # Skip if breakpoint is at the end of series
            if current_bp == n - 1:
                continue
                
            if len(breakpoints) == 0 or (current_bp - breakpoints[-1] >= 12):
                if breakpoints:
                    previous_bp = breakpoints[-1]
                    subset_diff = differences[previous_bp:current_bp+1]
                    
                    # Check if any value in subset is below threshold
                    if subset_diff.size > 0 and np.any(
                        (~np.isnan(subset_diff)) & (np.abs(subset_diff) < threshold)
                    ):
                        breakpoints.append(current_bp)
                else:
                    breakpoints.append(current_bp)
                    
        return breakpoints
    
    def _apply_corrections(self,
                          series: np.ndarray, 
                          neighbor_means: np.ndarray, 
                          breakpoints: List[int]) -> tuple:
        """
        Apply corrections to series segments based on identified breakpoints.
        
        Parameters:
        -----------
        series : np.ndarray
            Original time series
        neighbor_means : np.ndarray
            Mean values of neighbors
        breakpoints : list
            List of breakpoint indices
            
        Returns:
        --------
        tuple
            (corrected_series, corrections)
        """
        n = len(series)
        corrected_series = series.copy()
        
        if len(breakpoints) > 1:
            # Process breakpoints from end to beginning
            for i in range(len(breakpoints) - 1, 0, -1):
                current_bp = breakpoints[i]
                previous_bp = breakpoints[i - 1]
                correction_slice = slice(previous_bp, current_bp + 1)
                
                innovation = self._calculate_innovation(
                    series, neighbor_means, previous_bp, current_bp, n
                )
                
                # Apply correction
                corrected_series[correction_slice] += innovation
        
        corrections = corrected_series - series
        return corrected_series, corrections
    
    def _calculate_innovation(self,
                             series: np.ndarray, 
                             neighbor_means: np.ndarray, 
                             previous_bp: int, 
                             current_bp: int, 
                             n: int) -> float:
        """Calculate innovation value for correction."""
        if previous_bp <= 0:
            return 0.0
            
        # Calculate means before breakpoint
        start_prev = max(0, previous_bp - self.window_size)
        mean_before = np.nanmean(series[start_prev:previous_bp])
        mean_ref_before = np.nanmean(neighbor_means[start_prev:previous_bp])
        
        # Calculate means after breakpoint
        end_curr = min(n, current_bp + self.window_size + 1)
        mean_after = np.nanmean(series[current_bp:end_curr])
        mean_ref_after = np.nanmean(neighbor_means[current_bp:end_curr])
        
        # Calculate innovation
        innovation = (mean_before - mean_ref_before) - (mean_after - mean_ref_after)

        if np.isnan(innovation):
            innovation = 0.0

        return innovation
