# ==============================================================================
# SMICRAB Model Analysis - Validate Module
# This module handles model validation, residual analysis, and bootstrap validation
# ==============================================================================

tryCatch(
  {
    # Load common setup
    source("r_scripts/r_models/00_common_setup.R")
    
    # Load estimate module workspace
    estimate_workspace_path <- paste(output_dir, "/Rdata/estimate_module_workspace_", user_model_choice, "(", name.endogenous, ").RData", sep = "")
    
    if (file.exists(estimate_workspace_path)) {
      load(estimate_workspace_path)
      log_info("Loaded estimate module workspace from: {estimate_workspace_path}")
    } else {
      log_info("Estimate module workspace not found. Running estimate module first...")
      source("r_scripts/r_models/03_estimate_module.R")
    }
    
    # Objects to save for future use
    objects_to_save <- character(0)
    
    
    # ==============================================================================
    # VALIDATE MODULE
    # ==============================================================================
    
    log_info("Starting VALIDATE MODULE")
    
    # Check if we have estimation results (ONLY for non-Model1_Simple models)
    if (user_model_choice == "Model1_Simple") {
      log_info("Model1_Simple uses trend statistics instead of estimation results - validation will be limited")
    } else if (!exists("df.results.estimate")) {
      log_info("No estimation results found. Validation module requires estimation results.")
      log_info("Please run estimate module first.")
      stop("Estimation results not available for validation")
    }
    
    # Set alpha for significance tests
    if (!exists("pars_alpha")) {
      pars_alpha <- 0.05
    }
    
    # ==============================================================================
    # RESIDUAL SUMMARY STATISTICS (NOT for Model1_Simple)
    # ==============================================================================
    
    if (!(user_model_choice == "Model1_Simple")) {
      log_info("Plotting residual summary statistics")
      
      tryCatch(
        {
          if(user_model_choice == "Model2_Autoregressive" | user_model_choice == "Model3_MB_User")
            etichetta <- "~MB-Trend"
          else
            etichetta <- "~H-SDPD"
          for (stat_name in names(validation_stats)) {
            log_info("Plotting residual {stat_name}")
            output_filename <- paste0("residual_", stat_name, if (bool_dynamic) ".html" else ".png")
            output_path <- file.path(output_dir, "validate/plots", output_filename)
            stat_fun <- validation_stats[[stat_name]]
            
            fun.plot.stat.RESIDs(
              df.results = df.results.estimate,
              statistic = stat_fun,
              title = stat_name,
              model = model_type,
              bool_dynamic = bool_dynamic,
              output_path = output_path,
              endogenous = endogenous_variable, type.model=etichetta, time=tt.date,
              na.rm = TRUE
            )
            
            log_info("Saved residual {stat_name} plot to {output_path}")
          }
        },
        error = function(e) {
          log_info("Error plotting residual summary statistics: {e$message}")
        }
      )
    } else {
      log_info("Residual summary statistics not available for {user_model_choice}")
    }
    
    # ==============================================================================
    # AUTOCORRELATION TESTS (NOT for Model1_Simple)
    # ==============================================================================
    
    if (!(user_model_choice == "Model1_Simple")) {
      log_info("Plotting Ljung-Box autocorrelation test")
      
      tryCatch(
        {
          if(user_model_choice == "Model2_Autoregressive" | user_model_choice == "Model3_MB_User")
            etichetta <- "~MB-Trend"
          else
            etichetta <- "~H-SDPD"
          LBtest_variants <- list(no_Benjamini_Yekutieli = FALSE, with_Benjamini_Yekutieli = TRUE)
          for (variant in names(LBtest_variants)) {
            BYadjust <- LBtest_variants[[variant]]
            suffix <- ifelse(BYadjust, "BYadjusted", "not_adjusted")
            output_filename <- paste0("residual_LBtest_", suffix, if (bool_dynamic) ".html" else ".png")
            output_path <- file.path(output_dir, "validate/plots", output_filename)

            fun.plot.stat.discrete.RESIDs(
              df.results = df.results.estimate,
              title = paste("Ljung-Box\nautocorrelation\ntest (size 5%)", sep=""),
              model = model_type,
              statistic = fun.LBtest,
              alpha = pars_alpha,
              significant.test = TRUE,
              BYadjusted = BYadjust,
              endogenous = endogenous_variable, type.model=etichetta, time=tt.date,
              bool_dynamic = bool_dynamic,
              output_path = output_path
            )
            log_info("Saved Ljung-Box test ({suffix}) plot to {output_path}")
          }
        },
        error = function(e) {
          log_info("Error plotting Ljung-Box test: {e$message}")
        }
      )
      
      log_info("Plotting Jarque-Bera normality test")
      tryCatch(
        {
          JBtest_variants <- list(no_Benjamini_Yekutieli = FALSE, with_Benjamini_Yekutieli = TRUE)
          for (variant in names(JBtest_variants)) {
            BYadjust <- JBtest_variants[[variant]]
            suffix <- ifelse(BYadjust, "BYadjusted", "not_adjusted")
            output_filename <- paste0("residual_JBtest_", suffix, if (bool_dynamic) ".html" else ".png")
            output_path <- file.path(output_dir, "validate/plots", output_filename)


            fun.plot.stat.discrete.RESIDs(
              df.results = df.results.estimate,
              title = paste("Jarque-Bera\nnormality\ntest (size 5%)", sep=""),
              statistic = fun.JBtest,
              model = model_type,
              alpha = pars_alpha,
              significant.test = TRUE,
              BYadjusted = BYadjust,
              endogenous = endogenous_variable, type.model=etichetta, time=tt.date,
              bool_dynamic = bool_dynamic,
              output_path = output_path
            )
            
            log_info("Saved Jarque-Bera test ({suffix}) plot to {output_path}")
          }
        },
        error = function(e) {
          log_info("Error plotting Jarque-Bera test: {e$message}")
        }
      )
    } else {
      log_info("Autocorrelation and normality tests not available for {user_model_choice}")
    }
    
    # ==============================================================================
    # BOOTSTRAP VALIDATION (for H-SDPD models ONLY)
    # ==============================================================================
    
    # Load estimate module workspace
    if (!exists("df.results.test")) {
      log_info("Testing results not found. Running bootstrap resampling first...")
      bool_update <- TRUE
    }
    
    if (user_model_choice %in% c("Model6_HSDPD_user", "Model4_UHU", "Model5_RAB") &&
        (user_model_choice == "Model6_HSDPD_user" || bool_update)) {
      log_info("Starting bootstrap validation")
      
      # Check if we have the necessary objects for bootstrap
      if (exists("df.stime") && exists("label.province")) {
        tryCatch(
          {
            # Set bootstrap parameters
            if (!exists("CORRECTION")) CORRECTION <- FALSE
            if (!exists("NBOOT")) NBOOT <- 301
            if (!exists("markovian")) markovian <- FALSE
            
            plan(multisession, workers = 12)
            df.test <- df.stime %>% future_map(
              fun.testing.parameters,
              correction = CORRECTION,
              n.boot = NBOOT,
              label.group = label.province,
              markovian=markovian,
              plot = FALSE,
              .options = furrr_options(seed = TRUE)
            )
            log_info("Bootstrap testing completed")
            
            log_info("Assembling the bootstrap results")
            df.results.test <- df.test %>%
              map(fun.assemble.test.results) %>%
              bind_rows()
            
            ## bootstrap diagnostics
            log_info("Assembling the bootstrap diagnostics results")
            df.boot.diagnostics  <- df.test %>%
              map(fun.diagnostic.boot.results) %>%
              bind_rows()
            
            log_info("Bootstrap resampling completed")
            
            log_info("Saving the bootstrap results")
            objects_to_save <- c("df.results.test", "df.boot.diagnostics")
            
            # Bootstrap plots
            if (exists("fun.plot.coeffboot.TEST")) {
              log_info("Comparing the bootstrap and observed time series")
              plot.devs <- fun.plot.coeffboot.TEST(df.results.test, alpha = pars_alpha, name_y=name.endogenous, time=tt.date,
                                matrix1 = "sdevs.tsboot", pars = pars_list)
              boot_plot <- list(mean = 1, sd = 2)
              for (name in names(boot_plot)) {
                index <- boot_plot[[name]]
                if (index <= length(plot.devs)) {
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
                  matrix2 = params$matrix2, name_y=name.endogenous, time=tt.date,
                  pars = pars_list
                )
                
                if (user_coeff_choice <= length(plot.coeff)) {
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
              }
            }
            
            log_info("Bootstrap validation completed")
          },
          error = function(e) {
            log_info("Error in bootstrap validation: {e$message}")
          }
        )
      } else {
        log_info("Required objects for bootstrap validation not found (df.stime, label.province)")
        log_info("Bootstrap validation skipped")
      }
    } else {
      log_info("Bootstrap validation not available for {user_model_choice}")
    }
    
    # ==============================================================================
    # VALIDATION SUMMARY STATISTICS
    # ==============================================================================
    
    log_info("Computing validation summary statistics...")
    
    validation_summary <- list()
    
    if (exists("df.results.estimate")) {
      tryCatch(
        {
          # Basic residual statistics for other models
          if ("resid" %in% names(df.results.estimate)) {
            residuals <- df.results.estimate$resid
            
            if (is.data.frame(residuals)) {
              residual_values <- as.matrix(residuals[, -c(1, 2)]) # Exclude coordinates if present
            } else if (is.list(residuals)) {
              residual_values <- unlist(residuals)
            } else {
              residual_values <- residuals
            }
            
            validation_summary$residual_stats <- list(
              mean_residual = mean(residual_values, na.rm = TRUE),
              sd_residual = sd(residual_values, na.rm = TRUE),
              min_residual = min(residual_values, na.rm = TRUE),
              max_residual = max(residual_values, na.rm = TRUE),
              median_residual = median(residual_values, na.rm = TRUE),
              skewness_residual = if (length(residual_values) > 2) moments::skewness(residual_values, na.rm = TRUE) else NA,
              kurtosis_residual = if (length(residual_values) > 3) moments::kurtosis(residual_values, na.rm = TRUE) else NA
            )
            
            log_info("Residual statistics computed")
          }
          
          # Model fit statistics
          validation_summary$model_info <- list(
            model_type = user_model_choice,
            endogenous_variable = name.endogenous,
            covariates = name.covariates,
            n_spatial_units = nrow(df.results.estimate),
            bool_trend = bool_trend
          )
        },
        error = function(e) {
          log_info("Error computing validation summary statistics: {e$message}")
        }
      )
    }
    
    # Save validation summary
    validation_summary_path <- file.path(output_dir, "validate/stats", "validation_summary.json")
    tryCatch(
      {
        write(toJSON(validation_summary, pretty = TRUE), file = validation_summary_path)
        log_info("Validation summary saved to: {validation_summary_path}")
      },
      error = function(e) {
        log_info("Error saving validation summary: {e$message}")
      }
    )
    
    # ==============================================================================
    # EXPORT RESULTS
    # ==============================================================================
    
    # Update objects to save
    if (exists("df.results.test")) {
      objects_to_save <- c(objects_to_save, "df.results.test")
    }
    
    # Save validate module workspace
    if(bool_update){
      validate_workspace_path <- paste(output_dir, "/Rdata/validate_module_workspace_", user_model_choice, "(", name.endogenous, ").RData", sep = "")
      save(
        list = c(objects_to_save, "validation_summary"),
        file = validate_workspace_path
      )
    }
    
    log_info("VALIDATE MODULE Completed")
    log_info("Validate module workspace saved to: {validate_workspace_path}")
    
    # Summary report
    log_info("=== VALIDATE MODULE SUMMARY ===")
    log_info("Model type: {user_model_choice}")
    if (user_model_choice == "Model1_Simple") {
      log_info("Trend statistics validation: Available")
      log_info("Residual validation: Not applicable for Model1_Simple")
      log_info("Bootstrap validation: Not applicable for Model1_Simple")
    } else {
      log_info("Validation plots created: {if (user_model_choice != 'Model1_Simple') 'Yes' else 'No'}")
      log_info("Autocorrelation tests: {if (user_model_choice != 'Model1_Simple') 'Yes' else 'No'}")
      log_info("Bootstrap validation: {if (user_model_choice %in% c('Model6_HSDPD_user', 'Model4_UHU', 'Model5_RAB')) 'Yes' else 'No'}")
      if (exists("validation_summary") && "residual_stats" %in% names(validation_summary)) {
        log_info("Mean residual: {round(validation_summary$residual_stats$mean_residual, 4)}")
        log_info("SD residual: {round(validation_summary$residual_stats$sd_residual, 4)}")
      }
    }
    log_info("Output directory: {output_dir}/validate/")
    log_info("===============================")
  },
  error = function(e) {
    log_error("Error in VALIDATE MODULE: {e}")
    stop(e)
  }
)
