@echo off
setlocal enabledelayedexpansion

echo [TEST] 🧪 SMICRAB Backend Startup Test
echo [TEST] ===============================

rem Test 1: Check datasets directory
echo [TEST] Test 1: Checking datasets directory...
if exist "datasets" (
    set /a NC_COUNT=0
    for %%f in ("datasets\*.nc" "datasets\*.NC") do (
        if exist "%%f" set /a NC_COUNT+=1
    )
    if !NC_COUNT! gtr 0 (
        echo [SUCCESS] Found !NC_COUNT! NetCDF files in datasets directory
    ) else (
        echo [ERROR] No NetCDF files found in datasets directory
        echo Please add .nc files to the datasets\ directory
    )
) else (
    echo [ERROR] Datasets directory not found
    echo Please create a datasets\ directory and add .nc files
)

rem Test 2: Check R setup script
echo [TEST] Test 2: Checking R setup script...
if exist "r_scripts\project_setup\generate_csv.R" (
    echo [SUCCESS] R setup script found
) else (
    echo [ERROR] R setup script not found at r_scripts\project_setup\generate_csv.R
)

rem Test 3: Check startup script
echo [TEST] Test 3: Checking startup script...
if exist "startup.sh" (
    echo [SUCCESS] Startup script found
) else (
    echo [ERROR] Startup script not found
)

rem Test 4: Check Docker files
echo [TEST] Test 4: Checking Docker configuration...
if exist "Dockerfile" (
    echo [SUCCESS] Dockerfile found
) else (
    echo [ERROR] Dockerfile not found
)

if exist "docker-compose.yml" (
    echo [SUCCESS] docker-compose.yml found
) else (
    echo [ERROR] docker-compose.yml not found
)

rem Test 5: Check R packages file
echo [TEST] Test 5: Checking R packages configuration...
if exist "r_packages.R" (
    echo [SUCCESS] R packages file found
) else (
    echo [ERROR] r_packages.R not found
)

rem Test 6: Check Python requirements
echo [TEST] Test 6: Checking Python requirements...
if exist "requirements.txt" (
    findstr /i "psycopg2" requirements.txt >nul
    if !errorlevel! equ 0 (
        echo [SUCCESS] Python requirements include database drivers
    ) else (
        echo [WARNING] psycopg2 not found in requirements.txt
    )
) else (
    echo [ERROR] requirements.txt not found
)

rem Test 7: Check alembic configuration
echo [TEST] Test 7: Checking Alembic configuration...
if exist "alembic.ini" (
    echo [SUCCESS] Alembic configuration found
) else (
    echo [ERROR] alembic.ini not found
)

if exist "migrations" (
    set /a MIGRATION_COUNT=0
    for %%f in ("migrations\versions\*.py") do (
        if exist "%%f" set /a MIGRATION_COUNT+=1
    )
    if !MIGRATION_COUNT! gtr 0 (
        echo [SUCCESS] Found !MIGRATION_COUNT! migration files
    ) else (
        echo [WARNING] No migration files found in migrations\versions\
    )
) else (
    echo [ERROR] Migrations directory not found
)

rem Test 8: Check .env configuration
echo [TEST] Test 8: Checking environment configuration...
if exist ".env.example" (
    echo [SUCCESS] .env.example template found
) else (
    echo [WARNING] No .env.example file found. Consider creating one for configuration guidance.
)

rem Check critical environment variables
set MISSING_VARS=

if "%POSTGRES_HOST%"=="" set MISSING_VARS=%MISSING_VARS% POSTGRES_HOST
if "%POSTGRES_PORT%"=="" set MISSING_VARS=%MISSING_VARS% POSTGRES_PORT
if "%POSTGRES_DB%"=="" set MISSING_VARS=%MISSING_VARS% POSTGRES_DB
if "%POSTGRES_USER%"=="" set MISSING_VARS=%MISSING_VARS% POSTGRES_USER
if "%POSTGRES_PASSWORD%"=="" set MISSING_VARS=%MISSING_VARS% POSTGRES_PASSWORD

if "%MISSING_VARS%"=="" (
    echo [SUCCESS] All critical environment variables are set
) else (
    echo [WARNING] Missing environment variables:%MISSING_VARS%
    echo You can set these in a .env file or as environment variables
)

echo [TEST] ===============================
echo [TEST] Test completed!
echo [TEST] If all tests passed, you can run: docker-compose up --build

pause 