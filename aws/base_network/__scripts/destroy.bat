@echo off
REM Terraform Destroy Script for base_network
REM Destroys VPC peering (same region) and base_network
REM Uses dev profile with auto-approve
REM NOTE: Destroys in reverse order (dependencies first)

echo ============================================
echo Running Terraform Destroy for base_network
echo ============================================

REM Step 1: Destroy VPC Peering - Same Region (dependency)
echo.
echo [Step 1/2] Destroying VPC Peering - Same Region...
echo --------------------------------------------

cd /d "%~dp0..\modules\vpc\vpc_peering\same_region"

echo Initializing Terraform...
terraform init
if %errorlevel% neq 0 (
    echo ERROR: Terraform init failed
    exit /b %errorlevel%
)

echo.
echo Running Terraform Destroy with auto-approve...
terraform destroy -var="profile=dev" -auto-approve -backup=-
if %errorlevel% neq 0 (
    echo ERROR: Terraform destroy failed
    exit /b %errorlevel%
)

REM Step 2: Destroy base_network
echo.
echo [Step 2/2] Destroying base_network (VPCs, Subnets, NAT, IGW)...
echo --------------------------------------------

cd /d "%~dp0.."

echo Initializing Terraform...
terraform init
if %errorlevel% neq 0 (
    echo ERROR: Terraform init failed
    exit /b %errorlevel%
)

echo.
echo Running Terraform Destroy with auto-approve...
terraform destroy -var="profile=dev" -auto-approve -backup=-
if %errorlevel% neq 0 (
    echo ERROR: Terraform destroy failed
    exit /b %errorlevel%
)

echo.
echo ============================================
echo Terraform Destroy completed successfully
echo Base Network + VPC Peering destroyed
echo ============================================
