@echo off
REM Terraform Destroy Script for KMS _test module
REM Uses dev profile with auto-approve
REM NOTE: KMS key is preserved (not destroyed) for reuse
REM NOTE: Does not destroy downstream dependencies (01_infra_setup)
REM
REM To force destroy the KMS key, run manually:
REM   terraform destroy -var="profile=dev" -auto-approve

echo ============================================
echo Running Terraform Destroy for KMS _test
echo ============================================

cd /d "%~dp0.."

echo.
echo NOTE: KMS key is preserved for reuse.
echo No resources will be destroyed.
echo.
echo To force destroy the KMS key, run manually:
echo   cd %cd%
echo   terraform destroy -var="profile=dev" -auto-approve
echo.

echo ============================================
echo Terraform Destroy completed successfully
echo (KMS key preserved for reuse)
echo ============================================
