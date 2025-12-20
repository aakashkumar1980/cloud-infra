@echo off
REM Terraform Apply Script for 01_same_region
REM Uses dev profile with auto-approve
REM Depends on: base_network

echo ============================================
echo Running Terraform Apply for 01_same_region
echo ============================================

REM Run dependency: base_network
echo.
echo [Dependency] Running base_network apply first...
echo --------------------------------------------
call "%~dp0..\..\..\..\..\base_network\__scripts\apply.bat"
if %errorlevel% neq 0 (
    echo ERROR: Dependency base_network apply failed
    exit /b %errorlevel%
)

echo.
echo [Main] Running 01_same_region apply...
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
terraform apply -var="profile=dev" -auto-approve -backup=-
if %errorlevel% neq 0 (
    echo ERROR: Terraform apply failed
    exit /b %errorlevel%
)

echo.
echo ============================================
echo Terraform Apply completed successfully
echo ============================================
