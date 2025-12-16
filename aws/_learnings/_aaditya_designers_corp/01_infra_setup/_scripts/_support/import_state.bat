@echo off
REM ============================================================================
REM Terraform Import Script for KMS Resources
REM ============================================================================
REM
REM Purpose: Import existing KMS keys and aliases into Terraform state
REM
REM Use this script when:
REM   - Terraform state files were accidentally deleted
REM   - KMS resources exist in AWS but not in Terraform state
REM   - You see "AlreadyExistsException" errors for KMS aliases during apply
REM
REM Prerequisites:
REM   - AWS CLI installed and configured
REM   - Terraform installed
REM   - AWS profile "dev" configured with appropriate permissions
REM
REM Resources imported:
REM   - aws_kms_key.kms_nvirginia (N. Virginia primary key)
REM   - aws_kms_alias.kms_nvirginia (N. Virginia alias)
REM   - aws_kms_replica_key.kms_london (London replica key)
REM   - aws_kms_alias.kms_london (London alias)
REM
REM ============================================================================

echo ============================================
echo KMS Import Script for 01_infra_setup
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
echo ============================================
echo Fetching existing KMS Key IDs from AWS...
echo ============================================

REM Get N. Virginia key ID
echo.
echo [1/4] Getting N. Virginia KMS key ID...
for /f "tokens=*" %%i in ('aws kms describe-key --key-id alias/symmetric_kms-nvirginia-dev-aaditya_designers-terraform --region us-east-1 --profile dev --query "KeyMetadata.KeyId" --output text 2^>nul') do set NVIRGINIA_KEY_ID=%%i

if "%NVIRGINIA_KEY_ID%"=="" (
    echo ERROR: Could not find N. Virginia KMS key. It may not exist.
    exit /b 1
)
echo Found: %NVIRGINIA_KEY_ID%

REM Get London key ID
echo.
echo [2/4] Getting London KMS key ID...
for /f "tokens=*" %%i in ('aws kms describe-key --key-id alias/replica_symmetric_kms-london-dev-aaditya_designers-terraform --region eu-west-2 --profile dev --query "KeyMetadata.KeyId" --output text 2^>nul') do set LONDON_KEY_ID=%%i

if "%LONDON_KEY_ID%"=="" (
    echo ERROR: Could not find London KMS key. It may not exist.
    exit /b 1
)
echo Found: %LONDON_KEY_ID%

echo.
echo ============================================
echo Importing KMS resources into Terraform state...
echo ============================================

REM Import N. Virginia KMS key
echo.
echo [1/4] Importing N. Virginia KMS key...
terraform import -var="profile=dev" module.kms.aws_kms_key.kms_nvirginia %NVIRGINIA_KEY_ID%
if %errorlevel% neq 0 (
    echo WARNING: Import may have failed or resource already exists in state
)

REM Import N. Virginia KMS alias
echo.
echo [2/4] Importing N. Virginia KMS alias...
terraform import -var="profile=dev" module.kms.aws_kms_alias.kms_nvirginia alias/symmetric_kms-nvirginia-dev-aaditya_designers-terraform
if %errorlevel% neq 0 (
    echo WARNING: Import may have failed or resource already exists in state
)

REM Import London KMS replica key
echo.
echo [3/4] Importing London KMS replica key...
terraform import -var="profile=dev" module.kms.aws_kms_replica_key.kms_london %LONDON_KEY_ID%
if %errorlevel% neq 0 (
    echo WARNING: Import may have failed or resource already exists in state
)

REM Import London KMS alias
echo.
echo [4/4] Importing London KMS alias...
terraform import -var="profile=dev" module.kms.aws_kms_alias.kms_london alias/replica_symmetric_kms-london-dev-aaditya_designers-terraform
if %errorlevel% neq 0 (
    echo WARNING: Import may have failed or resource already exists in state
)

echo.
echo ============================================
echo Running Terraform Plan to verify state...
echo ============================================
terraform plan -var="profile=dev"

echo.
echo ============================================
echo Import completed!
echo ============================================
echo.
echo Next steps:
echo   1. Review the plan output above
echo   2. If no changes needed, state is in sync
echo   3. Run apply.bat to continue with deployment
echo.
