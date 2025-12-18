@echo off
REM ============================================================================
REM Terraform Apply All - Complete Infrastructure Deployment
REM ============================================================================
REM
REM Deploys all AWS infrastructure in dependency order.
REM
REM Apply Sequence:
REM   1. base_network           - VPCs (N. Virginia + London)
REM   2. vpc_peering/01_same_region      - Same-region peering
REM   3. vpc_peering/02_different_region - Cross-region peering
REM   4. 01_infra_setup         - KMS + Secrets Manager
REM   5. kms/_test/terraform    - IAM user for testing
REM
REM ============================================================================

setlocal EnableDelayedExpansion

set "AWS_ROOT=%~dp0"
set "PROFILE=dev"
set "ERROR_COUNT=0"

echo.
echo ============================================================================
echo                    TERRAFORM APPLY ALL
echo ============================================================================
echo.
echo This script will deploy all infrastructure.
echo.
echo Apply sequence:
echo   1. base_network
echo   2. vpc_peering/01_same_region
echo   3. vpc_peering/02_different_region
echo   4. 01_infra_setup
echo   5. kms/_test/terraform
echo.
echo ============================================================================
echo.

REM ============================================================================
REM Step 1: Apply Base Network (VPCs)
REM ============================================================================
echo [1/5] Applying base_network (VPCs)...
echo ----------------------------------------------------------------------------

cd /d "%AWS_ROOT%..\base_network"
if %errorlevel% neq 0 (
    echo WARNING: Directory not found, skipping...
    goto step2
)

terraform init -input=false
if %errorlevel% neq 0 (
    echo ERROR: Terraform init failed for base_network
    set /a ERROR_COUNT+=1
    goto step2
)

terraform apply -var="profile=%PROFILE%" -auto-approve
if %errorlevel% neq 0 (
    echo ERROR: Terraform apply failed for base_network
    set /a ERROR_COUNT+=1
) else (
    echo SUCCESS: Base network (VPCs) applied
)

:step2
echo.
REM ============================================================================
REM Step 2: Apply VPC Peering - Same Region
REM ============================================================================
echo [2/5] Applying vpc_peering/01_same_region...
echo ----------------------------------------------------------------------------

cd /d "%AWS_ROOT%..\_learnings\vpc_connectivity\01_vpc_peering\01_same_region"
if %errorlevel% neq 0 (
    echo WARNING: Directory not found, skipping...
    goto step3
)

terraform init -input=false
if %errorlevel% neq 0 (
    echo ERROR: Terraform init failed for vpc_peering/01_same_region
    set /a ERROR_COUNT+=1
    goto step3
)

terraform apply -var="profile=%PROFILE%" -auto-approve
if %errorlevel% neq 0 (
    echo ERROR: Terraform apply failed for vpc_peering/01_same_region
    set /a ERROR_COUNT+=1
) else (
    echo SUCCESS: Same-region VPC peering applied
)

:step3
echo.
REM ============================================================================
REM Step 3: Apply VPC Peering - Different Region (Cross-Region)
REM ============================================================================
echo [3/5] Applying vpc_peering/02_different_region...
echo ----------------------------------------------------------------------------

cd /d "%AWS_ROOT%..\_learnings\vpc_connectivity\01_vpc_peering\02_different_region"
if %errorlevel% neq 0 (
    echo WARNING: Directory not found, skipping...
    goto step4
)

terraform init -input=false
if %errorlevel% neq 0 (
    echo ERROR: Terraform init failed for vpc_peering/02_different_region
    set /a ERROR_COUNT+=1
    goto step4
)

terraform apply -var="profile=%PROFILE%" -auto-approve
if %errorlevel% neq 0 (
    echo ERROR: Terraform apply failed for vpc_peering/02_different_region
    set /a ERROR_COUNT+=1
) else (
    echo SUCCESS: Cross-region VPC peering applied
)

:step4
echo.
REM ============================================================================
REM Step 4: Apply 01_infra_setup (KMS + Secrets Manager)
REM ============================================================================
echo [4/5] Applying 01_infra_setup (KMS + Secrets Manager)...
echo ----------------------------------------------------------------------------

cd /d "%AWS_ROOT%..\_learnings\_aaditya_designers_corp\01_infra_setup"
if %errorlevel% neq 0 (
    echo WARNING: Directory not found, skipping...
    goto step5
)

terraform init -input=false
if %errorlevel% neq 0 (
    echo ERROR: Terraform init failed for 01_infra_setup
    set /a ERROR_COUNT+=1
    goto step5
)

terraform apply -var="profile=%PROFILE%" -auto-approve
if %errorlevel% neq 0 (
    echo ERROR: Terraform apply failed for 01_infra_setup
    set /a ERROR_COUNT+=1
) else (
    echo SUCCESS: KMS + Secrets Manager applied
)

:step5
echo.
REM ============================================================================
REM Step 5: Apply KMS _test (IAM module)
REM ============================================================================
echo [5/5] Applying kms/_test/terraform (IAM module)...
echo ----------------------------------------------------------------------------

cd /d "%AWS_ROOT%..\_learnings\_aaditya_designers_corp\01_infra_setup\modules\security\_test\terraform"
if %errorlevel% neq 0 (
    echo WARNING: Directory not found, skipping...
    goto summary
)

terraform init -input=false
if %errorlevel% neq 0 (
    echo ERROR: Terraform init failed for kms/_test
    set /a ERROR_COUNT+=1
    goto summary
)

terraform apply -var="profile=%PROFILE%" -auto-approve
if %errorlevel% neq 0 (
    echo ERROR: Terraform apply failed for kms/_test
    set /a ERROR_COUNT+=1
) else (
    echo SUCCESS: kms/_test applied
)

:summary
echo.
echo ============================================================================
echo                         APPLY ALL SUMMARY
echo ============================================================================
echo.
if %ERROR_COUNT% equ 0 (
    echo STATUS: All components applied successfully!
) else (
    echo STATUS: Completed with %ERROR_COUNT% error(s)
)
echo.
echo ============================================================================

cd /d "%AWS_ROOT%"
endlocal
exit /b %ERROR_COUNT%
