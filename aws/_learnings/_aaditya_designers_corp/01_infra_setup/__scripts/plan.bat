@echo off
REM Terraform Plan Script for 01_infra_setup
REM Uses dev profile
REM Depends on: 01_same_region, 02_different_region

echo ============================================
echo Running Terraform Plan for 01_infra_setup
echo ============================================

REM Run dependency: 01_same_region (which includes base_network)
echo.
echo [Dependency 1] Running 01_same_region plan first...
echo --------------------------------------------
call "%~dp0..\..\..\vpc_connectivity\01_vpc_peering\01_same_region\__scripts\plan.bat"
if %errorlevel% neq 0 (
    echo ERROR: Dependency 01_same_region plan failed
    exit /b %errorlevel%
)

REM Run dependency: 02_different_region (which includes base_network)
echo.
echo [Dependency 2] Running 02_different_region plan...
echo --------------------------------------------
call "%~dp0..\..\..\vpc_connectivity\01_vpc_peering\02_different_region\__scripts\plan.bat"
if %errorlevel% neq 0 (
    echo ERROR: Dependency 02_different_region plan failed
    exit /b %errorlevel%
)

echo.
echo [Main] Running 01_infra_setup plan...
echo --------------------------------------------

cd /d "%~dp0.."

echo Initializing Terraform...
terraform init
if %errorlevel% neq 0 (
    echo ERROR: Terraform init failed
    exit /b %errorlevel%
)

echo.
echo Running Terraform Plan...
terraform plan -var="profile=dev"
if %errorlevel% neq 0 (
    echo ERROR: Terraform plan failed
    exit /b %errorlevel%
)

echo.
echo ============================================
echo Terraform Plan completed successfully
echo ============================================
