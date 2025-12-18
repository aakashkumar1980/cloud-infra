@echo off
REM Terraform Apply Script for KMS _test module
REM Uses dev profile with auto-approve
REM Depends on: 01_infra_setup

echo ============================================
echo Running Terraform Apply for KMS _test
echo ============================================

REM Run dependency: 01_infra_setup
echo.
echo [Dependency] Running 01_infra_setup apply first...
echo --------------------------------------------
call "%~dp0..\..\..\..\..\..\_scripts\apply.bat"
if %errorlevel% neq 0 (
    echo ERROR: Dependency 01_infra_setup apply failed
    exit /b %errorlevel%
)

echo.
echo [Main] Running KMS _test apply...
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
