@echo off
setlocal enabledelayedexpansion
REM Terraform Apply Script for KMS _test module
REM Uses dev profile with auto-approve
REM Independent module - no dependencies
REM NOTE: Imports existing KMS key if found in AWS but not in Terraform state

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

REM Check if KMS key needs to be imported
echo.
echo Checking for existing KMS key...
set "KMS_ALIAS=alias/test_asymmetric_kms-nvirginia-dev-aaditya_designers_corp_v1-terraform"

REM Check if key is already in Terraform state
terraform state show module.kms.aws_kms_key.asymmetric >nul 2>&1
if %errorlevel% equ 0 (
    echo KMS key already in Terraform state - no import needed
    goto :apply
)

REM Key not in state, check if it exists in AWS
echo KMS key not in Terraform state. Checking AWS...
for /f "tokens=*" %%i in ('aws kms describe-key --key-id %KMS_ALIAS% --region us-east-1 --profile dev --query "KeyMetadata.KeyId" --output text 2^>nul') do set "KEY_ID=%%i"

if not defined KEY_ID (
    echo No existing KMS key found in AWS - will create new one
    goto :apply
)

if "!KEY_ID!"=="None" (
    echo No existing KMS key found in AWS - will create new one
    goto :apply
)

echo Found existing KMS key: !KEY_ID!
echo Importing into Terraform state...
terraform import -var="profile=dev" module.kms.aws_kms_key.asymmetric !KEY_ID!
if %errorlevel% neq 0 (
    echo WARNING: Import of KMS key failed - will try to create new one
)

REM Also import the alias
echo Importing KMS alias...
terraform import -var="profile=dev" module.kms.aws_kms_alias.asymmetric %KMS_ALIAS%
if %errorlevel% neq 0 (
    echo WARNING: Import of KMS alias failed
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
