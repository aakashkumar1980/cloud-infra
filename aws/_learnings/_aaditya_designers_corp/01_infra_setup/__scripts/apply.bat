@echo off
setlocal enabledelayedexpansion
REM Terraform Apply Script for 01_infra_setup
REM Uses dev profile with auto-approve
REM Depends on: 01_same_region, 02_different_region
REM NOTE: Checks AWS directly for existing KMS keys and imports if found

echo ============================================
echo Running Terraform Apply for 01_infra_setup
echo ============================================

REM Run dependency: 01_same_region (which includes base_network)
echo.
echo [Dependency 1] Running 01_same_region apply first...
echo --------------------------------------------
call "%~dp0..\..\..\vpc_connectivity\01_vpc_peering\01_same_region\__scripts\apply.bat"
if %errorlevel% neq 0 (
    echo ERROR: Dependency 01_same_region apply failed
    exit /b %errorlevel%
)

REM Run dependency: 02_different_region (which includes base_network)
echo.
echo [Dependency 2] Running 02_different_region apply...
echo --------------------------------------------
call "%~dp0..\..\..\vpc_connectivity\01_vpc_peering\02_different_region\__scripts\apply.bat"
if %errorlevel% neq 0 (
    echo ERROR: Dependency 02_different_region apply failed
    exit /b %errorlevel%
)

echo.
echo [Main] Running 01_infra_setup apply...
echo --------------------------------------------

cd /d "%~dp0.."

echo Initializing Terraform...
terraform init
if %errorlevel% neq 0 (
    echo ERROR: Terraform init failed
    exit /b %errorlevel%
)

REM Extract component_version and company from config files using PowerShell helper script
echo.
echo Checking for existing KMS keys in AWS...
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

REM Construct the alias name patterns (matches name_suffix in locals.tf)
set "KMS_ALIAS_NVIRGINIA=alias/symmetric_kms-nvirginia-dev-!COMPANY!_!VERSION!-terraform"
set "KMS_ALIAS_LONDON=alias/replica_symmetric_kms-london-dev-!COMPANY!_!VERSION!-terraform"
echo   Expected N.Virginia alias: !KMS_ALIAS_NVIRGINIA!
echo   Expected London alias: !KMS_ALIAS_LONDON!

REM Remove old KMS resources from state to handle version changes
REM This doesn't delete from AWS, just removes from Terraform tracking
echo.
echo   Clearing old KMS resources from state (if any)...
terraform state rm -backup=- module.kms.aws_kms_key.kms_nvirginia 2>nul
terraform state rm -backup=- module.kms.aws_kms_alias.kms_nvirginia 2>nul
terraform state rm -backup=- module.kms.aws_kms_replica_key.kms_london 2>nul
terraform state rm -backup=- module.kms.aws_kms_alias.kms_london 2>nul

REM Check if N. Virginia key exists in AWS
echo.
echo   Checking N. Virginia region (us-east-1)...
for /f "tokens=*" %%i in ('aws kms describe-key --key-id "!KMS_ALIAS_NVIRGINIA!" --region us-east-1 --profile dev --query "KeyMetadata.KeyId" --output text 2^>nul') do set "KEY_ID_NV=%%i"

if defined KEY_ID_NV (
    if not "!KEY_ID_NV!"=="None" (
        echo     Found existing KMS key: !KEY_ID_NV!
        echo     Importing N. Virginia KMS key...
        terraform import -backup=- -var="profile=dev" module.kms.aws_kms_key.kms_nvirginia !KEY_ID_NV!
        echo     Importing N. Virginia KMS alias...
        terraform import -backup=- -var="profile=dev" module.kms.aws_kms_alias.kms_nvirginia "!KMS_ALIAS_NVIRGINIA!"
    ) else (
        echo     No existing KMS key found - will create new one
    )
) else (
    echo     No existing KMS key found - will create new one
)

REM Check if London replica key exists in AWS
echo.
echo   Checking London region (eu-west-2)...
for /f "tokens=*" %%i in ('aws kms describe-key --key-id "!KMS_ALIAS_LONDON!" --region eu-west-2 --profile dev --query "KeyMetadata.KeyId" --output text 2^>nul') do set "KEY_ID_LN=%%i"

if defined KEY_ID_LN (
    if not "!KEY_ID_LN!"=="None" (
        echo     Found existing KMS replica key: !KEY_ID_LN!
        echo     Importing London KMS replica key...
        terraform import -backup=- -var="profile=dev" module.kms.aws_kms_replica_key.kms_london !KEY_ID_LN!
        echo     Importing London KMS alias...
        terraform import -backup=- -var="profile=dev" module.kms.aws_kms_alias.kms_london "!KMS_ALIAS_LONDON!"
    ) else (
        echo     No existing KMS replica key found - will create new one
    )
) else (
    echo     No existing KMS replica key found - will create new one
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
