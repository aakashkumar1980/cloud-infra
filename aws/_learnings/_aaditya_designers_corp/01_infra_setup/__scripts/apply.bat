@echo off
REM Terraform Apply Script for 01_infra_setup
REM Uses dev profile with auto-approve
REM Depends on: 01_same_region, 02_different_region

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
