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

REM Extract component_version from locals.tf using PowerShell
echo.
echo Checking for existing KMS key in AWS...
for /f "tokens=*" %%v in ('powershell -Command "(Get-Content 'locals.tf' | Select-String 'component_version\s*=\s*\"([^\"]+)\"' | ForEach-Object { $_.Matches.Groups[1].Value })"') do set "VERSION=%%v"

if not defined VERSION (
    echo WARNING: Could not extract version from locals.tf - proceeding with apply
    goto :apply
)

echo   Current version: !VERSION!

REM Construct the alias name pattern
set "KMS_ALIAS=alias/test_asymmetric_kms-nvirginia-dev-aaditya_designers_corp_!VERSION!-terraform"
echo   Expected alias: !KMS_ALIAS!

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

REM Import KMS key (ignore error if already in state)
terraform import -var="profile=dev" module.kms.aws_kms_key.asymmetric !KEY_ID! 2>nul
if %errorlevel% equ 0 (
    echo     - KMS key imported successfully
) else (
    echo     - KMS key already in state or import skipped
)

REM Import KMS alias (ignore error if already in state)
terraform import -var="profile=dev" module.kms.aws_kms_alias.asymmetric "!KMS_ALIAS!" 2>nul
if %errorlevel% equ 0 (
    echo     - KMS alias imported successfully
) else (
    echo     - KMS alias already in state or import skipped
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
