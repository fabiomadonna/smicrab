# ==============================================================================
# SMICRAB Model Analysis - Common Setup
# This file contains all common libraries, functions, and parameter initialization
# ==============================================================================


if (!requireNamespace("jsonlite", quietly = TRUE)) {
  install.packages("jsonlite", repos = "https://cran.rstudio.com")
}

# Load jsonlite to parse params
library(jsonlite)

# Read parameters
args <- commandArgs(trailingOnly = TRUE)
if (length(args) > 0) {
  param_path <- args[1]
  params <- fromJSON(param_path)
} else {
  params <- fromJSON('{
    "analysis_id": "769cdd08-20e9-4706-a62a-5f279aed845e",
    "model_type": "Model6_HSDPD_user"
  }')
  # stop("No parameters provided.")
}

model_type <- params$model_type

# Define base packages for all models
base_packages <- c(
  "terra", "tidyverse", "patchwork", "PerformanceAnalytics", "DT",
  "fable", "feasts", "tsibble", "plotly", "future", "furrr", "future.apply",
  "remotePARTS", "tseries", "doFuture", "doRNG", "fabletools",
  "jsonlite", "moments", "logger"
)

# Define extra packages only for Model1, Model2, Model3
extra_packages_models <- c("Model1_Simple", "Model2_Autoregressive", "Model3_MB_User")
extra_packages <- c("rtrend", "modifiedmk", "mclust")

# Choose packages to install/load
if (model_type %in% extra_packages_models) {
  required_packages <- c(base_packages, extra_packages)
} else {
  required_packages <- base_packages
}

# Install missing packages
missing_pkgs <- setdiff(required_packages, rownames(installed.packages()))
if (length(missing_pkgs) > 0) {
  install.packages(missing_pkgs, repos = "https://cran.rstudio.com")
}

# Load all packages
invisible(lapply(required_packages, library, character.only = TRUE))





# ==============================================================================
# Model 4, 5, 6 -> Install missing packages
# ==============================================================================

# required_packages <- c(
#   "terra",
#   "tidyverse",
#   "patchwork",
#   "PerformanceAnalytics",
#   "DT",
#   "fable",
#   "feasts",
#   "tsibble",
#   "plotly",
#   "future",
#   "furrr",
#   "future.apply",
#   "remotePARTS",
#   "tseries",
#   "doFuture",
#   "doRNG",
#   "fabletools",
#   "jsonlite",
#   "moments",
#   "logger"
# )

# # Install missing packages
# missing_pkgs <- setdiff(required_packages, rownames(installed.packages()))
# if (length(missing_pkgs) > 0) {
#   install.packages(missing_pkgs, repos = "https://cran.rstudio.com")
# }

# # Load all packages
# lapply(required_packages, library, character.only = TRUE)





# ==============================================================================
# Model 1, 2, 3 -> Install missing packages
# ==============================================================================

# install_if_missing <- function(pkgs) {
#   for (pkg in pkgs) {
#     if (!requireNamespace(pkg, quietly = TRUE)) {
#       install.packages(pkg)
#     }
#   }
# }

# needed_packages <- c("rtrend", "modifiedmk", "mclust")

# install_if_missing(needed_packages)



# library(terra)
# library(tidyverse)
# library(patchwork)
# library(PerformanceAnalytics)
# library(DT)
# library(fable)
# library(feasts)
# library(tsibble)
# library(future)
# library(furrr)
# library(future.apply)
# library(remotePARTS)
# library(tseries)
# library(doFuture)
# library(doRNG)
# library(fabletools)
# library(jsonlite)
# library(moments)
# library(logger)
# library(rtrend)
# library(modifiedmk)
# library(mclust)




# ==============================================================================
# Mix Of Model 1, 2, 3 and Model 4, 5, 6 -> Install missing packages
# ==============================================================================


# # Required packages
# required_packages <- c(
#   "terra",
#   "tidyverse",
#   "patchwork",
#   "PerformanceAnalytics",
#   "DT",
#   "fable",
#   "feasts",
#   "tsibble",
#   "plotly",
#   "future",
#   "furrr",
#   "future.apply",
#   "remotePARTS",
#   "tseries",
#   "doFuture",
#   "doRNG",
#   "fabletools",
#   "jsonlite",
#   "moments",
#   "logger",
#   "trend",
#   "modifiedmk",
#   "MASS",
#   "lmtest",
#   "sandwich",
#   "broom",
#   "zoo",
#   "dplyr",
#   "purrr",
#   "mclust",
#   "htmlwidgets",
#   "ggplot2",
#   "pryr"
# )

# # Install missing packages
# missing_pkgs <- setdiff(required_packages, rownames(installed.packages()))
# if (length(missing_pkgs) > 0) {
#   install.packages(missing_pkgs, repos = "https://cran.rstudio.com")
# }

# # Load all packages
# lapply(required_packages, library, character.only = TRUE)



# ==============================================================================
# Load Required scripts
# ==============================================================================

# Load scripts
source("r_scripts/script_package_sdpd.R")
source("r_scripts/script_funzioni_SMICRAB.R")
source("r_scripts/UtilityFunctions.R")
source("r_scripts/settings.R")


# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================


create_vec.options <- function(params) {
  vec.options <- list(
    groups = params$groups,
    px.core = params$px_core,
    px.neighbors = params$px_neighbors,
    t_frequency = params$t_frequency,
    na.rm = params$na_rm,
    NAcovs = params$NAcovs
  )
  return(vec.options)
}

get_analysis_path <- function() {
  if (.Platform$OS.type == "windows") {
    return(file.path(getwd(), "tmp", "analysis"))
  } else {
    return("tmp/analysis")
  }
}


# ==============================================================================
# PARAMETER INITIALIZATION
# ==============================================================================


# Read parameters from command line or use example
args <- commandArgs(trailingOnly = TRUE)
if (length(args) > 0) {
  param_path <- args[1] # first argument is the JSON file path
  params <- fromJSON(param_path)
} else {
  # log_info("No parameters provided. Using example parameters.")
  # stop("No parameters provided. Using example parameters.")
  # Example parameters if no command line argument provided
  
  # params <- fromJSON('{
  #   "analysis_id": "cfb87b97-7d58-4afd-9aef-9aa6c52648cf",
  #   "model_type": "Model1_Simple",
  #   "bool_update": false,
  #   "bool_trend": true,
  #   "summary_stat": "range",
  #   "user_longitude_choice": 11.2,
  #   "user_latitude_choice": 45.1,
  #   "user_coeff_choice": 3.0,
  #   "bool_dynamic": true,
  #   "endogenous_variable": "black_sky_albedo_all_mean",
  #   "covariate_variables": [],
  #   "covariate_legs": [],
  #   "user_date_choice": "2011-01-01",
  #   "vec_options": {
  #     "groups": 1,
  #     "px_core": 1,
  #     "px_neighbors": 3,
  #     "t_frequency": 12,
  #     "na_rm": true,
  #     "NAcovs": "pairwise.complete.obs"
  #   }
  # }')
  
  params <- fromJSON('{
    "analysis_id": "7c91d4ec-cee1-4860-95b9-2a1f52e6a1b0",
    "model_type": "Model2_Autoregressive",
    "bool_update": false,
    "bool_trend": true,
    "summary_stat": "standard_deviation",
    "user_longitude_choice": 11.2,
    "user_latitude_choice": 45.1,
    "user_coeff_choice": 1.0,
    "bool_dynamic": true,
    "endogenous_variable": "mean_wind_speed_adjusted",
      "covariate_variables": [],
    "covariate_legs": [],
    "user_date_choice": "2011-01-01",
    "vec_options": {
      "groups": 1,
      "px_core": 1,
      "px_neighbors": 3,
      "t_frequency": 12,
      "na_rm": true,
      "NAcovs": "pairwise.complete.obs"
    }
  }')
  
  
  
  # params <- fromJSON('{
  # "analysis_id": "61a6af69-2a20-40c6-9cf8-c1caf961f696",
  # "model_type": "Model3_MB_User",
  # "bool_update": true,
  # "bool_trend": true,
  # "summary_stat": "mean",
  # "user_longitude_choice": 11.2,
  # "user_latitude_choice": 45.1,
  # "user_coeff_choice": 1.0,
  # "bool_dynamic": true,
  # "endogenous_variable": "mean_air_temperature_adjusted",
  # "covariate_variables": [
  #     "mean_relative_humidity_adjusted"
  # ],
  # "covariate_legs": [0],
  # "user_date_choice": "2011-01-01",
  # "vec_options": {
  #   "na_rm": true,
  #   "NAcovs": "pairwise.complete.obs",
  #   "groups": 1,
  #   "px_core": 1,
  #   "t_frequency": 12,
  #   "px_neighbors": 3
  # }
  # }')
  
  
  # params <- fromJSON('{
  #   "analysis_id": "ef4e422c-8253-4a10-9d09-ca08fc89c670",
  #   "model_type": "Model4_UHU",
  #   "bool_update": false,
  #   "bool_trend": true,
  #   "summary_stat": "standard_deviation",
  #   "user_longitude_choice": 11.2,
  #   "user_latitude_choice": 45.1,
  #   "user_coeff_choice": 1.0,
  #   "bool_dynamic": true,
  #   "endogenous_variable": "LST_h18",
  #   "covariate_variables": [
  #     "maximum_air_temperature_adjusted",
  #     "mean_air_temperature_adjusted",
  #     "mean_relative_humidity_adjusted",
  #     "accumulated_precipitation_adjusted",
  #     "mean_wind_speed_adjusted",
  #     "black_sky_albedo_all_mean"
  #   ],
  #   "covariate_legs": [0, 0, 0, 0, 0, 0],
  #   "user_date_choice": "2011-01-01",
  #   "vec_options": {
  #     "na_rm": true,
  #     "NAcovs": "pairwise.complete.obs",
  #     "groups": 1,
  #     "px_core": 1,
  #     "t_frequency": 12,
  #     "px_neighbors": 3
  #   }
  # }')
  
  
  #   params <- fromJSON('{
  #     "analysis_id": "f5532c3b-bc1f-40dc-9c7b-83121c5f00d0",
  #     "model_type": "Model5_RAB",
  #     "bool_update": false,
  #     "bool_trend": true,
  #     "summary_stat": "max",
  #     "user_longitude_choice": 11.2,
  #     "user_latitude_choice": 45.1,
  #     "user_coeff_choice": 1.0,
  #     "bool_dynamic": true,
  #     "endogenous_variable": "black_sky_albedo_all_mean",
  #     "covariate_variables": [
  #       "maximum_air_temperature_adjusted",
  #       "mean_air_temperature_adjusted",
  #       "mean_relative_humidity_adjusted"
  #     ],
  #     "covariate_legs": [0, 0, 0],
  #     "user_date_choice": "2011-01-01",
  #     "vec_options": {
  #       "na_rm": true,
  #       "NAcovs": "pairwise.complete.obs",
  #       "groups": 1,
  #       "px_core": 1,
  #       "t_frequency": 12,
  #       "px_neighbors": 3
  #     }
  #   }
  # ')
  
  
  
  
  # params <- fromJSON('{
  #   "analysis_id": "119cdd08-20e9-4706-a62a-5f279aed845e",
  #   "model_type": "Model6_HSDPD_user",
  #   "bool_update": true,
  #   "bool_trend": true,
  #   "summary_stat": "mean",
  #   "user_longitude_choice": 11.2,
  #   "user_latitude_choice": 45.1,
  #   "user_coeff_choice": 1.0,
  #   "bool_dynamic": false,
  #   "endogenous_variable": "mean_air_temperature_adjusted",
  #     "covariate_variables": [
  #       "maximum_air_temperature_adjusted",
  #       "mean_relative_humidity_adjusted"
  #     ],
  #   "covariate_legs": [0, 2],
  #   "user_date_choice": "2011-01-01",
  #   "vec_options": {
  #     "na_rm": true,
  #     "NAcovs": "pairwise.complete.obs",
  #     "groups": 1,
  #     "px_core": 1,
  #     "t_frequency": 12,
  #     "px_neighbors": 3
  #   }
  # }')
  
  
}


# Initializations using the parameters:
analysis_id <- params$analysis_id
user_longitude_choice <- params$user_longitude_choice
user_latitude_choice <- params$user_latitude_choice
user_coeff_choice <- params$user_coeff_choice
bool_dynamic <- params$bool_dynamic
bool_update <- params$bool_update
bool_trend <- params$bool_trend
summary_stat <- params$summary_stat
endogenous_variable <- params$endogenous_variable
covariate_variables <- params$covariate_variables
covariate_legs <- params$covariate_legs
user_date_choice <- params$user_date_choice
vec.options <- create_vec.options(params$vec_options)
user_model_choice <- params$model_type

# Analysis configuration
analysis_status <- "in_progress"
output_base_dir <- get_analysis_path()
output_dir <- file.path(output_base_dir, analysis_id, params$model_type)
n.boot <- 299
tempo <- 1:156
offset <- 156
ora <- 18
indici <- seq(ora + 1, 7488, by = 24)

validation_stats <- list(
  mean = mean,
  sd = sd,
  skewness = skewness,
  kurtosis = kurtosis
)

shape_path <- "r_scripts/shapes/ProvCM01012025_g_WGS84.shp"
rdata_path <- file.path(output_dir, "dataframes.RData")

# Configure Logger
log_file <- file.path(output_dir, "analysis_log.log")
dir.create(dirname(log_file), recursive = TRUE, showWarnings = FALSE)
log_appender(appender_file(log_file))
log_threshold(TRACE)
log_layout(layout_glue_generator(
  format = "[{time}] {level} {msg}"
))

# Create output directories
dir.create(file.path(output_dir, "summary_stats/plots"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(output_dir, "summary_stats/stats"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(output_dir, "model_fits/plots"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(output_dir, "model_fits/stats"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(output_dir, "bootstrap/plots"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(output_dir, "bootstrap/stats"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(output_dir, "data"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(output_dir, "estimate/plots"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(output_dir, "estimate/stats"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(output_dir, "validate/plots"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(output_dir, "validate/stats"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(output_dir, "riskmap/plots"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(output_dir, "Rdata"), recursive = TRUE, showWarnings = FALSE)


# ==============================================================================
# DATA LOADING
# ==============================================================================

tryCatch(
  {
    log_info("Starting Data Loading Module...")
    
    # Load all datasets
    log_info("Loading raster datasets...")
    tg.m <- rast("datasets/tg_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly_CF-1.8_corrected.nc")
    tx.m <- rast("datasets/tx_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly_CF-1.8_corrected.nc")
    tn.m <- rast("datasets/tn_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly_CF-1.8_corrected.nc")
    rr.m <- rast("datasets/rr_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly_CF-1.8_corrected.nc")
    hu.m <- rast("datasets/hu_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly_CF-1.8_corrected.nc")
    fg.m <- rast("datasets/fg_ens_mean_0.1deg_reg_2011-2023_v30.0e_monthly_CF-1.8_corrected.nc")
    sal <- rast("datasets/SAL_IT_2011-2023_Monthly_CMSAF_ERA5_CF-1.8_Reinterpolated.nc")
    LST <- rast("datasets/LST_IT_2011_2023_agg_Monthly_per_hour_grid_0.1_CF-1.8.nc")
    lc22 <- rast("datasets/C3S-LC-L4-LCCS-Map-300m-P1Y-2022-v2.1.1.area-subset.49.20.32.6.nc")
    
    log_info("All datasets loaded successfully")
    
    # ==============================================================================
    # VARIABLE PREPARATION
    # ==============================================================================
    
    log_info("Preparing variables...")
    
    # Preparing Variables
    variable <- list()
    variable[[1]] <- tx.m[[tempo + offset]]
    names(variable)[1] <- varnames(variable[[1]]) <- "maximum_air_temperature_adjusted"
    variable[[2]] <- tg.m[[tempo + offset]]
    names(variable)[2] <- varnames(variable[[2]]) <- "mean_air_temperature_adjusted"
    variable[[3]] <- tn.m[[tempo + offset]]
    names(variable)[3] <- varnames(variable[[3]]) <- "minimum_air_temperature_adjusted"
    variable[[4]] <- hu.m[[tempo + offset]]
    names(variable)[4] <- varnames(variable[[4]]) <- "mean_relative_humidity_adjusted"
    variable[[5]] <- rr.m[[tempo + offset]]
    names(variable)[5] <- varnames(variable[[5]]) <- "accumulated_precipitation_adjusted"
    variable[[6]] <- fg.m[[tempo + offset]]
    names(variable)[6] <- varnames(variable[[6]]) <- "mean_wind_speed_adjusted"
    variable[[7]] <- sal[[tempo]] * 100
    names(variable)[7] <- varnames(variable[[7]]) <- "black_sky_albedo_all_mean"
    variable[[8]] <- LST[[indici[tempo]]]
    names(variable)[8] <- varnames(variable[[8]]) <- "LST_h18"
    
    log_info("Variables prepared: {paste(names(variable), collapse = ', ')}")
    
    
    # ==============================================================================
    # MODEL CONFIGURATION
    # ==============================================================================
    
    log_info("Configuring model variables...")
    
    # Model 6 Configuration - User-defined variables
    name.endogenous <- endogenous_variable
    name.covariates <- covariate_variables
    
    # Validate that endogenous variable exists
    if (!name.endogenous %in% names(variable)) {
      stop("Endogenous variable '", name.endogenous, "' not found in available variables")
    }
    
    # Validate that all covariate variables exist
    invalid_covs <- setdiff(name.covariates, names(variable))
    if (length(invalid_covs) > 0) {
      stop("Covariate variables not found: ", paste(invalid_covs, collapse = ", "))
    }
    
    # Validate that endogenous variable is not in covariates
    if (name.endogenous %in% name.covariates) {
      stop("Endogenous variable cannot be included in covariates")
    }
    
    rry <- variable[[name.endogenous]] # Endogenous variable
    
    # Build covariates list dynamically
    rrxx <- list()
    if (length(name.covariates) > 0) {
      for (i in seq_along(name.covariates)) {
        cov_name <- name.covariates[[i]]
        rrxx[[cov_name]] <- variable[[cov_name]]
      }
    }
    
    log_info("Endogenous name: {name.endogenous}")
    log_info("Covariates names: {paste(name.covariates, collapse = ', ')}")
    
    # rrgroups <- NULL
    # label_groups <- NULL
    # label.province <- NULL
    
    # Dynamic model configuration
    n.covs <- length(name.covariates)
    
    log_info("Common setup completed. Parameters loaded and directories created.")
  },
  error = function(e) {
    log_error("Error in COMMON SETUP: {e}")
    stop(e)
  }
)
