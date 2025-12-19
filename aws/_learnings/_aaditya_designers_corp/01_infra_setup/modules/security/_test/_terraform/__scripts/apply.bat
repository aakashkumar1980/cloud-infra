@echo off
setlocal enabledelayedexpansion
REM Terraform Apply Script for KMS _test module
REM Uses dev profile with auto-approve
REM Independent module - no dependencies
REM NOTE: Re-uses existing KMS key if found via Terraform data sources

echo ============================================
echo Running Terraform Apply for KMS _test
echo ============================================

cd /d "%~dp0.."

echo.
echo Initializing Terraform...
terraform init
if %errorlevel% neq 0 (
    echo ERROR: Terraform init failed
    exit /b %errorlevel%
)

echo.
echo Running Terraform Apply with auto-approve...
echo NOTE: Existing KMS keys will be detected and re-used automatically
terraform apply -var="profile=dev" -auto-approve
if %errorlevel% neq 0 (
    echo ERROR: Terraform apply failed
    exit /b %errorlevel%
)

echo.
echo ============================================
echo Terraform Apply completed successfully
echo ============================================

endlocal
