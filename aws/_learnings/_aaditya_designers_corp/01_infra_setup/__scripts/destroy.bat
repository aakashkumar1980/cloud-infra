@echo off
REM Terraform Destroy Script for 01_infra_setup
REM Uses dev profile with auto-approve
REM NOTE: KMS module is preserved (not destroyed) for reuse
REM NOTE: Does not destroy downstream dependencies (vpc_peering, base_network)

echo ============================================
echo Running Terraform Destroy for 01_infra_setup
echo ============================================

cd /d "%~dp0.."

echo Initializing Terraform...
terraform init
if %errorlevel% neq 0 (
    echo ERROR: Terraform init failed
    exit /b %errorlevel%
)

echo.
echo Running Terraform Destroy (excluding KMS module)...
REM Destroy secrets_manager but preserve KMS for reuse
terraform destroy -var="profile=dev" -target=module.secrets_manager -auto-approve
if %errorlevel% neq 0 (
    echo ERROR: Terraform destroy failed
    exit /b %errorlevel%
)

echo.
echo ============================================
echo Terraform Destroy completed successfully
echo (KMS keys preserved for reuse)
echo ============================================
