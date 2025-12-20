@echo off
REM ============================================================================
REM Terraform Destroy All - Complete Infrastructure Teardown
REM ============================================================================
REM
REM Destroys all AWS infrastructure by calling each module's destroy.bat script.
REM Destroys in reverse dependency order.
REM KMS keys are PRESERVED to avoid accidental deletion of encryption keys.
REM
REM Destroy Sequence:
REM   1. security/_test/_terraform   - IAM user (KMS preserved)
REM   2. 01_infra_setup         - Secrets Manager (KMS preserved)
REM   3. vpc_peering/02_different_region - Cross-region peering
REM   4. vpc_peering/01_same_region      - Same-region peering
REM   5. base_network           - VPCs (N. Virginia + London)
REM
REM ============================================================================

setlocal EnableDelayedExpansion

set "AWS_ROOT=%~dp0.."
set "ERROR_COUNT=0"

echo.
echo ============================================================================
echo                    TERRAFORM DESTROY ALL
echo ============================================================================
echo.
echo This script will destroy all infrastructure. KMS keys are preserved.
echo.
echo Destroy sequence:
echo   1. security/_test/_terraform    - IAM only
echo   2. 01_infra_setup          - Secrets Manager only
echo   3. vpc_peering/02_different_region
echo   4. vpc_peering/01_same_region
echo   5. base_network
echo.
echo ============================================================================
echo.

REM ============================================================================
REM Step 1: Destroy security/_test (IAM module only)
REM ============================================================================
echo [1/5] Destroying security/_test/_terraform (IAM module)...
echo ----------------------------------------------------------------------------

set "STEP1_SCRIPT=%AWS_ROOT%\_learnings\_aaditya_designers_corp\01_infra_setup\modules\security\_test\_terraform\__scripts\destroy.bat"
if not exist "%STEP1_SCRIPT%" (
    echo WARNING: Script not found: %STEP1_SCRIPT%
    goto step2
)

call "%STEP1_SCRIPT%"
if !errorlevel! neq 0 (
    echo ERROR: security/_test/_terraform destroy failed
    set /a ERROR_COUNT+=1
) else (
    echo SUCCESS: security/_test IAM module destroyed - KMS preserved
)

:step2
echo.
REM ============================================================================
REM Step 2: Destroy 01_infra_setup (Secrets Manager only)
REM ============================================================================
echo [2/5] Destroying 01_infra_setup (Secrets Manager)...
echo ----------------------------------------------------------------------------

set "STEP2_SCRIPT=%AWS_ROOT%\_learnings\_aaditya_designers_corp\01_infra_setup\__scripts\destroy.bat"
if not exist "%STEP2_SCRIPT%" (
    echo WARNING: Script not found: %STEP2_SCRIPT%
    goto step3
)

call "%STEP2_SCRIPT%"
if !errorlevel! neq 0 (
    echo ERROR: 01_infra_setup destroy failed
    set /a ERROR_COUNT+=1
) else (
    echo SUCCESS: Secrets Manager destroyed - KMS preserved
)

:step3
echo.
REM ============================================================================
REM Step 3: Destroy VPC Peering - Different Region (Cross-Region)
REM ============================================================================
echo [3/5] Destroying vpc_peering/02_different_region...
echo ----------------------------------------------------------------------------

set "STEP3_SCRIPT=%AWS_ROOT%\_learnings\vpc_connectivity\01_vpc_peering\02_different_region\__scripts\destroy.bat"
if not exist "%STEP3_SCRIPT%" (
    echo WARNING: Script not found: %STEP3_SCRIPT%
    goto step4
)

call "%STEP3_SCRIPT%"
if !errorlevel! neq 0 (
    echo ERROR: vpc_peering/02_different_region destroy failed
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

set "STEP4_SCRIPT=%AWS_ROOT%\_learnings\vpc_connectivity\01_vpc_peering\01_same_region\__scripts\destroy.bat"
if not exist "%STEP4_SCRIPT%" (
    echo WARNING: Script not found: %STEP4_SCRIPT%
    goto step5
)

call "%STEP4_SCRIPT%"
if !errorlevel! neq 0 (
    echo ERROR: vpc_peering/01_same_region destroy failed
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

set "STEP5_SCRIPT=%AWS_ROOT%\base_network\__scripts\destroy.bat"
if not exist "%STEP5_SCRIPT%" (
    echo WARNING: Script not found: %STEP5_SCRIPT%
    goto summary
)

call "%STEP5_SCRIPT%"
if !errorlevel! neq 0 (
    echo ERROR: base_network destroy failed
    set /a ERROR_COUNT+=1
) else (
    echo SUCCESS: Base network VPCs destroyed
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
    echo STATUS: Completed with %ERROR_COUNT% errors
)
echo.
echo Preserved resources - not destroyed:
echo   - KMS keys in security/_test/_terraform
echo   - KMS keys in 01_infra_setup
echo.
echo To destroy KMS keys manually, run:
echo   cd [module_path] ^&^& terraform destroy -var="profile=dev" -auto-approve
echo.
echo ============================================================================

cd /d "%AWS_ROOT%\__scripts"
endlocal
exit /b %ERROR_COUNT%
