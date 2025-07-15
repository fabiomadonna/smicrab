packages <- c(
  "terra", "logger", "ggplot2", "dplyr", "jsonlite", "tidyverse", "patchwork",
  "PerformanceAnalytics", "DT", "fable", "feasts", "tsibble", "plotly",
  "future", "furrr", "future.apply", "tseries", "doFuture", "doRNG",
  "fabletools", "moments", "htmlwidgets", "zoo", "remotePARTS",
  "trend", "modifiedmk", "rtrend", "MASS", "lmtest", "sandwich", "broom",
  "mclust", "forcats", "pryr", "purrr", "tibble", "tidyr", "stringr",
  "readr", "lubridate", "ggpubr", "cowplot", "viridis", "RColorBrewer"
)

install.packages(setdiff(packages, rownames(installed.packages())), repos = "https://cran.rstudio.com")