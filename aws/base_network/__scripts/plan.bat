@echo off
REM Terraform Plan Script for base_network
REM Plans base_network and VPC peering (same region)
REM Uses dev profile

echo ============================================
echo Running Terraform Plan for base_network
echo ============================================

REM Step 1: Plan base_network
echo.
echo [Step 1/2] Planning base_network (VPCs, Subnets, NAT, IGW)...
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

REM Step 2: Plan VPC Peering - Same Region
echo.
echo [Step 2/2] Planning VPC Peering - Same Region...
echo --------------------------------------------

cd /d "%~dp0..\modules\vpc\vpc_peering\same_region"

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
echo Base Network + VPC Peering planned
echo ============================================
