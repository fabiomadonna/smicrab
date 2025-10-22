
import numpy as np
from dataclasses import dataclass

@dataclass
class DatasetDTO:
    lons: np.ndarray
    lats: np.ndarray
    time: np.ndarray
    data: np.ndarray