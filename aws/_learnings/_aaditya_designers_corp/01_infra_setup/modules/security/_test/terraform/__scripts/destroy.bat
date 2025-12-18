@echo off
REM Terraform Destroy Script for KMS _test module
REM Uses dev profile with auto-approve
REM NOTE: Destroys IAM user and access keys
REM NOTE: KMS key is preserved for reuse

echo ============================================
echo Running Terraform Destroy for KMS _test
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
echo Destroying IAM module (user + access keys)...
terraform destroy -target=module.iam -var="profile=dev" -auto-approve
if %errorlevel% neq 0 (
    echo ERROR: IAM module destroy failed
    exit /b %errorlevel%
)

echo.
echo ============================================
echo Terraform Destroy completed successfully
echo   - IAM user and access keys: DESTROYED
echo   - KMS key: PRESERVED (for reuse)
echo ============================================
echo.
echo To also destroy the KMS key, run manually:
echo   cd %cd%
echo   terraform destroy -var="profile=dev" -auto-approve
echo.
