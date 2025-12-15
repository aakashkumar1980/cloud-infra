@echo off
REM Terraform Destroy Script for 01_same_region
REM Uses dev profile with auto-approve
REM Note: Destroys this module only, not base_network dependency

echo ============================================
echo Running Terraform Destroy for 01_same_region
echo ============================================

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

echo.
echo ============================================
echo Terraform Destroy completed successfully
echo ============================================
