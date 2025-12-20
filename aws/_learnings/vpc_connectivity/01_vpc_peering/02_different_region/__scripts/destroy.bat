@echo off
REM Terraform Destroy Script for 02_different_region
REM Uses dev profile with auto-approve
REM NOTE: Does not destroy downstream dependencies (base_network)

echo ============================================
echo Running Terraform Destroy for 02_different_region
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
terraform destroy -var="profile=dev" -auto-approve -backup=-
if %errorlevel% neq 0 (
    echo ERROR: Terraform destroy failed
    exit /b %errorlevel%
)

echo.
echo ============================================
echo Terraform Destroy completed successfully
echo ============================================
