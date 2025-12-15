@echo off
REM Terraform Destroy Script for 01_same_region
REM Uses dev profile with auto-approve
REM Destroys in reverse order: 01_same_region -> base_network

echo ============================================
echo Running Terraform Destroy for 01_same_region
echo ============================================

REM First destroy this module
echo.
echo [Main] Destroying 01_same_region...
echo --------------------------------------------

cd /d "%~dp0.."

echo Initializing Terraform...
terraform init
if %errorlevel% neq 0 (
    echo ERROR: Terraform init failed
    exit /b %errorlevel%
)

echo.
echo Running Terraform Destroy with auto-approve...
terraform destroy -var="profile=dev" -auto-approve
if %errorlevel% neq 0 (
    echo ERROR: Terraform destroy failed
    exit /b %errorlevel%
)

REM Then destroy dependency: base_network
echo.
echo [Dependency] Destroying base_network...
echo --------------------------------------------
call "%~dp0..\..\..\..\..\base_network\_scripts\destroy.bat"
if %errorlevel% neq 0 (
    echo ERROR: Dependency base_network destroy failed
    exit /b %errorlevel%
)

echo.
echo ============================================
echo Terraform Destroy completed successfully
echo ============================================
