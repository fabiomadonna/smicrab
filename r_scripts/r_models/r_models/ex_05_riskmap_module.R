# ==============================================================================
# SMICRAB Model Analysis - Risk Map Module
# This module handles trend analysis, spatial regression and risk map generation
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
    }
    
    # Load validate module workspace
    validate_workspace_path <- file.path(output_dir, "Rdata", "validate_module_workspace.RData")
    if (file.exists(validate_workspace_path)) {
      load(validate_workspace_path)
      log_info("Loaded validate module workspace from: {validate_workspace_path}")
    } else {
      log_info("Validate module workspace not found. Running validate module first...")
      source("r_scripts/r_models/04_validate_module.R")
    }
    
    # ==============================================================================
    # ADDITIONAL HELPER FUNCTIONS FOR RISK MAP
    # ==============================================================================
    
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
    
    # Enhanced diagnostic_models function with file output support
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
    
    # Helper function for spatial regression HTML output
    save_spatial_regression <- function(modelli, formule, ii, output_dir, prefix) {
      output_filename <- paste0(prefix, "_", ii, ".html")
      output_path <- file.path(output_dir, "riskmap/plots", output_filename)
      plots_dir <- file.path(output_dir, "riskmap/plots")
      
      tryCatch(
        {
          plot_files <- diagnostic_models(modelli[[ii]], output_dir = plots_dir, filename_prefix = paste0(prefix, "_", ii))
          
          output <- capture.output({
            cat(paste("\n--WARNING--: \n\nThe following linear regression model is made for explorative purposes.",
            "\nAlthough it is based on the results of a previous spatio-temporal model estimation, \nit may suffer due to residual spatial correlation in the data.\n",
            "\n-----------\n\n "))
            cat(paste("\n The linear model is:", formule[[ii]][2], formule[[ii]][1], formule[[ii]][3], "\n"))
            if (exists("Evaluate_global_Test")) {
              cat("\n", Evaluate_global_Test(modelli[[ii]], alpha = pars_alpha), "\n Details are presented below:")
            }
          })
          suffix_output <- capture.output(summary(modelli[[ii]]))
          
          html_content <- paste0(
            "<html><head><title>Spatial Regression Model ", ii, "</title></head><body>",
            "<pre>", paste(output, collapse = "<br>"), "</pre>"
          )
          
          if (!is.null(plot_files)) {
            html_content <- paste0(
              html_content,
              "<div>",
              "<div style='margin: 10px;'>",
              "<img src='", basename(plot_files[1]), "' alt='Residuals vs Fitted' style='max-width: 100%; height: auto;'>",
              "</div>",
              "<div style='margin: 10px;'>",
              "<img src='", basename(plot_files[2]), "' alt='Normal Q-Q Plot' style='max-width: 100%; height: auto;'>",
              "</div>"
            )
          }
          
          html_content <- paste0(
            html_content,
            "<div>",
            "<pre>", paste(suffix_output, collapse = "<br>"), "</pre>",
            "</div>",
            "</body></html>"
          )
          writeLines(html_content, con = output_path)
        },
        error = function(e) {
          log_info("Error saving spatial regression for model {ii}: {e$message}")
        }
      )
    }
    
    # Set default plot parameters if not available
    if (!exists("size.point")) size.point <- 0.8
    if (!exists("pars_alpha")) pars_alpha <- 0.05
    if (!exists("threshold.climate.zones")) threshold.climate.zones <- 0.1
    if (!exists("captions_list")) {
      captions_list <- list(
        plt_beta_sens = "Sen's slope estimates",
        plt_sig_sens = "Significant Sen's slope tests",
        plt_sig_sens_BY = "Sen's slope tests with BY correction",
        plt_beta_cs = "Cox-Snell estimates",
        plt_sig_cs = "Significant Cox-Snell tests",
        plt_sig_cs_BY = "Cox-Snell tests with BY correction",
        plt_beta_mk = "Mann-Kendall estimates",
        plt_sig_mk = "Significant Mann-Kendall tests",
        plt_sig_mk_BY = "Mann-Kendall tests with BY correction",
        plt_beta_smk = "Seasonal Mann-Kendall estimates",
        plt_sig_smk = "Significant Seasonal Mann-Kendall tests",
        plt_sig_smk_BY = "Seasonal Mann-Kendall tests with BY correction",
        plt_beta_pwmk = "Pre-whitened Mann-Kendall estimates",
        plt_sig_pwmk = "Significant Pre-whitened Mann-Kendall tests",
        plt_sig_pwmk_BY = "Pre-whitened Mann-Kendall tests with BY correction",
        plt_beta_bcpw = "Bias-corrected Pre-whitened estimates",
        plt_sig_bcpw = "Significant Bias-corrected Pre-whitened tests",
        plt_sig_bcpw_BY = "Bias-corrected Pre-whitened tests with BY correction",
        plt_beta_robust = "Robust trend estimates",
        plt_beta_robust_sd = "Robust trend estimates (std.error)",
        plt_sig_robust = "Significant Robust trend tests",
        plt_sig_robust_BY = "Robust trend tests with BY correction",
        plt_score = "Score function combination",
        plt_BY = "Score function with BY correction",
        plt_mv = "Majority voting result",
        plt_mv_BY = "Majority voting with BY correction",
        # H-SDPD Model captions (Models 4-6)
        plt_SDPD_estimates = "DIFF estimates from H-SDPD model showing spatial distribution of Heat/Cold pixels",
        plt_SDPD_std = "Standard errors of DIFF estimates from H-SDPD model",
        plt_sdpd = "Pixels with statistically significant DIFF coefficients from H-SDPD model",
        plt_SDPD_sig_BY = "Pixels with statistically significant DIFF coefficients after Benjamini-Yekutieli correction",
        plt_FE_estimates = "Fixed effects estimates from H-SDPD model showing spatial distribution of coefficients",
        plt_FE_std = "Standard errors of fixed effects estimates from H-SDPD model",
        plt_FE_sdpd = "Pixels with statistically significant fixed effects from H-SDPD model",
        plt_FE_sig_BY = "Pixels with statistically significant fixed effects after Benjamini-Yekutieli correction",
        plt_FE_lc = "Land cover classification map showing different land cover classes across the study area"
      )
    }
    
    # ==============================================================================
    # RISK MAP MODULE
    # ==============================================================================
    
    log_info("RISKMAP MODULE Started")
    
    # Check if we have necessary results based on model type
    if (user_model_choice == "Model1_Simple") {
      # Check if at least one trend statistic is available
      trend_stats_available <- exists("TrendSens_df") || exists("TrendCS_df") || exists("TrendMK_df") || 
        exists("TrendSMK_df") || exists("TrendPWMK_df") || exists("TrendBCPW_df") || 
        exists("TrendRobust_df")
      
      if (!trend_stats_available) {
        log_info("No trend results found. Risk map module requires at least one trend statistic for Model1_Simple.")
        log_info("Please run estimate module first.")
        stop("Trend results not available for risk map generation")
      } else {
        available_stats <- c()
        if (exists("TrendSens_df")) available_stats <- c(available_stats, "TrendSens_df")
        if (exists("TrendCS_df")) available_stats <- c(available_stats, "TrendCS_df")
        if (exists("TrendMK_df")) available_stats <- c(available_stats, "TrendMK_df")
        if (exists("TrendSMK_df")) available_stats <- c(available_stats, "TrendSMK_df")
        if (exists("TrendPWMK_df")) available_stats <- c(available_stats, "TrendPWMK_df")
        if (exists("TrendBCPW_df")) available_stats <- c(available_stats, "TrendBCPW_df")
        if (exists("TrendRobust_df")) available_stats <- c(available_stats, "TrendRobust_df")
        log_info("Available trend statistics: {paste(available_stats, collapse = ', ')}")
      }
    } else if (!exists("df.results.test")) {
      log_info("No test results found. Risk map module requires estimation and test results.")
      log_info("Please run estimate and validation modules first.")
      stop("Results not available for risk map generation")
    }
    
    # ==============================================================================
    # MODEL 1: SIMPLE LINEAR TREND ANALYSIS
    # ==============================================================================
    
    if (user_model_choice == "Model1_Simple") {
      log_info("Model 1: Simple Linear Trend Analysis")
      
      # Common summary statistics function
      summary_stats <- function(df, test_col, output_name) {
        tryCatch(
          {
            df_data <- df[[name.endogenous]] %>%
              select(Longitude, Latitude, !!sym(test_col)) %>%
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
          },
          error = function(e) {
            log_info("Error in summary_stats for {output_name}: {e$message}")
          }
        )
      }
      
      # A) Sen's Slope Test
      if (exists("TrendSens_df")) {
        log_info("Sen's Slope Test")
        tryCatch(
          {
            plt_beta_sens <- TrendSens_df[[name.endogenous]] %>%
              select(Longitude, Latitude, Sens_test) %>%
              unnest(cols = c(Sens_test)) %>%
              ggplot(aes(x = Longitude, y = Latitude, col = estimate)) +
              geom_point(size = size.point) +
              scale_color_gradient2(high = "red", low = "blue", mid = "grey90", midpoint = 0) +
              guides(fill = "none") +
              labs(y = "Latitude", x = "Longitude", col = "Trend", caption = captions_list[["plt_beta_sens"]]) +
              ggtitle(name.endogenous) +
              theme_bw()
            save_plot(plt_beta_sens, paste0("sens_estimates", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
            
            plt_sig_sens <- TrendSens_df[[name.endogenous]] %>%
              select(Longitude, Latitude, Sens_test) %>%
              unnest(cols = c(Sens_test)) %>%
              ggplot(aes(x = Longitude, y = Latitude, col = trend_lab)) +
              geom_point(size = size.point) +
              scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
              guides(fill = "none") +
              labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_sig_sens"]]) +
              ggtitle(paste(name.endogenous, "  (Significant tests at level ", pars_alpha * 100, "%)", sep = "")) +
              theme_bw()
            save_plot(plt_sig_sens, paste0("sens_significant_pixels", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
            
            plt_sig_sens_BY <- TrendSens_df[[name.endogenous]] %>%
              select(Longitude, Latitude, Sens_test) %>%
              unnest(cols = c(Sens_test)) %>%
              ggplot(aes(x = Longitude, y = Latitude, col = trend_lab_BY)) +
              geom_point(size = size.point) +
              scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
              guides(fill = "none") +
              labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_sig_sens_BY"]]) +
              ggtitle(paste(name.endogenous, "  (Significant tests with BY correction at level ", pars_alpha * 100, "%)", sep = "")) +
              theme_bw()
            save_plot(plt_sig_sens_BY, paste0("sens_significant_pixels_BY", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
            
            summary_stats(TrendSens_df, "Sens_test", "sens")
          },
          error = function(e) {
            log_info("Error in Sen's Slope Test: {e$message}")
          }
        )
      }
      
      # B) Cox and Snell (CS) Test
      if (exists("TrendCS_df")) {
        log_info("Cox and Snell Test")
        tryCatch(
          {
            plt_beta_cs <- TrendCS_df[[name.endogenous]] %>%
              select(Longitude, Latitude, CS_test) %>%
              unnest(cols = c(CS_test)) %>%
              ggplot(aes(x = Longitude, y = Latitude, col = estimate)) +
              geom_point(size = size.point) +
              scale_color_gradient2(high = "red", low = "blue", mid = "grey90", midpoint = 0) +
              guides(fill = "none") +
              labs(y = "Latitude", x = "Longitude", col = "Trend", caption = captions_list[["plt_beta_cs"]]) +
              ggtitle(name.endogenous) +
              theme_bw()
            save_plot(plt_beta_cs, paste0("cs_estimates", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
            
            plt_sig_cs <- TrendCS_df[[name.endogenous]] %>%
              select(Longitude, Latitude, CS_test) %>%
              unnest(cols = c(CS_test)) %>%
              ggplot(aes(x = Longitude, y = Latitude, col = trend_lab)) +
              geom_point(size = size.point) +
              scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
              guides(fill = "none") +
              labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_sig_cs"]]) +
              ggtitle(paste(name.endogenous, "  (Significant tests at level ", pars_alpha * 100, "%)", sep = "")) +
              theme_bw()
            save_plot(plt_sig_cs, paste0("cs_significant_pixels", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
            
            plt_sig_cs_BY <- TrendCS_df[[name.endogenous]] %>%
              select(Longitude, Latitude, CS_test) %>%
              unnest(cols = c(CS_test)) %>%
              ggplot(aes(x = Longitude, y = Latitude, col = trend_lab_BY)) +
              geom_point(size = size.point) +
              scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
              guides(fill = "none") +
              labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_sig_cs_BY"]]) +
              ggtitle(paste(name.endogenous, "  (Significant tests with BY correction at level ", pars_alpha * 100, "%)", sep = "")) +
              theme_bw()
            save_plot(plt_sig_cs_BY, paste0("cs_significant_pixels_BY", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
            
            summary_stats(TrendCS_df, "CS_test", "cs")
          },
          error = function(e) {
            log_info("Error in Cox and Snell Test: {e$message}")
          }
        )
      }
      
      # C) Mann-Kendall Test
      if (exists("TrendMK_df")) {
        log_info("Mann-Kendall Test")
        tryCatch(
          {
            plt_beta_mk <- TrendMK_df[[name.endogenous]] %>%
              select(Longitude, Latitude, MK_test) %>%
              unnest(cols = c(MK_test)) %>%
              ggplot(aes(x = Longitude, y = Latitude, col = estimate)) +
              geom_point(size = size.point) +
              scale_color_gradient2(high = "red", low = "blue", mid = "grey90", midpoint = 0) +
              guides(fill = "none") +
              labs(y = "Latitude", x = "Longitude", col = "Trend", caption = captions_list[["plt_beta_mk"]]) +
              ggtitle(name.endogenous) +
              theme_bw()
            save_plot(plt_beta_mk, paste0("mk_estimates", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
            
            plt_sig_mk <- TrendMK_df[[name.endogenous]] %>%
              select(Longitude, Latitude, MK_test) %>%
              unnest(cols = c(MK_test)) %>%
              ggplot(aes(x = Longitude, y = Latitude, col = trend_lab)) +
              geom_point(size = size.point) +
              scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
              guides(fill = "none") +
              labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_sig_mk"]]) +
              ggtitle(paste(name.endogenous, "  (Significant tests at level ", pars_alpha * 100, "%)", sep = "")) +
              theme_bw()
            save_plot(plt_sig_mk, paste0("mk_significant_pixels", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
            
            plt_sig_mk_BY <- TrendMK_df[[name.endogenous]] %>%
              select(Longitude, Latitude, MK_test) %>%
              unnest(cols = c(MK_test)) %>%
              ggplot(aes(x = Longitude, y = Latitude, col = trend_lab_BY)) +
              geom_point(size = size.point) +
              scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
              guides(fill = "none") +
              labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_sig_mk_BY"]]) +
              ggtitle(paste(name.endogenous, "  (Significant tests with BY correction at level ", pars_alpha * 100, "%)", sep = "")) +
              theme_bw()
            save_plot(plt_sig_mk_BY, paste0("mk_significant_pixels_BY", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
            
            summary_stats(TrendMK_df, "MK_test", "mk")
          },
          error = function(e) {
            log_info("Error in Mann-Kendall Test: {e$message}")
          }
        )
      }
      
      # D) Seasonal Mann-Kendall Test
      if (exists("TrendSMK_df")) {
        log_info("Seasonal Mann-Kendall Test")
        tryCatch(
          {
            plt_beta_smk <- TrendSMK_df[[name.endogenous]] %>%
              select(Longitude, Latitude, SMK_test) %>%
              unnest(cols = c(SMK_test)) %>%
              ggplot(aes(x = Longitude, y = Latitude, col = estimate)) +
              geom_point(size = size.point) +
              scale_color_gradient2(high = "red", low = "blue", mid = "grey90", midpoint = 0) +
              guides(fill = "none") +
              labs(y = "Latitude", x = "Longitude", col = "Trend-statistic", caption = captions_list[["plt_beta_smk"]]) +
              ggtitle(name.endogenous) +
              theme_bw()
            save_plot(plt_beta_smk, paste0("smk_estimates", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
            
            plt_sig_smk <- TrendSMK_df[[name.endogenous]] %>%
              select(Longitude, Latitude, SMK_test) %>%
              unnest(cols = c(SMK_test)) %>%
              ggplot(aes(x = Longitude, y = Latitude, col = trend_lab)) +
              geom_point(size = size.point) +
              scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
              guides(fill = "none") +
              labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_sig_smk"]]) +
              ggtitle(paste(name.endogenous, "  (Significant tests at level ", pars_alpha * 100, "%)", sep = "")) +
              theme_bw()
            save_plot(plt_sig_smk, paste0("smk_significant_pixels", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
            
            plt_sig_smk_BY <- TrendSMK_df[[name.endogenous]] %>%
              select(Longitude, Latitude, SMK_test) %>%
              unnest(cols = c(SMK_test)) %>%
              ggplot(aes(x = Longitude, y = Latitude, col = trend_lab_BY)) +
              geom_point(size = size.point) +
              scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
              guides(fill = "none") +
              labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_sig_smk_BY"]]) +
              ggtitle(paste(name.endogenous, "  (Significant tests with BY correction at level ", pars_alpha * 100, "%)", sep = "")) +
              theme_bw()
            save_plot(plt_sig_smk_BY, paste0("smk_significant_pixels_BY", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
            
            summary_stats(TrendSMK_df, "SMK_test", "smk")
          },
          error = function(e) {
            log_info("Error in Seasonal Mann-Kendall Test: {e$message}")
          }
        )
      }
      
      # E) Pre-whitened Mann-Kendall Test
      if (exists("TrendPWMK_df")) {
        log_info("Pre-whitened Mann-Kendall Test")
        tryCatch(
          {
            plt_beta_pwmk <- TrendPWMK_df[[name.endogenous]] %>%
              select(Longitude, Latitude, PWMK_test) %>%
              unnest(cols = c(PWMK_test)) %>%
              ggplot(aes(x = Longitude, y = Latitude, col = estimate)) +
              geom_point(size = size.point) +
              scale_color_gradient2(high = "red", low = "blue", mid = "grey90", midpoint = 0) +
              guides(fill = "none") +
              labs(y = "Latitude", x = "Longitude", col = "Trend", caption = captions_list[["plt_beta_pwmk"]]) +
              ggtitle(name.endogenous) +
              theme_bw()
            save_plot(plt_beta_pwmk, paste0("pwmk_estimates", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
            
            plt_sig_pwmk <- TrendPWMK_df[[name.endogenous]] %>%
              select(Longitude, Latitude, PWMK_test) %>%
              unnest(cols = c(PWMK_test)) %>%
              ggplot(aes(x = Longitude, y = Latitude, col = trend_lab)) +
              geom_point(size = size.point) +
              scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
              guides(fill = "none") +
              labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_sig_pwmk"]]) +
              ggtitle(paste(name.endogenous, "  (Significant tests at level ", pars_alpha * 100, "%)", sep = "")) +
              theme_bw()
            save_plot(plt_sig_pwmk, paste0("pwmk_significant_pixels", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
            
            plt_sig_pwmk_BY <- TrendPWMK_df[[name.endogenous]] %>%
              select(Longitude, Latitude, PWMK_test) %>%
              unnest(cols = c(PWMK_test)) %>%
              ggplot(aes(x = Longitude, y = Latitude, col = trend_lab_BY)) +
              geom_point(size = size.point) +
              scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
              guides(fill = "none") +
              labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_sig_pwmk_BY"]]) +
              ggtitle(paste(name.endogenous, "  (Significant tests with BY correction at level ", pars_alpha * 100, "%)", sep = "")) +
              theme_bw()
            save_plot(plt_sig_pwmk_BY, paste0("pwmk_significant_pixels_BY", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
            
            summary_stats(TrendPWMK_df, "PWMK_test", "pwmk")
          },
          error = function(e) {
            log_info("Error in Pre-whitened Mann-Kendall Test: {e$message}")
          }
        )
      }
      
      # F) Bias-corrected Pre-whitened Test
      if (exists("TrendBCPW_df")) {
        log_info("Bias-corrected Pre-whitened Test")
        tryCatch(
          {
            plt_beta_bcpw <- TrendBCPW_df[[name.endogenous]] %>%
              select(Longitude, Latitude, BCPW_test) %>%
              unnest(cols = c(BCPW_test)) %>%
              ggplot(aes(x = Longitude, y = Latitude, col = estimate)) +
              geom_point(size = size.point) +
              scale_color_gradient2(high = "red", low = "blue", mid = "grey90", midpoint = 0) +
              guides(fill = "none") +
              labs(y = "Latitude", x = "Longitude", col = "Trend", caption = captions_list[["plt_beta_bcpw"]]) +
              ggtitle(name.endogenous) +
              theme_bw()
            save_plot(plt_beta_bcpw, paste0("bcpw_estimates", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
            
            plt_sig_bcpw <- TrendBCPW_df[[name.endogenous]] %>%
              select(Longitude, Latitude, BCPW_test) %>%
              unnest(cols = c(BCPW_test)) %>%
              ggplot(aes(x = Longitude, y = Latitude, col = trend_lab)) +
              geom_point(size = size.point) +
              scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
              guides(fill = "none") +
              labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_sig_bcpw"]]) +
              ggtitle(paste(name.endogenous, "  (Significant tests at level ", pars_alpha * 100, "%)", sep = "")) +
              theme_bw()
            save_plot(plt_sig_bcpw, paste0("bcpw_significant_pixels", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
            
            plt_sig_bcpw_BY <- TrendBCPW_df[[name.endogenous]] %>%
              select(Longitude, Latitude, BCPW_test) %>%
              unnest(cols = c(BCPW_test)) %>%
              ggplot(aes(x = Longitude, y = Latitude, col = trend_lab_BY)) +
              geom_point(size = size.point) +
              scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
              guides(fill = "none") +
              labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_sig_bcpw_BY"]]) +
              ggtitle(paste(name.endogenous, "  (Significant tests with BY correction at level ", pars_alpha * 100, "%)", sep = "")) +
              theme_bw()
            save_plot(plt_sig_bcpw_BY, paste0("bcpw_significant_pixels_BY", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
            
            summary_stats(TrendBCPW_df, "BCPW_test", "bcpw")
          },
          error = function(e) {
            log_info("Error in Bias-corrected Pre-whitened Test: {e$message}")
          }
        )
      }
      
      # G) Robust Trend Test
      if (exists("TrendRobust_df")) {
        log_info("Robust Trend Test")
        tryCatch(
          {
            plt_beta_robust <- TrendRobust_df[[name.endogenous]] %>%
              select(Longitude, Latitude, Robust_test) %>%
              unnest(cols = c(Robust_test)) %>%
              ggplot(aes(x = Longitude, y = Latitude, col = estimate)) +
              geom_point(size = size.point) +
              scale_color_gradient2(high = "red", low = "blue", mid = "grey90", midpoint = 0) +
              guides(fill = "none") +
              labs(y = "Latitude", x = "Longitude", col = "Trend", caption = captions_list[["plt_beta_robust"]]) +
              ggtitle(name.endogenous) +
              theme_bw()
            save_plot(plt_beta_robust, paste0("robust_estimates", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
            
            plt_beta_robust_sd <- TrendRobust_df[[name.endogenous]] %>%
              select(Longitude, Latitude, Robust_test) %>%
              unnest(cols = c(Robust_test)) %>%
              ggplot(aes(x = Longitude, y = Latitude, col = std.error)) +
              geom_point(size = size.point) +
              scale_color_gradient2(high = "red", low = "blue", mid = "grey90", midpoint = 0) +
              guides(fill = "none") +
              labs(y = "Latitude", x = "Longitude", col = "std.error", caption = captions_list[["plt_beta_robust_sd"]]) +
              ggtitle(name.endogenous) +
              theme_bw()
            save_plot(plt_beta_robust_sd, paste0("robust_estimates_error", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
            
            
            plt_sig_robust <- TrendRobust_df[[name.endogenous]] %>%
              select(Longitude, Latitude, Robust_test) %>%
              unnest(cols = c(Robust_test)) %>%
              ggplot(aes(x = Longitude, y = Latitude, col = trend_lab)) +
              geom_point(size = size.point) +
              scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
              guides(fill = "none") +
              labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_sig_robust"]]) +
              ggtitle(paste(name.endogenous, "  (Significant tests at level ", pars_alpha * 100, "%)", sep = "")) +
              theme_bw()
            save_plot(plt_sig_robust, paste0("robust_significant_pixels", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
            
            plt_sig_robust_BY <- TrendRobust_df[[name.endogenous]] %>%
              select(Longitude, Latitude, Robust_test) %>%
              unnest(cols = c(Robust_test)) %>%
              ggplot(aes(x = Longitude, y = Latitude, col = trend_lab_BY)) +
              geom_point(size = size.point) +
              scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
              guides(fill = "none") +
              labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_sig_robust_BY"]]) +
              ggtitle(paste(name.endogenous, "  (Significant tests with BY correction at level ", pars_alpha * 100, "%)", sep = "")) +
              theme_bw()
            save_plot(plt_sig_robust_BY, paste0("robust_significant_pixels_BY", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
            
            summary_stats(TrendRobust_df, "Robust_test", "robust")
          },
          error = function(e) {
            log_info("Error in Robust Trend Test: {e$message}")
          }
        )
      }
      
      # H) Score Function Combination
      if (exists("ComputeScoreValue") && exists("TrendSens_df")) {
        log_info("Score Function Combination")
        tryCatch(
          {
            score_values <- ComputeScoreValue(
              TrendSens_df[[name.endogenous]],
              TrendCS_df[[name.endogenous]],
              TrendMK_df[[name.endogenous]],
              TrendSMK_df[[name.endogenous]],
              TrendPWMK_df[[name.endogenous]],
              TrendBCPW_df[[name.endogenous]],
              TrendRobust_df[[name.endogenous]]
            )
            
            plt_score <- score_values %>%
              ggplot(aes(y = Latitude, x = Longitude, col = score)) +
              geom_point(size = size.point) +
              scale_color_gradient2(high = "red", low = "blue", mid = "green", midpoint = 0) +
              guides(fill = "none") +
              labs(x = "Longitude", y = "Latitude", col = "Score", caption = captions_list[["plt_score"]]) +
              ggtitle(name.endogenous) +
              theme_bw()
            save_plot(plt_score, paste0("score_estimates", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
            
            plt_BY <- score_values %>%
              ggplot(aes(y = Latitude, x = Longitude, col = score_BY)) +
              geom_point(size = size.point) +
              scale_color_gradient2(high = "red", low = "blue", mid = "green", midpoint = 0) +
              guides(fill = "none") +
              labs(x = "Longitude", y = "Latitude", col = "Score", caption = captions_list[["plt_BY"]]) +
              ggtitle(paste(name.endogenous, " (Score value with BY correction)")) +
              theme_bw()
            save_plot(plt_BY, paste0("score_BY_estimates", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
          },
          error = function(e) {
            log_info("Error in Score Function Combination: {e$message}")
          }
        )
      } else if (!exists("TrendSens_df")) {
        log_info("Score Function Combination skipped - TrendSens_df not available")
      }
      
      # I) Majority Voting
      if (exists("ComputeMajorityVoteDataFrame") && exists("TrendSens_df")) {
        log_info("Majority Voting Combination")
        tryCatch(
          {
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
              select(Longitude, Latitude, Vote) %>%
              unnest(cols = c(Vote)) %>%
              ggplot(aes(x = Longitude, y = Latitude, col = Vote)) +
              geom_point(size = size.point) +
              scale_color_manual(
                labels = c("Neg", "Null", "Pos"),
                values = c("-1" = "blue", "0" = "green", "1" = "red")
              ) +
              guides(fill = "none") +
              labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_mv"]]) +
              ggtitle(paste(name.endogenous, " (majority vote)")) +
              theme_bw()
            save_plot(plt_mv, paste0("majority_vote", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
            
            plt_mv_BY <- mv$Vote_BY %>%
              select(Longitude, Latitude, Vote) %>%
              unnest(cols = c(Vote)) %>%
              ggplot(aes(x = Longitude, y = Latitude, col = Vote)) +
              geom_point(size = size.point) +
              scale_color_manual(
                labels = c("Neg", "Null", "Pos"),
                values = c("-1" = "blue", "0" = "green", "1" = "red")
              ) +
              guides(fill = "none") +
              labs(x = "Longitude", y = "Latitude", col = "Trend", caption = captions_list[["plt_mv_BY"]]) +
              ggtitle(paste(name.endogenous, " (majority vote with BY correction)")) +
              theme_bw()
            save_plot(plt_mv_BY, paste0("majority_vote_BY", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
            
            # Majority vote summary statistics
            tryCatch(
              {
                row1 <- table(factor(mv$Vote$Vote, levels = c("-1", "0", "1")))
                row2 <- table(factor(mv$Vote_BY$Vote, levels = c("-1", "0", "1")))
                dati <- data.frame(
                  as.vector(row1),
                  paste(round(prop.table(row1) * 100, 1), "%", sep = ""),
                  as.vector(row2),
                  paste(round(prop.table(row2) * 100, 1), "%", sep = "")
                )
                dimnames(dati)[[1]] <- c("Positive trends", "Null trend", "Negative trends")
                dimnames(dati)[[2]] <- c("Significant pixels", "%", "Significant pixels (BY adjusted)", "%")
                save_table(dati, "majority_vote_summary_table.html", output_dir, bool_dynamic)
              },
              error = function(e) {
                log_info("Error in majority vote summary statistics: {e$message}")
              }
            )
          },
          error = function(e) {
            log_info("Error in Majority Voting: {e$message}")
          }
        )
      } else if (!exists("TrendSens_df")) {
        log_info("Majority Voting skipped - TrendSens_df not available")
      }
      
      # If no trend statistics were successfully computed, create a summary message
      if (!exists("TrendSens_df") && !exists("TrendCS_df") && !exists("TrendMK_df") && 
          !exists("TrendSMK_df") && !exists("TrendPWMK_df") && !exists("TrendBCPW_df") && 
          !exists("TrendRobust_df")) {
        log_info("No trend statistics were successfully computed. Risk map generation may be limited.")
        
        # Create a basic summary file
        tryCatch({
          summary_info <- list(
            model_type = user_model_choice,
            endogenous_variable = name.endogenous,
            status = "Trend statistics computation failed",
            message = "Please check the estimate module logs for more details about the computation failure."
          )
          summary_path <- file.path(output_dir, "riskmap/plots", "trend_computation_summary.json")
          write(jsonlite::toJSON(summary_info, pretty = TRUE), file = summary_path)
          log_info("Created trend computation summary at: {summary_path}")
        }, error = function(e) {
          log_info("Error creating trend computation summary: {e$message}")
        })
      }
    }
    
    
    # ==============================================================================
    # MODELS 2 AND 3: MB-TREND ANALYSIS
    # ==============================================================================
    
    if (user_model_choice %in% c("Model2_Autoregressive", "Model3_MB_User")) {
      log_info("Models 2 and 3: MB-Trend Analysis")
      
      if (!exists("modelStats_df")) {
        log_info("ModelStats_df not found for MB-Trend analysis")
      } else {
        # 1° Stage - Temporal Analysis
        log_info("Temporal Analysis")
        tryCatch(
          {
            plt_MB_estimates <- modelStats_df$modStats[[name.endogenous]] %>%
              ggplot(aes(x = Longitude, y = Latitude, col = estimate)) +
              geom_point(size = size.point) +
              scale_color_gradient2(high = "red", low = "blue", mid = "white", midpoint = 0) +
              guides(fill = "none") +
              labs(y = "Latitude", x = "Longitude", col = "Trend") +
              ggtitle(name.endogenous) +
              theme_bw()
            save_plot(plt_MB_estimates, paste0("mb_estimates", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
            
            # Estimate std.errors plot
            plt_MB_std <- modelStats_df$modStats[[name.endogenous]] %>%
              ggplot(aes(x = Longitude, y = Latitude, col = std.error)) +
              geom_point(size = size.point) +
              scale_color_gradient2(high = "red", low = "blue", mid = "white", midpoint = 0) +
              guides(fill = "none") +
              labs(y = "Latitude", x = "Longitude", col = "std.error") +
              ggtitle(name.endogenous) +
              theme_bw()
            save_plot(plt_MB_std, paste0("mb_std_errors", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
            
            plt_MB_sig <- modelStats_df$modStats[[name.endogenous]] %>%
              ggplot(aes(x = Longitude, y = Latitude, col = trend_lab)) +
              geom_point(size = size.point) +
              scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
              guides(fill = "none") +
              labs(x = "Longitude", y = "Latitude", col = "Trend") +
              ggtitle(paste(name.endogenous, "  (Significant tests at level ", pars_alpha * 100, "%)", sep = "")) +
              theme_bw()
            save_plot(plt_MB_sig, paste0("mb_significant_pixels", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
            
            # Adjusted (BY) test plot
            if ("trend_lab_BY" %in% names(modelStats_df$modStats[[name.endogenous]])) {
              plt_MB_sig_BY <- modelStats_df$modStats[[name.endogenous]] %>%
                ggplot(aes(x = Longitude, y = Latitude, col = trend_lab_BY)) +
                geom_point(size = size.point) +
                scale_color_manual(values = c("Neg" = "blue", "Null" = "green", "Pos" = "red")) +
                guides(fill = "none") +
                labs(x = "Longitude", y = "Latitude", col = "Trend") +
                ggtitle(paste(name.endogenous, "  (Significant tests with BY correction at level ", pars_alpha * 100, "%)", sep = "")) +
                theme_bw()
              save_plot(plt_MB_sig_BY, paste0("mb_significant_pixels_BY", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
            }
            
            # Summary table
            row1 <- table(factor(modelStats_df$modStats[[name.endogenous]]$trend_lab, levels = c("Neg", "Null", "Pos")))
            row2 <- if ("trend_lab_BY" %in% names(modelStats_df$modStats[[name.endogenous]])) {
              table(factor(modelStats_df$modStats[[name.endogenous]]$trend_lab_BY, levels = c("Neg", "Null", "Pos")))
            } else {
              row1
            }
            dati <- data.frame(
              as.vector(row1),
              paste(round(prop.table(row1) * 100, 1), "%", sep = ""),
              as.vector(row2),
              paste(round(prop.table(row2) * 100, 1), "%", sep = "")
            )
            dimnames(dati)[[1]] <- c("Positive trends", "Null trend", "Negative trends")
            dimnames(dati)[[2]] <- c("Significant pixels", "%", "Significant pixels (BY adjusted)", "%")
            save_table(dati, "mb_summary_table.html", output_dir, bool_dynamic)
          },
          error = function(e) {
            log_info("Error in MB-Trend temporal analysis: {e$message}")
          }
        )
        
        # 2° Stage - Spatial Analysis
        if (exists("spatialModels_df")) {
          log_info("Spatial Analysis")
          tryCatch(
            {
              # Map effect (GLS.int)
              if ("GLS.int" %in% names(spatialModels_df[[name.endogenous]])) {
                output_path <- file.path(output_dir, "riskmap/plots", "map_effect.html")
                model_output <- capture.output(print(spatialModels_df[[name.endogenous]]$GLS.int))
                eval_output <- if (exists("EvaluateTest_map")) {
                  EvaluateTest_map(spatialModels_df[[name.endogenous]]$GLS.int)
                } else {
                  ""
                }
                html_content <- paste0(
                  "<html><head><title>Map Effect Analysis</title></head><body>",
                  "<pre>", paste(model_output, collapse = "\n"), "</pre>",
                  if (eval_output != "") paste0("<p><strong>", eval_output, "</strong></p>") else "",
                  "</body></html>"
                )
                writeLines(html_content, con = output_path)
              }
              
              # LC effect (GLS.lc)
              if ("GLS.lc" %in% names(spatialModels_df[[name.endogenous]])) {
                output_path <- file.path(output_dir, "riskmap/plots", "lc_effect.html")
                model_output <- capture.output(print(spatialModels_df[[name.endogenous]]$GLS.lc))
                eval_output <- if (exists("EvaluateTest_LC")) {
                  EvaluateTest_LC(spatialModels_df[[name.endogenous]]$GLS.lc)
                } else {
                  ""
                }
                html_content <- paste0(
                  "<html><head><title>Land Cover Effect Analysis</title></head><body>",
                  "<pre>", paste(model_output, collapse = "\n"), "</pre>",
                  if (eval_output != "") paste0("<p>", eval_output, "</p>") else "",
                  "</body></html>"
                )
                writeLines(html_content, con = output_path)
              }
              
              # Latitude effect (GLS.lat)
              if ("GLS.lat" %in% names(spatialModels_df[[name.endogenous]])) {
                output_path <- file.path(output_dir, "riskmap/plots", "latitude_effect.html")
                model_output <- capture.output(print(spatialModels_df[[name.endogenous]]$GLS.lat))
                eval_output <- if (exists("EvaluateTest_latitude")) {
                  EvaluateTest_latitude(spatialModels_df[[name.endogenous]]$GLS.lat)
                } else {
                  ""
                }
                html_content <- paste0(
                  "<html><head><title>Latitude Effect Analysis</title></head><body>",
                  "<pre>", paste(model_output, collapse = "\n"), "</pre>",
                  if (eval_output != "") paste0("<p>", eval_output, "</p>") else "",
                  "</body></html>"
                )
                writeLines(html_content, con = output_path)
              }
              
              # Longitude effect (GLS.lon)
              if ("GLS.lon" %in% names(spatialModels_df[[name.endogenous]])) {
                output_path <- file.path(output_dir, "riskmap/plots", "longitude_effect.html")
                model_output <- capture.output(print(spatialModels_df[[name.endogenous]]$GLS.lon))
                eval_output <- if (exists("EvaluateTest_longitude")) {
                  EvaluateTest_longitude(spatialModels_df[[name.endogenous]]$GLS.lon)
                } else {
                  ""
                }
                html_content <- paste0(
                  "<html><head><title>Longitude Effect Analysis</title></head><body>",
                  "<pre>", paste(model_output, collapse = "\n"), "</pre>",
                  if (eval_output != "") paste0("<p>", eval_output, "</p>") else "",
                  "</body></html>"
                )
                writeLines(html_content, con = output_path)
              }
              
              # Longitude effect x LC (GLS.lonxlc)
              if ("GLS.lonxlc" %in% names(spatialModels_df[[name.endogenous]])) {
                output_path <- file.path(output_dir, "riskmap/plots", "longitude_lc_interaction.html")
                model_output <- capture.output(print(spatialModels_df[[name.endogenous]]$GLS.lonxlc))
                eval_output <- if (exists("EvaluateTest_lonxlc")) {
                  EvaluateTest_lonxlc(spatialModels_df[[name.endogenous]]$GLS.lonxlc)
                } else {
                  ""
                }
                html_content <- paste0(
                  "<html><head><title>Longitude x Land Cover Interaction Analysis</title></head><body>",
                  "<pre>", paste(model_output, collapse = "\n"), "</pre>",
                  if (eval_output != "") paste0("<p>", eval_output, "</p>") else "",
                  "</body></html>"
                )
                writeLines(html_content, con = output_path)
              }
              
              # Latitude effect x LC (GLS.latxlc)
              if ("GLS.latxlc" %in% names(spatialModels_df[[name.endogenous]])) {
                output_path <- file.path(output_dir, "riskmap/plots", "latitude_lc_interaction.html")
                model_output <- capture.output(print(spatialModels_df[[name.endogenous]]$GLS.latxlc))
                eval_output <- if (exists("EvaluateTest_latxlc")) {
                  EvaluateTest_latxlc(spatialModels_df[[name.endogenous]]$GLS.latxlc)
                } else {
                  ""
                }
                html_content <- paste0(
                  "<html><head><title>Latitude x Land Cover Interaction Analysis</title></head><body>",
                  "<pre>", paste(model_output, collapse = "\n"), "</pre>",
                  if (eval_output != "") paste0("<p>", eval_output, "</p>") else "",
                  "</body></html>"
                )
                writeLines(html_content, con = output_path)
              }
            },
            error = function(e) {
              log_info("Error in spatial analysis: {e$message}")
            }
          )
        }
        
        # Land Cover Map
        if (exists("slc_df")) {
          log_info("Creating Land Cover Map")
          tryCatch(
            {
              plt_MB_lc <- slc_df %>%
                ggplot(aes(x = Longitude, y = Latitude, color = LC)) +
                geom_point(size = size.point) +
                guides(fill = "none") +
                labs(x = "Longitude", y = "Latitude", title = "MAP of Land Cover classes", col = "LC") +
                theme_bw()
              save_plot(plt_MB_lc, paste0("land_cover_map", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
            },
            error = function(e) {
              log_info("Error creating land cover map: {e$message}")
            }
          )
        }
      }
    }
    
    # ==============================================================================
    # MODELS 4, 5, AND 6: SPATIO-TEMPORAL H-SDPD ANALYSIS
    # ==============================================================================
    
    if (user_model_choice %in% c("Model4_UHU", "Model5_RAB", "Model6_HSDPD_user", "Model6_UserDefined") && exists("df.results.test")) {
      log_info("Models 4, 5, and 6: Spatio-temporal H-SDPD Analysis")
      
      # Use bootstrap results
      df.results <- df.results.test |>
        left_join(df.boot.diagnostics) |>
        mutate(longitude=lon, latitude=lat) |>
        left_join(slc_df) |>
        select(-c(Longitude, Latitude))
        
      log_info("Created df.results, by joining df.results.test and df.boot.diagnostics")
      
      
      dati.intercept <- data.frame(longitude=df.results$lon, latitude=df.results$lat, district=df.results$district, estimate=df.results$coeff.hat$intercept_norm, stdev=df.results$coeff.sd.boot$intercept_norm, pvalue=df.results$pvalue.test$intercept_norm) |>
        left_join(slc_df) |>
        select(-c(Longitude, Latitude, slc)) |>
        mutate(sig_trend=pvalue < pars_alpha) |>
        mutate(trend1=ifelse(estimate > 0 & sig_trend==TRUE,1,0)) |>
        mutate(trend2=ifelse(estimate < 0 & sig_trend==TRUE,-1,0)) |>
        mutate(trend_sdpd=factor(trend1+trend2)) |>
        mutate(intercept_test = recode(trend_sdpd, "-1" = "Neg", "0" = "Null","1" = "Pos")) |>
        select(-c(trend1,trend2,sig_trend,trend_sdpd)) |>
        mutate(p.value_BY=p.adjust(pvalue,method="BY")) |>
        mutate(sig_trend_BY=p.value_BY < pars_alpha) |>
        mutate(trend1=ifelse(estimate > 0 & sig_trend_BY==TRUE,1,0)) |>
        mutate(trend2=ifelse(estimate < 0 & sig_trend_BY==TRUE,-1,0)) |>
        mutate(trend_sdpd_BY=factor(trend1+trend2)) |>
        mutate(intercept_test_BY = recode(trend_sdpd_BY, "-1" = "Neg", "0" = "Null","1" = "Pos")) |>
        select(-c(trend1,trend2,sig_trend_BY,trend_sdpd_BY,sig_trend_BY))
      
      dati.slopes0 <- data.frame(longitude=df.results$lon, latitude=df.results$lat, district=df.results$district, estimate=df.results$coeff.hat$slope_norm, stdev=df.results$coeff.sd.boot$slope_norm, pvalue=df.results$pvalue.test$slope_norm) |>
        left_join(slc_df) |>
        select(-c(Longitude, Latitude, slc)) |>
        mutate(sig_trend=pvalue < pars_alpha) |>
        mutate(trend1=ifelse(estimate > 0 & sig_trend==TRUE,1,0)) |>
        mutate(trend2=ifelse(estimate < 0 & sig_trend==TRUE,-1,0)) |>
        mutate(trend_sdpd=factor(trend1+trend2)) |>
        mutate(slope_test = recode(trend_sdpd, "-1" = "Neg", "0" = "Null","1" = "Pos")) |>
        select(-c(trend1,trend2,trend_sdpd,sig_trend)) |>
        mutate(p.value_BY=p.adjust(pvalue,method="BY")) |>
        mutate(sig_trend_BY=p.value_BY < pars_alpha) |>
        mutate(trend1=ifelse(estimate > 0 & sig_trend_BY==TRUE,1,0)) |>
        mutate(trend2=ifelse(estimate < 0 & sig_trend_BY==TRUE,-1,0)) |>
        mutate(trend_sdpd_BY=factor(trend1+trend2)) |>
        mutate(slope_test_BY = recode(trend_sdpd_BY, "-1" = "Neg", "0" = "Null","1" = "Pos")) |>
        select(-c(trend1,trend2,trend_sdpd_BY,sig_trend_BY))
      
      limite <- 0.1
      dati.HI <- df.results |>
        select(px, lon, lat, mu.i) |>
        rename(longitude=lon, latitude=lat) |>
        mutate(abs.difference=df.results$coeff.hat[as.character(px), "abs_diff"]) |>
        mutate(pvalue=df.results$pvalue.test[as.character(px), "abs_diff"]) |>
        mutate(sig_trend=pvalue < pars_alpha) |>
        mutate(trend1=ifelse(abs.difference > 0 & sig_trend==TRUE,1,0)) |>
        mutate(trend2=ifelse(abs.difference < 0 & sig_trend==TRUE,-1,0)) |>
        mutate(trend_sdpd=factor(trend1+trend2)) |>
        mutate(condition_test = recode(trend_sdpd, "-1" = "Cold", "0" = "Null","1" = "Heat")) |>
        select(-c(trend1,trend2,sig_trend,trend_sdpd)) |>
        mutate(p.value_BY=p.adjust(pvalue,method="BY")) |>
        mutate(sig_trend_BY=p.value_BY < pars_alpha) |>
        mutate(trend1=ifelse(abs.difference > 0 & sig_trend_BY==TRUE,1,0)) |>
        mutate(trend2=ifelse(abs.difference < 0 & sig_trend_BY==TRUE,-1,0)) |>
        mutate(trend_sdpd_BY=factor(trend1+trend2)) |>
        mutate(condition_test_BY = recode(trend_sdpd_BY, "-1" = "Cold", "0" = "Null","1" = "Heat")) |>
        select(-c(trend1,trend2,trend_sdpd_BY,sig_trend_BY), pvalue, p.value_BY) |>
        mutate(norm.difference=df.results$coeff.hat[as.character(px), "norm_diff"]) |>
        mutate(pvalue=df.results$pvalue.test[as.character(px), "norm_diff"]) |>
        mutate(sig_trend=pvalue < pars_alpha) |>
        mutate(trend1=ifelse(norm.difference > 0 & sig_trend==TRUE,1,0)) |>
        mutate(trend2=ifelse(norm.difference < 0 & sig_trend==TRUE,-1,0)) |>
        mutate(trend_sdpd=factor(trend1+trend2)) |>
        mutate(norm_test = recode(trend_sdpd, "-1" = "Cold", "0" = "Null","1" = "Heat")) |>
        select(-c(trend1,trend2,sig_trend,trend_sdpd)) |>
        mutate(p.value_BY=p.adjust(pvalue,method="BY")) |>
        mutate(sig_trend_BY=p.value_BY < pars_alpha) |>
        mutate(trend1=ifelse(norm.difference > 0 & sig_trend_BY==TRUE,1,0)) |>
        mutate(trend2=ifelse(norm.difference < 0 & sig_trend_BY==TRUE,-1,0)) |>
        mutate(trend_sdpd_BY=factor(trend1+trend2)) |>
        mutate(norm_test_BY = recode(trend_sdpd_BY, "-1" = "Cold", "0" = "Null","1" = "Heat")) |>
        select(-c(trend1,trend2,trend_sdpd_BY,sig_trend_BY, pvalue, p.value_BY)) |>
        left_join(dati.intercept, by=join_by(px, longitude, latitude)) |>
        select(-c(stdev, pvalue, px, intercept_test, p.value_BY)) |>
        rename(intercept_norm=estimate) |>
        left_join(dati.slopes0) |>
        select(-c(stdev, pvalue, px, slope_test, p.value_BY)) |>
        rename(slope_norm=estimate) |>
        mutate(zone = case_when(
          (condition_test_BY=="Heat" & slope_norm< -limite) ~ "Weak spillover & SuHI effects", 
          (condition_test_BY=="Heat" & abs(slope_norm)<=limite) ~ "Uniform spillover & SuHI effects", 
          (condition_test_BY=="Heat" & slope_norm>limite) ~ "Strong spillover & SuHI effects", 
          (condition_test_BY=="Null" & slope_norm< -limite) ~ "NO SuHI/SuCI", 
          (condition_test_BY=="Null" & abs(slope_norm)<=limite) ~ "NO SuHI/SuCI", 
          (condition_test_BY=="Null" & slope_norm>limite) ~ "NO SuHI/SuCI", 
          (condition_test_BY=="Cold" & slope_norm< -limite) ~ "Weak spillover & SuCI effects", 
          (condition_test_BY=="Cold" & abs(slope_norm)<=limite) ~ "Uniform spillover & SuCI effects", 
          (condition_test_BY=="Cold" & slope_norm>limite) ~ "Strong spillover & SuCI effects")) |>
        mutate(Intercept_norm=round(intercept_norm, 3)) |>
        mutate(Slope_norm=round(slope_norm, 3)) |>
        select(-c(intercept_test_BY, slope_test_BY, intercept_norm, slope_norm))
      
      
      # 1. SPATIO-TEMPORAL Absolute DIFF measure ANALYSIS
      log_info("1. Spatio-temporal Absolute DIFF measure Analysis")
      tryCatch(
        {
            limiti <- quantile(dati.intercept$estimate, probs=c(0.01, 0.99))
            plt_SDPD_estimates <- dati.intercept |>
              select(longitude, latitude, district, LC, estimate) |>
              ggplot(aes(x = longitude, y = latitude, district=district, LC=LC, col = estimate)) + 
              geom_point(size = size.point) + 
              scale_color_gradient2(high = "red", low = "blue", mid = "white", midpoint = 0, limits=limiti) + 
              guides(fill = "none") + 
              labs(x="Longitude", y="Latitude", col=paste("Normalized\nintercept:\nestimates", sep=""),  subtitle=paste("(based on data from ",   range(tt.date)[1], " to ", range(tt.date)[2], ")", sep="")) + 
              ggtitle(paste(name.endogenous, "~ H-SDPD"))

            save_plot(plt_SDPD_estimates, paste0("trend_estimates_map", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)

          # DIFF Standard Errors
            limiti <- quantile(dati.intercept$stdev, probs=c(0.005, 0.995))
            plt_SDPD_std <- dati.intercept |>
              select(longitude, latitude, district, LC, stdev) |>
              ggplot(aes(x = longitude, y = latitude, district=district, LC=LC, col = stdev)) + 
              geom_point(size = size.point) + 
              scale_color_gradient2(high = "red", low = "blue", mid = "white", midpoint = 0, limits=limiti) + 
              guides(fill = "none") + 
              labs(x="Longitude", y="Latitude", col=paste("Normalized\nintercept:\nstandard\ndeviations", sep=""),  subtitle=paste("(based on data from ",   range(tt.date)[1], " to ", range(tt.date)[2], ")", sep="")) + 
              ggtitle(paste(name.endogenous, "~ H-SDPD"))
            
            save_plot(plt_SDPD_std, paste0("trend_std_error_map", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)

          # Significant Pixels
            plt_sdpd <- dati.intercept |>
              select(longitude, latitude, district, LC, intercept_test) |>
              ggplot(aes(x = longitude,  y = latitude, district=district, LC=LC, col = intercept_test)) +
              geom_point(size = size.point) +
              scale_color_manual(values = c("Neg" = "blue", "Null"="white", "Pos"="red")) +
              guides(fill = "none") +
              labs(x="Longitude", y="Latitude", col=paste("Normalized\nintercepts:\nunivariate\ntests\n(size ", pars_alpha*100, "%)", sep=""),  subtitle=paste("(based on data from ",   range(tt.date)[1], " to ", range(tt.date)[2], ")", sep="")) + 
              ggtitle(paste(name.endogenous, "~ H-SDPD"))
            
            save_plot(plt_sdpd, paste0("significant_trend_pixels_map", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
            
          # BY-adjusted significant pixels
            plt_SDPD_sig_BY <- dati.intercept |>
              select(longitude, latitude, district, LC, intercept_test_BY) |>
              ggplot(aes(x = longitude, y = latitude, district=district, LC=LC, col = intercept_test_BY)) +
              geom_point(size = size.point) +
              scale_color_manual(values = c("Neg" = "blue", "Null"="white", "Pos"="red")) +
              guides(fill = "none") +
              labs(x="Longitude", y="Latitude", col=paste("Normalized\nintercept:\nglobal\nBY test\n(size ", pars_alpha*100, "%)", sep=""),  subtitle=paste("(based on data from ",   range(tt.date)[1], " to ", range(tt.date)[2], ")", sep="")) + 
              ggtitle(paste(name.endogenous, "~ H-SDPD"))
            
            save_plot(plt_SDPD_sig_BY, paste0("by_adjusted_trend_map", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
            
          # Summary Statistics
            row1 <- table(factor(dati.intercept$intercept_test, levels = c("Neg", "Null", "Pos")))
            row2 <- table(factor(dati.intercept$intercept_test_BY, levels = c("Neg", "Null", "Pos")))
            dati_summary <- data.frame(
              as.vector(row1),
              paste(round(prop.table(row1) * 100, 1), "%", sep = ""),
              as.vector(row2),
              paste(round(prop.table(row2) * 100, 1), "%", sep = "")
            )
            dimnames(dati_summary)[[1]] <- c("Negative normalized intercepts", "Null intercepts", "Positive normalized intercepts")
            dimnames(dati_summary)[[2]] <- c("Significant pixels", "%", "Significant pixels (BY adjusted)", "%")
            save_table(dati_summary, "trend_analysis_summary_table.html", output_dir, bool_dynamic)
        },
        error = function(e) {
          log_info("Error in H-SDPD DIFF analysis: {e$message}")
        }
      )
      
      # 2. SPATIAL REGRESSION OF DIFF PARAMETERS
      if (exists("fun.estimate.global.models") && exists("slc_df")) {
        log_info("2. Spatial Regression of DIFF Parameters")
  
        data_elevation <- read.csv("datasets/elevation_dataset/dati_medie_lst.csv") |>
          select(Longitude, Latitude, LC, elevation, district)
        
        df.results.modelli <- df.results.estimate |>
          mutate(Longitude=round(lon, 1), Latitude=round(lat, 1)) |>
          select(-c(lon, lat)) |>
          left_join(data_elevation)
        
        tryCatch(
          {
            # Land Cover Map for DIFF Regression
            plt_trend_lc <- slc_df %>%
              ggplot(aes(x = Longitude, y = Latitude, color = LC)) +
              geom_point(size = size.point) +
              guides(fill = "none") +
              labs(x = "Longitude", y = "Latitude", title = "Land Cover class map", col = "LC", caption = captions_list[["plt_FE_lc"]])
            save_plot(plt_trend_lc, paste0("land_cover_map_trend_regression", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)

            if(length(name.covariates)==0){
              nomi.variabili <- NULL
            } else{
              nomi.variabili <- name.covariates
            }
                                    
            modelli_globali <- fun.estimate.global.models(
              df.results = df.results.modelli,
              name.covariates = nomi.variabili,
              name.response = "abs_diff"
            )
            formule <- modelli_globali[[7]]
            
            for (ii in 1:min(length(modelli_globali), 6)) {
              save_spatial_regression(modelli_globali, formule, ii, output_dir, "trend_regression_model")
            }
          },
          error = function(e) {
            log_info("Error in spatial regression of DIFF parameters: {e$message}")
          }
        )
      }
      
      # 3. Fixed Effects ANALYSIS
        log_info("3. Fixed Effects Analysis")
        tryCatch(
          {
            limiti <- quantile(df.results$coeff.hat$fixed_effects, probs=c(0.01, 0.99))
            plt_FE_estimates <- df.results %>%
              ggplot(aes(x = lon, y = lat, district=district, LC=LC, col = coeff.hat$fixed_effects)) +
              geom_point(size = size.point) +
              scale_color_gradient2(high = "red", low = "blue", mid = "white", midpoint = 0, limits=limiti) +
              guides(fill = "none") +
              labs(y = "Latitude", x = "Longitude", col = paste("Fixed\neffects:\nestimates", sep=""),  subtitle=paste("(based on data from ",   range(tt.date)[1], " to ", range(tt.date)[2], ")", sep=""),
                   caption = captions_list[["plt_FE_estimates"]]) +
              ggtitle(paste(name.endogenous, "~ H-SDPD"))

            save_plot(plt_FE_estimates, paste0("fixed_effects_estimates_map", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
            
                        
            # Fixed Effects Standard Errors (if bootstrap results available)
            if (exists("df.results.test") && "coeff.sd.boot" %in% names(df.results.test) && "fixed_effects" %in% names(df.results.test$coeff.sd.boot)) {
              limiti <- quantile(df.results$coeff.sd.boot$fixed_effects, probs=c(0.005, 0.995))
              plt_FE_std <- df.results %>%
                ggplot(aes(x = lon, y = lat, district=district, LC=LC, col = coeff.sd.boot$fixed_effects)) +
                geom_point(size = size.point) +
                scale_color_gradient2(high = "red", low = "blue", mid = "white", midpoint = 0, limits=limiti) +
                guides(fill = "none") +
                labs(y = "Latitude", x = "Longitude", col = "Fixed\neffects:\nstandard\ndeviations", caption = captions_list[["plt_FE_std"]],
                     subtitle=paste("(based on data from ",   range(tt.date)[1], " to ", range(tt.date)[2], ")", sep="")) +
                ggtitle(paste(name.endogenous, "~ H-SDPD"))

                save_plot(plt_FE_std, paste0("fixed_effects_std_error_map", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)
            }

            # Fixed Effects Significant Pixels (if bootstrap results available)
            if (exists("df.results.test") && "pvalue.test" %in% names(df.results.test) && "fixed_effects" %in% names(df.results.test$pvalue.test)) {
              dati_fe <- df.results |>
                select(lon, lat, LC, district) |>
                mutate(estimate = df.results$coeff.hat$fixed_effects) |>
                mutate(pvalue.test = df.results$pvalue.test$fixed_effects) |>
                mutate(sig_trend = pvalue.test < pars_alpha) %>%
                mutate(trend1 = ifelse(estimate > 0 & sig_trend == TRUE, 1, 0)) %>%
                mutate(trend2 = ifelse(estimate < 0 & sig_trend == TRUE, -1, 0)) %>%
                mutate(trend_sdpd = factor(trend1 + trend2)) %>%
                mutate(trend_sdpd_lab = recode(trend_sdpd, "-1" = "Neg", "0" = "Null", "1" = "Pos")) %>%
                select(-c(trend1, trend2)) %>%
                mutate(p.value_sdpd_BY = p.adjust(pvalue.test, method = "BY")) %>%
                mutate(sig_trend_BY = p.value_sdpd_BY < pars_alpha) %>%
                mutate(trend1 = ifelse(estimate > 0 & sig_trend_BY == TRUE, 1, 0)) %>%
                mutate(trend2 = ifelse(estimate < 0 & sig_trend_BY == TRUE, -1, 0)) %>%
                mutate(trend_sdpd_BY = factor(trend1 + trend2)) %>%
                mutate(trend_sdpd_lab_BY = recode(trend_sdpd_BY, "-1" = "Neg", "0" = "Null", "1" = "Pos"))
              
              plt_FE_sdpd <- dati_fe %>%
                ggplot(aes(x = lon, y = lat, district=district, LC=LC, col = trend_sdpd_lab)) +
                geom_point(size = size.point) +
                scale_color_manual(values = c("Neg" = "blue", "Null" = "white", "Pos" = "red")) +
                guides(fill = "none") +
                labs(x = "Longitude", y = "Latitude", col = paste("Fixed\neffects:\nunivariate\ntests\n(size ", pars_alpha*100, "%)", sep=""),  subtitle=paste("(based on data from ",   range(tt.date)[1], " to ", range(tt.date)[2], ")", sep=""),
                     caption = captions_list[["plt_FE_sdpd"]]) +
                ggtitle(paste(name.endogenous, "~ H-SDPD"))
              
              save_plot(plt_FE_sdpd, paste0("significant_fixed_effects_map", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)


              # BY-adjusted significant pixels for fixed effects
              plt_FE_sig_BY <- dati_fe %>%
                ggplot(aes(x = lon, y = lat, district=district, LC=LC, col = trend_sdpd_lab_BY)) +
                geom_point(size = size.point) +
                scale_color_manual(values = c("Neg" = "blue", "Null" = "white", "Pos" = "red")) +
                guides(fill = "none") +
                labs(x = "Longitude", y = "Latitude", col = paste("Fixed\neffects:\nglobal\nBY test\n(size ", pars_alpha*100, "%)", sep=""),  subtitle=paste("(based on data from ",   range(tt.date)[1], " to ", range(tt.date)[2], ")", sep="")) +
                ggtitle(paste(name.endogenous, "~ H-SDPD"))

              save_plot(plt_FE_sig_BY, paste0("by_adjusted_fixed_effects_map", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)


              # Fixed Effects Summary Statistics
              row1_fe <- table(factor(dati_fe$trend_sdpd_lab, levels = c("Neg", "Null", "Pos")))
              row2_fe <- table(factor(dati_fe$trend_sdpd_lab_BY, levels = c("Neg", "Null", "Pos")))
              dati_summary_fe <- data.frame(
                as.vector(row1_fe),
                paste0(round(prop.table(row1_fe) * 100, 1), "%"),
                as.vector(row2_fe),
                paste0(round(prop.table(row2_fe) * 100, 1), "%")
              )
              dimnames(dati_summary_fe)[[1]] <- c("Negative fixed effects", "Null fixed effects", "Positive fixed effects")
              dimnames(dati_summary_fe)[[2]] <- c("Significant pixels", "%", "Significant pixels (BY adjusted)", "%")
              save_table(dati_summary_fe, "fixed_effects_summary_table.html", output_dir, bool_dynamic)
            }
          },
          error = function(e) {
            log_info("Error in fixed effects analysis: {e$message}")
          }
        )

      
      # 4. SPATIAL REGRESSION OF FIXED EFFECTS PARAMETERS
      if (exists("fun.estimate.global.models") && exists("slc_df") && "fixed_effects" %in% names(df.results.estimate$coeff.hat)) {
        log_info("4. Spatial Regression of Fixed Effects Parameters")
        tryCatch(
          {
            # Land Cover Map for Fixed Effects Regression
            plt_FE_lc_regression <- slc_df %>%
              ggplot(aes(x = Longitude, y = Latitude, color = LC)) +
              geom_point(size = size.point) +
              guides(fill = "none") +
              labs(x = "Longitude", y = "Latitude", title = "Land Cover class map", col = "LC", caption = captions_list[["plt_FE_lc"]])
            save_plot(plt_FE_lc_regression, paste0("land_cover_map_fixed_effects_regression", if (bool_dynamic) ".html" else ".png"), output_dir, bool_dynamic)

            if(length(name.covariates)==0){
              nomi.variabili <- NULL
            } else{
              nomi.variabili <- name.covariates
            }
            
            modelli_globali_FE <- fun.estimate.global.models(
              df.results = df.results.modelli,
              name.covariates = nomi.variabili,
              name.response = "fixed_effects"
            )
            formule_FE <- modelli_globali_FE[[7]]
            
            for (ii in 1:min(length(modelli_globali_FE), 6)) {
              save_spatial_regression(modelli_globali_FE, formule_FE, ii, output_dir, "fixed_effects_regression_model")
            }
          },
          error = function(e) {
            log_info("Error in spatial regression of fixed effects parameters: {e$message}")
          }
        )
      }
    }
    
    # ==============================================================================
    # SAVE UPDATED RDATA
    # ==============================================================================
    
    log_info("Saving Updated Rdata")
    if (bool_update) {
      load_path <- file.path(output_dir, paste0("Rdata/workfile_model_", name.endogenous, ".RData"))
      save(list = objects_to_save, file = load_path)
      log_info("Saved {load_path}")
    }
    
    # ==============================================================================
    # EXPORT RESULTS
    # ==============================================================================
    
    # Save riskmap module workspace
    riskmap_workspace_path <- file.path(output_dir, "Rdata", "riskmap_module_workspace.RData")
    save(
      list = objects_to_save,
      file = riskmap_workspace_path
    )
    
    # Set analysis status
    analysis_status <- "done"
    
    # Save analysis_status to flag file
    tryCatch(
      {
        writeLines(analysis_status, con = file.path(output_dir, paste0(analysis_id, ".flag")))
        log_info("Analysis status saved to flag file")
      },
      error = function(e) {
        log_info("Error saving analysis status: {e$message}")
      }
    )
    
    log_info("RISKMAP MODULE Completed")
    log_info("Riskmap module workspace saved to: {riskmap_workspace_path}")
    
    # Summary report
    log_info("=== RISKMAP MODULE SUMMARY ===")
    log_info("Model type: {user_model_choice}")
    log_info("Analysis completed successfully")
    log_info("Risk maps generated for: {name.endogenous}")
    if (length(name.covariates) > 0) {
      log_info("Covariates included: {paste(name.covariates, collapse = ', ')}")
    }
    log_info("Output directory: {output_dir}/riskmap/")
    log_info("Analysis status: {analysis_status}")
    log_info("==============================")
    
    log_info("Complete analysis pipeline finished for {user_model_choice} with endogenous variable {name.endogenous}")
    log_info("All modules completed successfully. Outputs saved in: {output_dir}")
  },
  error = function(e) {
    log_error("Error in RISKMAP MODULE: {e}")
    stop(e)
  }
)
