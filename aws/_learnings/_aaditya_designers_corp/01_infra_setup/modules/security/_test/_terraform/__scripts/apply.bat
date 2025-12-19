@echo off
setlocal enabledelayedexpansion
REM Terraform Apply Script for KMS _test module
REM Uses dev profile with auto-approve
REM Auto-detects existing resources and skips creation if they exist

echo ============================================
echo Running Terraform Apply for KMS _test
echo ============================================

cd /d "%~dp0.."

REM Set profile (default to dev if not provided)
set PROFILE=%1
if "%PROFILE%"=="" set PROFILE=dev

REM Build alias name
set ALIAS_NAME=alias/test_asymmetric_kms-nvirginia-%PROFILE%-aaditya_designers_v3-terraform

REM Check if KMS alias already exists
echo.
echo Checking for existing KMS resources...
echo Alias: %ALIAS_NAME%

aws kms describe-key --key-id "%ALIAS_NAME%" --profile %PROFILE% >nul 2>&1
if !errorlevel! equ 0 (
    echo [INFO] KMS alias already exists. Using existing resources.
    set CREATE_RESOURCES=false
) else (
    echo [INFO] KMS alias not found. Will create new resources.
    set CREATE_RESOURCES=true
)

echo.
echo Initializing Terraform...
terraform init
if !errorlevel! neq 0 (
    echo ERROR: Terraform init failed
    exit /b !errorlevel!
)

echo.
echo Running Terraform Apply with auto-approve...
terraform apply -var="profile=%PROFILE%" -var="create_resources=!CREATE_RESOURCES!" -auto-approve
if !errorlevel! neq 0 (
    echo ERROR: Terraform apply failed
    exit /b !errorlevel!
)

echo.
echo ============================================
echo Terraform Apply completed successfully
echo ============================================

endlocal
