@echo off
REM Terraform Apply Script for base_network
REM Applies base_network and VPC peering (same region)
REM Uses dev profile with auto-approve

echo ============================================
echo Running Terraform Apply for base_network
echo ============================================

REM Step 1: Apply base_network
echo.
echo [Step 1/2] Applying base_network (VPCs, Subnets, NAT, IGW)...
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

REM Step 2: Apply VPC Peering - Same Region
echo.
echo [Step 2/2] Applying VPC Peering - Same Region...
echo --------------------------------------------

cd /d "%~dp0..\modules\vpc\vpc_peering\same_region"

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
echo Base Network + VPC Peering deployed
echo ============================================
