# SMICRAB Backend Startup Guide

This guide explains the new sequential startup process that ensures all dependencies are properly configured before the backend starts.

## Prerequisites

Before starting the SMICRAB backend, ensure you have:

1. **Dataset Files**: Place your NetCDF (`.nc`) files in the `datasets/` directory
2. **Docker and Docker Compose**: Installed and running on your system

## Startup Process

The backend now follows a strict sequential startup process:

### Step 1: Dataset Validation
- ✅ Checks if `datasets/` directory exists
- ✅ Verifies the directory is not empty
- ✅ Confirms NetCDF files (`.nc` or `.NC`) are present
- ❌ **Fails if**: No datasets directory, empty directory, or no NetCDF files

### Step 2: R Setup Script Execution
- ✅ Runs `r_scripts/project_setup/generate_csv.R`
- ✅ Loads required R packages (terra, logger)
- ✅ Processes NetCDF files and exports to CSV format
- ✅ Creates `datasets/csv/` directory with processed data
- ❌ **Fails if**: R script encounters errors, missing dependencies, or file processing issues

### Step 3: Database Migration
- ✅ Waits for PostgreSQL database to be ready (up to 30 attempts)
- ✅ Runs Alembic migrations (`alembic upgrade head`)
- ✅ Creates necessary database tables
- ❌ **Fails if**: Database connection issues or migration errors

### Step 4: Dataset Metadata Loading (Optional)
- ✅ Loads dataset metadata into the database
- ⚠️ **Warning if fails**: Continues startup but logs warning

### Step 5: Backend Server Start
- ✅ Starts FastAPI server on port 8000
- ✅ Server becomes available for requests

## Pre-Startup Validation

Before starting the application, you can run a validation test to ensure all prerequisites are met:

### Linux/Mac:
```bash
./test_startup.sh
```

### Windows:
```cmd
test_startup.bat
```

This will check for:
- Dataset files in the correct location
- Required configuration files
- R scripts and packages
- Database migration files

## Starting the Application

### Using Docker Compose (Recommended)

```bash
# Start all services
docker-compose up --build

# Start in background
docker-compose up -d --build

# View logs
docker-compose logs -f backend
```

### Manual Docker Build

```bash
# Build the image
docker build -t smicrab-backend .

# Run with environment variables
docker run -p 8000:8000 \
  -e POSTGRES_HOST=your_db_host \
  -e POSTGRES_PORT=5432 \
  -e POSTGRES_DB=smicrab \
  -e POSTGRES_USER=smicrab_user \
  -e POSTGRES_PASSWORD=smicrab_password \
  -v ./datasets:/app/datasets \
  smicrab-backend
```

## Error Handling

If the startup fails, you'll see colored error messages indicating which step failed:

### 🔴 Dataset Errors
```
[ERROR] Datasets directory is empty: /app/datasets
[ERROR] No NetCDF (.nc) files found in datasets directory
```
**Solution**: Add your `.nc` files to the `datasets/` directory

### 🔴 R Script Errors
```
[ERROR] R setup script failed. Please check the R script logs above for details.
```
**Solution**: Check R script output for missing packages or file processing errors

### 🔴 Database Errors
```
[ERROR] Failed to connect to database after 30 attempts
[ERROR] Database migrations failed. Please check the migration logs above
```
**Solution**: Ensure PostgreSQL is running and accessible, check connection parameters

## Monitoring Startup

The startup script provides detailed logging with timestamps and colored output:

- 🔵 **Blue**: General information and step progress
- 🟢 **Green**: Success messages
- 🟡 **Yellow**: Warnings (non-fatal)
- 🔴 **Red**: Errors (fatal)

## File Structure

```
smicrab-backend/
├── datasets/           # Place your .nc files here
│   ├── file1.nc
│   ├── file2.nc
│   └── csv/           # Generated CSV files (auto-created)
├── r_scripts/
│   └── project_setup/
│       └── generate_csv.R    # R preprocessing script
├── startup.sh         # Main startup script
├── Dockerfile
└── docker-compose.yml
```

## Environment Variables

The following environment variables are used:

- `POSTGRES_HOST`: Database host
- `POSTGRES_PORT`: Database port
- `POSTGRES_DB`: Database name
- `POSTGRES_USER`: Database user
- `POSTGRES_PASSWORD`: Database password

## Troubleshooting

### Container Keeps Restarting
Check logs: `docker-compose logs backend`

### R Package Installation Issues
The Dockerfile installs R packages from `r_packages.R`. Ensure all required packages are listed.

### Permission Issues
Ensure the startup script is executable:
```bash
chmod +x startup.sh
```

### Database Connection Issues
1. Verify PostgreSQL is running: `docker-compose ps`
2. Check database logs: `docker-compose logs postgres`
3. Verify environment variables in docker-compose.yml

## Manual Recovery

If you need to run individual steps manually:

```bash
# Enter the container
docker-compose exec backend bash

# Run R script manually
cd /app/r_scripts/project_setup && Rscript generate_csv.R

# Run migrations manually
cd /app && alembic upgrade head

# Load dataset metadata manually
python /app/resources/scripts/load_dataset_data.py
``` 