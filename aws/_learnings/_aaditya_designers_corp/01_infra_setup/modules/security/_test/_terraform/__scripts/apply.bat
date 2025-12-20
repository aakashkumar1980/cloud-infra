@echo off
setlocal enabledelayedexpansion
REM Terraform Apply Script for KMS _test module
REM Uses dev profile with auto-approve
REM Independent module - no dependencies
REM NOTE: Always checks AWS for existing KMS key (for current version) and imports if found

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

REM Get the name_suffix dynamically from Terraform (includes version)
echo.
echo Getting current version alias name from Terraform...
REM Disable color output to avoid ANSI codes in the result
set "NO_COLOR=1"
echo local.name_suffix | terraform console -var="profile=dev" > "%TEMP%\name_suffix.txt" 2>nul
set "NO_COLOR="
set /p NAME_SUFFIX=<"%TEMP%\name_suffix.txt"
del "%TEMP%\name_suffix.txt" 2>nul

REM Remove quotes from the output
set "NAME_SUFFIX=!NAME_SUFFIX:"=!"

if not defined NAME_SUFFIX (
    echo WARNING: Could not get name_suffix from Terraform - will proceed with apply
    goto :apply
)

REM Construct the alias name
set "KMS_ALIAS=alias/test_asymmetric_kms-!NAME_SUFFIX!"
echo Current version alias: !KMS_ALIAS!

REM Check if alias exists in AWS
echo.
echo Checking AWS for existing KMS key...
for /f "tokens=*" %%i in ('aws kms describe-key --key-id !KMS_ALIAS! --region us-east-1 --profile dev --query "KeyMetadata.KeyId" --output text 2^>nul') do set "KEY_ID=%%i"

if not defined KEY_ID (
    echo No existing KMS key found for current version - will create new one
    goto :apply
)

if "!KEY_ID!"=="None" (
    echo No existing KMS key found for current version - will create new one
    goto :apply
)

echo Found existing KMS key: !KEY_ID!
echo Importing into Terraform state...

REM Import KMS key (ignore error if already in state)
terraform import -var="profile=dev" module.kms.aws_kms_key.asymmetric !KEY_ID! 2>nul
if %errorlevel% equ 0 (
    echo   - KMS key imported successfully
) else (
    echo   - KMS key already in state or import skipped
)

REM Import KMS alias (ignore error if already in state)
terraform import -var="profile=dev" module.kms.aws_kms_alias.asymmetric !KMS_ALIAS! 2>nul
if %errorlevel% equ 0 (
    echo   - KMS alias imported successfully
) else (
    echo   - KMS alias already in state or import skipped
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
