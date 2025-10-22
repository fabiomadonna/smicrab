# ==============================================================================
# SMICRAB Model Analysis - Estimate Module
# This module handles model estimation and coefficient analysis
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
    # ADDITIONAL HELPER FUNCTIONS FOR ESTIMATION
    # ==============================================================================
    
    save_coeff_plots <- function(plot.coeffs, output_dir, name.endogenous, name.covariates, bool_dynamic = TRUE, bool_trend = FALSE) {
      # Helper function to save a single plot
      save_plot <- function(plot_obj, filename, bool_dynamic) {
        if (bool_dynamic) {
          htmlwidgets::saveWidget(plot_obj, file = filename, selfcontained = TRUE)
        } else {
          ggsave(filename = filename, plot = plot_obj, width = 8, height = 6)
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
        save_plot(fe_plot, output_path, bool_dynamic)
      }
    }
    
    diagnostic_models <- function(mod.fit, output_dir = NULL, filename_prefix = "diagnostic") {
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
        plot(mod.fit, which = c(1, 2))
        return(NULL)
      }
    }
    
    # ==============================================================================
    # ESTIMATE MODULE
    # ==============================================================================
    
    log_info("ESTIMATE MODULE Started")
    
    # Model configuration details - B) Create or load the R objects required for estimations
    log_info("Starting configuration of model objects for {user_model_choice}")

    estimate_workspace_path <- paste(output_dir, "/Rdata/estimate_module_workspace_", user_model_choice, "(", name.endogenous, ").RData", sep = "")
    
    if (!bool_update) {
      log_info("Loading pre-computed results for {user_model_choice} with endogenous variable {name.endogenous}")
      load_path <- estimate_workspace_path
      tryCatch(
        {
          load(load_path)
          log_info("Successfully loaded pre-computed results from {load_path}")
        },
        error = function(e) {
          log_info("Error loading pre-computed results from {load_path}: {e$message}")
          log_info("Will proceed with model estimation...")
          bool_update <<- TRUE
        }
      )
    }
    
    # Objects to save for future use
    objects_to_save <- character(0)

    # ==============================================================================
    # MODEL CONFIGURATION BASED ON MODEL TYPE
    # ==============================================================================
    
    if (user_model_choice %in% c("Model3_MB_User", "Model6_HSDPD_user") | bool_update) {
      log_info("Building dataframes for all variables")
      
      # Ensure dataframes exist
      if (!exists("dataframes")) {
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
        objects_to_save <- c(objects_to_save, "dataframes")
        #save(dataframes, file = rdata_path)
      }
      
      log_info("Building endogenous variable and covariates")
      var_y <- variable[[name.endogenous]]
      tt <- length(time(var_y))
      tt.date <- time(variable[[name.endogenous]])
      kk <- length(rrxx)
      
      # Handle empty covariate_legs for models without covariates
      if (length(covariate_legs) == 0 || length(covariate_variables) == 0) {
        integer_lags <- numeric(0)
        log_info("No covariates specified, using empty lags")
      } else {
        integer_lags <- setNames(covariate_legs, covariate_variables)
        log_info("Integer lags: {integer_lags}")
      }
      
      # Calculate time range with proper handling of empty lags
      max_lag <- if (length(integer_lags) > 0) max(integer_lags) else 0
      from.tt <- 1 + max(max_lag, 0)
      to.tt <- tt
      rry <- var_y[[from.tt:to.tt]]
      log_info("Endogenous variable {name.endogenous} prepared with time range {from.tt}:{to.tt}")
      
      resized.covariates <- list()
      n.covs <- length(name.covariates)
      if (n.covs > 0) {
        for (ii in seq_along(name.covariates)) {
          cov_name <- name.covariates[[ii]]
          lag <- integer_lags[[cov_name]]
          from.tt <- 1 + max(max_lag, 0) - lag
          to.tt <- tt - lag
          resized.covariates[[cov_name]] <- variable[[cov_name]][[from.tt:to.tt]]
          log_info("Covariate {cov_name} prepared with time range {from.tt}:{to.tt}")
        }
      }
      
      # Validate shapefile and rasterization
      log_info("Loading shapefile for pixel grouping")
      tryCatch(
        {
          italy.shape <- vect(shape_path)
          italy.shape <- project(italy.shape, var_y)
          province <- rasterize(italy.shape, var_y, field = "COD_PROV")
          if (!inherits(province, "SpatRaster")) {
            stop("rasterize did not produce a SpatRaster object")
          }
          label.province <- values(italy.shape)[, "DEN_UTS"]
          names(label.province) <- values(italy.shape)[, "COD_PROV"]
          log_info("Shapefile loaded and projected successfully")
        },
        error = function(e) {
          log_info("Error loading shapefile from {shape_path}: {e$message}")
          # Create dummy province data if shapefile fails
          province <- NULL
          label.province <- NULL
          log_info("Proceeding without province grouping")
        }
      )
    }
    
    # ==============================================================================
    # H-SDPD MODELS CONFIGURATION
    # ==============================================================================
    
    if (user_model_choice %in% c("Model6_HSDPD_user") |
        (bool_update & user_model_choice %in% c("Model4_UHU", "Model5_RAB"))) {
      log_info("Configuring H-SDPD model for {user_model_choice}")
      
      if (bool_trend) {
        resized.covariates[["trend"]] <- "trend"
        log_info("Added trend covariate")
      }
      
      sdpd.model <- list()
      sdpd.model$lambda.coeffs <- c(TRUE, TRUE, TRUE)
      names(sdpd.model$lambda.coeffs) <- c("lambda0", "lambda1", "lambda2")
      
      if (length(resized.covariates) > 0) {
        sdpd.model$beta.coeffs <- rep(TRUE, length(resized.covariates))
        names(sdpd.model$beta.coeffs) <- names(resized.covariates)
      } else {
        sdpd.model$beta.coeffs <- NULL
        resized.covariates <- NULL
      }
      
      sdpd.model$fixed_effects <- TRUE
      sdpd.model$time_effects <- FALSE
      log_info("H-SDPD model structure defined with {length(resized.covariates)} covariates")
      
      log_info("Building spatial-temporal series for H-SDPD model")
      tryCatch(
        {
          global.series <- build.sdpd.series(
            px = "all",
            rry = rry,
            rrXX = resized.covariates,
            rrgroups = province,
            label_groups = label.province,
            vec.options = vec.options
          )
          log_info("Spatial-temporal series built successfully")
        },
        error = function(e) {
          log_info("Error building spatial-temporal series: {e$message}")
          log_error("Error call: {deparse(e$call)}")
          log_error("Error traceback: {paste(capture.output(traceback(e)), collapse = '\\n')}")
          log_error("Error traceback: {paste(capture.output(traceback(e)), collapse = '\\n')}")
          stop("Failed to build spatial-temporal series")
        }
      )
      
      log_info("Grouping pixels by districts")
      df.gruppi <- tibble(gruppo = global.series$p.axis$group, px = global.series$p.axis$pixel) %>%
        nest_by(.by = gruppo, .key = "gruppo")
      
      names(df.gruppi$gruppo) <- seq(1, length(df.gruppi$gruppo))
      for (ii in 1:length(df.gruppi$gruppo)) {
        names(df.gruppi$gruppo)[ii] <- df.gruppi$gruppo[[ii]]$gruppo[1, 2]
      }
      log_info("Pixels grouped into {length(df.gruppi$gruppo)} districts")
      
      log_info("Preparing data for H-SDPD model estimation")
      tryCatch(
        {
          df.data <- df.gruppi$gruppo %>%
            map(fun.extract.data,
                rry = rry,
                rrxx = resized.covariates,
                rrgroups = province,
                label_groups = label.province,
                vec.options = vec.options
            )
          log_info("Data prepared for H-SDPD model estimation")
        },
        error = function(e) {
          log_info("Error preparing data for H-SDPD model: {e$message}")
          stop("Failed to prepare data for H-SDPD model")
        }
      )
      
      objects_to_save <- c(objects_to_save, "sdpd.model", "global.series", "tt.date")
      log_info("Added sdpd.model and global.series to objects_to_save")
    }
    
    # ==============================================================================
    # MB-TREND MODELS CONFIGURATION
    # ==============================================================================
    
    if (bool_update & user_model_choice %in% c("Model1_Simple", "Model2_Autoregressive", "Model3_MB_User")) {
      log_info("Configuring MB-Trend model for {user_model_choice}")
      
      false.covariates <- variable
      false.covariates[[name.endogenous]] <- NULL
      
      log_info("Building spatial-temporal series for MB-Trend model")
      tryCatch(
        {
          global.series <- build.sdpd.series(
            px = "all",
            rry = rry,
            rrXX = false.covariates,
            rrgroups = province,
            label_groups = label.province,
            vec.options = vec.options
          )
          tt.date <- time(variable[[name.endogenous]])
          log_info("Spatial-temporal series built successfully for MB-Trend model")
        },
        error = function(e) {
          log_info("Error building spatial-temporal series for MB-Trend model: {e$message}")
          stop("Failed to build spatial-temporal series for MB-Trend model")
        }
      )
      
      new_dataframes <- variable
      for (ii in names(variable)) {
        log_info("Processing variable {ii} for MB-Trend dataframes")
        if (ii == name.endogenous) {
          valori <- global.series$series
        } else {
          valori <- global.series$X[ii, , ]
        }
        new_dataframes[[ii]] <- data.frame(
          longitude = global.series$p.axis$longit,
          latitude = global.series$p.axis$latit,
          valori
        )
      }
      
      log_info("Creating long and nested dataframes")
      data_df <- lapply(new_dataframes, CreateLongDF)
      data_nested_df <- lapply(data_df, CreateNestedDF)
      
      log_info("Generating time-series dataframes")
      plan(multisession, workers = 12)
      
      tryCatch(
        {
          data_nested_ts_df <- lapply(data_nested_df, GenerateTSDataFrame)
          log_info("Time-series dataframes generated successfully")
        },
        error = function(e) {
          log_error("Error generating time-series dataframes: {e$message}")
          log_info("Memory usage: {pryr::mem_used()}")
          stop("Failed to generate time-series dataframes")
        },
        warning = function(w) {
          log_warning("Warning during GenerateTSDataFrame: {w$message}")
        }
      )
      
      log_info("Creating full dataset")
      plan(multisession, workers = 12)
      tryCatch(
        {
          full_data_ts_df <- CreateFullDataset(data_df)
          log_info("Full dataset created successfully")
        },
        error = function(e) {
          log_info("Error creating full dataset: {e$message}")
          stop("Failed to create full dataset")
        }
      )
      
      objects_to_save <- c(objects_to_save, "data_df", "tt.date")
      log_info("Added data_df to objects_to_save")
    }
    
    # ==============================================================================
    # LAND COVER DATASET
    # ==============================================================================
    
    if (user_model_choice == "Model6_HSDPD_user" | bool_update) {
      log_info("Creating Land Cover dataset")
      tryCatch(
        {
          if (exists("global.series")) {
            px <- as.numeric(dimnames(global.series$series)[[1]])
            coordinate <- xyFromCell(variable[[name.endogenous]], px)
            indici <- cellFromXY(lc22[[1]], coordinate)
            slc_df <- data.frame(
              longitude = global.series$p.axis$longit,
              latitude = global.series$p.axis$latit,
              slc = values(lc22)[indici, 1]
            )
            slc_df <- slc_df %>%
              mutate(Longitude = round(longitude, 1), Latitude = round(latitude, 1)) %>%
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
          } else {
            log_info("Global series not available, skipping land cover dataset creation")
          }
        },
        error = function(e) {
          log_info("Error creating Land Cover dataset: {e$message}")
        }
      )
      
      if (exists("slc_df")) {
        objects_to_save <- c(objects_to_save, "slc_df")
        log_info("Added slc_df to objects_to_save")
      }
    }
    
    log_info("Model configuration completed for {user_model_choice}")
    
    # ==============================================================================
    # MODEL ESTIMATION
    # ==============================================================================
    
    log_info("Starting model estimation for {user_model_choice}")
    
    # A) Simple Trend Model (Model1_Simple)
    if (user_model_choice == "Model1_Simple" & bool_update) {
      log_info("Computing trend statistics for Model1_Simple")
      
      if (exists("data_nested_ts_df")) {
        # Try to compute trend statistics individually with better error handling
        trend_stats_computed <- FALSE
        
        # Try Sen's slope test
        tryCatch(
          {
            log_info("Computing TrendSens_df")
            plan(multisession, workers = 12)
            TrendSens_df <- lapply(data_nested_ts_df, ComputeSens_Stats)
            log_info("Computed TrendSens_df")
            trend_stats_computed <- TRUE
          },
          error = function(e) {
            log_info("Error computing TrendSens_df: {e$message}")
            log_info("Trying sequential computation...")
            tryCatch(
              {
                plan(sequential)
                TrendSens_df <<- lapply(data_nested_ts_df, ComputeSens_Stats)
                log_info("Computed TrendSens_df with sequential processing")
                trend_stats_computed <<- TRUE
              },
              error = function(e2) {
                log_info("Sequential computation also failed: {e2$message}")
              }
            )
          }
        )
        
        # Try Cox-Snell test
        tryCatch(
          {
            log_info("Computing TrendCS_df")
            plan(multisession, workers = 12)
            TrendCS_df <- lapply(data_nested_ts_df, ComputeCS_Stats)
            log_info("Computed TrendCS_df")
          },
          error = function(e) {
            log_info("Error computing TrendCS_df: {e$message}")
          }
        )
        
        # Try Mann-Kendall test
        tryCatch(
          {
            log_info("Computing TrendMK_df")
            plan(multisession, workers = 12)
            TrendMK_df <- lapply(data_nested_ts_df, ComputeMK_Stats)
            log_info("Computed TrendMK_df")
          },
          error = function(e) {
            log_info("Error computing TrendMK_df: {e$message}")
          }
        )
        
        # Try other trend tests
        tryCatch(
          {
            log_info("Computing TrendSMK_df")
            plan(multisession, workers = 12)
            TrendSMK_df <- lapply(data_nested_ts_df, ComputeSMK_Stats)
            log_info("Computed TrendSMK_df")
          },
          error = function(e) {
            log_info("Error computing TrendSMK_df: {e$message}")
          }
        )
        
        tryCatch(
          {
            log_info("Computing TrendPWMK_df")
            plan(multisession, workers = 12)
            TrendPWMK_df <- lapply(data_nested_ts_df, ComputePWMK_Stats)
            log_info("Computed TrendPWMK_df")
          },
          error = function(e) {
            log_info("Error computing TrendPWMK_df: {e$message}")
          }
        )
        
        tryCatch(
          {
            log_info("Computing TrendBCPW_df")
            plan(multisession, workers = 12)
            TrendBCPW_df <- lapply(data_nested_ts_df, ComputeBCPW_Stats)
            log_info("Computed TrendBCPW_df")
          },
          error = function(e) {
            log_info("Error computing TrendBCPW_df: {e$message}")
          }
        )
        
        tryCatch(
          {
            log_info("Computing TrendRobust_df")
            plan(multisession, workers = 12)
            TrendRobust_df <- lapply(data_nested_ts_df, ComputeRobust_Stats)
            log_info("Computed TrendRobust_df")
          },
          error = function(e) {
            log_info("Error computing TrendRobust_df: {e$message}")
          }
        )
        
        # Add available trend statistics to objects_to_save
        trend_objects <- c()
        if (exists("TrendSens_df")) trend_objects <- c(trend_objects, "TrendSens_df")
        if (exists("TrendCS_df")) trend_objects <- c(trend_objects, "TrendCS_df")
        if (exists("TrendMK_df")) trend_objects <- c(trend_objects, "TrendMK_df")
        if (exists("TrendSMK_df")) trend_objects <- c(trend_objects, "TrendSMK_df")
        if (exists("TrendPWMK_df")) trend_objects <- c(trend_objects, "TrendPWMK_df")
        if (exists("TrendBCPW_df")) trend_objects <- c(trend_objects, "TrendBCPW_df")
        if (exists("TrendRobust_df")) trend_objects <- c(trend_objects, "TrendRobust_df")
        
        if (length(trend_objects) > 0) {
          objects_to_save <- c(objects_to_save, trend_objects)
          log_info("Added trend statistics to objects_to_save: {paste(trend_objects, collapse = ', ')}")
        } else {
          log_info("No trend statistics were computed successfully")
        }
      } else {
        log_info("data_nested_ts_df not available for Model1_Simple")
      }
    }
    
    # B) MB-Trend Models (Model2_Autoregressive, Model3_MB_User)
    if (user_model_choice == "Model3_MB_User" | (bool_update & user_model_choice == "Model2_Autoregressive")) {
      log_info("Estimating MB-Trend model for {user_model_choice}")
      
      if (user_model_choice == "Model2_Autoregressive") {
        log_info("Loading pre-computed data for Model2_Autoregressive")
        model2_path <- paste(output_dir, "/Rdata/workfile_model2_", endogenous_variable, ".RData", sep="")
        if (file.exists(model2_path)) {
          tryCatch(
            {
              load(model2_path)
              log_info("Successfully loaded workfile_model2_[endogenous].RData")
            },
            error = function(e) {
              log_info("Error loading workfile_model2_[endogenous].RData: {e$message}")
            }
          )
        }
      }
      
      if (exists("full_data_ts_df")) {
        xreg <- NULL
        if (length(name.covariates) > 0) {
          xreg <- paste(name.covariates, collapse = " + ")
          log_info("Covariates for xreg: {xreg}")
        }
        
        xreg <- paste("trend() + season()", xreg, " + pdq(d=0,q=0) + PDQ(0,0,0)", sep = "")
        log_info("xreg formula: {xreg}")
        
        log_info("Estimating temporal model")
        tryCatch(
          {
            modelStats_df <- computeTemporalModelStats(full_data_ts_df, name.endogenous, xreg)
            log_info("Temporal model stats computed")
          },
          error = function(e) {
            log_info("Error estimating temporal model: {e$message}")
          }
        )
        
        if (exists("slc_df") && exists("modelStats_df")) {
          log_info("Estimating spatial models")
          tryCatch(
            {
              spatialModels_df <- estimateSpatialModels(modelStats_df, slc_df)
              log_info("Spatial models estimated")
            },
            error = function(e) {
              log_info("Error estimating spatial models: {e$message}")
            }
          )
        }
        
        if (exists("modelStats_df")) {
          log_info("Deriving estimated quantities")
          beta_df <- modelStats_df$modStats[[name.endogenous]]
          df.results.estimate <- modelStats_df$Residuals[[name.endogenous]]
          
          if (exists("province") && !is.null(province)) {
            indici <- cellFromXY(province, cbind(x = df.results.estimate$Longitude, y = df.results.estimate$Latitude))
            gruppi <- data.frame(COD = values(province)[indici, 1], LABEL = label.province[values(province)[indici, 1]])
          } else {
            gruppi <- data.frame(COD = rep(1, nrow(df.results.estimate)), LABEL = rep("Region1", nrow(df.results.estimate)))
          }
          
          df.results.estimate <- df.results.estimate %>%
            rename(lon = Longitude, lat = Latitude, resid = Residuals) %>%
            mutate(group = gruppi) %>%
            mutate(coeff.hat = data.frame(trend = beta_df$estimate))
          log_info("Derived df.results.estimate")
          
          objects_to_save <- c(objects_to_save, "modelStats_df", "df.results.estimate")
          if (exists("spatialModels_df")) {
            objects_to_save <- c(objects_to_save, "spatialModels_df")
          }
          log_info("Added estimation results to objects_to_save")
        }
      }
    }
    
    # C) H-SDPD Models (Model4_UHU, Model5_RAB, Model6_HSDPD_user)
    if (user_model_choice %in% c("Model4_UHU", "Model5_RAB", "Model6_HSDPD_user") |
        (bool_update & user_model_choice %in% c("Model4_UHU", "Model5_RAB"))) {
      log_info("Estimating H-SDPD model for {user_model_choice}")
      
      if (exists("df.data") && exists("sdpd.model")) {
        tryCatch(
          {
            df.stime <- df.data %>% map(fun.estimate.parameters,
                                        model = sdpd.model,
                                        vec.options = vec.options
            )
            log_info("H-SDPD model parameters estimated")
          },
          error = function(e) {
            log_info("Error estimating H-SDPD model parameters: {e$message}")
          }
        )
        
        if (exists("df.stime")) {
          tryCatch(
            {
              df.results.estimate <- df.stime %>%
                map(fun.assemble.estimate.results) %>%
                bind_rows()
              log_info("H-SDPD estimation results assembled")
            },
            error = function(e) {
              log_info("Error assembling H-SDPD estimation results: {e$message}")
            }
          )
          
          if (exists("df.results.estimate")) {
            objects_to_save <- c(objects_to_save, "df.results.estimate", "df.stime")
            log_info("Added df.results.estimate to objects_to_save")
          }
        }
      }
    }
    
    log_info("Model estimation completed for {user_model_choice}")
    
    # ==============================================================================
    # OUTPUT GENERATION
    # ==============================================================================
    
    log_info("Starting output generation for {user_model_choice}")
    
    # Table with estimated parameters (NOT for Model1_Simple)
    if (!(user_model_choice == "Model1_Simple") && exists("df.results.estimate")) {
      log_info("Saving table with the estimated parameters")
      tryCatch(
        {
          dati <- data.frame(
            lon = round(df.results.estimate$lon, 1),
            lat = round(df.results.estimate$lat, 1),
            district = if ("group" %in% names(df.results.estimate)) df.results.estimate$group$LABEL else "Unknown",
            coeff = round(df.results.estimate$coeff.hat, digits = 3),
            row.names = NULL
          )
          
          output_file_html <- file.path(output_dir, "model_fits/plots", paste0("coeff_", name.endogenous, ".html"))
          output_file_csv <- file.path(output_dir, "model_fits/plots", paste0("coeff_", name.endogenous, ".csv"))
          
          if (bool_dynamic) {
            widget <- datatable(dati, filter = "top")
          } else {
            widget <- datatable(dati, filter = "top")
          }
          htmlwidgets::saveWidget(widget, file = output_file_html, selfcontained = TRUE)
          write.csv(dati, file = output_file_csv, row.names = FALSE)
          log_info("Saved coefficient table to {output_file_html} and {output_file_csv}")
        },
        error = function(e) {
          log_info("Error saving coefficient table: {e$message}")
        }
      )
    }
    
    # Plot of estimated coefficients (NOT for Model1_Simple)
    if (!(user_model_choice == "Model1_Simple") && exists("df.results.estimate")) {
      log_info("Plotting the estimated coefficients")
      tryCatch(
        {
          if (exists("fun.plot.coeff.FITs")) {
            plot.coeffs <- fun.plot.coeff.FITs(df.results.estimate, name.endogenous=name.endogenous, type.model=etichetta, time=tt.date, bool_dynamic = bool_dynamic)
            if(user_model_choice == "Model2_Autoregressive" | user_model_choice == "Model3_MB_User")
              etichetta <- "~MB-Trend"
            else
              etichetta <- "~H-SDPD"
            
            save_coeff_plots(
              plot.coeffs = plot.coeffs,
              output_dir = output_dir,
              name.endogenous = name.endogenous,
              name.covariates = name.covariates,
              bool_dynamic = bool_dynamic,
              bool_trend = bool_trend
            )
            log_info("Saved coefficient plots to {file.path(output_dir, 'estimate/plots')}")
          } else {
            log_info("Function fun.plot.coeff.FITs not available")
          }
        },
        error = function(e) {
          log_info("Error generating coefficient plots: {e$message}")
        }
      )
    }
    
    # Time series plots (NOT for Model1_Simple)
    if (!(user_model_choice == "Model1_Simple") && exists("df.results.estimate")) {
      log_info("Plotting the fitted and residual time-series for a given location")
      tryCatch(
        {
          if (user_model_choice %in% c("Model2_Autoregressive", "Model3_MB_User")) {
            if (exists("fun.plot.series.FITs2")) {
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
            }
          } else if (user_model_choice %in% c("Model4_UHU", "Model5_RAB", "Model6_HSDPD_user")) {
            if (exists("fun.plot.series.FITs")) {
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
          }
        },
        error = function(e) {
          log_info("Error generating time-series plots: {e$message}")
        }
      )
    } else if (user_model_choice == "Model1_Simple") {
      log_info("Time-series plots not available for {user_model_choice}")
    }
    
    # Save estimated results as CSV (NOT for Model1_Simple)
    if (!(user_model_choice == "Model1_Simple") && exists("df.results.estimate")) {
      log_info("Saving estimated results as CSV")
      tryCatch(
        {
          if (exists("fun.prepare.df.results")) {
            df.results <- fun.prepare.df.results(df.results = df.results.estimate, model = user_model_choice)
          } else {
            df.results <- df.results.estimate
          }
          csv_path <- file.path(output_dir, "estimate/stats", "df_results_estimate.csv")
          write.csv(df.results, file = csv_path, row.names = FALSE)
          log_info("Saved CSV to {csv_path}")
        },
        error = function(e) {
          log_info("Error generating CSV download: {e$message}")
        }
      )
    } else if (user_model_choice == "Model1_Simple") {
      log_info("CSV download not available for {user_model_choice}")
    }
    
    # ==============================================================================
    # SAVE WORKSPACE
    # ==============================================================================
    
    # Save estimate module workspace
    if(bool_update){
      save(
        list = objects_to_save,
        file = estimate_workspace_path
      )
    }
    
    log_info("ESTIMATE MODULE Completed")
    log_info("Estimate module workspace saved to: {estimate_workspace_path}")
    
    # Summary report
    log_info("=== ESTIMATE MODULE SUMMARY ===")
    log_info("Model type: {user_model_choice}")
    log_info("Endogenous variable: {name.endogenous}")
    log_info("Covariates: {paste(name.covariates, collapse = ', ')}")
    if (user_model_choice == "Model1_Simple") {
      log_info("Trend statistics computed successfully")
      if (exists("TrendSens_df")) {
        log_info("Available trend statistics: TrendSens_df, TrendCS_df, TrendMK_df, etc.")
      }
    } else if (exists("df.results.estimate")) {
      log_info("Estimation completed successfully")
      log_info("Number of spatial units: {nrow(df.results.estimate)}")
    } else {
      log_info("Estimation may not have completed successfully")
    }
    log_info("Output directory: {output_dir}/estimate/")
    log_info("===============================")
  },
  error = function(e) {
    log_error("Error in ESTIMATE MODULE: {e}")
    stop(e)
  }
)


