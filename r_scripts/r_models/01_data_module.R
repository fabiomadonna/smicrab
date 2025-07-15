# ==============================================================================
# SMICRAB Model Analysis - Data Loading Module
# This module handles data loading, variable preparation, and initial processing
# ==============================================================================

# Load common setup
source("r_scripts/r_models/00_common_setup.R")


tryCatch(
  {
    # ==============================================================================
    # DATAFRAME CREATION
    # ==============================================================================

    log_info("Load or updating dataframes...")
    if (!bool_update) {
      if (file.exists(rdata_path)) {
        load(rdata_path)
        log_info("Loaded existing dataframes from {rdata_path}")
      } else {
        log_info("RData file not found, creating new dataframes...")
        bool_update <- TRUE
      }
    }

    if (bool_update) {
      log_info("Creating new dataframes...")
      dataframes <- variable
      for (ii in names(variable)) {
        log_info("Processing variable: {ii}")
        px <- seq(1, dim(values(variable[[ii]]))[1])
        coordinate <- xyFromCell(variable[[ii]], px)
        valori <- values(variable[[ii]])
        dimnames(valori)[[2]] <- substr(time(variable[[ii]]), start = 1, stop = 10)
        dataframes[[ii]] <- data.frame(longitude = coordinate[, 1], latitude = coordinate[, 2], valori)
      }
      log_info("Saving dataframes to {rdata_path}")
      save(dataframes, file = rdata_path)
    }



    log_info("Saving the endogenous variable as csv")
    fun.download.csv(rry, name_file = name.endogenous, output_dir = file.path(output_dir, "data"))

    # ==============================================================================
    # EXPORT RESULTS
    # ==============================================================================

    # Save workspace for other modules
    workspace_path <- file.path(output_dir, "Rdata", "data_module_workspace.RData")
    save(
      list = c(
        "dataframes", "name.endogenous", "name.covariates", "n.covs"
      ),
      file = workspace_path
    )

    log_info("Data module completed. Workspace saved to: {workspace_path}")
    log_info("Available variables: {paste(names(variable), collapse = ', ')}")
    log_info("Selected endogenous variable: {name.endogenous}")
    log_info("Selected covariates: {paste(name.covariates, collapse = ', ')}")

    # Optional: Export all variables to CSV if requested
    if (exists("export_all_csv") && export_all_csv) {
      log_info("Exporting all variables to CSV...")
      lapply(names(variable), function(var_name) {
        fun.download.csv(variable[[var_name]], name_file = var_name, output_dir = file.path(output_dir, "data"))
      })
    }

    log_info("DATA MODULE COMPLETED")
  },
  error = function(e) {
    log_error("Error in DATA MODULE: {e}")
    stop(e)
  }
)
