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

# Read parameters
args <- commandArgs(trailingOnly = TRUE)
param_path <- args[1]  # first argument is the JSON file path
params <- fromJSON(param_path)


# Example: Read parameters
# params <- fromJSON('{
#   "analysis_id": "769cdd08-20e9-4706-a62a-5f279aed845e",
#   "model_type": "Model6_UserDefined",
#   "bool_update": true,
#   "bool_trend": true,
#   "summary_stat": "mean",
#   "user_longitude_choice": 11.2,
#   "user_latitude_choice": 45.1,
#   "user_coeff_choice": 1.0,
#   "bool_dynamic": true,
#   "endogenous_variable": "mean_air_temperature_adjusted",
#   "covariate_variables": ["mean_relative_humidity_adjusted", "black_sky_albedo_all_mean"],
#   "user_date_choice": "2011-01-01",
# 	"vec.options": {
#     "groups": 1,
#     "px.core": 1,
#     "px.neighbors": 3,
#     "t_frequency": 12,
#     "na.rm": true,
#     "NAcovs": "pairwise.complete.obs"
#   }
# }')

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
user_date_choice <- params$user_date_choice
vec.options <- params$vec.options

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
  
  log_info("Configure the model")
  var_y <- variable[[name.endogenous]]
  tt <- length(time(var_y))
  from.tt <- 1
  to.tt <- tt
  rry <- var_y[[from.tt:to.tt]]
  
  resized.covariates <- list()
  if (n.covs > 0) {
    for(ii in name.covariates) {
      resized.covariates[[ii]] <- variable[[ii]][[from.tt:to.tt]]
    }
  }
  
  italy.shape <- vect(shape_path)
  italy.shape <- project(italy.shape, var_y)
  province <- rasterize(italy.shape, var_y, field="COD_PROV")
  label.province <- values(italy.shape)[,"DEN_UTS"]
  names(label.province) <- values(italy.shape)[,"COD_PROV"]
  
  if (bool_trend) {
    resized.covariates[["trend"]] <- "trend"
  }
  
  sdpd.model <- list()
  sdpd.model$lambda.coeffs <- c(TRUE, TRUE, TRUE)
  names(sdpd.model$lambda.coeffs) <- c("lambda0", "lambda1", "lambda2")
  
  if (length(resized.covariates) > 0) {
    sdpd.model$beta.coeffs <- rep(TRUE, n.covs + bool_trend)
    names(sdpd.model$beta.coeffs) <- names(resized.covariates)
  } else {
    sdpd.model$beta.coeffs <- resized.covariates <- NULL
  }
  
  sdpd.model$fixed_effects <- TRUE
  sdpd.model$time_effects <- FALSE
  
  global.series <- build.sdpd.series(px = "all", rry = rry, rrXX = resized.covariates, rrgroups = province, label_groups = label.province, vec.options = vec.options)
  
  df.gruppi <- tibble(gruppo = global.series$p.axis$group, px = global.series$p.axis$pixel) %>%
    nest_by(.by = gruppo, .key = "gruppo")
  
  names(df.gruppi$gruppo) <- seq(1, length(df.gruppi$gruppo))
  for (ii in 1:length(df.gruppi$gruppo)) {
    names(df.gruppi$gruppo)[ii] <- df.gruppi$gruppo[[ii]]$gruppo[1,2]
  }
  
  df.data <- df.gruppi$gruppo %>%
    map(fun.extract.data, rry = rry, rrxx = resized.covariates, rrgroups = province, label_groups = label.province, vec.options = vec.options)
  
  log_info("Extract data from the model")
  objects_to_save <- c("sdpd.model", "vec.options", "global.series")
  
  df.obj <- fun.extract.data(
    df.obj = list(px = "all"),
    rry = rry,
    rrxx = resized.covariates,
    rrgroups = province,
    label_groups = label.province,
    vec.options = vec.options
  )
  
  if (!is.null(df.obj$error)) {
    stop("Error in data preparation: ", df.obj$error)
  }
  
  df.stime    <- df.data %>% map(fun.estimate.parameters, model=sdpd.model, vec.options=vec.options)
  
  ## collect the results in a list of objects of the same size, to be able to put them side by side in a dataframe of final results
  df.results.estimate  <- df.stime %>%
    map(fun.assemble.estimate.results) %>%
    bind_rows()
  
  # enrich the list of objects to save, in case bool_update=TRUE
  objects_to_save <- c(objects_to_save, "df.results.estimate")

  
  if(bool_update){
    
    ## creates the Land Cover dataset
    px <- as.numeric(dimnames(global.series$series)[[1]])
    coordinate <- xyFromCell(variable[[name.endogenous]], px)
    indici <- cellFromXY(lc22[[1]], coordinate)
    slc.df <- data.frame(longitude=global.series$p.axis$longit, latitude=global.series$p.axis$latit, slc=values(lc22)[indici,1])
    slc_df <- slc.df |>
      mutate(Longitude=round(longitude,1),Latitude=round(latitude,1))
    
    slc_df <- slc_df |>
      mutate(LC = case_when((slc <= 40) ~ "Agriculture", 
                            (slc >40 & slc<=100) | slc==160 | slc==170 ~ "Forest",
                            slc==110 | slc==130 ~ "Grassland",
                            slc==180 ~ "Wetland",
                            slc==190 ~ "Settlement",
                            (slc>=120 & slc <= 122) | (slc==140) | (slc >= 150 & slc <= 153) | (slc>=200) ~ "Other")) |>
      mutate(LC=factor(LC)) |>
      mutate(LC=fct_relevel(LC,c("Forest","Agriculture","Grassland","Wetland","Settlement","Other")))
    
    # enrich the list of objects to save, in case bool_update=TRUE
    objects_to_save <- c(objects_to_save, "slc_df") 
    
  }

  
  log_info("Save table with the estimated parameters")
  
  # Save table with the estimated parameters
  dati <- data.frame(
    lon = round(df.results.estimate$lon, 1),
    lat = round(df.results.estimate$lat, 1),
    district = df.results.estimate$group$LABEL,
    coeff = round(df.results.estimate$coeff.hat, digits=3),
    row.names = NULL
  )
  
  output_file <- file.path(output_dir, "model_fits/plots", paste0("coeff_", name.endogenous, ".html"))
  
  if (bool_dynamic) {
    widget <- datatable(dati, filter = "top")
  } else {
    widget <- datatable(head(dati), filter = "none")
  }
  
  htmlwidgets::saveWidget(widget, file = output_file, selfcontained = TRUE)
  
  
  log_info("Plotting the estimated coefficients")
  plot.coeffs <- fun.plot.coeff.FITs(df.results.estimate, pars=pars_list)
  
  save_coeff_plots(
    plot.coeffs = plot.coeffs,
    output_dir = output_dir,
    name.endogenous = name.endogenous,
    name.covariates = name.covariates,
    bool_dynamic = bool_dynamic,
    bool_trend = bool_trend
  )
  
  
  log_info("Plotting the fitted and residual time-series for a given location")
  plot.series.FITs <- fun.plot.series.FITs(df.results.estimate, latitude=user_latitude_choice, longitude=user_longitude_choice, pars=pars_list)
  if(bool_dynamic) {
    plt <- plotly::ggplotly(plot.series.FITs)
    htmlwidgets::saveWidget(plt, file = file.path(output_dir, "estimate/plots", paste0("series_", name.endogenous, ".html")))
  } else {
    ggsave(filename = file.path(output_dir, "estimate/plots", paste0("series_", name.endogenous, ".png")), plot = plot.series.FITs, width = 8, height = 6)
  }
  
  
  log_info("Saving Stimated results as csv")
  df.results <- fun.prepare.df.results(df.results=df.results.estimate, model=user_model_choice)
  write.csv(df.results, file=file.path(output_dir, "estimate/stats", paste0("df_results_estimate.csv")))
  
  log_info("ESTIMATE MODULE Completed")
  
  
  log_info("Starting VALIDATE MODULE")
  
  log_info("Plotting the residuals")
  for(stat_name in names(validation_stats)) {
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
  }
  
  log_info("Plotting Ljung-Box autocorrelation test")
  
  LBtest_variants <- list(
    no_Benjamini_Yekutieli = FALSE,
    with_Benjamini_Yekutieli = TRUE
  )
  
  for (BYadjust in LBtest_variants) {
    suffix <- ifelse(BYadjust, "BYadjusted", "not_adjusted")
    output_filename <- paste0("residual_LBtest_", suffix, if (bool_dynamic) ".html" else ".png")
    output_path <- file.path(output_dir, "validate/plots", output_filename)
    
    plot_obj <- fun.plot.stat.discrete.RESIDs(
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
  }
  
  log_info("Plotting Jarque-Bera normality test")
  JBtest_variants <- list(FALSE, TRUE)
  for (BYadjust in JBtest_variants) {
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
  }
  
  
  log_info("Starting bootstrap validation")
  
  # plan(multisession)
  plan(multisession, workers = 2)
  df.test <- df.stime %>% future_map(fun.testing.parameters, correzione=CORREZIONE, n.boot=NBOOT, label.group=label.province, plot=FALSE, .options=furrr_options(seed=TRUE))

  log_info("Assembling the results")

  # Collecting and storing results
  df.results.test <- df.test %>%
    map(fun.assemble.test.results) %>%
    bind_rows()

  log_info("Saving the results")
  # enrich the list of objects to save, in case bool_update=TRUE
  objects_to_save <- c(objects_to_save, "df.results.test") 
  
  log_info("Bootstrap resampling completed")
  
  log_info("Comparing the bootstrap and the observed time series")
  
  plot.devs <- fun.plot.coeffboot.TEST(df.results.test, alpha=pars_alpha, matrix1="sdevs.tsboot", pars=pars_list)
  
  boot_plot <- list(mean=1, sd=2)
  
  for (name in names(boot_plot)) {
    index <- boot_plot[[name]]
    plot_obj <- plot.devs[[index]]
    filename <- paste0("coeffboot_", name, if (bool_dynamic) ".html" else ".png")
    output_path <- file.path(output_dir, "bootstrap/plots", filename)
    
    if (bool_dynamic) {
      htmlwidgets::saveWidget(
        widget = plotly::ggplotly(plot_obj),
        file = output_path,
        selfcontained = TRUE
      )
    } else {
      ggplot2::ggsave(
        filename = output_path,
        plot = plot_obj,
        width = 10, height = 6, dpi = 300
      )
    }
  }
  
  log_info("Plotting Bootstrap distribution of the parameter estimators")
  
  # Plot of estimated coefficients, validated by bootstrap test (with p-values)
  plot.coeff <- fun.plot.coeffboot.TEST(
    df.results.test,
    alpha = pars_alpha,
    matrix1 = "coeff.hat",
    matrix2 = "pvalue.test",
    pars = pars_list
  )
  
  # Save plot
  plot_obj <- plot.coeff[[user_coeff_choice]]
  filename <- paste0("coeff_hat", if (bool_dynamic) ".html" else ".png")
  output_path <- file.path(output_dir, "bootstrap/plots", filename)
  
  if (bool_dynamic) {
    htmlwidgets::saveWidget(
      widget = plotly::ggplotly(plot_obj),
      file = output_path,
      selfcontained = TRUE
    )
  } else {
    ggplot2::ggsave(
      filename = output_path,
      plot = plot_obj,
      width = 10, height = 6, dpi = 300
    )
  }
  
  
  # Plot of bootstrap bias
  plot.coeff <- fun.plot.coeffboot.TEST(
    df.results.test,
    alpha = pars_alpha,
    matrix1 = "coeff.bias.boot",
    pars = pars_list
  )
  
  # Save plot
  plot_obj <- plot.coeff[[user_coeff_choice]]
  filename <- paste0("coeff_bias_boot", if (bool_dynamic) ".html" else ".png")
  output_path <- file.path(output_dir, "bootstrap/plots", filename)
  
  if (bool_dynamic) {
    htmlwidgets::saveWidget(
      widget = plotly::ggplotly(plot_obj),
      file = output_path,
      selfcontained = TRUE
    )
  } else {
    ggplot2::ggsave(
      filename = output_path,
      plot = plot_obj,
      width = 10, height = 6, dpi = 300
    )
  }
  
  # Plot of bootstrap standard deviation
  plot.coeff <- fun.plot.coeffboot.TEST(
    df.results.test,
    alpha = pars_alpha,
    matrix1 = "coeff.sd.boot",
    pars = pars_list
  )
  
  # Save plot
  plot_obj <- plot.coeff[[user_coeff_choice]]
  filename <- paste0("coeff_sd_boot", if (bool_dynamic) ".html" else ".png")
  output_path <- file.path(output_dir, "bootstrap/plots", filename)
  
  if (bool_dynamic) {
    htmlwidgets::saveWidget(
      widget = plotly::ggplotly(plot_obj),
      file = output_path,
      selfcontained = TRUE
    )
  } else {
    ggplot2::ggsave(
      filename = output_path,
      plot = plot_obj,
      width = 10, height = 6, dpi = 300
    )
  }
  
  log_info("Bootstrap validation completed")
  
  log_info("\nVALIDATE MODULE Completed")
  
  
  log_info("\n RISK MAP MODULE Started")
  
  log_info("Plotting Trend Estimates")
  
  plt_SDPD_estimates <- df.results.test |>
    ggplot(aes(x = lon, y = lat, col = coeff.hat$trend)) + 
    geom_point(size = size.point) + 
    scale_color_gradient2(high = "red", low = "blue", mid = "white", midpoint = 0) + 
    guides(fill = "none") + 
    labs(y = "Latitude", x = "Longitude", col = "Trend", caption = captions_list[["plt_SDPD_estimates"]]) +
    ggtitle(char(name.endogenous))
  
  filename <- paste0("SDPD_trend_estimates", if (bool_dynamic) ".html" else ".png")
  output_path <- file.path(output_dir, "riskmap/plots", filename)
  
  if (bool_dynamic) {
    htmlwidgets::saveWidget(plotly::ggplotly(plt_SDPD_estimates), output_path, selfcontained = TRUE)
  } else {
    ggsave(output_path, plot = plt_SDPD_estimates, width = 8, height = 6)
  }
  
  
  log_info("Plotting Trend Standard Errors")
  plt_SDPD_std <- df.results.test |>
    ggplot(aes(x = lon, y = lat, col = coeff.sd.boot$trend)) + 
    geom_point(size = size.point) + 
    scale_color_gradient2(high = "red", low = "blue", mid = "white", midpoint = 0) + 
    guides(fill = "none") + 
    labs(y = "Latitude", x = "Longitude", col = "Std. Error", caption = captions_list[["plt_SDPD_std"]]) +
    ggtitle(char(name.endogenous))
  
  filename <- paste0("SDPD_trend_std_error", if (bool_dynamic) ".html" else ".png")
  output_path <- file.path(output_dir, "riskmap/plots", filename)
  
  if (bool_dynamic) {
    htmlwidgets::saveWidget(plotly::ggplotly(plt_SDPD_std), output_path, selfcontained = TRUE)
  } else {
    ggsave(output_path, plot = plt_SDPD_std, width = 8, height = 6)
  }
  
  log_info("Plotting Trend Signefecant pixels")
  dati <- data.frame(lon=df.results.test$lon, lat=df.results.test$lat, estimate=df.results.test$coeff.hat$trend, stdev=df.results.test$coeff.sd.boot$trend, pvalue.test=df.results.test$pvalue.test$trend) |>
    mutate(sig_trend=pvalue.test < pars_alpha) |>
    mutate(trend1=ifelse(estimate > 0 & sig_trend==TRUE,1,0)) |>
    mutate(trend2=ifelse(estimate < 0 & sig_trend==TRUE,-1,0)) |>
    mutate(trend_sdpd=factor(trend1+trend2)) |>
    mutate(trend_sdpd_lab = recode(trend_sdpd, "-1" = "Neg", "0" = "Null","1" = "Pos")) |>
    select(-c(trend1,trend2)) |>
    mutate(p.value_sdpd_BY=p.adjust(pvalue.test,method="BY")) |>
    mutate(sig_trend_BY=p.value_sdpd_BY < pars_alpha) |>
    mutate(trend1=ifelse(estimate > 0 & sig_trend_BY==TRUE,1,0)) |>
    mutate(trend2=ifelse(estimate < 0 & sig_trend_BY==TRUE,-1,0)) |>
    mutate(trend_sdpd_BY=factor(trend1+trend2)) |>
    mutate(trend_sdpd_lab_BY = recode(trend_sdpd_BY, "-1" = "Neg", "0" = "Null","1" = "Pos"))
  
  plt_sdpd <- dati |>
    ggplot(aes(x = lon,  y = lat, col = trend_sdpd_lab)) +
    geom_point(size = size.point) +
    scale_color_manual(values = c("Neg" = "blue", "Null"="green", "Pos"="red")) +
    guides(fill = "none") +
    labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_sdpd"]]) +
    ggtitle(paste(name.endogenous,"  (Significant tests at level ", pars_alpha*100, "%)", sep=""))
  
  filename <- paste0("SDPD_trend_signefecant_pixels", if (bool_dynamic) ".html" else ".png")
  output_path <- file.path(output_dir, "riskmap/plots", filename)
  
  if (bool_dynamic) {
    htmlwidgets::saveWidget(plotly::ggplotly(plt_sdpd), output_path, selfcontained = TRUE)
  } else {
    ggsave(output_path, plot = plt_sdpd, width = 8, height = 6)
  }
  
  
  log_info("Plotting Trend Adjested BY test")
  plt_SDPD_sig_BY <- dati |>
    ggplot(aes(x = lon, y = lat, col = trend_sdpd_lab_BY)) +
    geom_point(size = size.point) +
    scale_color_manual(values = c("Neg" = "blue", "Null"="green", "Pos"="red")) +
    guides(fill = "none") +
    labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_SDPD_sig_BY"]]) +
    ggtitle(paste(name.endogenous,"  (Significant tests with BY correction at level ", pars_alpha*100, "%)", sep=""))
  
  filename <- paste0("SDPD_adjusted_BY", if (bool_dynamic) ".html" else ".png")
  output_path <- file.path(output_dir, "riskmap/plots", filename)
  
  if (bool_dynamic) {
    htmlwidgets::saveWidget(plotly::ggplotly(plt_SDPD_sig_BY), output_path, selfcontained = TRUE)
  } else {
    ggsave(output_path, plot = plt_SDPD_sig_BY, width = 8, height = 6)
  }
  
  
  log_info("Saving Spatio-temporal Trend analysis Statistics")
  row1 <- table(factor(dati$trend_sdpd_lab, levels = c("Neg", "Null", "Pos")))
  row2 <- table(factor(dati$trend_sdpd_lab_BY, levels = c("Neg", "Null", "Pos")))
  
  dati_summary <- data.frame(
    as.vector(row1),
    paste(round(prop.table(row1) * 100, 1), "%", sep = ""),
    as.vector(row2),
    paste(round(prop.table(row2) * 100, 1), "%", sep = "")
  )
  
  dimnames(dati_summary)[[1]] <- c("Negative trends", "Null trend", "Positive trends")
  dimnames(dati_summary)[[2]] <- c("Significant pixels", "%", "Significant pixels (BY adjusted)", "%")
  
  # Choose full or partial data for widget
  if (bool_dynamic) {
    widget <- datatable(dati_summary, filter = "top")
  } else {
    widget <- datatable(head(dati_summary), filter = "none")
  }
  
  # Save to HTML
  output_file <- file.path(output_dir, "riskmap/plots", "SDPD_table_summary.html")
  htmlwidgets::saveWidget(widget, file = output_file, selfcontained = TRUE)
  
  
  
  log_info("\nPlotting Spatial Regression of TREND parameters")
  modelli_globali <- fun.estimate.global.models(df.results=df.results.estimate, slc=slc_df, name.covariates=name.covariates, name.response="trend")
  formule <- modelli_globali[[7]]
  
  
  log_info("Plotting Land Cover map")
  output_filename <- paste0("plt_FE_lc_map", if (bool_dynamic) ".html" else ".png")
  output_path <- file.path(output_dir, "riskmap/plots", output_filename)
  
  plt_FE_lc <- slc_df |> 
    ggplot(aes(x=Longitude, y=Latitude, color=LC)) +
    geom_point(size = size.point) +
    guides(fill = "none") +
    labs(x = "Longitude", y = "Latitude", title = "MAP of Land Cover classes", col = "LC", caption = captions_list[["plt_FE_lc"]])
  
  if (bool_dynamic) {
    htmlwidgets::saveWidget(plotly::ggplotly(plt_FE_lc), output_path, selfcontained = TRUE)
  } else {
    ggsave(output_path, plot = plt_FE_lc, width = 8, height = 6, dpi = 300)
  }
  
  
  cat("Plotting Spatial Regression for each land cover class\n")
  for (ii in 1:6) {
    # Define output path
    output_filename <- paste0("patial_regression_", ii, ".html")
    output_path <- file.path(output_dir, "riskmap/plots", output_filename)
    
    plots_dir <- file.path(output_dir, "riskmap/plots")
    plot_files <- diagnostic_models(modelli_globali[[ii]], 
                                    output_dir = plots_dir, 
                                    filename_prefix = paste0("patial_regression_", ii))
    
    # Capture text output
    output <- capture.output({
      cat(paste("\n The model is:", formule[[ii]][2], formule[[ii]][1], formule[[ii]][3], "\n"))
      cat("\n", Evaluate_global_Test(modelli_globali[[ii]], alpha=pars_alpha), "\n Details are presented below:")
    })
    
    suffix_output <- capture.output({
      summary(modelli_globali[[ii]])
    })
    
    # Create HTML content with embedded images
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
      "</div>",
      "</body></html>"
    )
    
    # Save to HTML file
    writeLines(html_content, con = output_path)
  }
  
  
  
  
  log_info("Plotting Fixed Effects Estimates")
  output_filename <- paste0("FE_estimates_map", if (bool_dynamic) ".html" else ".png")
  output_path <- file.path(output_dir, "riskmap/plots", output_filename)
  
  # Generate plot
  plt_FE_estimates <- df.results.test |>
    ggplot(aes(x = lon, y = lat, col = coeff.hat$fixed_effects)) + 
    geom_point(size = size.point) + 
    scale_color_gradient2(high = "red", low = "blue", mid = "white", midpoint = 0) + 
    guides(fill = "none") + 
    labs(y = "Latitude", x = "Longitude", col = "Fixed Effects", caption = captions_list[["plt_FE_estimates"]]) +
    ggtitle(char(name.endogenous))
  
  # Save based on bool_dynamic
  if (bool_dynamic) {
    plt <- plotly::ggplotly(plt_FE_estimates)
    htmlwidgets::saveWidget(plt, file = output_path)
  } else {
    ggplot2::ggsave(output_path, plt_FE_estimates, width = 8, height = 6, dpi = 300)
  }
  
  log_info("Plotting Fixed Effects Standard Errors")
  output_filename <- paste0("plt_FE_std_map", if (bool_dynamic) ".html" else ".png")
  output_path <- file.path(output_dir, "riskmap/plots", output_filename)
  
  # Generate plot
  plt_FE_std <- df.results.test |>
    ggplot(aes(x = lon, y = lat, col = coeff.sd.boot$fixed_effects)) + 
    geom_point(size = size.point) + 
    scale_color_gradient2(high = "red", low = "blue", mid = "white", midpoint = 0) + 
    guides(fill = "none") + 
    labs(y = "Latitude", x = "Longitude", col = "std.error", caption = captions_list[["plt_FE_std"]]) +
    ggtitle(char(name.endogenous))
  
  # Save based on bool_dynamic
  if (bool_dynamic) {
    plt <- plotly::ggplotly(plt_FE_std)
    htmlwidgets::saveWidget(plt, file = output_path)
  } else {
    ggplot2::ggsave(output_path, plt_FE_std, width = 8, height = 6, dpi = 300)
  }
  
  
  log_info("Plotting Fixed Effects Significant pixels")
  output_filename <- paste0("plt_FE_sdpd_map", if (bool_dynamic) ".html" else ".png")
  output_path <- file.path(output_dir, "riskmap/plots", output_filename)
  
  # Process data
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
  
  # Generate plot
  plt_FE_sdpd <- dati |>
    ggplot(aes(x = lon, y = lat, col = trend_sdpd_lab)) +
    geom_point(size = size.point) +
    scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
    guides(fill = "none") +
    labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_FE_sdpd"]]) +
    ggtitle(paste(name.endogenous, "  (Significant tests at level ", pars_alpha * 100, "%)", sep = ""))
  
  # Save based on bool_dynamic
  if (bool_dynamic) {
    plt <- plotly::ggplotly(plt_FE_sdpd)
    htmlwidgets::saveWidget(plt, file = output_path)
  } else {
    ggplot2::ggsave(output_path, plt_FE_sdpd, width = 8, height = 6, dpi = 300)
  }
  
  
  log_info("Plotting Fixed Effects Significant pixels Adjusted (BY) Test")
  output_filename <- paste0("plt_FE_sig_BY_map", if (bool_dynamic) ".html" else ".png")
  output_path <- file.path(output_dir, "riskmap/plots", output_filename)
  
  # Ensure output directory exists
  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  
  # Generate plot
  plt_FE_sig_BY <- dati |>
    ggplot(aes(x = lon, y = lat, col = trend_sdpd_lab_BY)) +
    geom_point(size = size.point) +
    scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
    guides(fill = "none") +
    labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_FE_sig_BY"]]) +
    ggtitle(paste(name.endogenous, "  (Significant tests with BY correction at level ", pars_alpha * 100, "%)", sep = ""))
  
  # Save based on bool_dynamic
  if (bool_dynamic) {
    plt <- plotly::ggplotly(plt_FE_sig_BY)
    htmlwidgets::saveWidget(plt, file = output_path)
  } else {
    ggplot2::ggsave(output_path, plt_FE_sig_BY, width = 8, height = 6, dpi = 300)
  }
  
  
  log_info("Saving Spatio-temporal Fixed Effects Statistics")
  row1 <- table(factor(dati$trend_sdpd_lab, levels = c("Neg", "Null", "Pos")))
  row2 <- table(factor(dati$trend_sdpd_lab_BY, levels = c("Neg", "Null", "Pos")))
  dati_summary <- data.frame(
    as.vector(row1), 
    paste0(round(prop.table(row1) * 100, 1), "%"), 
    as.vector(row2), 
    paste0(round(prop.table(row2) * 100, 1), "%")
  )
  dimnames(dati_summary)[[1]] <- c("Positive trends", "Null trend", "Negative trends")
  dimnames(dati_summary)[[2]] <- c("Significant pixels", "%", "Significant pixels (BY adjusted)", "%")
  
  if (bool_dynamic) {
    widget <- datatable(dati_summary, filter = "top")
  } else {
    widget <- datatable(head(dati_summary), filter = "none")
  }

  output_file <- file.path(output_dir, "riskmap/plots", "fixed_effects_summary_table.html")
  htmlwidgets::saveWidget(widget, file = output_file, selfcontained = TRUE)
  
  
  
  log_info("Saving Spatial Regression of FIXED EFFECT parameters")
  
  modelli_globali_FE <- fun.estimate.global.models(df.results=df.results.estimate, slc=slc_df, name.covariates=name.covariates, name.response="fixed_effects")
  formule_FE <- modelli_globali[[7]]
  
  
  log_info("Plotting Land Cover map")
  output_filename <- paste0("plt_FE_lc_map", if (bool_dynamic) ".html" else ".png")
  output_path <- file.path(output_dir, "riskmap/plots", output_filename)
  
  # Ensure output directory exists
  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  
  # Generate plot
  plt_FE_lc <- slc_df |> 
    ggplot(aes(x=Longitude, y=Latitude, color=LC)) +
    geom_point(size = size.point) +
    guides(fill = "none") +
    labs(x = "Longitude", y = "Latitude", title="MAP of Land Cover classes", col = "LC", 
         caption = captions_list[["plt_FE_lc"]])
  
  # Save based on bool_dynamic
  if (bool_dynamic) {
    plt <- plotly::ggplotly(plt_FE_lc)
    htmlwidgets::saveWidget(plt, file = output_path)
  } else {
    ggplot2::ggsave(output_path, plt_FE_lc, width = 8, height = 6, dpi = 300)
  }
  
  
  log_info("Saving Results of Spatial Regression for each land cover class")
  # Regressions 1-6: Model Summaries using a for loop
  for (ii in 1:6) {
    # Define output path
    output_filename <- paste0("model_output_FE_", ii, ".html")
    output_path <- file.path(output_dir, "riskmap/plots", output_filename)
    
    plots_dir <- file.path(output_dir, "riskmap/plots")
    plot_files <- diagnostic_models(modelli_globali[[ii]], 
                                    output_dir = plots_dir, 
                                    filename_prefix = paste0("model_output_FE_", ii))
    
    
    # Capture text output
    output <- capture.output({
      log_info(paste("\n The model is:", formule[[ii]][2], formule[[ii]][1], formule[[ii]][3], "\n"))
      log_info("\n", Evaluate_global_Test(modelli_globali[[ii]], alpha=pars_alpha), "\n Details are presented below:")
    })
    
    suffix_output <- capture.output({
      summary(modelli_globali[[ii]])
    })
    
    # Create HTML content with embedded images
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
      "</div>",
      "</body></html>"
    )
    
    
    
    # Save to HTML file
    writeLines(html_content, con = output_path)
  }
  
  
  log_info("RISKMAP MODEL completed")
  
  
  log_info("Saving Updated Rdata")
  if(bool_update){
    save(list=objects_to_save, file=paste(output_dir, "/Rdata/workfile_model6_", name.endogenous, ".RData", sep=""))
  }
  
  analysis_status <<- "done"
  log_info("Model 4: Analysis completed. Outputs saved in {output_dir}")
  
}, error = function(e) {
  # Set status to "error" if any step fails
  analysis_status <<- "error"
  log_error("Error during analysis: {conditionMessage(e)}")
})

# Save analysis_status to flag file
writeLines(analysis_status, con = file.path(output_dir, paste0(analysis_id, ".flag"))) 
