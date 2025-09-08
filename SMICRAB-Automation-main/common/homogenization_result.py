import numpy as np
from dataclasses import dataclass

@dataclass
class BasicHomogenizationResult:
    original: np.ndarray
    corrected: np.ndarray

@dataclass
class SNHTHomogenizationResult:
    original: np.ndarray
    corrected: np.ndarray
    moving_variance: np.ndarray
    acf_original: np.ndarray
    acf_corrected: np.ndarray

@dataclass
class PairwiseHomogenizationResult:
    original: np.ndarray
    corrected: np.ndarray