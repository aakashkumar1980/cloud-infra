@echo off
REM ============================================================================
REM Terraform Apply All - Complete Infrastructure Deployment
REM ============================================================================
REM
REM Deploys all AWS infrastructure by calling each module's apply.bat script.
REM Each module's apply.bat handles its own dependencies.
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

set "STEP1_SCRIPT=%AWS_ROOT%\base_network\__scripts\apply.bat"
if not exist "%STEP1_SCRIPT%" (
    echo WARNING: Script not found: %STEP1_SCRIPT%
    goto step2
)

call "%STEP1_SCRIPT%"
if !errorlevel! neq 0 (
    echo ERROR: base_network apply failed
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

set "STEP2_SCRIPT=%AWS_ROOT%\_learnings\vpc_connectivity\01_vpc_peering\01_same_region\__scripts\apply.bat"
if not exist "%STEP2_SCRIPT%" (
    echo WARNING: Script not found: %STEP2_SCRIPT%
    goto step3
)

call "%STEP2_SCRIPT%"
if !errorlevel! neq 0 (
    echo ERROR: vpc_peering/01_same_region apply failed
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

set "STEP3_SCRIPT=%AWS_ROOT%\_learnings\vpc_connectivity\01_vpc_peering\02_different_region\__scripts\apply.bat"
if not exist "%STEP3_SCRIPT%" (
    echo WARNING: Script not found: %STEP3_SCRIPT%
    goto step4
)

call "%STEP3_SCRIPT%"
if !errorlevel! neq 0 (
    echo ERROR: vpc_peering/02_different_region apply failed
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

set "STEP4_SCRIPT=%AWS_ROOT%\_learnings\_aaditya_designers_corp\01_infra_setup\__scripts\apply.bat"
if not exist "%STEP4_SCRIPT%" (
    echo WARNING: Script not found: %STEP4_SCRIPT%
    goto step5
)

call "%STEP4_SCRIPT%"
if !errorlevel! neq 0 (
    echo ERROR: 01_infra_setup apply failed
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

set "STEP5_SCRIPT=%AWS_ROOT%\_learnings\_aaditya_designers_corp\01_infra_setup\modules\security\_test\_terraform\__scripts\apply.bat"
if not exist "%STEP5_SCRIPT%" (
    echo WARNING: Script not found: %STEP5_SCRIPT%
    goto summary
)

call "%STEP5_SCRIPT%"
if !errorlevel! neq 0 (
    echo ERROR: security/_test/_terraform apply failed
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
