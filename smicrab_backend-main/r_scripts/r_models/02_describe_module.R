# ==============================================================================
# SMICRAB Model Analysis - Describe Module
# This module handles data description, visualization, and summary statistics
# ==============================================================================

tryCatch(
  {
    # Load common setup
    source("r_scripts/r_models/00_common_setup.R")

    # Load data module workspace
    data_workspace_path <- file.path(output_dir, "Rdata", "data_module_workspace.RData")
    if (file.exists(data_workspace_path)) {
      load(data_workspace_path)
      log_info("Loaded data module workspace from: {data_workspace_path}")
    } else {
      log_info("Data module workspace not found. Running data module first...")
      source("r_scripts/r_models/01_data_module.R")
    }

    # ==============================================================================
    # DESCRIBE MODULE
    # ==============================================================================

    log_info("DESCRIBE MODULE Started")

    log_info("Create (or load) the R objects required for estimations")
    if (!bool_update) {
      workfile_path <- paste(output_dir, "/Rdata/workfile_model_", name.endogenous, ".RData", sep = "")
      if (file.exists(workfile_path)) {
        load(workfile_path)
        log_info("Loaded existing workfile from: {workfile_path}")
      } else {
        log_info("Workfile not found, will create new one")
      }
    }

    # ==============================================================================
    # SPATIAL DISTRIBUTION PLOTS
    # ==============================================================================

    log_info("Plotting Spatial distribution of values at a fixed date")
    for (ii in names(variable)) {
      log_info("Plotting spatial distribution for: {ii}")
      output_path <- if (bool_dynamic) {
        file.path(output_dir, "summary_stats/plots", paste0(ii, "_spatial.html"))
      } else {
        file.path(output_dir, "summary_stats/plots", paste0(ii, "_spatial.png"))
      }

      tryCatch(
        {
          plotVarSpatial(ii, user_date_choice, dataframes[[ii]], pars_list[[ii]], bool_dynamic, output_path)
          log_info("Successfully created spatial plot for {ii}")
        },
        error = function(e) {
          log_error("Error creating spatial plot for {ii}: {e$message}")
        }
      )
    }

    # ==============================================================================
    # TEMPORAL DISTRIBUTION PLOTS
    # ==============================================================================

    log_info("Plotting Temporal distribution of values for a fixed pixel")
    for (ii in names(variable)) {
      log_info("Plotting temporal distribution for: {ii}")
      output_path <- if (bool_dynamic) {
        file.path(output_dir, "summary_stats/plots", paste0(ii, "_stl_decomposition.html"))
      } else {
        file.path(output_dir, "summary_stats/plots", paste0(ii, "_stl_decomposition.png"))
      }

      tryCatch(
        {
          PlotComponentsSTL_nonest_lonlat2(
            user_latitude_choice,
            user_longitude_choice,
            ii,
            dataframes[[ii]],
            pars_list[[ii]],
            bool_dynamic,
            output_path
          )
          log_info("Successfully created STL decomposition plot for {ii}")
        },
        error = function(e) {
          log_error("Error creating STL decomposition plot for {ii}: {e$message}")
        }
      )
    }

    # ==============================================================================
    # SUMMARY STATISTICS PLOTS
    # ==============================================================================

    log_info("Plotting Summary Statistics")

    for (ii in names(variable)) {
      log_info("Plotting summary statistics for: {ii}")

      tryCatch(
        {
          funzione <- fun.derive.function.VARs(summary_stat)
          titolo <- paste(summary_stat, "of", ii)
          pars <- pars_list[[ii]]
          df <- dataframes[[ii]]
          output_path <- if (bool_dynamic) {
            file.path(output_dir, "summary_stats/plots", paste0(summary_stat, "_", ii, ".html"))
          } else {
            file.path(output_dir, "summary_stats/plots", paste0(summary_stat, "_", ii, ".png"))
          }

          fun.plot.stat.VARs(df, funzione, titolo, pars, output_path, bool_dynamic)
          log_info("Successfully created summary statistics plot for {ii}")
        },
        error = function(e) {
          log_error("Error creating summary statistics plot for {ii}: {e$message}")
        }
      )
    }

    # ==============================================================================
    # ADDITIONAL SUMMARY STATISTICS
    # ==============================================================================

    log_info("Computing additional summary statistics...")

    # Compute basic statistics for each variable
    summary_stats <- list()
    for (ii in names(variable)) {
      log_info("Computing statistics for: {ii}")

      tryCatch(
        {
          df <- dataframes[[ii]]
          numeric_cols <- df[, -c(1, 2)] # Exclude longitude and latitude

          summary_stats[[ii]] <- list(
            variable_name = ii,
            n_pixels = nrow(df),
            n_time_points = ncol(numeric_cols),
            mean_value = mean(as.matrix(numeric_cols), na.rm = TRUE),
            sd_value = sd(as.matrix(numeric_cols), na.rm = TRUE),
            min_value = min(as.matrix(numeric_cols), na.rm = TRUE),
            max_value = max(as.matrix(numeric_cols), na.rm = TRUE),
            na_count = sum(is.na(as.matrix(numeric_cols))),
            na_percentage = sum(is.na(as.matrix(numeric_cols))) / length(as.matrix(numeric_cols)) * 100
          )

          log_info("Statistics for {ii}: Mean={round(summary_stats[[ii]]$mean_value, 3)}, SD={round(summary_stats[[ii]]$sd_value, 3)}")
        },
        error = function(e) {
          log_error("Error computing statistics for {ii}: {e$message}")
        }
      )
    }

    # Save summary statistics
    summary_stats_path <- file.path(output_dir, "summary_stats/stats", "variable_summary_statistics.json")
    tryCatch(
      {
        write(toJSON(summary_stats, pretty = TRUE), file = summary_stats_path)
        log_info("Summary statistics saved to: {summary_stats_path}")
      },
      error = function(e) {
        log_error("Error saving summary statistics: {e$message}")
      }
    )

    # ==============================================================================
    # TIME SERIES ANALYSIS
    # ==============================================================================

    log_info("Performing basic time series analysis...")

    tryCatch(
      {
        # Extract time series for a specific pixel
        pixel_ts_data <- list()

        for (ii in names(variable)) {
          df <- dataframes[[ii]]

          # Find pixel closest to user-specified coordinates
          distances <- sqrt((df$longitude - user_longitude_choice)^2 + (df$latitude - user_latitude_choice)^2)
          closest_pixel_idx <- which.min(distances)

          # Extract time series for this pixel
          numeric_cols <- df[closest_pixel_idx, -c(1, 2)]
          pixel_ts_data[[ii]] <- as.numeric(numeric_cols)
        }

        # Save time series data
        ts_data_path <- file.path(output_dir, "summary_stats/stats", "pixel_time_series_data.json")
        write(toJSON(pixel_ts_data, pretty = TRUE), file = ts_data_path)
        log_info("Time series data saved to: {ts_data_path}")
      },
      error = function(e) {
        log_error("Error in time series analysis: {e$message}")
      }
    )

    # ==============================================================================
    # EXPORT RESULTS
    # ==============================================================================

    # Save describe module workspace
    describe_workspace_path <- file.path(output_dir, "Rdata", "describe_module_workspace.RData")
    save(
      list = c(
        "summary_stats", "variable", "dataframes", "name.endogenous", "name.covariates"
      ),
      file = describe_workspace_path
    )

    log_info("DESCRIBE MODULE Completed")
    log_info("Describe module workspace saved to: {describe_workspace_path}")

    # Summary report
    log_info("=== DESCRIBE MODULE SUMMARY ===")
    log_info("Variables analyzed: {length(variable)}")
    log_info("Spatial plots created: {length(variable)}")
    log_info("Temporal plots created: {length(variable)}")
    log_info("Summary statistics computed for: {paste(names(summary_stats), collapse = ', ')}")
    log_info("Selected endogenous variable: {name.endogenous}")
    log_info("Selected covariates: {paste(name.covariates, collapse = ', ')}")
    log_info("Output directory: {output_dir}/summary_stats/")
    log_info("=================================")
  },
  error = function(e) {
    log_error("Error in DESCRIBE MODULE: {e}")
    stop(e)
  }
)
