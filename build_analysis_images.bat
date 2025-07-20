@echo off
setlocal

echo 🚀 Building SMICRAB Analysis Docker Images
echo ================================================

REM Step 1: Build analysis packages base image
echo [%date% %time%] Building analysis packages base image (smicrab-analysis-packages)...
docker build -f Dockerfile.analysis_packages -t smicrab-analysis-packages:latest . || goto :error
echo ✅ Analysis packages base image built.

REM Step 2: Build analysis runner image  
echo [%date% %time%] Building analysis runner image (smicrab-analysis)...
docker build -f Dockerfile.analysis -t smicrab-analysis:latest . || goto :error
echo ✅ Analysis runner image built.

REM Step 3: List created images
echo [%date% %time%] Listing created analysis images...
docker images | findstr /R "smicrab-analysis-packages smicrab-analysis"

echo ✅ 🎉 All analysis Docker images built successfully!
echo.
echo You can now:
echo   - Tag and push smicrab-analysis-packages to Docker Hub
echo   - Run analysis containers using smicrab-analysis:latest  
echo   - Start the main application with 'test_startup.bat'
goto :EOF

:error
echo ❌ Error occurred during image building
exit /b 1 