required_packages <- c(
  "terra",
  "tidyverse",
  "patchwork",
  "PerformanceAnalytics",
  "DT",
  "fable",
  "feasts",
  "tsibble",
  "plotly",
  "future",
  "furrr",
  "future.apply",
  "remotePARTS",
  "tseries",
  "doFuture",
  "doRNG",
  "fabletools",
  "jsonlite",
  "moments",
  "logger"
)

# Install missing packages
missing_pkgs <- setdiff(required_packages, rownames(installed.packages()))
if (length(missing_pkgs) > 0) {
  install.packages(missing_pkgs, repos = "https://cran.rstudio.com")
}

# Load all packages
lapply(required_packages, library, character.only = TRUE)

# Load scripts
source("r_scripts/script_package_sdpd.R")
source("r_scripts/script_funzioni_SMICRAB.R")
source("r_scripts/UtilityFunctions.R")
source("r_scripts/settings.R")


# Modified Helper Functions
fun.download.csv <- function(raster_obj, name_file = varnames(raster_obj)[1], output_dir) {
  tempo <- as.character(time(raster_obj))
  valori <- values(raster_obj)
  dimnames(valori)[[2]] <- tempo
  px <- seq(1, dim(valori)[1])
  coordinate <- xyFromCell(raster_obj, px)
  dataframe <- data.frame(longitude = coordinate[,1], latitude = coordinate[,2], valori)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  write.csv(dataframe, file = file.path(output_dir, paste0(name_file, ".csv")), row.names = FALSE)
}


fun.derive.function.VARs <- function(summary_stat) {
  switch(
    summary_stat,
    mean = function(x) mean(x, na.rm = TRUE),
    standard_deviation = function(x) sd(x, na.rm = TRUE),
    min = function(x) min(x, na.rm = TRUE),
    max = function(x) max(x, na.rm = TRUE),
    median = function(x) median(x, na.rm = TRUE),
    range = function(x) diff(range(x, na.rm = TRUE)),
    count.NAs = function(x) sum(is.na(x)),
    skewness = function(x) {
      x <- x[!is.na(x)]
      if (length(x) > 2) moments::skewness(x) else NA
    },
    kurtosis = function(x) {
      x <- x[!is.na(x)]
      if (length(x) > 3) moments::kurtosis(x) else NA
    },
    stop(paste("Unknown statistic:", summary_stat))
  )
}

plotVarSpatial <- function(varName, datePoint, data, pars, bool_dynamic = FALSE, output_path) {
  new.date <- paste(substr(datePoint, 1, 4), substr(datePoint, 6, 7), substr(datePoint, 9, 10), sep = ".")
  
  # Dynamically select the value column (e.g., "X2023.07.01")
  value_col <- paste0("X", new.date)
  
  plt <- data %>%
    rename(Latitude = latitude, Longitude = longitude) %>%
    mutate(value = .data[[value_col]]) %>%
    ggplot(aes(x = Longitude, y = Latitude)) +
    geom_point(aes(colour = value), size = 0.8) +
    scale_colour_gradientn(colours = pars$colori, limits = pars$limiti) +
    labs(
      title = paste("Monthly mean value of", varName),
      subtitle = paste("Observed on", substr(datePoint, 1, 7)),
      colour = pars$unit
    ) +
    theme_bw()
  
  if (bool_dynamic) {
    interactive_plot <- plotly::ggplotly(plt)
    htmlwidgets::saveWidget(interactive_plot, file = output_path)
  } else {
    ggsave(filename = output_path, plot = plt, width = 8, height = 6)
  }
}

PlotComponentsSTL_nonest_lonlat2 <- function(lat, lon, varName, data, pars, bool_dynamic = FALSE, output_path) {
  # Filter and prepare data
  data_df <- data %>%
    mutate(Latitude = round(latitude, 1)) %>%
    mutate(Longitude = round(longitude, 1)) %>%
    filter(Latitude == round(lat, 1), Longitude == round(lon, 1)) %>%
    select(-c(Latitude, Longitude))
  
  data_df <- CreateLongDF(data_df)
  data_nested_df <- CreateNestedDF(data_df)
  
  temp_data <- data_nested_df$data[[1]] %>%
    mutate(Month = yearmonth(Date))
  
  from.to <- range(temp_data$Month)
  
  # Create STL decomposition plot
  base_plot <- temp_data %>%
    as_tsibble(index = Month) %>%
    model(STL(value ~ season(period = 12), robust = TRUE)) %>%
    components() %>%
    autoplot() +
    ggtitle(paste(varName, "(STL decomposition)")) +
    guides(x = guide_axis(minor.ticks = TRUE, angle = 0, check.overlap = FALSE)) +
    labs(caption = paste("(based on data from ", from.to[1], " to ", from.to[2], ")", sep = "")) +
    theme_bw()
  
  if (bool_dynamic) {
    interactive_plot <- plotly::ggplotly(base_plot)
    htmlwidgets::saveWidget(interactive_plot, file = output_path)
  } else {
    ggsave(filename = output_path, plot = base_plot, width = 8, height = 6)
  }
}


fun.plot.stat.VARs <- function(df_serie, statistic, title, pars, output_path, bool_dynamic = FALSE) {
  
  plot <- df_serie %>%
    mutate(newvar = apply(df_serie[, -c(1, 2)], 1, FUN = statistic)) %>%
    ggplot(aes(longitude, latitude, colour = newvar)) +
    geom_point(size = 0.8) +
    scale_colour_gradientn(colours = pars$colori, limits = pars$limiti) +
    labs(title = title, colour = pars$unit)
  
  if (bool_dynamic) {
    interactive_plot <- plotly::ggplotly(plot)
    htmlwidgets::saveWidget(interactive_plot, file = output_path)
  } else {
    ggsave(
      filename = output_path,
      plot = plot,
      width = 8,
      height = 6
    )
  }
}


save_coeff_plots <- function(plot.coeffs, output_dir, name.endogenous, name.covariates, bool_dynamic = TRUE, bool_trend = FALSE) {
  
  # Helper function to save a single plot
  save_plot <- function(plot_obj, filename, bool_dynamic) {
    if(bool_dynamic) {
      htmlwidgets::saveWidget(plot_obj, file = filename, selfcontained = TRUE)
    } else {
      ggsave(filename = output_path, plot = plot_obj, width = 8, height = 6)
      
    }
  }
  
  # 1. Trend Plot
  if (bool_trend && "trend" %in% names(plot.coeffs)) {
    trend_plot <- if (bool_dynamic) plotly::ggplotly(plot.coeffs$trend) else plot.coeffs$trend
    filename <- paste0("plot_trend_", name.endogenous, if (bool_dynamic) ".html" else ".png")
    output_path <- file.path(output_dir, "estimate/plots", filename) 
    save_plot(trend_plot, output_path, bool_dynamic)
  }
  
  # 2. Covariate Plots
  for (ii in name.covariates) {
    if (ii %in% names(plot.coeffs)) {
      cov_plot <- if (bool_dynamic) plotly::ggplotly(plot.coeffs[[ii]]) else plot.coeffs[[ii]]
      filename <- paste0("plot_", ii, if (bool_dynamic) ".html" else ".png")
      output_path <- file.path(output_dir, "estimate/plots", filename) 
      save_plot(cov_plot, output_path, bool_dynamic)
    }
  }
  
  # 3. Lambda Coefficients
  for (lambda in c("lambda0", "lambda1", "lambda2")) {
    if (lambda %in% names(plot.coeffs)) {
      lambda_plot <- if (bool_dynamic) plotly::ggplotly(plot.coeffs[[lambda]]) else plot.coeffs[[lambda]]
      filename <- paste0("plot_", lambda, "_", name.endogenous, if (bool_dynamic) ".html" else ".png")
      output_path <- file.path(output_dir, "estimate/plots", filename) 
      save_plot(lambda_plot, output_path, bool_dynamic)
      
    }
  }
  
  # 4. Fixed Effects
  if ("fixed_effects" %in% names(plot.coeffs)) {
    fe_plot <- if (bool_dynamic) plotly::ggplotly(plot.coeffs$fixed_effects) else plot.coeffs$fixed_effects
    filename <- paste0("plot_fixed_effects_", name.endogenous, if (bool_dynamic) ".html" else ".png")
    output_path <- file.path(output_dir, "estimate/plots", filename) 
    save_plot(lambda_plot, output_path, bool_dynamic)
  }
  
}


fun.plot.stat.RESIDs <- function(df.results, statistic, title, pars = NULL, bool_dynamic = FALSE, output_path, ...) {
  
  # Check if residuals are in data.frame or list format
  if (is.data.frame(df.results$resid)) {
    dati <- data.frame(lon = df.results$lon, lat = df.results$lat, newvar = apply(df.results$resid, 1, FUN = statistic, ...))
  } else if (is.list(df.results$resid)) {
    dati <- data.frame(lon = df.results$lon, lat = df.results$lat, newvar = unlist(lapply(df.results$resid, FUN = statistic, ...)))
  }
  
  # Create the base ggplot
  res <- dati %>%
    ggplot(aes(lon, lat, colour = newvar)) +
    geom_point(size = 0.8) +
    guides(fill = "none") +
    labs(
      title = "Summary statistics for residuals",
      x = "Longitude",
      y = "Latitude",
      colour = paste(title, "\nof residuals")
    ) +
    scale_colour_gradient2(high = "red", low = "blue", mid = "white", midpoint = 0) +
    theme_bw()
  
  # Save as either interactive HTML or static PNG based on bool_dynamic
  if (bool_dynamic) {
    interactive_plot <- plotly::ggplotly(res)
    htmlwidgets::saveWidget(interactive_plot, file = output_path)
  } else {
    ggsave(filename = output_path, plot = res, width = 8, height = 6)
  }
}

fun.plot.stat.discrete.RESIDs <- function(
    df.results,
    statistic = mean,
    title,
    significant.test = FALSE,
    BYadjusted = FALSE,
    alpha,
    pars = NULL,
    bool_dynamic = FALSE,
    output_path,
    ...
) {
  
  # Compute summary statistics on residuals
  if (is.data.frame(df.results$resid)) {
    dati <- data.frame(
      lon = df.results$lon,
      lat = df.results$lat,
      newvar = apply(df.results$resid[, -1], 1, FUN = statistic, ...)
    )
  } else if (is.list(df.results$resid)) {
    dati <- data.frame(
      lon = df.results$lon,
      lat = df.results$lat,
      newvar = unlist(lapply(df.results$resid, FUN = statistic, ...))
    )
  }
  
  # Adjust p-values if requested
  if (BYadjusted) {
    dati$newvar <- p.adjust(dati$newvar, method = "BY")
  }
  
  # Convert to factor for significance test
  if (significant.test) {
    dati$newvar <- as.factor(ifelse(dati$newvar < alpha, "Significant", "Not significant"))
  }
  
  # Create plot
  res <- dati %>%
    ggplot(aes(x = lon, y = lat, colour = newvar)) +
    geom_point(size = 0.8) +
    guides(fill = "none") +
    labs(
      title = "Summary statistics for residuals",
      x = "Longitude",
      y = "Latitude",
      colour = paste(title, "\nof residuals")
    ) +
    theme_bw()
  
  # Save plot
  if (bool_dynamic) {
    interactive_plot <- plotly::ggplotly(res)
    htmlwidgets::saveWidget(interactive_plot, file = output_path)
  } else {
    ggsave(filename = output_path, plot = res, width = 8, height = 6)
  }
}


diagnostic_models <- function(mod.fit, output_dir = NULL, filename_prefix = "diagnostic"){
  
  if (!is.null(output_dir)) {
    # Save plots as PNG files
    png_file1 <- file.path(output_dir, paste0(filename_prefix, "_residuals_vs_fitted.png"))
    png_file2 <- file.path(output_dir, paste0(filename_prefix, "_qq_plot.png"))
    
    # Create first plot
    png(png_file1, width = 800, height = 600)
    plot(mod.fit, which = 1)
    dev.off()
    
    # Create second plot
    png(png_file2, width = 800, height = 600)
    plot(mod.fit, which = 2)
    dev.off()
    
    # Return the file paths for embedding in HTML
    return(c(png_file1, png_file2))
  } else {
    # Original behavior for interactive use
    plot(mod.fit, which = c(1,2))
    return(NULL)
  }
}




get_analysis_path <- function() {
  if (.Platform$OS.type == "windows") {
    return(file.path(getwd(), "tmp", "analysis"))
  } else {
    return("/tmp/analysis")
  }
}

# # Read parameters
# args <- commandArgs(trailingOnly = TRUE)
# param_path <- args[1]  # first argument is the JSON file path
# params <- fromJSON(param_path)


# Example: Read parameters
params <- fromJSON('{
  "analysis_id": "769cdd08-20e9-4706-a62a-5f279aed845e",
  "model_type": "Model6_UserDefined",
  "bool_update": true,
  "bool_trend": true,
  "summary_stat": "mean",
  "user_longitude_choice": 11.2,
  "user_latitude_choice": 45.1,
  "user_coeff_choice": 1.0,
  "bool_dynamic": true,
  "endogenous_variable": "mean_air_temperature_adjusted",
  "covariate_variables": ["mean_relative_humidity_adjusted", "black_sky_albedo_all_mean"],
  "covariate_legs": [2, 3],
  "user_date_choice": "2011-01-01",
	"vec.options": {
    "groups": 1,
    "px.core": 1,
    "px.neighbors": 3,
    "t_frequency": 12,
    "na.rm": true,
    "NAcovs": "pairwise.complete.obs"
  }
}')

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
vec.options <- params$vec.options
user_model_choice <- params$model_type

analysis_status <- "in_progress"
output_base_dir <- get_analysis_path()
output_dir <- file.path(output_base_dir, analysis_id, params$model_type)
n.boot <- 999
tempo <- 1:156
offset <- 156
ora <- 18
indici <- seq(ora+1, 7488, by=24)

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
log_appender(appender_file(log_file))  # Set log output to file
log_threshold(TRACE)  # Set log level to capture all messages (TRACE is the most verbose)
log_layout(layout_glue_generator(
  format = "[{time}] {level} {msg}"
))  # Custom log format with timestamp and level



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

# Data Loading
tg.m <- rast("datasets/tg_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly_CF-1.8_corrected.nc")
tx.m <- rast("datasets/tx_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly_CF-1.8_corrected.nc")
tn.m <- rast("datasets/tn_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly_CF-1.8_corrected.nc")
rr.m <- rast("datasets/rr_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly_CF-1.8_corrected.nc")
hu.m <- rast("datasets/hu_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly_CF-1.8_corrected.nc")
fg.m <- rast("datasets/fg_ens_mean_0.1deg_reg_2011-2023_v30.0e_monthly_CF-1.8_corrected.nc")
sal <- rast("datasets/SAL_IT_2011-2023_Monthly_CMSAF_ERA5_CF-1.8_Reinterpolated.nc")
LST <- rast("datasets/LST_IT_2011_2023_agg_Monthly_per_hour_grid_0.1_CF-1.8.nc")
lc22 <- rast("datasets/C3S-LC-L4-LCCS-Map-300m-P1Y-2022-v2.1.1.area-subset.49.20.32.6.nc")

# Export all variables to CSV if requested
# lapply(list(tg.m, tx.m, tn.m, rr.m, hu.m, fg.m, sal, LST, lc22), fun.download.csv, output_dir = file.path(output_dir, "data"))


# Main processing wrapped in tryCatch
tryCatch({
  log_info("Model 6: User-defined analysis in progress...")
  
  # Preparing Variables
  variable <- list()
  variable[[1]] <- tx.m[[tempo+offset]]
  names(variable)[1] <- varnames(variable[[1]]) <- "maximum_air_temperature_adjusted"
  variable[[2]] <- tg.m[[tempo+offset]]
  names(variable)[2] <- varnames(variable[[2]]) <- "mean_air_temperature_adjusted"
  variable[[3]] <- tn.m[[tempo+offset]]
  names(variable)[3] <- varnames(variable[[3]]) <- "minimum_air_temperature_adjusted"
  variable[[4]] <- hu.m[[tempo+offset]]
  names(variable)[4] <- varnames(variable[[4]]) <- "mean_relative_humidity_adjusted"
  variable[[5]] <- rr.m[[tempo+offset]]
  names(variable)[5] <- varnames(variable[[5]]) <- "accumulated_precipitation_adjusted"
  variable[[6]] <- fg.m[[tempo+offset]]
  names(variable)[6] <- varnames(variable[[6]]) <- "mean_wind_speed_adjusted"
  variable[[7]] <- sal[[tempo]]*100
  names(variable)[7] <- varnames(variable[[7]]) <- "black_sky_albedo_all_mean"
  variable[[8]] <- LST[[indici[tempo]]]
  names(variable)[8] <- varnames(variable[[8]]) <- "LST_h18"
  
  log_info("Load or updating dataframes...")
  if (!bool_update) {
    load(rdata_path)
  } else {
    dataframes <- variable
    for (ii in names(variable)) {
      px <- seq(1, dim(values(variable[[ii]]))[1])
      coordinate <- xyFromCell(variable[[ii]], px)
      valori <- values(variable[[ii]])
      dimnames(valori)[[2]] <- substr(time(variable[[ii]]), start = 1, stop = 10)
      dataframes[[ii]] <- data.frame(longitude = coordinate[, 1], latitude = coordinate[, 2], valori)
    }
    save(dataframes, file = rdata_path)
  }
  
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
  
  rry <- variable[[name.endogenous]]  # Endogenous variable
  
  # Build covariates list dynamically
  rrxx <- list()
  if (length(name.covariates) > 0) {
    for (i in seq_along(name.covariates)) {
      cov_name <- name.covariates[i]
      rrxx[[cov_name]] <- variable[[cov_name]]
    }
  }
  
  log_info("Endogenous name: {name.endogenous}")
  log_info("Covariates names: {name.covariates}")
  log_info("Covariates list: {rrxx}")
  log_info("Endogenous variable: {rry}")
  
  rrgroups <- NULL
  label_groups <- NULL
  
  # Initialize proper variable references for province mapping
  label.province <- NULL
  
  # Dynamic model configuration
  n.covs <- length(name.covariates)
  
  
  log_info("Downloading the endogenous variable as csv")
  fun.download.csv(rry, name_file = name.endogenous, output_dir = file.path(output_dir, "data"))
  
  
  
  log_info("DESCRIBE MODULE Started")
  
  log_info("Create (or load) the R objects required for estimations")
  if(!bool_update){
    load(paste(output_dir, "/Rdata/workfile_model6_", name.endogenous, ".RData", sep=""))
  }
  
  log_info("\nPlotting Spatial distribution of values at a fixed date")
  for (ii in names(variable)) {
    log_info("Plotting {ii}")
    output_path <- if (bool_dynamic) file.path(output_dir, "summary_stats/plots", paste0(ii, "_spatial.html")) else file.path(output_dir, "summary_stats/plots", paste0(ii, "_spatial.png"))
    plotVarSpatial(ii, user_date_choice, dataframes[[ii]], pars_list[[ii]], bool_dynamic, output_path)
  }
  
  
  log_info("\nPlotting Temporal distribution of values for a fixed pixel")
  for (ii in names(variable)) {
    log_info("Plotting {ii}")
    output_path <- if (bool_dynamic) file.path(output_dir, "summary_stats/plots", paste0(ii, "_stl_decomposition.html")) else file.path(output_dir, "summary_stats/plots", paste0(ii, "_stl_decomposition.png"))
    
    PlotComponentsSTL_nonest_lonlat2(user_latitude_choice, user_longitude_choice, ii, dataframes[[ii]], pars_list[[ii]], bool_dynamic, output_path)
  }
  
  
  log_info("\nPlotting Summary Statistics")
  
  for (ii in names(variable)) {
    log_info("Plotting {ii}")
    funzione <- fun.derive.function.VARs(summary_stat)
    titolo <- paste(summary_stat, "of", ii)
    pars <- pars_list[[ii]]
    df <- dataframes[[ii]]
    output_path <- if (bool_dynamic) file.path(output_dir, "summary_stats/plots", paste0(summary_stat, "_", ii, ".html")) else file.path(output_dir, "summary_stats/plots", paste0(summary_stat, "_", ii, ".png"))
    fun.plot.stat.VARs(df, funzione, titolo, pars, output_path, bool_dynamic)
  }
  
  
  log_info("DESCRIBE MODULE Completed")
  
  
  
  
  log_info("ESTIMATE MODULE Started")

  
  # Model configuration details - B) Create or load the R objects required for estimations
  log_info("Starting configuration of model objects for {user_model_choice}")
  
  if (!bool_update) {
    log_info("Loading pre-computed results for {user_model_choice} with endogenous variable {name.endogenous}")
    load_path <- paste(output_dir, "/Rdata/workfile_", user_model_choice, "_", name.endogenous, ".RData", sep="")
    tryCatch({
      load(load_path)
      log_info("Successfully loaded pre-computed results from {load_path}")
    }, error = function(e) {
      log_info("Error loading pre-computed results from {load_path}: {e$message}")
      stop("Failed to load pre-computed results")
    })
  }
  
  if (user_model_choice %in% c("Model3_MB_User", "Model6_HSDPD_user") | bool_update) {
    log_info("Building dataframes for all variables")
    dataframes <- variable
    for (ii in names(variable)) {
      log_info("Processing variable {ii}")
      px <- seq(1, dim(values(variable[[ii]]))[1])
      coordinate <- xyFromCell(variable[[ii]], px)
      valori <- values(variable[[ii]])
      dimnames(valori)[[2]] <- substr(time(variable[[ii]]), start = 1, stop = 10)
      dataframes[[ii]] <- data.frame(longitude = coordinate[, 1], latitude = coordinate[, 2], valori)
    }
    log_info("Saving dataframes to {rdata_path}")
    save(dataframes, file = rdata_path)
    
    log_info("Building endogenous variable and covariates")
    var_y <- variable[[name.endogenous]]
    tt <- length(time(var_y))
    kk <- length(rrxx)
    
    integer_lags <- setNames(covariate_legs, covariate_variables)
    log_info("Integer lags: {integer_lags}")
    
    from.tt <- 1 + max(integer_lags)
    to.tt <- tt
    rry <- var_y[[from.tt:to.tt]]
    log_info("Endogenous variable {name.endogenous} prepared with time range {from.tt}:{to.tt}")
    
    resized.covariates <- list()
    n.covs <- length(name.covariates)
    for (ii in seq_along(name.covariates)) {
      cov_name <- name.covariates[ii]
      lag <- integer_lags[cov_name]
      from.tt <- 1 + max(integer_lags) - lag
      to.tt <- tt - lag
      resized.covariates[[cov_name]] <- variable[[cov_name]][[from.tt:to.tt]]
      log_info("Covariate {cov_name} prepared with time range {from.tt}:{to.tt}")
    }
    
    # Validate shapefile and rasterization
    log_info("Loading shapefile for pixel grouping")
    tryCatch({
      italy.shape <- vect(shape_path)
      italy.shape <- project(italy.shape, var_y)
      province <- rasterize(italy.shape, var_y, field="COD_PROV")
      if (!inherits(province, "SpatRaster")) {
        stop("rasterize did not produce a SpatRaster object")
      }
      label.province <- values(italy.shape)[,"DEN_UTS"]
      names(label.province) <- values(italy.shape)[,"COD_PROV"]
      log_info("Shapefile loaded and projected successfully")
    }, error = function(e) {
      log_info("Error loading shapefile from {shape_path}: {e$message}")
      stop("Failed to load shapefile")
    })
  }
  
  # H-SDPD models (Model4_UHI, Model5_RAB, Model6_HSDPD_user)
  if (user_model_choice %in% c("Model4_UHI", "Model5_RAB", "Model6_HSDPD_user") | (bool_update & user_model_choice %in% c("Model4_UHI", "Model5_RAB"))) {
    # Configure H-SDPD model
    log_info("Configuring H-SDPD model for {user_model_choice}")
    if (bool_trend) {
      resized.covariates[["trend"]] <- "trend"  # Ensure trend is added correctly
      log_info("Added trend covariate")
    }
    

    sdpd.model <- list()
    sdpd.model$lambda.coeffs <- c(TRUE, TRUE, TRUE)
    names(sdpd.model$lambda.coeffs) <- c("lambda0", "lambda1", "lambda2")
    n.covs <- length(name.covariates)  # Reset n.covs to number of actual covariates
    if (length(resized.covariates) > 0) {
      # sdpd.model$beta.coeffs <- rep(TRUE, length(resized.covariates))
      sdpd.model$beta.coeffs <- rep(TRUE, n.covs + bool_trend)

      names(sdpd.model$beta.coeffs) <- names(resized.covariates)
    } else {
      sdpd.model$beta.coeffs <- NULL
      resized.covariates <- NULL
    }
    sdpd.model$fixed_effects <- TRUE
    sdpd.model$time_effects <- FALSE
    log_info("H-SDPD model structure defined with {length(resized.covariates)} covariates")


    
    log_info("Building spatial-temporal series for H-SDPD model")
    tryCatch({
      global.series <- build.sdpd.series(px="all", rry=rry, rrXX=resized.covariates, rrgroups=province, label_groups=label.province, vec.options=vec.options)
      log_info("Spatial-temporal series built successfully")
    }, error = function(e) {
      log_info("Error building spatial-temporal series: {e$message}")
      stop("Failed to build spatial-temporal series")
    })
    
    log_info("Grouping pixels by districts")
    df.gruppi <- tibble(gruppo=global.series$p.axis$group, px=global.series$p.axis$pixel) %>%
      nest_by(.by=gruppo, .key="gruppo")
    
    names(df.gruppi$gruppo) <- seq(1, length(df.gruppi$gruppo))
    for (ii in 1:length(df.gruppi$gruppo)) {
      names(df.gruppi$gruppo)[ii] <- df.gruppi$gruppo[[ii]]$gruppo[1,2]
    }
    log_info("Pixels grouped into {length(df.gruppi$gruppo)} districts")
    
    log_info("Preparing data for H-SDPD model estimation")
    tryCatch({
      df.data <- df.gruppi$gruppo %>%
        map(fun.extract.data, rry=rry, rrxx=resized.covariates, rrgroups=province, label_groups=label.province, vec.options=vec.options)
      log_info("Data prepared for H-SDPD model estimation")
    }, error = function(e) {
      log_info("Error preparing data for H-SDPD model: {e$message}")
      stop("Failed to prepare data for H-SDPD model")
    })
    
    objects_to_save <- c(objects_to_save, "sdpd.model", "global.series")
    log_info("Added sdpd.model and global.series to objects_to_save")
  }
  
  # MB-Trend models (Model1_Simple, Model2_Autoregressive, Model3_MB_User)
  if (bool_update & user_model_choice %in% c("Model1_Simple", "Model2_Autoregressive", "Model3_MB_User")) {
    log_info("Configuring MB-Trend model for {user_model_choice}")
    false.covariates <- variable
    false.covariates[[name.endogenous]] <- NULL
    log_info("Building spatial-temporal series for MB-Trend model")
    tryCatch({
      global.series <- build.sdpd.series(px="all", rry=rry, rrXX=false.covariates, rrgroups=province, label_groups=label.province, vec.options=vec.options)
      log_info("Spatial-temporal series built successfully for MB-Trend model")
    }, error = function(e) {
      log_info("Error building spatial-temporal series for MB-Trend model: {e$message}")
      stop("Failed to build spatial-temporal series for MB-Trend model")
    })
    
    new_dataframes <- variable
    for (ii in names(variable)) {
      log_info("Processing variable {ii} for MB-Trend dataframes")
      if (ii == name.endogenous) {
        valori <- global.series$series
      } else {
        valori <- global.series$X[ii,,]
      }
      new_dataframes[[ii]] <- data.frame(longitude=global.series$p.axis$longit, latitude=global.series$p.axis$latit, valori)
    }
    
    log_info("Creating long and nested dataframes")
    data_df <- lapply(new_dataframes, CreateLongDF)
    data_nested_df <- lapply(data_df, CreateNestedDF)
    
    log_info("Generating time-series dataframes")
    plan(multisession)
    tryCatch({
      data_nested_ts_df <- lapply(data_nested_df, GenerateTSDataFrame)
      log_info("Time-series dataframes generated successfully")
    }, error = function(e) {
      log_info("Error generating time-series dataframes: {e$message}")
      stop("Failed to generate time-series dataframes")
    })
    
    log_info("Creating full dataset")
    plan(multisession)
    tryCatch({
      full_data_ts_df <- CreateFullDataset(data_df)
      log_info("Full dataset created successfully")
    }, error = function(e) {
      log_info("Error creating full dataset: {e$message}")
      stop("Failed to create full dataset")
    })
    
    objects_to_save <- c(objects_to_save, "data_df")
    log_info("Added data_df to objects_to_save")
  }
  
  # Land Cover Dataset for all models
  if (user_model_choice == "Model6_HSDPD_user" | bool_update) {
    log_info("Creating Land Cover dataset")
    tryCatch({
      px <- as.numeric(dimnames(global.series$series)[[1]])
      coordinate <- xyFromCell(variable[[name.endogenous]], px)
      indici <- cellFromXY(lc22[[1]], coordinate)
      slc_df <- data.frame(longitude=global.series$p.axis$longit, latitude=global.series$p.axis$latit, slc=values(lc22)[indici,1])
      slc_df <- slc_df %>%
        mutate(Longitude=round(longitude,1), Latitude=round(latitude,1)) %>%
        mutate(LC = case_when(
          (slc <= 40) ~ "Agriculture",
          (slc > 40 & slc <= 100) | slc == 160 | slc == 170 ~ "Forest",
          slc == 110 | slc == 130 ~ "Grassland",
          slc == 180 ~ "Wetland",
          slc == 190 ~ "Settlement",
          (slc >= 120 & slc <= 122) | (slc == 140) | (slc >= 150 & slc <= 153) | (slc >= 200) ~ "Other"
        )) %>%
        mutate(LC = factor(LC)) %>%
        mutate(LC = fct_relevel(LC, c("Forest", "Agriculture", "Grassland", "Wetland", "Settlement", "Other")))
      log_info("Land Cover dataset created successfully")
    }, error = function(e) {
      log_info("Error creating Land Cover dataset: {e$message}")
      stop("Failed to create Land Cover dataset")
    })
    
    objects_to_save <- c(objects_to_save, "slc_df")
    log_info("Added slc_df to objects_to_save")
  }
  
  log_info("Model configuration completed for {user_model_choice}")
  
  

  # FOCUS 5: Estimate the Model
  log_info("Starting model estimation for {user_model_choice}")

  # A) Estimate the Simple Trend model
  if (user_model_choice == "Model1_Simple" & bool_update) {
    log_info("Computing trend statistics for Model1_Simple")
    tryCatch({
      plan(multisession)
      TrendSens_df <- lapply(data_nested_ts_df, ComputeSens_Stats)
      log_info("Computed TrendSens_df")
      
      plan(multisession)
      TrendCS_df <- lapply(data_nested_ts_df, ComputeCS_Stats)
      log_info("Computed TrendCS_df")
      
      plan(multisession)
      TrendMK_df <- lapply(data_nested_ts_df, ComputeMK_Stats)
      log_info("Computed TrendMK_df")
      
      plan(multisession)
      TrendSMK_df <- lapply(data_nested_ts_df, ComputeSMK_Stats)
      log_info("Computed TrendSMK_df")
      
      plan(multisession)
      TrendPWMK_df <- lapply(data_nested_ts_df, ComputePWMK_Stats)
      log_info("Computed TrendPWMK_df")
      
      plan(multisession)
      TrendBCPW_df <- lapply(data_nested_ts_df, ComputeBCPW_Stats)
      log_info("Computed TrendBCPW_df")
      
      plan(multisession)
      TrendRobust_df <- lapply(data_nested_ts_df, ComputeRobust_Stats)
      log_info("Computed TrendRobust_df")
      
      objects_to_save <- c(objects_to_save, "TrendSens_df", "TrendCS_df", "TrendMK_df", "TrendSMK_df", "TrendPWMK_df", "TrendBCPW_df", "TrendRobust_df")
      log_info("Added trend statistics to objects_to_save")
    }, error = function(e) {
      log_info("Error computing trend statistics for Model1_Simple: {e$message}")
      stop("Failed to compute trend statistics")
    })
  }

  # B) Estimate the MB-Trend models
  if (user_model_choice == "Model3_MB_User" | (bool_update & user_model_choice == "Model2_Autoregressive")) {
    log_info("Estimating MB-Trend model for {user_model_choice}")
    if (user_model_choice == "Model3_MB_User") {
      log_info("Loading pre-computed data for Model3_MB_User")
      tryCatch({
        load(load_path)
        log_info("Successfully loaded {load_path}")
      }, error = function(e) {
        log_info("Error loading {load_path}: {e$message}")
        stop("Failed to load {load_path}")
      })
    }

    xreg <- NULL
    # Replace with:
    if (length(name.covariates) > 0) {
      xreg <- paste(name.covariates, collapse=" + ")
      log_info("Covariates for xreg: {xreg}")
    }
    
    xreg <- paste("trend() + season()", xreg, " + pdq(d=0,q=0) + PDQ(0,0,0)", sep="")
    log_info("xreg formula: {xreg}")

    log_info("Estimating temporal model")
    tryCatch({
      modelStats_df <- computeTemporalModelStats(full_data_ts_df, name.endogenous, xreg)
      log_info("Temporal model stats computed")
    }, error = function(e) {
      log_info("Error estimating temporal model: {e$message}")
      stop("Failed to estimate temporal model")
    })

    log_info("Estimating spatial models")
    tryCatch({
      spatialModels_df <- estimateSpatialModels(modelStats_df, slc_df)
      log_info("Spatial models estimated")
    }, error = function(e) {
      log_info("Error estimating spatial models: {e$message}")
      stop("Failed to estimate spatial models")
    })

    log_info("Deriving estimated quantities")
    beta_df <- modelStats_df$modStats[[name.endogenous]]
    df.results.estimate <- modelStats_df$Residuals[[name.endogenous]]
    indici <- cellFromXY(province, cbind(x=df.results.estimate$Longitude, y=df.results.estimate$Latitude))
    gruppi <- data.frame(COD=values(province)[indici,1], LABEL=label.province[values(province)[indici,1]])
    
    df.results.estimate <- df.results.estimate %>%
      rename(lon=Longitude, lat=Latitude, resid=Residuals) %>%
      mutate(group=gruppi) %>%
      mutate(coeff.hat=data.frame(trend=beta_df$estimate))
    log_info("Derived df.results.estimate")

    objects_to_save <- c(objects_to_save, "modelStats_df", "spatialModels_df", "df.results.estimate")
    log_info("Added modelStats_df, spatialModels_df, df.results.estimate to objects_to_save")

    if (user_model_choice == "Model3_MB_User") {
      log_info("Saving objects for Model3_MB_User")
      tryCatch({
        save(list=c("full_data_ts_df", "slc_df", "data_df"), file=load_path)
        log_info("Saved {load_path}")
      }, error = function(e) {
        log_info("Error saving {load_path}: {e$message}")
        stop("Failed to save {load_path}")
      })
    }
  }

  # C) Estimate the H-SDPD models
  if (user_model_choice %in% c("Model4_UHI", "Model5_RAB", "Model6_HSDPD_user") | (bool_update & user_model_choice %in% c("Model4_UHI", "Model5_RAB"))) {
    log_info("Estimating H-SDPD model for {user_model_choice}")
    tryCatch({
      df.stime <- df.data %>% map(fun.estimate.parameters, model=sdpd.model, vec.options=vec.options)
      log_info("H-SDPD model parameters estimated")
    }, error = function(e) {
      log_info("Error estimating H-SDPD model parameters: {e$message}")
      stop("Failed to estimate H-SDPD model parameters")
    })

    tryCatch({
      df.results.estimate <- df.stime %>%
        map(fun.assemble.estimate.results) %>%
        bind_rows()
      log_info("H-SDPD estimation results assembled")
    }, error = function(e) {
      log_info("Error assembling H-SDPD estimation results: {e$message}")
      stop("Failed to assemble H-SDPD estimation results")
    })

    objects_to_save <- c(objects_to_save, "df.results.estimate")
    log_info("Added df.results.estimate to objects_to_save")
  }

  log_info("Model estimation completed for {user_model_choice}")


  
  # Output Generation for ESTIMATE Module
  log_info("Starting output generation for {user_model_choice}")

  # A) Table with the estimated parameters
  if (user_model_choice != "Model1_Simple") {
    log_info("Saving table with the estimated parameters")
    tryCatch({
      dati <- data.frame(
        lon = round(df.results.estimate$lon, 1),
        lat = round(df.results.estimate$lat, 1),
        district = df.results.estimate$group$LABEL,
        coeff = round(df.results.estimate$coeff.hat, digits = 3),
        row.names = NULL
      )
      output_file_html <- file.path(output_dir, "model_fits/plots", paste0("coeff_", name.endogenous, ".html"))
      output_file_csv <- file.path(output_dir, "model_fits/plots", paste0("coeff_", name.endogenous, ".csv"))
      
      if (bool_dynamic) {
        widget <- datatable(dati, filter = "top")
      } else {
        widget <- datatable(head(dati), filter = "none")
      }
      htmlwidgets::saveWidget(widget, file = output_file_html, selfcontained = TRUE)
      write.csv(dati, file = output_file_csv, row.names = FALSE)
      log_info("Saved coefficient table to {output_file_html} and {output_file_csv}")
    }, error = function(e) {
      log_info("Error saving coefficient table: {e$message}")
      stop("Failed to save coefficient table")
    })
  } else {
    log_info("Coefficient table not available for {user_model_choice}")
  }

  # B) Plot of the estimated coefficients
  if (user_model_choice != "Model1_Simple") {
    log_info("Plotting the estimated coefficients")
    tryCatch({
      # Generate and save coefficient plots using existing save_coeff_plots
      plot.coeffs <- fun.plot.coeff.FITs(df.results.estimate, pars=pars_list)

      save_coeff_plots(
        plot.coeffs = plot.coeffs,
        output_dir = output_dir,
        name.endogenous = name.endogenous,
        name.covariates = name.covariates,
        bool_dynamic = bool_dynamic,
        bool_trend = bool_trend
      )
      log_info("Saved coefficient plots to {file.path(output_dir, 'estimate/plots')}")
    }, error = function(e) {
      log_info("Error generating coefficient plots: {e$message}")
      stop("Failed to generate coefficient plots")
    })
  } else {
    log_info("Coefficient plots not available for {user_model_choice}")
  }

  # C) Plot of the fitted and residual time-series for a given location
  if (user_model_choice != "Model1_Simple") {
    log_info("Plotting the fitted and residual time-series for a given location")
    tryCatch({
      if (user_model_choice %in% c("Model2_Autoregressive", "Model3_MB_User")) {
        plot.series.FITs <- fun.plot.series.FITs2(
          df.results.estimate,
          latitude = user_latitude_choice,
          longitude = user_longitude_choice,
          pars = pars_list
        )
        output_file <- if (bool_dynamic) {
          file.path(output_dir, "estimate/plots", paste0("series_", name.endogenous, ".html"))
        } else {
          file.path(output_dir, "estimate/plots", paste0("series_", name.endogenous, ".png"))
        }
        if (bool_dynamic) {
          plt <- plotly::ggplotly(plot.series.FITs)
          htmlwidgets::saveWidget(plt, file = output_file)
        } else {
          ggsave(filename = output_file, plot = plot.series.FITs, width = 8, height = 6)
        }
        log_info("Saved MB-Trend time-series plot to {output_file}")
      } else if (user_model_choice %in% c("Model4_UHI", "Model5_RAB", "Model6_HSDPD_user")) {
        plot.series.FITs <- fun.plot.series.FITs(
          df.results.estimate,
          latitude = user_latitude_choice,
          longitude = user_longitude_choice,
          pars = pars_list
        )
        output_file <- if (bool_dynamic) {
          file.path(output_dir, "estimate/plots", paste0("series_", name.endogenous, ".html"))
        } else {
          file.path(output_dir, "estimate/plots", paste0("series_", name.endogenous, ".png"))
        }
        if (bool_dynamic) {
          plt <- plotly::ggplotly(plot.series.FITs)
          htmlwidgets::saveWidget(plt, file = output_file)
        } else {
          ggsave(filename = output_file, plot = plot.series.FITs, width = 8, height = 6)
        }
        log_info("Saved H-SDPD time-series plot to {output_file}")
      }
    }, error = function(e) {
      log_info("Error generating time-series plots: {e$message}")
      stop("Failed to generate time-series plots")
    })
  } else {
    log_info("Time-series plots not available for {user_model_choice}")
  }

  # D) Save estimated results as CSV
  if (user_model_choice != "Model1_Simple") {
    log_info("Saving estimated results as CSV")
    tryCatch({
      df.results <- fun.prepare.df.results(df.results = df.results.estimate, model = user_model_choice)
      csv_path <- file.path(output_dir, "estimate/stats", "df_results_estimate.csv")
      write.csv(df.results, file = csv_path, row.names = FALSE)
      log_info("Saved CSV to {csv_path}")
    }, error = function(e) {
      log_info("Error generating CSV download: {e$message}")
      stop("Failed to generate CSV download")
    })
  } else {
    log_info("CSV download not available for {user_model_choice}")
  }

  log_info("ESTIMATE MODULE Completed")


  
  log_info("Starting VALIDATE MODULE")

  # FOCUS 6: Validate the Estimated Model
  # A) Plot of summary statistics of the residual series
  if (user_model_choice != "Model1_Simple") {
    log_info("Plotting residual summary statistics")
    tryCatch({
      for (stat_name in names(validation_stats)) {
        log_info("Plotting {stat_name}")
        output_filename <- paste0("residual_", stat_name, if (bool_dynamic) ".html" else ".png")
        output_path <- file.path(output_dir, "validate/plots", output_filename)
        stat_fun <- validation_stats[[stat_name]]
        fun.plot.stat.RESIDs(
          df.results = df.results.estimate,
          statistic = stat_fun,
          title = stat_name,
          pars = pars,
          bool_dynamic = bool_dynamic,
          output_path = output_path,
          na.rm = TRUE
        )

        log_info("Saved residual {stat_name} plot to {output_path}")
      }
    }, error = function(e) {
      log_info("Error plotting residual summary statistics: {e$message}")
      stop("Failed to plot residual summary statistics")
    })
  } else {
    log_info("Residual summary statistics not available for {user_model_choice}")
  }

  # B) Autocorrelation and normality tests
  if (user_model_choice != "Model1_Simple") {
    log_info("Plotting Ljung-Box autocorrelation test")
    tryCatch({
      LBtest_variants <- list(no_Benjamini_Yekutieli = FALSE, with_Benjamini_Yekutieli = TRUE)
      for (variant in names(LBtest_variants)) {
        BYadjust <- LBtest_variants[[variant]]
        suffix <- ifelse(BYadjust, "BYadjusted", "not_adjusted")
        output_filename <- paste0("residual_LBtest_", suffix, if (bool_dynamic) ".html" else ".png")
        output_path <- file.path(output_dir, "validate/plots", output_filename)
        fun.plot.stat.discrete.RESIDs(
          df.results = df.results.estimate,
          title = "Ljung-Box\nautocorrelation\ntest",
          statistic = fun.LBtest,
          alpha = pars_alpha,
          significant.test = TRUE,
          BYadjusted = BYadjust,
          pars = pars,
          bool_dynamic = bool_dynamic,
          output_path = output_path
        )
        log_info("Saved Ljung-Box test ({suffix}) plot to {output_path}")
      }
    }, error = function(e) {
      log_info("Error plotting Ljung-Box test: {e$message}")
      stop("Failed to plot Ljung-Box test")
    })

    log_info("Plotting Jarque-Bera normality test")
    tryCatch({
      JBtest_variants <- list(no_Benjamini_Yekutieli = FALSE, with_Benjamini_Yekutieli = TRUE)
      for (variant in names(JBtest_variants)) {
        BYadjust <- JBtest_variants[[variant]]
        suffix <- ifelse(BYadjust, "BYadjusted", "not_adjusted")
        output_filename <- paste0("residual_JBtest_", suffix, if (bool_dynamic) ".html" else ".png")
        output_path <- file.path(output_dir, "validate/plots", output_filename)
        fun.plot.stat.discrete.RESIDs(
          df.results = df.results.estimate,
          title = "Jarque-Bera\nnormality test",
          statistic = fun.JBtest,
          alpha = pars_alpha,
          significant.test = TRUE,
          BYadjusted = BYadjust,
          pars = pars,
          bool_dynamic = bool_dynamic,
          output_path = output_path
        )

        log_info("Saved Jarque-Bera test ({suffix}) plot to {output_path}")
      }
    }, error = function(e) {
      log_info("Error plotting Jarque-Bera test: {e$message}")
      stop("Failed to plot Jarque-Bera test")
    })
  } else {
    log_info("Autocorrelation and normality tests not available for {user_model_choice}")
  }

  # FOCUS 7: Bootstrap Validation for H-SDPD Models
  if (user_model_choice %in% c("Model6_HSDPD_user", "Model4_UHI", "Model5_RAB") && (user_model_choice == "Model6_HSDPD_user" || bool_update)) {
    log_info("Starting bootstrap validation")
    tryCatch({
      plan(multisession, workers = 2)
      df.test <- df.stime %>% future_map(
        fun.testing.parameters,
        correzione = CORREZIONE,
        n.boot = NBOOT,
        label.group = label.province,
        plot = FALSE,
        .options = furrr_options(seed = TRUE)
      )
      log_info("Assembling the results")
      df.results.test <- df.test %>%
        map(fun.assemble.test.results) %>%
        bind_rows()
      log_info("Bootstrap resampling completed")

      log_info("Saving the results")
      objects_to_save <- c(objects_to_save, "df.results.test")
      
      log_info("Comparing the bootstrap and observed time series")
      plot.devs <- fun.plot.coeffboot.TEST(df.results.test, alpha = pars_alpha, matrix1 = "sdevs.tsboot", pars = pars_list)
      boot_plot <- list(mean = 1, sd = 2)
      for (name in names(boot_plot)) {
        index <- boot_plot[[name]]
        plot_obj <- plot.devs[[index]]
        filename <- paste0("coeffboot_", name, if (bool_dynamic) ".html" else ".png")
        output_path <- file.path(output_dir, "bootstrap/plots", filename)
        if (bool_dynamic) {
          htmlwidgets::saveWidget(plotly::ggplotly(plot_obj), file = output_path, selfcontained = TRUE)
        } else {
          ggsave(filename = output_path, plot = plot_obj, width = 10, height = 6, dpi = 300)
        }
        log_info("Saved bootstrap {name} plot to {output_path}")
      }

      log_info("Plotting bootstrap distribution of the parameter estimators")
      boot_types <- list(
        significance = list(matrix1 = "coeff.hat", matrix2 = "pvalue.test", name = "coeff_hat"),
        bias = list(matrix1 = "coeff.bias.boot", name = "coeff_bias_boot"),
        standard_deviation = list(matrix1 = "coeff.sd.boot", name = "coeff_sd_boot")
      )
      for (type in names(boot_types)) {
        params <- boot_types[[type]]
        plot.coeff <- fun.plot.coeffboot.TEST(
          df.results.test,
          alpha = pars_alpha,
          matrix1 = params$matrix1,
          matrix2 = params$matrix2,
          pars = pars_list
        )
        
        log_info("Plotting bootstrap distribution of the parameter estimators")
        plot_obj <- plot.coeff[[user_coeff_choice]]
        filename <- paste0(params$name, if (bool_dynamic) ".html" else ".png")
        output_path <- file.path(output_dir, "bootstrap/plots", filename)
        if (bool_dynamic) {
          htmlwidgets::saveWidget(plotly::ggplotly(plot_obj), file = output_path, selfcontained = TRUE)
        } else {
          ggsave(filename = output_path, plot = plot_obj, width = 10, height = 6, dpi = 300)
        }
        log_info("Saved bootstrap {type} plot to {output_path}")
      }
      log_info("Bootstrap validation completed")
    }, error = function(e) {
      log_info("Error in bootstrap validation: {e$message}")
      stop("Failed to perform bootstrap validation")
    })
  } else {
    log_info("Bootstrap validation not available for {user_model_choice}")
  }

  log_info("VALIDATE MODULE Completed")

  
  
  

  log_info("\nRISK MAP MODULE Started")

  # Helper function to save plots
  save_plot <- function(plot, filename, output_dir, bool_dynamic, width = 8, height = 6, dpi = 300) {
    output_path <- file.path(output_dir, "riskmap/plots", filename)
    if (bool_dynamic) {
      htmlwidgets::saveWidget(plotly::ggplotly(plot), output_path, selfcontained = TRUE)
    } else {
      ggsave(output_path, plot = plot, width = width, height = height, dpi = dpi)
    }
  }

  # Helper function to save tables
  save_table <- function(data, filename, output_dir, bool_dynamic) {
    output_path <- file.path(output_dir, "riskmap/plots", filename)
    if (bool_dynamic) {
      widget <- datatable(data, filter = "top")
    } else {
      widget <- datatable(head(data), filter = "none")
    }
    htmlwidgets::saveWidget(widget, file = output_path, selfcontained = TRUE)
  }

  # Helper function for spatial regression HTML output
  save_spatial_regression <- function(modelli, formule, ii, output_dir, prefix) {
    output_filename <- paste0(prefix, "_", ii, ".html")
    output_path <- file.path(output_dir, "riskmap/plots", output_filename)
    plots_dir <- file.path(output_dir, "riskmap/plots")
    plot_files <- diagnostic_models(modelli[[ii]], output_dir = plots_dir, filename_prefix = paste0(prefix, "_", ii))
    
    output <- capture.output({
      cat(paste("\n The model is:", formule[[ii]][2], formule[[ii]][1], formule[[ii]][3], "\n"))
      cat("\n", Evaluate_global_Test(modelli[[ii]], alpha = pars_alpha), "\n Details are presented below:")
    })
    suffix_output <- capture.output(summary(modelli[[ii]]))
    
    html_content <- paste0(
      "<html><head><title>Spatial Regression Model ", ii, "</title></head><body>",
      "<pre>", paste(output, collapse = "<br>"), "</pre>",
      "<div>",
      "<div style='margin: 10px;'>",
      "<img src='", basename(plot_files[1]), "' alt='Residuals vs Fitted' style='max-width: 100%; height: auto;'>",
      "</div>",
      "<div style='margin: 10px;'>",
      "<img src='", basename(plot_files[2]), "' alt='Normal Q-Q Plot' style='max-width: 100%; height: auto;'>",
      "</div>",
      "<div>",
      "<pre>", paste(suffix_output, collapse = "<br>"), "</pre>",
      "</div>",
      "</body></html>"
    )
    writeLines(html_content, con = output_path)
  }

  # Model 1: Simple Linear Trend Analysis
  if (user_model_choice == "Model_1") {
    log_info("Model 1: Simple Linear Trend Analysis")
    
    # Common summary statistics function
    summary_stats <- function(df, test_col, output_name) {
      df_data <- df[[name.endogenous]] |>
        select(Longitude, Latitude, !!sym(test_col)) |>
        unnest(cols = !!sym(test_col))
      npixels <- dim(df_data)[1]
      row1 <- table(factor(df_data$trend_lab, levels = c("Neg", "Null", "Pos")))
      row2 <- table(factor(df_data$trend_lab_BY, levels = c("Neg", "Null", "Pos")))
      dati <- data.frame(
        as.vector(row1),
        paste(round(prop.table(row1) * 100, 1), "%", sep = ""),
        as.vector(row2),
        paste(round(prop.table(row2) * 100, 1), "%", sep = "")
      )
      dimnames(dati)[[1]] <- c("Positive trends", "Null trend", "Negative trends")
      dimnames(dati)[[2]] <- c("Significant pixels", "%", "Significant pixels (BY adjusted)", "%")
      save_table(dati, paste0(output_name, "_summary_table.html"), output_dir, bool_dynamic)
    }
    
    # A) Sen’s Slope Test
    log_info("Sen’s Slope Test")
    plt_beta_sens <- TrendSens_df[[name.endogenous]] |>
      select(Longitude, Latitude, Sens_test) |>
      unnest(cols = c(Sens_test)) |>
      ggplot(aes(x = Longitude, y = Latitude, col = estimate)) +
      geom_point(size = size.point) +
      scale_color_gradient2(high = "red", low = "blue", mid = "grey90", midpoint = 0) +
      guides(fill = "none") +
      labs(y = "Latitude", x = "Longitude", col = "Trend", caption = captions_list[["plt_beta_sens"]]) +
      ggtitle(char(name.endogenous)) +
      theme_bw()
    save_plot(plt_beta_sens, paste0("sens_estimates", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    plt_sig_sens <- TrendSens_df[[name.endogenous]] |>
      select(Longitude, Latitude, Sens_test) |>
      unnest(cols = c(Sens_test)) %>%
      ggplot(aes(x = Longitude, y = Latitude, col = trend_lab)) +
      geom_point(size = size.point) +
      scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
      guides(fill = "none") +
      labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_sig_sens"]]) +
      ggtitle(paste(name.endogenous, "  (Significant tests at level ", pars_alpha * 100, "%)", sep = "")) +
      theme_bw()
    save_plot(plt_sig_sens, paste0("sens_significant_pixels", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    plt_sig_sens_BY <- TrendSens_df[[name.endogenous]] |>
      select(Longitude, Latitude, Sens_test) |>
      unnest(cols = c(Sens_test)) %>%
      ggplot(aes(x = Longitude, y = Latitude, col = trend_lab_BY)) +
      geom_point(size = size.point) +
      scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
      guides(fill = "none") +
      labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_sig_sens_BY"]]) +
      ggtitle(paste(name.endogenous, "  (Significant tests with BY correction at level ", pars_alpha * 100, "%)", sep = "")) +
      theme_bw()
    save_plot(plt_sig_sens_BY, paste0("sens_by_adjusted", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    summary_stats(TrendSens_df, "Sens_test", "sens")
    
    # B) Cox and Snell (CS) Test
    log_info("Cox and Snell Test")
    plt_beta_cs <- TrendCS_df[[name.endogenous]] |>
      select(Longitude, Latitude, CS_test) |>
      unnest(cols = c(CS_test)) |>
      ggplot(aes(x = Longitude, y = Latitude, col = estimate)) +
      geom_point(size = size.point) +
      scale_color_gradient2(high = "red", low = "blue", mid = "grey90", midpoint = 0) +
      guides(fill = "none") +
      labs(y = "Latitude", x = "Longitude", col = "Trend", caption = captions_list[["plt_beta_cs"]]) +
      ggtitle(char(name.endogenous)) +
      theme_bw()
    save_plot(plt_beta_cs, paste0("cs_estimates", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    plt_sig_cs <- TrendCS_df[[name.endogenous]] |>
      select(Longitude, Latitude, CS_test) |>
      unnest(cols = c(CS_test)) %>%
      ggplot(aes(x = Longitude, y = Latitude, col = trend_lab)) +
      geom_point(size = size.point) +
      scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
      guides(fill = "none") +
      labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_sig_cs"]]) +
      ggtitle(paste(name.endogenous, "  (Significant tests at level ", pars_alpha * 100, "%)", sep = "")) +
      theme_bw()
    save_plot(plt_sig_cs, paste0("cs_significant_pixels", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    plt_sig_cs_BY <- TrendCS_df[[name.endogenous]] |>
      select(Longitude, Latitude, CS_test) |>
      unnest(cols = c(CS_test)) %>%
      ggplot(aes(x = Longitude, y = Latitude, col = trend_lab_BY)) +
      geom_point(size = size.point) +
      scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
      guides(fill = "none") +
      labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_sig_cs_BY"]]) +
      ggtitle(paste(name.endogenous, "  (Significant tests with BY correction at level ", pars_alpha * 100, "%)", sep = "")) +
      theme_bw()
    save_plot(plt_sig_cs_BY, paste0("cs_by_adjusted", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    summary_stats(TrendCS_df, "CS_test", "cs")
    
    # C) Mann-Kendall (MK) Test
    log_info("Mann-Kendall Test")
    plt_beta_mk <- TrendMK_df[[name.endogenous]] |>
      select(Longitude, Latitude, MK_test) |>
      unnest(cols = c(MK_test)) |>
      ggplot(aes(x = Longitude, y = Latitude, col = estimate)) +
      geom_point(size = size.point) +
      scale_color_gradient2(high = "red", low = "blue", mid = "grey90", midpoint = 0) +
      guides(fill = "none") +
      labs(y = "Latitude", x = "Longitude", col = "Trend", caption = captions_list[["plt_beta_mk"]]) +
      ggtitle(char(name.endogenous)) +
      theme_bw()
    save_plot(plt_beta_mk, paste0("mk_estimates", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    plt_sig_mk <- TrendMK_df[[name.endogenous]] |>
      select(Longitude, Latitude, MK_test) |>
      unnest(cols = c(MK_test)) %>%
      ggplot(aes(x = Longitude, y = Latitude, col = trend_lab)) +
      geom_point(size = size.point) +
      scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
      guides(fill = "none") +
      labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_sig_mk"]]) +
      ggtitle(paste(name.endogenous, "  (Significant tests at level ", pars_alpha * 100, "%)", sep = "")) +
      theme_bw()
    save_plot(plt_sig_mk, paste0("mk_significant_pixels", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    plt_sig_mk_BY <- TrendMK_df[[name.endogenous]] |>
      select(Longitude, Latitude, MK_test) |>
      unnest(cols = c(MK_test)) %>%
      ggplot(aes(x = Longitude, y = Latitude, col = trend_lab_BY)) +
      geom_point(size = size.point) +
      scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
      guides(fill = "none") +
      labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_sig_mk_BY"]]) +
      ggtitle(paste(name.endogenous, "  (Significant tests with BY correction at level ", pars_alpha * 100, "%)", sep = "")) +
      theme_bw()
    save_plot(plt_sig_mk_BY, paste0("mk_by_adjusted", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    summary_stats(TrendMK_df, "MK_test", "mk")
    
    # D) Seasonal Mann-Kendall (SMK) Test
    log_info("Seasonal Mann-Kendall Test")
    plt_beta_smk <- TrendSMK_df[[name.endogenous]] |>
      select(Longitude, Latitude, SMK_test) |>
      unnest(cols = c(SMK_test)) |>
      ggplot(aes(x = Longitude, y = Latitude, col = estimate)) +
      geom_point(size = size.point) +
      scale_color_gradient2(high = "red", low = "blue", mid = "grey90", midpoint = 0) +
      guides(fill = "none") +
      labs(y = "Latitude", x = "Longitude", col = "Trend-statistic", caption = captions_list[["plt_beta_smk"]]) +
      ggtitle(char(name.endogenous)) +
      theme_bw()
    save_plot(plt_beta_smk, paste0("smk_estimates", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    plt_sig_smk <- TrendSMK_df[[name.endogenous]] |>
      select(Longitude, Latitude, SMK_test) |>
      unnest(cols = c(SMK_test)) %>%
      ggplot(aes(x = Longitude, y = Latitude, col = trend_lab)) +
      geom_point(size = size.point) +
      scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
      guides(fill = "none") +
      labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_sig_smk"]]) +
      ggtitle(paste(name.endogenous, "  (Significant tests at level ", pars_alpha * 100, "%)", sep = "")) +
      theme_bw()
    save_plot(plt_sig_smk, paste0("smk_significant_pixels", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    plt_sig_smk_BY <- TrendSMK_df[[name.endogenous]] |>
      select(Longitude, Latitude, SMK_test) |>
      unnest(cols = c(SMK_test)) %>%
      ggplot(aes(x = Longitude, y = Latitude, col = trend_lab_BY)) +
      geom_point(size = size.point) +
      scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
      guides(fill = "none") +
      labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_sig_smk_BY"]]) +
      ggtitle(paste(name.endogenous, "  (Significant tests with BY correction at level ", pars_alpha * 100, "%)", sep = "")) +
      theme_bw()
    save_plot(plt_sig_smk_BY, paste0("smk_by_adjusted", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    summary_stats(TrendSMK_df, "SMK_test", "smk")
    
    # E) Pre-whitened Mann-Kendall (PWMK) Test
    log_info("Pre-whitened Mann-Kendall Test")
    plt_beta_pwmk <- TrendPWMK_df[[name.endogenous]] |>
      select(Longitude, Latitude, PWMK_test) |>
      unnest(cols = c(PWMK_test)) |>
      ggplot(aes(x = Longitude, y = Latitude, col = estimate)) +
      geom_point(size = size.point) +
      scale_color_gradient2(high = "red", low = "blue", mid = "grey90", midpoint = 0) +
      guides(fill = "none") +
      labs(y = "Latitude", x = "Longitude", col = "Trend", caption = captions_list[["plt_beta_pwmk"]]) +
      ggtitle(char(name.endogenous)) +
      theme_bw()
    save_plot(plt_beta_pwmk, paste0("pwmk_estimates", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    plt_sig_pwmk <- TrendPWMK_df[[name.endogenous]] |>
      select(Longitude, Latitude, PWMK_test) |>
      unnest(cols = c(PWMK_test)) %>%
      ggplot(aes(x = Longitude, y = Latitude, col = trend_lab)) +
      geom_point(size = size.point) +
      scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
      guides(fill = "none") +
      labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_sig_pwmk"]]) +
      ggtitle(paste(name.endogenous, "  (Significant tests at level ", pars_alpha * 100, "%)", sep = "")) +
      theme_bw()
    save_plot(plt_sig_pwmk, paste0("pwmk_significant_pixels", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    plt_sig_pwmk_BY <- TrendPWMK_df[[name.endogenous]] |>
      select(Longitude, Latitude, PWMK_test) |>
      unnest(cols = c(PWMK_test)) %>%
      ggplot(aes(x = Longitude, y = Latitude, col = trend_lab_BY)) +
      geom_point(size = size.point) +
      scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
      guides(fill = "none") +
      labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_sig_pwmk_BY"]]) +
      ggtitle(paste(name.endogenous, "  (Significant tests with BY correction at level ", pars_alpha * 100, "%)", sep = "")) +
      theme_bw()
    save_plot(plt_sig_pwmk_BY, paste0("pwmk_by_adjusted", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    summary_stats(TrendPWMK_df, "PWMK_test", "pwmk")
    
    # F) Bias-corrected Pre-whitened (BCPW) Test
    log_info("Bias-corrected Pre-whitened Test")
    plt_beta_bcpw <- TrendBCPW_df[[name.endogenous]] |>
      select(Longitude, Latitude, BCPW_test) |>
      unnest(cols = c(BCPW_test)) |>
      ggplot(aes(x = Longitude, y = Latitude, col = estimate)) +
      geom_point(size = size.point) +
      scale_color_gradient2(high = "red", low = "blue", mid = "grey90", midpoint = 0) +
      guides(fill = "none") +
      labs(y = "Latitude", x = "Longitude", col = "Trend", caption = captions_list[["plt_beta_bcpw"]]) +
      ggtitle(char(name.endogenous)) +
      theme_bw()
    save_plot(plt_beta_bcpw, paste0("bcpw_estimates", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    plt_sig_bcpw <- TrendBCPW_df[[name.endogenous]] |>
      select(Longitude, Latitude, BCPW_test) |>
      unnest(cols = c(BCPW_test)) %>%
      ggplot(aes(x = Longitude, y = Latitude, col = trend_lab)) +
      geom_point(size = size.point) +
      scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
      guides(fill = "none") +
      labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_sig_bcpw"]]) +
      ggtitle(paste(name.endogenous, "  (Significant tests at level ", pars_alpha * 100, "%)", sep = "")) +
      theme_bw()
    save_plot(plt_sig_bcpw, paste0("bcpw_significant_pixels", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    plt_sig_bcpw_BY <- TrendBCPW_df[[name.endogenous]] |>
      select(Longitude, Latitude, BCPW_test) |>
      unnest(cols = c(BCPW_test)) %>%
      ggplot(aes(x = Longitude, y = Latitude, col = trend_lab_BY)) +
      geom_point(size = size.point) +
      scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
      guides(fill = "none") +
      labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_sig_bcpw_BY"]]) +
      ggtitle(paste(name.endogenous, "  (Significant tests with BY correction at level ", pars_alpha * 100, "%)", sep = "")) +
      theme_bw()
    save_plot(plt_sig_bcpw_BY, paste0("bcpw_by_adjusted", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    summary_stats(TrendBCPW_df, "BCPW_test", "bcpw")
    
    # G) Robust Trend with Newey-West Correction
    log_info("Robust Trend with Newey-West Correction")
    plt_beta_robust <- TrendRobust_df[[name.endogenous]] |>
      select(Longitude, Latitude, Robust_test) |>
      unnest(cols = c(Robust_test)) |>
      ggplot(aes(x = Longitude, y = Latitude, col = estimate)) +
      geom_point(size = size.point) +
      scale_color_gradient2(high = "red", low = "blue", mid = "grey90", midpoint = 0) +
      guides(fill = "none") +
      labs(y = "Latitude", x = "Longitude", col = "Trend", caption = captions_list[["plt_beta_robust"]]) +
      ggtitle(char(name.endogenous)) +
      theme_bw()
    save_plot(plt_beta_robust, paste0("robust_estimates", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    plt_beta_robust_sd <- TrendRobust_df[[name.endogenous]] |>
      select(Longitude, Latitude, Robust_test) |>
      unnest(cols = c(Robust_test)) |>
      ggplot(aes(x = Longitude, y = Latitude, col = std.error)) +
      geom_point(size = size.point) +
      scale_color_gradient2(high = "red", low = "blue", mid = "grey90", midpoint = 0) +
      guides(fill = "none") +
      labs(y = "Latitude", x = "Longitude", caption = captions_list[["plt_beta_robust_sd"]]) +
      ggtitle(char(name.endogenous)) +
      theme_bw()
    save_plot(plt_beta_robust_sd, paste0("robust_std_errors", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    plt_sig_robust <- TrendRobust_df[[name.endogenous]] |>
      select(Longitude, Latitude, Robust_test) |>
      unnest(cols = c(Robust_test)) %>%
      ggplot(aes(x = Longitude, y = Latitude, col = trend_lab)) +
      geom_point(size = size.point) +
      scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
      guides(fill = "none") +
      labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_sig_robust"]]) +
      ggtitle(paste(name.endogenous, "  (Significant tests at level ", pars_alpha * 100, "%)", sep = "")) +
      theme_bw()
    save_plot(plt_sig_robust, paste0("robust_significant_pixels", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    plt_sig_robust_BY <- TrendRobust_df[[name.endogenous]] |>
      select(Longitude, Latitude, Robust_test) |>
      unnest(cols = c(Robust_test)) %>%
      ggplot(aes(x = Longitude, y = Latitude, col = trend_lab_BY)) +
      geom_point(size = size.point) +
      scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
      guides(fill = "none") +
      labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_sig_robust_BY"]]) +
      ggtitle(paste(name.endogenous, "  (Significant tests with BY correction at level ", pars_alpha * 100, "%)", sep = "")) +
      theme_bw()
    save_plot(plt_sig_robust_BY, paste0("robust_by_adjusted", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    summary_stats(TrendRobust_df, "Robust_test", "robust")
    
    # H) Score Function Combination
    log_info("Score Function Combination")
    score_values <- ComputeScoreValue(
      TrendSens_df[[name.endogenous]],
      TrendCS_df[[name.endogenous]],
      TrendMK_df[[name.endogenous]],
      TrendSMK_df[[name.endogenous]],
      TrendPWMK_df[[name.endogenous]],
      TrendBCPW_df[[name.endogenous]],
      TrendRobust_df[[name.endogenous]]
    )
    
    plt_score <- score_values |>
      ggplot(aes(y = Latitude, x = Longitude, col = score)) +
      geom_point(size = size.point) +
      scale_color_gradient2(high = "red", low = "blue", mid = "green", midpoint = 0) +
      guides(fill = "none") +
      labs(x = "Longitude", y = "Latitude", col = "Score", caption = captions_list[["plt_score"]]) +
      ggtitle(char(name.endogenous)) +
      theme_bw()
    save_plot(plt_score, paste0("score_estimates", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    plt_BY <- score_values %>%
      ggplot(aes(y = Latitude, x = Longitude, col = score_BY)) +
      geom_point(size = size.point) +
      scale_color_gradient2(high = "red", low = "blue", mid = "green", midpoint = 0) +
      guides(fill = "none") +
      labs(x = "Longitude", y = "Latitude", caption = captions_list[["plt_BY"]]) +
      ggtitle(paste(name.endogenous, " (Score value with BY correction)")) +
      theme_bw()
    save_plot(plt_BY, paste0("score_by_adjusted", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    # I) Majority Voting Combination
    log_info("Majority Voting Combination")
    mv <- ComputeMajorityVoteDataFrame(
      TrendSens_df[[name.endogenous]],
      TrendCS_df[[name.endogenous]],
      TrendMK_df[[name.endogenous]],
      TrendSMK_df[[name.endogenous]],
      TrendPWMK_df[[name.endogenous]],
      TrendBCPW_df[[name.endogenous]],
      TrendRobust_df[[name.endogenous]]
    )
    
    plt_mv <- mv$Vote %>%
      select(Longitude, Latitude, Vote) |>
      unnest(cols = c(Vote)) |>
      ggplot(aes(x = Longitude, y = Latitude, col = Vote)) +
      geom_point(size = size.point) +
      scale_color_manual(labels = c("Neg", "Null", "Pos"), values = c("-1" = "blue", "0" = "green", "1" = "red")) +
      guides(fill = "none") +
      labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_mv"]]) +
      ggtitle(paste(name.endogenous, " (majority vote)")) +
      theme_bw()
    save_plot(plt_mv, paste0("mv_estimates", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    plt_mv_BY <- mv$Vote_BY %>%
      select(Longitude, Latitude, Vote) |>
      unnest(cols = c(Vote)) |>
      ggplot(aes(x = Longitude, y = Latitude, col = Vote)) +
      geom_point(size = size.point) +
      scale_color_manual(labels = c("Neg", "Null", "Pos"), values = c("-1" = "blue", "0" = "green", "1" = "red")) +
      guides(fill = "none") +
      labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_mv_BY"]]) +
      ggtitle(paste(name.endogenous, " (majority vote with BY correction)")) +
      theme_bw()
    save_plot(plt_mv_BY, paste0("mv_by_adjusted", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    row1 <- table(factor(mv$Vote$Vote, levels = c("Neg", "Null", "Pos")))
    row2 <- table(factor(mv$Vote_BY$Vote, levels = c("Neg", "Null", "Pos")))
    dati <- data.frame(
      as.vector(row1),
      paste(round(prop.table(row1) * 100, 1), "%", sep = ""),
      as.vector(row2),
      paste(round(prop.table(row2) * 100, 1), "%", sep = "")
    )
    dimnames(dati)[[1]] <- c("Positive trends", "Null trend", "Negative trends")
    dimnames(dati)[[2]] <- c("Significant pixels", "%", "Significant pixels (BY adjusted)", "%")
    save_table(dati, "mv_summary_table.html", output_dir, bool_dynamic)
  }

  # Models 2 and 3: MB-Trend Analysis
  if (user_model_choice %in% c("Model_2", "Model_3")) {
    log_info("Models 2 and 3: MB-Trend Analysis")
    
    # 1° Stage - Temporal Analysis
    log_info("Temporal Analysis")
    plt_MB_estimates <- modelStats_df$modStats[[name.endogenous]] |>
      ggplot(aes(x = Longitude, y = Latitude, col = estimate)) +
      geom_point(size = size.point) +
      scale_color_gradient2(high = "red", low = "blue", mid = "white", midpoint = 0) +
      guides(fill = "none") +
      labs(y = "Latitude", x = "Longitude", col = "Trend", caption = captions_list[["plt_MB_estimates"]]) +
      ggtitle(char(name.endogenous))
    save_plot(plt_MB_estimates, paste0("mb_estimates", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    plt_MB_std <- modelStats_df$modStats[[name.endogenous]] |>
      ggplot(aes(x = Longitude, y = Latitude, col = std.error)) +
      geom_point(size = size.point) +
      scale_color_gradient2(high = "red", low = "blue", mid = "white", midpoint = 0) +
      guides(fill = "none") +
      labs(y = "Latitude", x = "Longitude", caption = captions_list[["plt_MB_std"]]) +
      ggtitle(char(name.endogenous))
    save_plot(plt_MB_std, paste0("mb_std_errors", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    plt_MB_sig <- modelStats_df$modStats[[name.endogenous]] |>
      ggplot(aes(x = Longitude, y = Latitude, col = trend_lab)) +
      geom_point(size = size.point) +
      scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
      guides(fill = "none") +
      labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_MB_sig"]]) +
      ggtitle(paste(name.endogenous, "  (Significant tests at level ", pars_alpha * 100, "%)", sep = ""))
    save_plot(plt_MB_sig, paste0("mb_significant_pixels", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    plt_MB_sig_BY <- modelStats_df$modStats[[name.endogenous]] |>
      ggplot(aes(x = Longitude, y = Latitude, col = trend_lab_BY)) +
      geom_point(size = size.point) +
      scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
      guides(fill = "none") +
      labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_MB_sig_BY"]]) +
      ggtitle(paste(name.endogenous, "  (Significant tests with BY correction at level ", pars_alpha * 100, "%)", sep = ""))
    save_plot(plt_MB_sig_BY, paste0("mb_by_adjusted", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    row1 <- table(factor(modelStats_df$modStats[[name.endogenous]]$trend_lab, levels = c("Neg", "Null", "Pos")))
    row2 <- table(factor(modelStats_df$modStats[[name.endogenous]]$trend_lab_BY, levels = c("Neg", "Null", "Pos")))
    dati <- data.frame(
      as.vector(row1),
      paste(round(prop.table(row1) * 100, 1), "%", sep = ""),
      as.vector(row2),
      paste(round(prop.table(row2) * 100, 1), "%", sep = "")
    )
    dimnames(dati)[[1]] <- c("Positive trends", "Null trend", "Negative trends")
    dimnames(dati)[[2]] <- c("Significant pixels", "%", "Significant pixels (BY adjusted)", "%")
    save_table(dati, "mb_summary_table.html", output_dir, bool_dynamic)
    
    # 2° Stage - Spatial Analysis
    log_info("Spatial Analysis")
    output_path <- file.path(output_dir, "riskmap/plots", "map_effect.html")
    capture.output(print(spatialModels_df[[name.endogenous]]$GLS.int), file = output_path)
    capture.output(EvaluateTest_map(spatialModels_df[[name.endogenous]]$GLS.int), file = output_path, append = TRUE)
    
    output_path <- file.path(output_dir, "riskmap/plots", "lc_effect.html")
    capture.output(print(spatialModels_df[[name.endogenous]]$GLS.lc), file = output_path)
    capture.output(EvaluateTest_LC(spatialModels_df[[name.endogenous]]$GLS.lc), file = output_path, append = TRUE)
    
    output_path <- file.path(output_dir, "riskmap/plots", "latitude_effect.html")
    capture.output(print(spatialModels_df[[name.endogenous]]$GLS.lat), file = output_path)
    capture.output(EvaluateTest_latitude(spatialModels_df[[name.endogenous]]$GLS.lat), file = output_path, append = TRUE)
    
    output_path <- file.path(output_dir, "riskmap/plots", "longitude_effect.html")
    capture.output(print(spatialModels_df[[name.endogenous]]$GLS.lon), file = output_path)
    capture.output(EvaluateTest_longitude(spatialModels_df[[name.endogenous]]$GLS.lon), file = output_path, append = TRUE)
    
    output_path <- file.path(output_dir, "riskmap/plots", "longitude_lc_interaction.html")
    capture.output(print(spatialModels_df[[name.endogenous]]$GLS.lonxlc), file = output_path)
    capture.output(EvaluateTest_lonxlc(spatialModels_df[[name.endogenous]]$GLS.lonxlc), file = output_path, append = TRUE)
    
    output_path <- file.path(output_dir, "riskmap/plots", "latitude_lc_interaction.html")
    capture.output(print(spatialModels_df[[name.endogenous]]$GLS.latxlc), file = output_path)
    capture.output(EvaluateTest_latxlc(spatialModels_df[[name.endogenous]]$GLS.latxlc), file = output_path, append = TRUE)
    
    plt_MB_lc <- slc_df |>
      ggplot(aes(x = Longitude, y = Latitude, color = LC)) +
      geom_point(size = size.point) +
      guides(fill = "none") +
      labs(x = "Longitude", y = "Latitude", title = "MAP of Land Cover classes", col = "LC", caption = captions_list[["plt_MB_lc"]])
    save_plot(plt_MB_lc, paste0("land_cover_map", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
  }

  # Models 4, 5, and 6: Spatio-temporal H-SDPD Analysis
  if (user_model_choice %in% c("Model_4", "Model_5", "Model_6")) {
    log_info("Models 4, 5, and 6: Spatio-temporal H-SDPD Analysis")
    
    # Trend Estimates
    log_info("Plotting Trend Estimates")
    plt_SDPD_estimates <- df.results.test |>
      ggplot(aes(x = lon, y = lat, col = coeff.hat$trend)) +
      geom_point(size = size.point) +
      scale_color_gradient2(high = "red", low = "blue", mid = "white", midpoint = 0) +
      guides(fill = "none") +
      labs(y = "Latitude", x = "Longitude", col = "Trend", caption = captions_list[["plt_SDPD_estimates"]]) +
      ggtitle(char(name.endogenous))
    save_plot(plt_SDPD_estimates, paste0("SDPD_trend_estimates", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    # Standard Errors
    log_info("Plotting Trend Standard Errors")
    plt_SDPD_std <- df.results.test |>
      ggplot(aes(x = lon, y = lat, col = coeff.sd.boot$trend)) +
      geom_point(size = size.point) +
      scale_color_gradient2(high = "red", low = "blue", mid = "white", midpoint = 0) +
      guides(fill = "none") +
      labs(y = "Latitude", x = "Longitude", col = "Std. Error", caption = captions_list[["plt_SDPD_std"]]) +
      ggtitle(char(name.endogenous))
    save_plot(plt_SDPD_std, paste0("SDPD_trend_std_error", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    # Significant Pixels
    log_info("Plotting Trend Significant Pixels")
    dati <- data.frame(
      lon = df.results.test$lon,
      lat = df.results.test$lat,
      estimate = df.results.test$coeff.hat$trend,
      stdev = df.results.test$coeff.sd.boot$trend,
      pvalue.test = df.results.test$pvalue.test$trend
    ) |>
      mutate(sig_trend = pvalue.test < pars_alpha) |>
      mutate(trend1 = ifelse(estimate > 0 & sig_trend == TRUE, 1, 0)) |>
      mutate(trend2 = ifelse(estimate < 0 & sig_trend == TRUE, -1, 0)) |>
      mutate(trend_sdpd = factor(trend1 + trend2)) |>
      mutate(trend_sdpd_lab = recode(trend_sdpd, "-1" = "Neg", "0" = "Null", "1" = "Pos")) |>
      select(-c(trend1, trend2)) |>
      mutate(p.value_sdpd_BY = p.adjust(pvalue.test, method = "BY")) |>
      mutate(sig_trend_BY = p.value_sdpd_BY < pars_alpha) |>
      mutate(trend1 = ifelse(estimate > 0 & sig_trend_BY == TRUE, 1, 0)) |>
      mutate(trend2 = ifelse(estimate < 0 & sig_trend_BY == TRUE, -1, 0)) |>
      mutate(trend_sdpd_BY = factor(trend1 + trend2)) |>
      mutate(trend_sdpd_lab_BY = recode(trend_sdpd_BY, "-1" = "Neg", "0" = "Null", "1" = "Pos"))
    
    plt_sdpd <- dati |>
      ggplot(aes(x = lon, y = lat, col = trend_sdpd_lab)) +
      geom_point(size = size.point) +
      scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
      guides(fill = "none") +
      labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_sdpd"]]) +
      ggtitle(paste(name.endogenous, "  (Significant tests at level ", pars_alpha * 100, "%)", sep = ""))
    save_plot(plt_sdpd, paste0("SDPD_trend_signefecant_pixels", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    # Adjusted (BY) Test
    log_info("Plotting Trend Adjusted BY Test")
    plt_SDPD_sig_BY <- dati |>
      ggplot(aes(x = lon, y = lat, col = trend_sdpd_lab_BY)) +
      geom_point(size = size.point) +
      scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
      guides(fill = "none") +
      labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_SDPD_sig_BY"]]) +
      ggtitle(paste(name.endogenous, "  (Significant tests with BY correction at level ", pars_alpha * 100, "%)", sep = ""))
    save_plot(plt_SDPD_sig_BY, paste0("SDPD_adjusted_BY", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    # Summary Statistics
    log_info("Saving Spatio-temporal Trend Analysis Statistics")
    row1 <- table(factor(dati$trend_sdpd_lab, levels = c("Neg", "Null", "Pos")))
    row2 <- table(factor(dati$trend_sdpd_lab_BY, levels = c("Neg", "Null", "Pos")))
    dati_summary <- data.frame(
      as.vector(row1),
      paste(round(prop.table(row1) * 100, 1), "%", sep = ""),
      as.vector(row2),
      paste(round(prop.table(row2) * 100, 1), "%", sep = "")
    )
    dimnames(dati_summary)[[1]] <- c("Positive trends", "Null trend", "Negative trends")
    dimnames(dati_summary)[[2]] <- c("Significant pixels", "%", "Significant pixels (BY adjusted)", "%")
    save_table(dati_summary, "SDPD_table_summary.html", output_dir, bool_dynamic)
    
    # Spatial Regression of Trend Parameters
    log_info("Plotting Spatial Regression of TREND Parameters")
    modelli_globali <- fun.estimate.global.models(df.results = df.results.estimate, slc = slc_df, name.covariates = name.covariates, name.response = "trend")
    formule <- modelli_globali[[7]]
    
    for (ii in 1:min(length(modelli_globali), 6)) {
      save_spatial_regression(modelli_globali, formule, ii, output_dir, "patial_regression")
    }
    
    # Land Cover Map
    log_info("Plotting Land Cover Map")
    plt_FE_lc <- slc_df |>
      ggplot(aes(x = Longitude, y = Latitude, color = LC)) +
      geom_point(size = size.point) +
      guides(fill = "none") +
      labs(x = "Longitude", y = "Latitude", title = "MAP of Land Cover classes", col = "LC", caption = captions_list[["plt_FE_lc"]])
    save_plot(plt_FE_lc, paste0("plt_FE_lc_map", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    # Fixed Effects Analysis
    log_info("Plotting Fixed Effects Estimates")
    plt_FE_estimates <- df.results.test |>
      ggplot(aes(x = lon, y = lat, col = coeff.hat$fixed_effects)) +
      geom_point(size = size.point) +
      scale_color_gradient2(high = "red", low = "blue", mid = "white", midpoint = 0) +
      guides(fill = "none") +
      labs(y = "Latitude", x = "Longitude", col = "Fixed Effects", caption = captions_list[["plt_FE_estimates"]]) +
      ggtitle(char(name.endogenous))
    save_plot(plt_FE_estimates, paste0("FE_estimates_map", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    log_info("Plotting Fixed Effects Standard Errors")
    plt_FE_std <- df.results.test |>
      ggplot(aes(x = lon, y = lat, col = coeff.sd.boot$fixed_effects)) +
      geom_point(size = size.point) +
      scale_color_gradient2(high = "red", low = "blue", mid = "white", midpoint = 0) +
      guides(fill = "none") +
      labs(y = "Latitude", x = "Longitude", col = "std.error", caption = captions_list[["plt_FE_std"]]) +
      ggtitle(char(name.endogenous))
    save_plot(plt_FE_std, paste0("plt_FE_std_map", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    log_info("Plotting Fixed Effects Significant Pixels")
    dati <- data.frame(
      lon = df.results.test$lon,
      lat = df.results.test$lat,
      estimate = df.results.test$coeff.hat$fixed_effects,
      stdev = df.results.test$coeff.sd.boot$fixed_effects,
      pvalue.test = df.results.test$pvalue.test$fixed_effects
    ) |>
      mutate(sig_trend = pvalue.test < pars_alpha) |>
      mutate(trend1 = ifelse(estimate > 0 & sig_trend == TRUE, 1, 0)) |>
      mutate(trend2 = ifelse(estimate < 0 & sig_trend == TRUE, -1, 0)) |>
      mutate(trend_sdpd = factor(trend1 + trend2)) |>
      mutate(trend_sdpd_lab = recode(trend_sdpd, "-1" = "Neg", "0" = "Null", "1" = "Pos")) |>
      select(-c(trend1, trend2)) |>
      mutate(p.value_sdpd_BY = p.adjust(pvalue.test, method = "BY")) |>
      mutate(sig_trend_BY = p.value_sdpd_BY < pars_alpha) |>
      mutate(trend1 = ifelse(estimate > 0 & sig_trend_BY == TRUE, 1, 0)) |>
      mutate(trend2 = ifelse(estimate < 0 & sig_trend_BY == TRUE, -1, 0)) |>
      mutate(trend_sdpd_BY = factor(trend1 + trend2)) |>
      mutate(trend_sdpd_lab_BY = recode(trend_sdpd_BY, "-1" = "Neg", "0" = "Null", "1" = "Pos"))
    
    plt_FE_sdpd <- dati |>
      ggplot(aes(x = lon, y = lat, col = trend_sdpd_lab)) +
      geom_point(size = size.point) +
      scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
      guides(fill = "none") +
      labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_FE_sdpd"]]) +
      ggtitle(paste(name.endogenous, "  (Significant tests at level ", pars_alpha * 100, "%)", sep = ""))
    save_plot(plt_FE_sdpd, paste0("plt_FE_sdpd_map", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    log_info("Plotting Fixed Effects Adjusted (BY) Test")
    plt_FE_sig_BY <- dati |>
      ggplot(aes(x = lon, y = lat, col = trend_sdpd_lab_BY)) +
      geom_point(size = size.point) +
      scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
      guides(fill = "none") +
      labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_FE_sig_BY"]]) +
      ggtitle(paste(name.endogenous, "  (Significant tests with BY correction at level ", pars_alpha * 100, "%)", sep = ""))
    save_plot(plt_FE_sig_BY, paste0("plt_FE_sig_BY_map", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
    
    log_info("Saving Spatio-temporal Fixed Effects Statistics")
    row1 <- table(factor(dati$trend_sdpd_lab, levels = c("Neg", "Null", "Pos")))
    row2 <- table(factor(dati$trend_sdpd_lab_BY, levels = c("Neg", "Null", "Pos")))
    dati_summary <- data.frame(
      as.vector(row1),
      paste(round(prop.table(row1) * 100, 1), "%", sep = ""),
      as.vector(row2),
      paste(round(prop.table(row2) * 100, 1), "%", sep = "")
    )
    dimnames(dati_summary)[[1]] <- c("Positive trends", "Null trend", "Negative trends")
    dimnames(dati_summary)[[2]] <- c("Significant pixels", "%", "Significant pixels (BY adjusted)", "%")
    save_table(dati_summary, "fixed_effects_summary_table.html", output_dir, bool_dynamic)
    
    # Spatial Regression of Fixed Effect Parameters
    log_info("Saving Spatial Regression of FIXED EFFECT Parameters")
    modelli_globali_FE <- fun.estimate.global.models(df.results = df.results.estimate, slc = slc_df, name.covariates = name.covariates, name.response = "fixed_effects")
    formule_FE <- modelli_globali_FE[[7]]
    
    for (ii in 1:min(length(modelli_globali_FE), 6)) {
      save_spatial_regression(modelli_globali_FE, formule_FE, ii, output_dir, "model_output_FE")
    }
  }

  # Saving Updates
  log_info("Saving Updated Rdata")
  if (bool_update) {
    save(list = objects_to_save, file = load_path)
    log_info("Saved {load_path}")
  }

  log_info("RISKMAP MODULE Completed")
  analysis_status <<- "done"
  log_info(paste("Analysis completed for", user_model_choice, ". Outputs saved in", output_dir))
  
}, error = function(e) {
  # Set status to "error" if any step fails
  analysis_status <<- "error"
  log_error("Error during analysis: {conditionMessage(e)}")
})

# Save analysis_status to flag file
writeLines(analysis_status, con = file.path(output_dir, paste0(analysis_id, ".flag"))) 
