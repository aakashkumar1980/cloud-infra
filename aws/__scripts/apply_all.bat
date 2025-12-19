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
REM   5. security/_test/_terraform   - IAM user for testing
REM
REM ============================================================================

setlocal EnableDelayedExpansion

set "AWS_ROOT=%~dp0.."
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
echo   5. security/_test/_terraform
echo.
echo ============================================================================
echo.

REM ============================================================================
REM Step 1: Apply Base Network (VPCs)
REM ============================================================================
echo [1/5] Applying base_network (VPCs)...
echo ----------------------------------------------------------------------------

set "STEP1_DIR=%AWS_ROOT%\base_network"
if not exist "%STEP1_DIR%" (
    echo WARNING: Directory not found: %STEP1_DIR%
    goto step2
)

cd /d "%STEP1_DIR%"
call :run_terraform
if !errorlevel! neq 0 (
    set /a ERROR_COUNT+=1
) else (
    echo SUCCESS: Base network applied
)

:step2
echo.
REM ============================================================================
REM Step 2: Apply VPC Peering - Same Region
REM ============================================================================
echo [2/5] Applying vpc_peering/01_same_region...
echo ----------------------------------------------------------------------------

set "STEP2_DIR=%AWS_ROOT%\_learnings\vpc_connectivity\01_vpc_peering\01_same_region"
if not exist "%STEP2_DIR%" (
    echo WARNING: Directory not found: %STEP2_DIR%
    goto step3
)

cd /d "%STEP2_DIR%"
call :run_terraform
if !errorlevel! neq 0 (
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

set "STEP3_DIR=%AWS_ROOT%\_learnings\vpc_connectivity\01_vpc_peering\02_different_region"
if not exist "%STEP3_DIR%" (
    echo WARNING: Directory not found: %STEP3_DIR%
    goto step4
)

cd /d "%STEP3_DIR%"
call :run_terraform
if !errorlevel! neq 0 (
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

set "STEP4_DIR=%AWS_ROOT%\_learnings\_aaditya_designers_corp\01_infra_setup"
if not exist "%STEP4_DIR%" (
    echo WARNING: Directory not found: %STEP4_DIR%
    goto step5
)

cd /d "%STEP4_DIR%"
call :run_terraform
if !errorlevel! neq 0 (
    set /a ERROR_COUNT+=1
) else (
    echo SUCCESS: KMS + Secrets Manager applied
)

:step5
echo.
REM ============================================================================
REM Step 5: Apply security/_test (IAM module)
REM ============================================================================
echo [5/5] Applying security/_test/_terraform (IAM module)...
echo ----------------------------------------------------------------------------

set "STEP5_DIR=%AWS_ROOT%\_learnings\_aaditya_designers_corp\01_infra_setup\modules\security\_test\_terraform"
if not exist "%STEP5_DIR%" (
    echo WARNING: Directory not found: %STEP5_DIR%
    goto summary
)

cd /d "%STEP5_DIR%"
call :run_terraform
if !errorlevel! neq 0 (
    set /a ERROR_COUNT+=1
) else (
    echo SUCCESS: security/_test applied
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

cd /d "%AWS_ROOT%\__scripts"
endlocal
exit /b %ERROR_COUNT%

REM ============================================================================
REM Subroutine: Run terraform init and apply
REM ============================================================================
:run_terraform
terraform init -input=false
if !errorlevel! neq 0 (
    echo ERROR: Terraform init failed
    exit /b 1
)
terraform apply -var="profile=%PROFILE%" -auto-approve
if !errorlevel! neq 0 (
    echo ERROR: Terraform apply failed
    exit /b 1
)
exit /b 0
