FROM python:3.12-slim

# Install R + system dependencies
RUN apt-get update && apt-get install -y \
    r-base r-base-dev libcurl4-openssl-dev libssl-dev libxml2-dev \
    build-essential gfortran libnetcdf-dev libhdf5-dev libblas-dev \
    liblapack-dev libopenmpi-dev libeccodes-dev libproj-dev libgeos-dev \
    libgdal-dev curl \
    libfontconfig1-dev libfreetype6-dev libharfbuzz-dev libfribidi-dev libpng-dev pandoc \
    libfftw3-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c( \
    'terra', 'ggplot2', 'dplyr', 'jsonlite', 'tidyverse', 'patchwork', \
    'PerformanceAnalytics', 'DT', 'fable', 'feasts', 'tsibble', 'plotly', \
    'future', 'furrr', 'future.apply', 'tseries', 'doFuture', 'doRNG', \
    'fabletools', 'moments', 'htmlwidgets', 'zoo', 'logger', 'remotePARTS', \
    'trend', 'modifiedmk', 'rtrend', 'MASS', 'lmtest', 'sandwich', 'broom', \
    'mclust', 'forcats', 'pryr', 'purrr', 'tibble', 'tidyr', 'stringr', \
    'readr', 'lubridate', 'ggpubr', 'cowplot', 'viridis', 'RColorBrewer' \
    ), \
    repos='https://cran.rstudio.com', dependencies=TRUE)"

# Install Python packages
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy rest of the app
COPY . .

# Create folders
RUN mkdir -p logs tmp/analysis datasets

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]