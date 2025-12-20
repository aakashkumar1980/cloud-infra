@echo off
setlocal enabledelayedexpansion
REM Terraform Apply Script for KMS _test module
REM Uses dev profile with auto-approve
REM Independent module - no dependencies
REM NOTE: Checks AWS directly for existing KMS key and imports if found

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

REM Extract component_version and company from config files using PowerShell helper script
echo.
echo Checking for existing KMS key in AWS...
for /f "tokens=1,2 delims=|" %%a in ('powershell -ExecutionPolicy Bypass -File "%~dp0get_version.ps1"') do (
    set "VERSION=%%a"
    set "COMPANY=%%b"
)

if not defined VERSION (
    echo WARNING: Could not extract version from locals.tf - proceeding with apply
    goto :apply
)

if not defined COMPANY (
    echo WARNING: Could not extract company from tags.yaml - proceeding with apply
    goto :apply
)

echo   Current version: !VERSION!
echo   Company: !COMPANY!

REM Construct the alias name pattern (matches name_suffix_version in locals.tf)
set "KMS_ALIAS=alias/test_asymmetric_kms-nvirginia-dev-!COMPANY!_!VERSION!-terraform"
echo   Expected alias: !KMS_ALIAS!

REM Remove old KMS resources from state to handle version changes
REM This doesn't delete from AWS, just removes from Terraform tracking
echo.
echo   Clearing old KMS resources from state (if any)...
terraform state rm -backup=- module.kms.aws_kms_key.asymmetric 2>nul
terraform state rm -backup=- module.kms.aws_kms_alias.asymmetric 2>nul

REM Check if alias exists in AWS
for /f "tokens=*" %%i in ('aws kms describe-key --key-id "!KMS_ALIAS!" --region us-east-1 --profile dev --query "KeyMetadata.KeyId" --output text 2^>nul') do set "KEY_ID=%%i"

if not defined KEY_ID (
    echo   No existing KMS key found - will create new one
    goto :apply
)

if "!KEY_ID!"=="None" (
    echo   No existing KMS key found - will create new one
    goto :apply
)

echo   Found existing KMS key: !KEY_ID!
echo   Importing into Terraform state...

REM Import KMS key
echo.
echo   Importing KMS key...
terraform import -var="profile=dev" module.kms.aws_kms_key.asymmetric !KEY_ID!
if %errorlevel% equ 0 (
    echo     - KMS key imported successfully
) else (
    echo     - KMS key import failed or already in state
)

REM Import KMS alias
echo   Importing KMS alias...
terraform import -var="profile=dev" module.kms.aws_kms_alias.asymmetric "!KMS_ALIAS!"
if %errorlevel% equ 0 (
    echo     - KMS alias imported successfully
) else (
    echo     - KMS alias import failed or already in state
)

:apply
echo.
echo Running Terraform Apply with auto-approve...
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
