@echo off
setlocal enabledelayedexpansion
REM Terraform Apply Script for KMS _test module
REM Uses dev profile with auto-approve
REM Independent module - no dependencies
REM NOTE: Always checks AWS for existing KMS key and imports if found

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

REM Always check AWS for existing KMS key (don't rely on Terraform state)
echo.
echo Checking AWS for existing KMS key...

REM Search for alias matching pattern (no hardcoded version)
set "ALIAS_PREFIX=alias/test_asymmetric_kms-nvirginia-dev-aaditya_designers_corp_"
for /f "tokens=*" %%i in ('aws kms list-aliases --region us-east-1 --profile dev --query "Aliases[?starts_with(AliasName,'%ALIAS_PREFIX%')].AliasName" --output text 2^>nul') do set "KMS_ALIAS=%%i"

if not defined KMS_ALIAS (
    echo No existing KMS key found in AWS - will create new one
    goto :apply
)

if "!KMS_ALIAS!"=="None" (
    echo No existing KMS key found in AWS - will create new one
    goto :apply
)

echo Found existing KMS alias: !KMS_ALIAS!

REM Get the Key ID from the alias
for /f "tokens=*" %%i in ('aws kms describe-key --key-id !KMS_ALIAS! --region us-east-1 --profile dev --query "KeyMetadata.KeyId" --output text 2^>nul') do set "KEY_ID=%%i"

if not defined KEY_ID (
    echo WARNING: Could not get Key ID from alias
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
