@echo off
REM Terraform Apply Script for KMS _test module
REM Uses dev profile with auto-approve
REM Auto-detects existing resources and skips creation if they exist

echo ============================================
echo Running Terraform Apply for KMS _test
echo ============================================

cd /d "%~dp0.."

REM Check if KMS alias already exists
echo.
echo Checking for existing KMS resources...
set ALIAS_NAME=alias/test_asymmetric_kms-nvirginia-%1-aaditya_designers_v3-terraform
if "%1"=="" set ALIAS_NAME=alias/test_asymmetric_kms-nvirginia-dev-aaditya_designers_v3-terraform

aws kms describe-key --key-id "%ALIAS_NAME%" --profile %1 >nul 2>&1
if "%1"=="" (
    aws kms describe-key --key-id "%ALIAS_NAME%" --profile dev >nul 2>&1
)

if %errorlevel% equ 0 (
    echo [INFO] KMS alias already exists. Using existing resources.
    set CREATE_RESOURCES=false
) else (
    echo [INFO] KMS alias not found. Will create new resources.
    set CREATE_RESOURCES=true
)

echo.
echo Initializing Terraform...
terraform init
if %errorlevel% neq 0 (
    echo ERROR: Terraform init failed
    exit /b %errorlevel%
)

echo.
echo Running Terraform Apply with auto-approve...
if "%1"=="" (
    terraform apply -var="profile=dev" -var="create_resources=%CREATE_RESOURCES%" -auto-approve
) else (
    terraform apply -var="profile=%1" -var="create_resources=%CREATE_RESOURCES%" -auto-approve
)
if %errorlevel% neq 0 (
    echo ERROR: Terraform apply failed
    exit /b %errorlevel%
)

echo.
echo ============================================
echo Terraform Apply completed successfully
echo ============================================
