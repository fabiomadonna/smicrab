# ==============================================================================
# SMICRAB Model Analysis - Validate Module
# This module handles model validation, residual analysis, and bootstrap validation
# ==============================================================================

tryCatch(
  {
    # Load common setup
    source("r_scripts/r_models/00_common_setup.R")

    # Load estimate module workspace
    estimate_workspace_path <- file.path(output_dir, "Rdata", "estimate_module_workspace.RData")
    if (file.exists(estimate_workspace_path)) {
      load(estimate_workspace_path)
      log_info("Loaded estimate module workspace from: {estimate_workspace_path}")
    } else {
      log_info("Estimate module workspace not found. Running estimate module first...")
      source("r_scripts/r_models/03_estimate_module.R")
    }

    # ==============================================================================
    # ADDITIONAL HELPER FUNCTIONS FOR VALIDATION
    # ==============================================================================

    fun.plot.stat.RESIDs <- function(df.results, statistic, title, pars = NULL, bool_dynamic = FALSE, output_path, ...) {
      # Check if residuals are in data.frame or list format
      if (is.data.frame(df.results$resid)) {
        dati <- data.frame(lon = df.results$lon, lat = df.results$lat, newvar = apply(df.results$resid, 1, FUN = statistic, ...))
      } else if (is.list(df.results$resid)) {
        dati <- data.frame(lon = df.results$lon, lat = df.results$lat, newvar = unlist(lapply(df.results$resid, FUN = statistic, ...)))
      } else {
        # Handle simple vector case
        dati <- data.frame(lon = df.results$lon, lat = df.results$lat, newvar = statistic(df.results$resid, ...))
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
        ...) {
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
      } else {
        # Handle simple vector case
        dati <- data.frame(
          lon = df.results$lon,
          lat = df.results$lat,
          newvar = statistic(df.results$resid, ...)
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

    # Test functions (if not already defined)
    fun.LBtest <- function(x, ...) {
      tryCatch(
        {
          if (length(x) > 10 && !all(is.na(x))) {
            test_result <- Box.test(x, lag = min(10, length(x) / 4), type = "Ljung-Box")
            return(test_result$p.value)
          } else {
            return(NA)
          }
        },
        error = function(e) {
          return(NA)
        }
      )
    }

    fun.JBtest <- function(x, ...) {
      tryCatch(
        {
          if (length(x) > 7 && !all(is.na(x))) {
            # Simple Jarque-Bera test implementation
            n <- length(x)
            x_centered <- x - mean(x, na.rm = TRUE)
            s <- sqrt(sum(x_centered^2, na.rm = TRUE) / n)
            skewness_val <- sum(x_centered^3, na.rm = TRUE) / (n * s^3)
            kurtosis_val <- sum(x_centered^4, na.rm = TRUE) / (n * s^4)
            jb_stat <- n * (skewness_val^2 / 6 + (kurtosis_val - 3)^2 / 24)
            p_value <- 1 - pchisq(jb_stat, df = 2)
            return(p_value)
          } else {
            return(NA)
          }
        },
        error = function(e) {
          return(NA)
        }
      )
    }

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
          for (stat_name in names(validation_stats)) {
            log_info("Plotting residual {stat_name}")
            output_filename <- paste0("residual_", stat_name, if (bool_dynamic) ".html" else ".png")
            output_path <- file.path(output_dir, "validate/plots", output_filename)
            stat_fun <- validation_stats[[stat_name]]

            fun.plot.stat.RESIDs(
              df.results = df.results.estimate,
              statistic = stat_fun,
              title = stat_name,
              pars = NULL,
              bool_dynamic = bool_dynamic,
              output_path = output_path,
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
              pars = NULL,
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
              title = "Jarque-Bera\nnormality test",
              statistic = fun.JBtest,
              alpha = pars_alpha,
              significant.test = TRUE,
              BYadjusted = BYadjust,
              pars = NULL,
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

    if (user_model_choice %in% c("Model6_HSDPD_user", "Model4_UHI", "Model5_RAB") &&
      (user_model_choice == "Model6_HSDPD_user" || bool_update)) {
      log_info("Starting bootstrap validation")

      # Check if we have the necessary objects for bootstrap
      if (exists("df.stime") && exists("label.province")) {
        tryCatch(
          {
            # Set bootstrap parameters
            if (!exists("CORREZIONE")) CORREZIONE <- "none"
            if (!exists("NBOOT")) NBOOT <- 999

            plan(multisession, workers = 2)
            df.test <- df.stime %>% future_map(
              fun.testing.parameters,
              correzione = CORREZIONE,
              n.boot = NBOOT,
              label.group = label.province,
              plot = FALSE,
              .options = furrr_options(seed = TRUE)
            )
            log_info("Bootstrap testing completed")

            log_info("Assembling the bootstrap results")
            df.results.test <- df.test %>%
              map(fun.assemble.test.results) %>%
              bind_rows()
            log_info("Bootstrap resampling completed")

            log_info("Saving the bootstrap results")
            objects_to_save <- c(objects_to_save, "df.results.test")

            # Bootstrap plots
            if (exists("fun.plot.coeffboot.TEST")) {
              log_info("Comparing the bootstrap and observed time series")
              plot.devs <- fun.plot.coeffboot.TEST(df.results.test, alpha = pars_alpha, matrix1 = "sdevs.tsboot", pars = pars_list)
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
                  matrix2 = params$matrix2,
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
    validate_workspace_path <- file.path(output_dir, "Rdata", "validate_module_workspace.RData")
    save(
      list = c(objects_to_save, "validation_summary"),
      file = validate_workspace_path
    )

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
      log_info("Bootstrap validation: {if (user_model_choice %in% c('Model6_HSDPD_user', 'Model4_UHI', 'Model5_RAB')) 'Yes' else 'No'}")
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
