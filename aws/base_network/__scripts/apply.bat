@echo off
REM Terraform Apply Script for base_network
REM Uses dev profile with auto-approve

echo ============================================
echo Running Terraform Apply for base_network
echo ============================================

cd /d "%~dp0.."

echo Initializing Terraform...
terraform init
if %errorlevel% neq 0 (
    echo ERROR: Terraform init failed
    exit /b %errorlevel%
)

echo.
echo Running Terraform Apply with auto-approve...
terraform apply -var="profile=dev" -auto-approve -backup=-
if %errorlevel% neq 0 (
    echo ERROR: Terraform apply failed
    exit /b %errorlevel%
)

echo.
echo ============================================
echo Terraform Apply completed successfully
echo ============================================
