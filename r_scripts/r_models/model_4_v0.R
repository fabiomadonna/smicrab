
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
  "moments"
)

# Install missing packages
installed_packages <- installed.packages()[,"Package"]
for (pkg in required_packages) {
  if (!(pkg %in% installed_packages)) {
    install.packages(pkg)
  }
}

# Load all packages
lapply(required_packages, library, character.only = TRUE)

# Load scripts
source("r_scripts/script_package_sdpd.R")
source("r_scripts/script_funzioni_SMICRAB.R")
source("r_scripts/UtilityFunctions.R")
source("r_scripts/settings.R")


# Modified Helper Functions
fun.download.csv <- function(raster_obj, name_file = varnames(raster_obj)[1]) {
  tempo <- as.character(time(raster_obj))
  valori <- values(raster_obj)
  dimnames(valori)[[2]] <- tempo
  px <- seq(1, dim(valori)[1])
  coordinate <- xyFromCell(raster_obj, px)
  dataframe <- data.frame(longitude = coordinate[,1], latitude = coordinate[,2], valori)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  write.csv(dataframe, file = file.path(output_dir, paste0(name_file, ".csv")), row.names = FALSE)
}

fun.plot.stat.VARs <- function(df_serie, statistic, title, pars, output_dir, bool_dynamic = FALSE) {
  dati <- apply(df_serie[, -c(1, 2)], 1, FUN = statistic)
  plot.VAR <- df_serie %>%
    mutate(newvar = dati) %>%
    ggplot(aes(longitude, latitude, colour = newvar)) +
    geom_point(size = 0.8) +
    scale_colour_gradientn(colours = pars$colori, limits = pars$limiti) +
    labs(title = title, colour = pars$unit)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  ggsave(filename = file.path(output_dir, paste0(title, ".png")), plot = plot.VAR, width = 8, height = 6)
  if (bool_dynamic) {
    plt <- plotly::ggplotly(plot.VAR)
    htmlwidgets::saveWidget(plt, file = file.path(output_dir, paste0(title, ".html")))
  }
  write_json(plot.VAR, path = file.path(output_dir, paste0(title, ".json")))
  return(plot.VAR)
}

fun.plot.coeff.FITs <- function(obj.results, pars = NULL, output_dir, bool_dynamic = FALSE) {
  res <- list()
  nomi <- names(obj.results$coeff.hat)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  for (ii in 1:length(nomi)) {
    dati <- data.frame(lon = obj.results$lon, lat = obj.results$lat, newvar = obj.results$coeff.hat[, ii])
    plot.coeff <- dati %>%
      ggplot(aes(lon, lat)) +
      geom_point(aes(colour = newvar), size = 0.8) +
      scale_colour_gradient2(high = "red", low = "blue", mid = "white", midpoint = 0, limits = pars$limiti) +
      labs(title = paste("Estimated coefficients for", nomi[ii]), colour = "value")
    ggsave(filename = file.path(output_dir, paste0("coeff_", nomi[ii], ".png")), plot = plot.coeff, width = 8, height = 6)
    if (bool_dynamic) {
      plt <- plotly::ggplotly(plot.coeff)
      htmlwidgets::saveWidget(plt, file = file.path(output_dir, paste0("coeff_", nomi[ii], ".html")))
    }
    write_json(plot.coeff, path = file.path(output_dir, paste0("coeff_", nomi[ii], ".json")))
    res[[ii]] <- plot.coeff
  }
  names(res) <- nomi
  return(res)
}

fun.plot.series.FITs <- function(df.results, latitude, longitude, name_y = "", pars = NULL, output_dir, bool_dynamic = FALSE) {
  sottotitolo <- paste("longitude =", longitude, " - latitude =", latitude, sep = "")
  interval.range <- dimnames(df.results$fitted)[[2]]
  serie1 <- df.results %>%
    mutate(Latitude = round(lat, 1)) %>%
    mutate(Longitude = round(lon, 1)) %>%
    filter(Latitude == round(latitude, 1), Longitude = round(longitude, 1))
  if (dim(serie1)[1] == 0) {
    return("These coordinates are not present in the database")
  }
  coeff <- range(serie1$fitted, na.rm = TRUE)[1] - 0.1 * diff(range(serie1$fitted, na.rm = TRUE))
  plot.series <- data.frame(time = as.yearmon(interval.range), fitted = as.numeric(serie1$fitted), resid = as.numeric(serie1$resid)) %>%
    ggplot(aes(x = time)) +
    geom_line(aes(y = fitted, color = "Fitted")) +
    geom_line(aes(y = resid + fitted, color = "Observed")) +
    geom_line(aes(y = resid + coeff, color = "Residuals")) +
    geom_hline(aes(yintercept = mean(resid, na.rm = TRUE) + coeff)) +
    guides(x = guide_axis(angle = 0)) +
    scale_y_continuous(
      name = name_y,
      sec.axis = sec_axis(transform = ~. - coeff, name = "2° axis is for residuals")
    ) +
    labs(title = "Estimated model series", subtitle = sottotitolo, x = "", color = "")
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  filename <- paste0("series_lon_", longitude, "_lat_", latitude)
  ggsave(filename = file.path(output_dir, paste0(filename, ".png")), plot = plot.series, width = 8, height = 6)
  if (bool_dynamic) {
    plt <- plotly::ggplotly(plot.series)
    htmlwidgets::saveWidget(plt, file = file.path(output_dir, paste0(filename, ".html")))
  }
  write_json(plot.series, path = file.path(output_dir, paste0(filename, ".json")))
  return(plot.series)
}

fun.plot.stat.RESIDs <- function(df.results, statistic, title, pars = NULL, output_dir, bool_dynamic = FALSE, ...) {
  if (is.data.frame(df.results$resid)) {
    dati <- data.frame(lon = df.results$lon, lat = df.results$lat, newvar = apply(df.results$resid, 1, FUN = statistic, ...))
  } else if (is.list(df.results$resid)) {
    dati <- data.frame(lon = df.results$lon, lat = df.results$lat, newvar = unlist(lapply(df.results$resid, FUN = statistic, ...)))
  }
  plot.resid <- dati %>%
    ggplot(aes(lon, lat, colour = newvar)) +
    geom_point(size = 0.8) +
    guides(fill = "none") +
    labs(title = "Summary statistics for residuals", x = "Longitude", y = "Latitude", colour = paste(title, "\nof residuals")) +
    scale_colour_gradient2(high = "red", low = "blue", mid = "white", midpoint = 0)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  ggsave(filename = file.path(output_dir, paste0("resid_", title, ".png")), plot = plot.resid, width = 8, height = 6)
  if (bool_dynamic) {
    plt <- plotly::ggplotly(plot.resid)
    htmlwidgets::saveWidget(plt, file = file.path(output_dir, paste0("resid_", title, ".html")))
  }
  write_json(plot.resid, path = file.path(output_dir, paste0("resid_", title, ".json")))
  return(plot.resid)
}

fun.plot.coeffboot.TEST <- function(obj.results, matrix1, matrix2 = NULL, alpha = 0.05, limiti = NULL,
                                    titolo = NULL, sottotitolo = "", legenda_colore = "value",
                                    output_dir, bool_dynamic = FALSE, pars = NULL) {
  res <- list()
  nomi <- names(obj.results[[matrix1]])
  if (matrix1 == "sdevs.tsboot") {
    sottotitolo <- "of differences between the bootstrap and the observed time series\n(grey pixels show values bigger than 100)"
    limiti <- c(0, 100)
  } else if (matrix1 == "coeff.hat") {
    sottotitolo <- "Estimated coefficients validated by the bootstrap test"
  } else if (matrix1 == "coeff.bias.boot") {
    sottotitolo <- "Bootstrap bias estimation"
    legenda_colore <- "bias"
  } else if (matrix1 == "coeff.sd.boot") {
    sottotitolo <- "Boostrap standard deviation estimation"
    legenda_colore <- "sd"
  }
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  for (ii in 1:length(nomi)) {
    if (is.null(titolo)) titolo2 <- nomi[ii] else titolo2 <- titolo
    if (is.null(matrix2)) {
      dati <- data.frame(lon = obj.results$lon, lat = obj.results$lat, newvar = obj.results[[matrix1]][, ii])
    } else {
      reject <- obj.results[[matrix2]][, ii] < alpha
      dati <- data.frame(lon = obj.results$lon, lat = obj.results$lat, newvar = obj.results[[matrix1]][, ii] * reject)
    }
    plot.coeff <- dati %>%
      ggplot(aes(lon, lat)) +
      geom_point(aes(colour = newvar), size = 0.8) +
      scale_colour_gradient2(high = "red", low = "blue", mid = "white", midpoint = 0, limits = limiti) +
      labs(title = titolo2, subtitle = sottotitolo, colour = legenda_colore)
    ggsave(filename = file.path(output_dir, paste0("coeffboot_", nomi[ii], ".png")), plot = plot.coeff, width = 8, height = 6)
    if (bool_dynamic) {
      plt <- plotly::ggplotly(plot.coeff)
      htmlwidgets::saveWidget(plt, file = file.path(output_dir, paste0("coeffboot_", nomi[ii], ".html")))
    }
    write_json(plot.coeff, path = file.path(output_dir, paste0("coeffboot_", nomi[ii], ".json")))
    res[[ii]] <- plot.coeff
  }
  names(res) <- nomi
  return(res)
}

fun.derive.function.VARs <- function(stat) {
  switch(
    stat,
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
    stop(paste("Unknown statistic:", stat))
  )
}



# Initializations
analysis_id <- "advs-snvd-bmks-mdvs"
user_longitude_choice <- 11.2
user_latitude_choice <- 45.1
user_coeff_choice <- 1
analysis_status <- "in progress"
output_base_dir <- "/tmp/analysis"
output_dir <- file.path(output_base_dir, analysis_id, "Model4_UHI")
bool_dynamic <- TRUE
n.boot <- 999
tempo <- 1:156
offset <- 156
ora <- 18
indici <- seq(ora+1, 7488, by=24)
bool_update <- TRUE
bool_trend <- TRUE
stat <- "mean"
validation_statistics <- c("mean", "standard_deviation", "skewness", "kurtosis")



# Create output directories
dir.create(file.path(output_dir, "summary_stats/plots"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(output_dir, "summary_stats/stats"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(output_dir, "model_fits/plots"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(output_dir, "model_fits/stats"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(output_dir, "bootstrap/plots"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(output_dir, "bootstrap/stats"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(output_dir, "data"), recursive = TRUE, showWarnings = FALSE)


# Data Loading
tg.m <- rast("data/tg_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly_CF-1.8_corrected.nc")
tx.m <- rast("data/tx_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly_CF-1.8_corrected.nc")
tn.m <- rast("data/tn_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly_CF-1.8_corrected.nc")
rr.m <- rast("data/rr_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly_CF-1.8_corrected.nc")
hu.m <- rast("data/hu_ens_mean_0.1deg_reg_2011-2023_v29.0e_monthly_CF-1.8_corrected.nc")
fg.m <- rast("data/fg_ens_mean_0.1deg_reg_2011-2023_v30.0e_monthly_CF-1.8_corrected.nc")
sal <- rast("data/SAL_IT_2011-2023_Monthly_CMSAF_ERA5_CF-1.8_Reinterpolated_v2.nc")
LST <- rast("data/LST_IT_2011_2023_agg_Monthly_per_hour_grid_0.1_CF-1.8_v2.nc")
lc22 <- rast("data/C3S-LC-L4-LCCS-Map-300m-P1Y-2022-v2.1.1.area-subset.49.20.32.6.nc")

lapply(list(tg.m, tx.m, tn.m, rr.m, hu.m, fg.m, sal, LST, lc22), fun.download.csv, output_dir = file.path(output_dir, "data"))


# Main processing wrapped in tryCatch
tryCatch({
  cat("Model 4: Analysis in progress...\n")


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

  if (!bool_update) {
    load("Rdata/dataframes.RData")
  } else {
    dataframes <- variable
    for (ii in names(variable)) {
      px <- seq(1, dim(values(variable[[ii]]))[1])
      coordinate <- xyFromCell(variable[[ii]], px)
      valori <- values(variable[[ii]])
      dimnames(valori)[[2]] <- substr(time(variable[[ii]]), start=1, stop=10)
      dataframes[[ii]] <- data.frame(longitude=coordinate[,1], latitude=coordinate[,2], valori)
    }
    save("dataframes", file="Rdata/dataframes.RData")
  }

  # Model 4 Configuration
  rry <- variable[["mean_air_temperature_adjusted"]]  # Endogenous variable
  rrxx <- list(humidity = variable[["mean_relative_humidity_adjusted"]], albedo = variable[["black_sky_albedo_all_mean"]])  # Additional covariates
  name.endogenous <- varnames(rry)[1]
  name.covariates <- c("mean_relative_humidity_adjusted", "black_sky_albedo_all_mean") # Define name.covariates

  rrgroups <- NULL
  label_groups <- NULL
  vec.options <- list(groups = 0, px.core = 0, px.neighbors = 4, t_frequency = 12, na.rm = TRUE, NAcovs = "pairwise.complete.obs")
  model <- list(lambda.coeffs = c(TRUE, TRUE, TRUE), beta.coeffs = c("humidity", "albedo"), fixed_effects = TRUE, time_effects = TRUE)


  fun.download.csv(rry, name_file = name.endogenous, output_dir = file.path(output_dir, "data"))
  df_serie <- read.csv(file.path(output_dir, "data", paste0(name.endogenous, ".csv")))

  funzione <- fun.derive.function.VARs(stat)
  titolo <- paste(stat, "of", name.endogenous)
  plot.VAR <- df_serie %>%
    mutate(newvar = apply(df_serie[, -c(1, 2)], 1, FUN = funzione)) %>%
    ggplot(aes(longitude, latitude, colour = newvar)) +
    geom_point(size = 0.8) +
    scale_colour_gradientn(colours = pars_list[[name.endogenous]]$colori, limits = pars_list[[name.endogenous]]$limiti) +
    labs(title = titolo, colour = pars_list[[name.endogenous]]$unit)
  ggsave(filename = file.path(output_dir, "summary_stats/plots", paste0(stat, "_", name.endogenous, ".png")), plot = plot.VAR, width = 8, height = 6)

  if (bool_dynamic) {
    plt <- plotly::ggplotly(plot.VAR)
    htmlwidgets::saveWidget(plt, file = file.path(output_dir, "summary_stats/plots", paste0(stat, "_", name.endogenous, ".html")))
  }

  stat_data <- data.frame(
    longitude = df_serie$longitude,
    latitude = df_serie$latitude,
    value = apply(df_serie[, 3:ncol(df_serie)], 1, funzione)
  )

  write.csv(stat_data, file = file.path(output_dir, "summary_stats/stats", paste0(stat, "_", name.endogenous, ".csv")), row.names = FALSE)
  write_json(stat_data, path = file.path(output_dir, "summary_stats/stats", paste0(stat, "_", name.endogenous, ".json")))

  var_y <- variable[[name.endogenous]]
  tt <- length(time(var_y))
  from.tt <- 1
  to.tt <- tt
  rry <- var_y[[from.tt:to.tt]]

  resized.covariates <- list()
  n.covs <- 0
  for(ii in name.covariates) {
   n.covs <- n.covs + 1
   resized.covariates[[n.covs]] <- variable[[ii]][[from.tt:to.tt]]
   names(resized.covariates)[n.covs] <- ii
  }

  italy.shape <- vect("r_scripts/shapes/ProvCM01012025_g_WGS84.shp")
  italy.shape <- project(italy.shape, var_y)
  province <- rasterize(italy.shape, var_y, field="COD_PROV")
  label.province <- values(italy.shape)[,"DEN_UTS"]
  names(label.province) <- values(italy.shape)[,"COD_PROV"]

  if (bool_trend) {
   resized.covariates[[n.covs + 1]] <- "trend"
   names(resized.covariates)[n.covs + 1] <- "trend"
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

  vec.options <- list(px.core = 1, px.neighbors = 3, t_frequency = 12, na.rm = TRUE, groups = 1, NAcovs = "pairwise.complete.obs")

  global.series <- build.sdpd.series(px = "all", rry = rry, rrXX = resized.covariates, rrgroups = province, label_groups = label.province, vec.options = vec.options)

  df.gruppi <- tibble(gruppo = global.series$p.axis$group, px = global.series$p.axis$pixel) %>%
   nest_by(.by = gruppo, .key = "gruppo")

  names(df.gruppi$gruppo) <- seq(1, length(df.gruppi$gruppo))
  for (ii in 1:length(df.gruppi$gruppo)) {
   names(df.gruppi$gruppo)[ii] <- df.gruppi$gruppo[[ii]]$gruppo[1,2]
  }

  df.data <- df.gruppi$gruppo %>%
   map(fun.extract.data, rry = rry, rrxx = resized.covariates, rrgroups = province, label_groups = label.province, vec.options = vec.options)

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

  model_results <- fun.estimate.parameters(df.obj, model = sdpd.model, vec.options = vec.options)

  if (!is.null(model_results$error)) {
   stop("Error in model estimation: ", model_results$error)
  }

  assembled_results <- fun.assemble.estimate.results(model_results)

  write.csv(assembled_results$coeff.hat, file = file.path(output_dir, "model_fits/stats", "coefficients.csv"), row.names = FALSE)
  write_json(assembled_results$coeff.hat, path = file.path(output_dir, "model_fits/stats", "coefficients.json"))
  write.csv(assembled_results$fitted, file = file.path(output_dir, "model_fits/stats", "fitted.csv"), row.names = FALSE)
  write_json(assembled_results$fitted, path = file.path(output_dir, "model_fits/stats", "fitted.json"))
  write.csv(assembled_results$resid, file = file.path(output_dir, "model_fits/stats", "residuals.csv"), row.names = FALSE)
  write_json(assembled_results$resid, path = file.path(output_dir, "model_fits/stats", "residuals.json"))

  res <- list()
  nomi <- names(assembled_results$coeff.hat)
  for (ii in 1:length(nomi)) {
   dati <- data.frame(lon = assembled_results$lon, lat = assembled_results$lat, newvar = assembled_results$coeff.hat[, ii])
   plot.coeff <- dati %>%
     ggplot(aes(lon, lat)) +
     geom_point(aes(colour = newvar), size = 0.8) +
     scale_colour_gradient2(high = "red", low = "blue", mid = "white", midpoint = 0, limits = pars_list[[name.endogenous]]$limiti) +
     labs(title = paste("Estimated coefficients for", nomi[ii]), colour = "value")
   ggsave(filename = file.path(output_dir, "model_fits/plots", paste0("coeff_", nomi[ii], ".png")), plot = plot.coeff, width = 8, height = 6)
   if (bool_dynamic) {
     plt <- plotly::ggplotly(plot.coeff)
     htmlwidgets::saveWidget(plt, file = file.path(output_dir, "model_fits/plots", paste0("coeff_", nomi[ii], ".html")))
   }
   res[[ii]] <- plot.coeff
  }
  names(res) <- nomi

  interval.range <- dimnames(assembled_results$fitted)[[2]]
  time_index <- as.yearmon(interval.range)

  i <- which(
   round(assembled_results$lon, 5) == round(user_longitude_choice, 5) &
     round(assembled_results$lat, 5) == round(user_latitude_choice, 5)
  )

  if (length(i) > 0) {
   sottotitolo <- paste("longitude =", assembled_results$lon[i], " - latitude =", assembled_results$lat[i])
   fitted_i <- as.numeric(assembled_results$fitted[i, ])
   resid_i <- as.numeric(assembled_results$resid[i, ])
   observed_i <- fitted_i + resid_i
   coeff <- min(fitted_i, na.rm = TRUE) - 0.1 * diff(range(fitted_i, na.rm = TRUE))
   plot.series <- tibble(
     time = time_index,
     fitted = fitted_i,
     resid = resid_i,
     observed = observed_i
   ) %>%
     ggplot(aes(x = time)) +
     geom_line(aes(y = fitted, color = "Fitted")) +
     geom_line(aes(y = observed, color = "Observed")) +
     geom_line(aes(y = resid + coeff, color = "Residuals")) +
     geom_hline(yintercept = mean(resid_i, na.rm = TRUE) + coeff, linetype = "dashed") +
     scale_y_continuous(
       name = name.endogenous,
       sec.axis = sec_axis(~ . - coeff, name = "Residuals")
     ) +
     labs(title = "Estimated model series", subtitle = sottotitolo, x = "", color = "") +
     theme_minimal()
   filename <- paste0("series_lon_", assembled_results$lon[i], "_lat_", assembled_results$lat[i])
   ggsave(filename = file.path(output_dir, "model_fits/plots", paste0(filename, ".png")), plot = plot.series, width = 8, height = 6)
   if (bool_dynamic) {
     plt <- plotly::ggplotly(plot.series)
     htmlwidgets::saveWidget(plt, file = file.path(output_dir, "model_fits/plots", paste0(filename, ".html")))
   }
   write_json(list(
     lon = assembled_results$lon[i],
     lat = assembled_results$lat[i],
     plot_data = list(
       time = as.character(time_index),
       fitted = fitted_i,
       observed = observed_i,
       resid = resid_i
     )
   ), path = file.path(output_dir, "model_fits/plots", paste0(filename, ".json")))
  }

  for (stat in validation_statistics) {
   funzione <- fun.derive.function.VARs(stat)
   titolo <- paste(stat)
   if (is.data.frame(assembled_results$resid)) {
     dati <- data.frame(
       lon = assembled_results$lon,
       lat = assembled_results$lat,
       newvar = apply(assembled_results$resid, 1, FUN = funzione)
     )
   } else if (is.list(assembled_results$resid)) {
     dati <- data.frame(
       lon = assembled_results$lon,
       lat = assembled_results$lat,
       newvar = unlist(lapply(assembled_results$resid, FUN = funzione))
     )
   }
   plot.resid <- dati %>%
     ggplot(aes(lon, lat, colour = newvar)) +
     geom_point(size = 0.8) +
     guides(fill = "none") +
     labs(
       title = "Summary validation statistics for residuals",
       x = "Longitude", y = "Latitude",
       colour = paste(titolo, "\nof residuals")
     ) +
     scale_colour_gradient2(high = "red", low = "blue", mid = "white", midpoint = 0)
   ggsave(filename = file.path(output_dir, "model_fits/plots", paste0("resid_", stat, "_", name.endogenous, ".png")), plot = plot.resid, width = 8, height = 6)
   if (bool_dynamic) {
     plt <- plotly::ggplotly(plot.resid)
     htmlwidgets::saveWidget(plt, file = file.path(output_dir, "model_fits/plots", paste0("resid_", stat, "_", name.endogenous, ".html")))
   }
   stat_data <- data.frame(
     longitude = assembled_results$lon,
     latitude = assembled_results$lat,
     value = apply(assembled_results$resid, 1, funzione)
   )
   write.csv(stat_data, file = file.path(output_dir, "model_fits/stats", paste0("resid_", stat, "_", name.endogenous, ".csv")), row.names = FALSE)
   write_json(stat_data, path = file.path(output_dir, "model_fits/stats", paste0("resid_", stat, "_", name.endogenous, ".json")))
  }

  test_results <- fun.testing.parameters(
   df.obj = model_results,
   correzione = TRUE,
   n.boot = n.boot,
   label.group = label_groups,
   plot = bool_dynamic
  )

  if (!is.null(test_results)) {
   assembled_test_results <- fun.assemble.test.results(test_results)
   write.csv(assembled_test_results$pvalue.test, file = file.path(output_dir, "bootstrap/stats", "pvalues.csv"), row.names = FALSE)
   write_json(assembled_test_results$pvalue.test, path = file.path(output_dir, "bootstrap/stats", "pvalues.json"))
   write.csv(assembled_test_results$diagnostics, file = file.path(output_dir, "bootstrap/stats", "diagnostics.csv"), row.names = FALSE)
   write_json(assembled_test_results$diagnostics, path = file.path(output_dir, "bootstrap/stats", "diagnostics.json"))
   write.csv(assembled_test_results$coeff.bias.boot, file = file.path(output_dir, "bootstrap/stats", "coeff_bias.csv"), row.names = FALSE)
   write_json(assembled_test_results$coeff.bias.boot, path = file.path(output_dir, "bootstrap/stats", "coeff_bias.json"))
   write.csv(assembled_test_results$coeff.sd.boot, file = file.path(output_dir, "bootstrap/stats", "coeff_sd.csv"), row.names = FALSE)
   write_json(assembled_test_results$coeff.sd.boot, path = file.path(output_dir, "bootstrap/stats", "coeff_sd.json"))
   write.csv(assembled_test_results$sdevs.tsboot, file = file.path(output_dir, "bootstrap/stats", "sdevs_tsboot.csv"), row.names = FALSE)
   write_json(assembled_test_results$sdevs.tsboot, path = file.path(output_dir, "bootstrap/stats", "sdevs_tsboot.json"))

   ii <- user_coeff_choice
   param_name <- names(assembled_test_results$coeff.hat)[ii]
   reject <- assembled_test_results$pvalue.test[, ii] < 0.05
   dati <- data.frame(
     lon = assembled_test_results$lon,
     lat = assembled_test_results$lat,
     newvar = assembled_test_results$coeff.hat[, ii] * reject
   )
   plot.coeff <- dati %>%
     ggplot(aes(lon, lat)) +
     geom_point(aes(colour = newvar), size = 0.8) +
     scale_colour_gradient2(high = "red", low = "blue", mid = "white", midpoint = 0) +
     labs(title = param_name, subtitle = "Estimated coefficients validated by the bootstrap test", colour = "value")
   ggsave(filename = file.path(output_dir, "bootstrap/plots", paste0("coeffboot_", param_name, ".png")), plot = plot.coeff, width = 8, height = 6)
   if (bool_dynamic) {
     plt <- plotly::ggplotly(plot.coeff)
     htmlwidgets::saveWidget(plt, file = file.path(output_dir, "bootstrap/plots", paste0("coeffboot_", param_name, ".html")))
   }
   write_json(plot.coeff, path = file.path(output_dir, "bootstrap/plots", paste0("coeffboot_", param_name, ".json")))

   dati <- data.frame(
     lon = assembled_test_results$lon,
     lat = assembled_test_results$lat,
     newvar = assembled_test_results$coeff.bias.boot[, ii]
   )
   plot.bias <- dati %>%
     ggplot(aes(lon, lat)) +
     geom_point(aes(colour = newvar), size = 0.8) +
     scale_colour_gradient2(high = "red", low = "blue", mid = "white", midpoint = 0) +
     labs(title = param_name, subtitle = "Bootstrap bias estimation", colour = "bias")
   ggsave(filename = file.path(output_dir, "bootstrap/plots", paste0("coeffboot_bias_", param_name, ".png")), plot = plot.bias, width = 8, height = 6)
   if (bool_dynamic) {
     plt <- plotly::ggplotly(plot.bias)
     htmlwidgets::saveWidget(plt, file = file.path(output_dir, "bootstrap/plots", paste0("coeffboot_bias_", param_name, ".html")))
   }
   write_json(plot.bias, path = file.path(output_dir, "bootstrap/plots", paste0("coeffboot_bias_", param_name, ".json")))

   dati <- data.frame(
     lon = assembled_test_results$lon,
     lat = assembled_test_results$lat,
     newvar = assembled_test_results$coeff.sd.boot[, ii]
   )
   plot.sd <- dati %>%
     ggplot(aes(lon, lat)) +
     geom_point(aes(colour = newvar), size = 0.8) +
     scale_colour_gradient2(high = "red", low = "blue", mid = "white", midpoint = 0) +
     labs(title = param_name, subtitle = "Bootstrap standard deviation estimation", colour = "sd")
   ggsave(filename = file.path(output_dir, "bootstrap/plots", paste0("coeffboot_sd_", param_name, ".png")), plot = plot.sd, width = 8, height = 6)
   if (bool_dynamic) {
     plt <- plotly::ggplotly(plot.sd)
     htmlwidgets::saveWidget(plt, file = file.path(output_dir, "bootstrap/plots", paste0("coeffboot_sd_", param_name, ".html")))
   }
   write_json(plot.sd, path = file.path(output_dir, "bootstrap/plots", paste0("coeffboot_sd_", param_name, ".json")))

   dati <- data.frame(
     lon = assembled_test_results$lon,
     lat = assembled_test_results$lat,
     newvar = assembled_test_results$sdevs.tsboot[, ii]
   )
   plot.sdevs <- dati %>%
     ggplot(aes(lon, lat)) +
     geom_point(aes(colour = newvar), size = 0.8) +
     scale_colour_gradient2(high = "red", low = "blue", mid = "white", midpoint = 0, limits = c(0, 100)) +
     labs(title = param_name, subtitle = "Differences between bootstrap and observed time series\n(Grey pixels show values > 100)", colour = "value")
   ggsave(filename = file.path(output_dir, "bootstrap/plots", paste0("coeffboot_sdevs_", param_name, ".png")), plot = plot.sdevs, width = 8, height = 6)
   if (bool_dynamic) {
     plt <- plotly::ggplotly(plot.sdevs)
     htmlwidgets::saveWidget(plt, file = file.path(output_dir, "bootstrap/plots", paste0("coeffboot_sdevs_", param_name, ".html")))
   }
   write_json(plot.sdevs, path = file.path(output_dir, "bootstrap/plots", paste0("coeffboot_sdevs_", param_name, ".json")))
  }

  # Set status to "done" only after all outputs are generated
  analysis_status <<- "done"
  cat("Model 4: Analysis completed. Outputs saved in", output_dir, "\n")
}, error = function(e) {
  # Set status to "error" if any step fails
  analysis_status <<- "error"
  cat("Error during analysis:", conditionMessage(e), "\n")
})

  # Save analysis_status to flag file
  writeLines(analysis_status, con = file.path(output_dir, paste0(analysis_id, ".flag")))