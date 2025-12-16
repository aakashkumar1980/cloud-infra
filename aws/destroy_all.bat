@echo off
REM ============================================================================
REM Terraform Destroy All - Complete Infrastructure Teardown
REM ============================================================================
REM
REM Destroys all AWS infrastructure in dependency order (reverse of creation).
REM KMS keys are PRESERVED to avoid accidental deletion of encryption keys.
REM
REM Destroy Sequence:
REM   1. kms/_test/terraform    - IAM user (KMS preserved)
REM   2. 01_infra_setup         - Secrets Manager (KMS preserved)
REM   3. vpc_peering/02_different_region - Cross-region peering
REM   4. vpc_peering/01_same_region      - Same-region peering
REM   5. base_network           - VPCs (N. Virginia + London)
REM
REM ============================================================================

setlocal EnableDelayedExpansion

set "AWS_ROOT=%~dp0"
set "PROFILE=dev"
set "ERROR_COUNT=0"

echo.
echo ============================================================================
echo                    TERRAFORM DESTROY ALL
echo ============================================================================
echo.
echo This script will destroy all infrastructure (KMS keys preserved).
echo.
echo Destroy sequence:
echo   1. kms/_test/terraform     (IAM only)
echo   2. 01_infra_setup          (Secrets Manager only)
echo   3. vpc_peering/02_different_region
echo   4. vpc_peering/01_same_region
echo   5. base_network
echo.
echo ============================================================================
echo.

REM ============================================================================
REM Step 1: Destroy KMS _test (IAM module only)
REM ============================================================================
echo [1/5] Destroying kms/_test/terraform (IAM module)...
echo ----------------------------------------------------------------------------

cd /d "%AWS_ROOT%_learnings\_aaditya_designers_corp\01_infra_setup\modules\security\kms\_test\terraform"
if %errorlevel% neq 0 (
    echo WARNING: Directory not found, skipping...
    goto step2
)

terraform init -input=false
if %errorlevel% neq 0 (
    echo ERROR: Terraform init failed for kms/_test
    set /a ERROR_COUNT+=1
    goto step2
)

terraform destroy -target=module.iam -var="profile=%PROFILE%" -auto-approve
if %errorlevel% neq 0 (
    echo ERROR: Terraform destroy failed for kms/_test IAM module
    set /a ERROR_COUNT+=1
) else (
    echo SUCCESS: kms/_test IAM module destroyed (KMS preserved)
)

:step2
echo.
REM ============================================================================
REM Step 2: Destroy 01_infra_setup (Secrets Manager only)
REM ============================================================================
echo [2/5] Destroying 01_infra_setup (Secrets Manager)...
echo ----------------------------------------------------------------------------

cd /d "%AWS_ROOT%_learnings\_aaditya_designers_corp\01_infra_setup"
if %errorlevel% neq 0 (
    echo WARNING: Directory not found, skipping...
    goto step3
)

terraform init -input=false
if %errorlevel% neq 0 (
    echo ERROR: Terraform init failed for 01_infra_setup
    set /a ERROR_COUNT+=1
    goto step3
)

terraform destroy -target=module.secrets_manager -var="profile=%PROFILE%" -auto-approve
if %errorlevel% neq 0 (
    echo ERROR: Terraform destroy failed for secrets_manager
    set /a ERROR_COUNT+=1
) else (
    echo SUCCESS: Secrets Manager destroyed (KMS preserved)
)

:step3
echo.
REM ============================================================================
REM Step 3: Destroy VPC Peering - Different Region (Cross-Region)
REM ============================================================================
echo [3/5] Destroying vpc_peering/02_different_region...
echo ----------------------------------------------------------------------------

cd /d "%AWS_ROOT%_learnings\vpc_connectivity\01_vpc_peering\02_different_region"
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

terraform destroy -var="profile=%PROFILE%" -auto-approve
if %errorlevel% neq 0 (
    echo ERROR: Terraform destroy failed for vpc_peering/02_different_region
    set /a ERROR_COUNT+=1
) else (
    echo SUCCESS: Cross-region VPC peering destroyed
)

:step4
echo.
REM ============================================================================
REM Step 4: Destroy VPC Peering - Same Region
REM ============================================================================
echo [4/5] Destroying vpc_peering/01_same_region...
echo ----------------------------------------------------------------------------

cd /d "%AWS_ROOT%_learnings\vpc_connectivity\01_vpc_peering\01_same_region"
if %errorlevel% neq 0 (
    echo WARNING: Directory not found, skipping...
    goto step5
)

terraform init -input=false
if %errorlevel% neq 0 (
    echo ERROR: Terraform init failed for vpc_peering/01_same_region
    set /a ERROR_COUNT+=1
    goto step5
)

terraform destroy -var="profile=%PROFILE%" -auto-approve
if %errorlevel% neq 0 (
    echo ERROR: Terraform destroy failed for vpc_peering/01_same_region
    set /a ERROR_COUNT+=1
) else (
    echo SUCCESS: Same-region VPC peering destroyed
)

:step5
echo.
REM ============================================================================
REM Step 5: Destroy Base Network (VPCs)
REM ============================================================================
echo [5/5] Destroying base_network (VPCs)...
echo ----------------------------------------------------------------------------

cd /d "%AWS_ROOT%base_network"
if %errorlevel% neq 0 (
    echo WARNING: Directory not found, skipping...
    goto summary
)

terraform init -input=false
if %errorlevel% neq 0 (
    echo ERROR: Terraform init failed for base_network
    set /a ERROR_COUNT+=1
    goto summary
)

terraform destroy -var="profile=%PROFILE%" -auto-approve
if %errorlevel% neq 0 (
    echo ERROR: Terraform destroy failed for base_network
    set /a ERROR_COUNT+=1
) else (
    echo SUCCESS: Base network (VPCs) destroyed
)

:summary
echo.
echo ============================================================================
echo                         DESTROY ALL SUMMARY
echo ============================================================================
echo.
if %ERROR_COUNT% equ 0 (
    echo STATUS: All components destroyed successfully!
) else (
    echo STATUS: Completed with %ERROR_COUNT% error(s)
)
echo.
echo Preserved resources (not destroyed):
echo   - KMS keys in kms/_test/terraform
echo   - KMS keys in 01_infra_setup
echo.
echo To destroy KMS keys manually, run:
echo   cd [module_path] ^&^& terraform destroy -var="profile=dev" -auto-approve
echo.
echo ============================================================================

cd /d "%AWS_ROOT%"
endlocal
exit /b %ERROR_COUNT%
