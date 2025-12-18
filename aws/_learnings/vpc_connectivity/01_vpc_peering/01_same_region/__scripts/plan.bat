@echo off
REM Terraform Plan Script for 01_same_region
REM Uses dev profile
REM Depends on: base_network

echo ============================================
echo Running Terraform Plan for 01_same_region
echo ============================================

REM Run dependency: base_network
echo.
echo [Dependency] Running base_network plan first...
echo --------------------------------------------
call "%~dp0..\..\..\..\..\base_network\__scripts\plan.bat"
if %errorlevel% neq 0 (
    echo ERROR: Dependency base_network plan failed
    exit /b %errorlevel%
)

echo.
echo [Main] Running 01_same_region plan...
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
