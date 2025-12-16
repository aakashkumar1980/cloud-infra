@echo off
REM Terraform Destroy Script for KMS _test module
REM Uses dev profile with auto-approve
REM NOTE: Independent - does not destroy downstream dependencies (01_infra_setup)

echo ============================================
echo Running Terraform Destroy for KMS _test
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
