@echo off
REM Terraform Plan Script for KMS _test module
REM Uses dev profile
REM Depends on: 01_infra_setup

echo ============================================
echo Running Terraform Plan for KMS _test
echo ============================================

REM Run dependency: 01_infra_setup
echo.
echo [Dependency] Running 01_infra_setup plan first...
echo --------------------------------------------
call "%~dp0..\..\..\..\..\_scripts\plan.bat"
if %errorlevel% neq 0 (
    echo ERROR: Dependency 01_infra_setup plan failed
    exit /b %errorlevel%
)

echo.
echo [Main] Running KMS _test plan...
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
