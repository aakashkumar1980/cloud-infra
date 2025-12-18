@echo off
REM Terraform Plan Script for base_network
REM Uses dev profile
REM No dependencies (this is the foundational layer)

echo ============================================
echo Running Terraform Plan for base_network
echo ============================================

cd /d "%~dp0.."

echo Initializing Terraform...
terraform init
if %errorlevel% neq 0 (
    echo ERROR: Terraform init failed
    exit /b %errorlevel%
)

echo.
echo Running Terraform Plan...
terraform plan -var="profile=dev"
if %errorlevel% neq 0 (
    echo ERROR: Terraform plan failed
    exit /b %errorlevel%
)

echo.
echo ============================================
echo Terraform Plan completed successfully
echo ============================================
