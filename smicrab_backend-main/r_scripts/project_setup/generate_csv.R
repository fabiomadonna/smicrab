# Required packages
required_packages <- c("terra", "logger")

# Install and load
missing_pkgs <- setdiff(required_packages, rownames(installed.packages()))
if (length(missing_pkgs) > 0) {
    install.packages(missing_pkgs, repos = "https://cran.rstudio.com")
}

lapply(required_packages, library, character.only = TRUE)

# Export function
fun.download.csv <- function(raster_obj, name_file = varnames(raster_obj)[1], output_dir) {
    tempo <- as.character(time(raster_obj))
    valori <- values(raster_obj)
    dimnames(valori)[[2]] <- tempo
    px <- seq(1, dim(valori)[1])
    coordinate <- xyFromCell(raster_obj, px)
    dataframe <- data.frame(longitude = coordinate[, 1], latitude = coordinate[, 2], valori)
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
    write.csv(dataframe, file = file.path(output_dir, paste0(name_file, ".csv")), row.names = FALSE)
}

# Get variable name from NetCDF file
get_variable_name <- function(raster_obj) {
    return(varnames(raster_obj)[1])
}

# Try block
tryCatch(
    {
        log_info("Loading raster datasets...")
        
        # Dynamically find all NetCDF files in the datasets directory
        datasets_dir <- "../../datasets"
        nc_pattern <- "\\.(nc|NC)$"
        netcdf_files <- list.files(datasets_dir, pattern = nc_pattern, full.names = TRUE)
        
        if (length(netcdf_files) == 0) {
            stop("No NetCDF files found in datasets directory")
        }
        
        log_info(paste("Found", length(netcdf_files), "NetCDF files"))

        output_dir <- "../../datasets_csv"
        log_info("Checking and generating CSV files...")

        # Track files that need generation
        files_to_generate <- c()
        processed_files <- c()

        # Process each NetCDF file dynamically
        for (nc_file in netcdf_files) {
            if (file.exists(nc_file)) {
                log_info(paste("Processing:", basename(nc_file)))
                
                tryCatch({
                    # Load raster
                    raster_obj <- rast(nc_file)
                    
                    # Get the actual variable name from the NetCDF file
                    var_name <- get_variable_name(raster_obj)
                    csv_filename <- paste0(var_name, ".csv")
                    csv_path <- file.path(output_dir, csv_filename)

                    if (!file.exists(csv_path)) {
                        log_info(paste("CSV file missing:", csv_filename, "- will generate"))
                        files_to_generate <- c(files_to_generate, csv_filename)
                        fun.download.csv(raster_obj, name_file = var_name, output_dir = output_dir)
                        processed_files <- c(processed_files, paste(basename(nc_file), "->", csv_filename))
                    } else {
                        log_info(paste("CSV file exists:", csv_filename))
                        processed_files <- c(processed_files, paste(basename(nc_file), "->", csv_filename, "(exists)"))
                    }
                }, error = function(e) {
                    log_error(paste("Failed to process", basename(nc_file), ":", e$message))
                })
            } else {
                log_warn(paste("NetCDF file not found:", nc_file))
            }
        }

        if (length(files_to_generate) > 0) {
            log_info(paste("Generated", length(files_to_generate), "CSV files:", paste(files_to_generate, collapse = ", ")))
        } else {
            log_info("All CSV files already exist. No generation needed.")
        }

        # Log all processed files for reference
        log_info("File mapping summary:")
        for (mapping in processed_files) {
            log_info(paste("  ", mapping))
        }
    },
    error = function(e) {
        log_error("Error in Project Setup: {e}")
        stop(e)
    }
)
