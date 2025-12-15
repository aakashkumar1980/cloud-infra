@echo off
REM Terraform Destroy Script for 01_infra_setup
REM Uses dev profile with auto-approve
REM Destroys in reverse order: 01_infra_setup -> 02_different_region -> 01_same_region -> base_network
REM NOTE: KMS module is preserved (not destroyed) for reuse

echo ============================================
echo Running Terraform Destroy for 01_infra_setup
echo ============================================

REM First destroy this module (excluding KMS)
echo.
echo [Main] Destroying 01_infra_setup (preserving KMS)...
echo --------------------------------------------

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

REM Then destroy dependency: 02_different_region (reverse of apply order)
echo.
echo [Dependency 1] Destroying 02_different_region...
echo --------------------------------------------
call "%~dp0..\..\..\vpc_connectivity\01_vpc_peering\02_different_region\_scripts\destroy.bat"
if %errorlevel% neq 0 (
    echo ERROR: Dependency 02_different_region destroy failed
    exit /b %errorlevel%
)

REM Then destroy dependency: 01_same_region (reverse of apply order)
echo.
echo [Dependency 2] Destroying 01_same_region...
echo --------------------------------------------
call "%~dp0..\..\..\vpc_connectivity\01_vpc_peering\01_same_region\_scripts\destroy.bat"
if %errorlevel% neq 0 (
    echo ERROR: Dependency 01_same_region destroy failed
    exit /b %errorlevel%
)

echo.
echo ============================================
echo Terraform Destroy completed successfully
echo (KMS keys preserved for reuse)
echo ============================================
