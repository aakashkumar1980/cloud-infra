<#
.SYNOPSIS
    Aaditya Designers Corp - Infrastructure Deployment Script

.DESCRIPTION
    This script automates the deployment of all required infrastructure
    in the correct order:
      1. Base Network (VPCs, Subnets, NAT, IGW)
      2. VPC Peering - Same Region (VPC A <-> VPC B)
      3. VPC Peering - Cross Region (N. Virginia <-> London)
      4. This Infrastructure (Security, Compute, etc.)

.PARAMETER Action
    The action to perform: apply, destroy, or plan

.PARAMETER Profile
    The AWS profile/environment: dev, stage, or prod

.EXAMPLE
    .\scripts\deploy.ps1 -Action apply -Profile dev

.EXAMPLE
    .\scripts\deploy.ps1 -Action destroy -Profile dev

.EXAMPLE
    .\scripts\deploy.ps1 -Action plan -Profile dev
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("apply", "destroy", "plan")]
    [string]$Action = "apply",

    [Parameter(Mandatory=$false)]
    [ValidateSet("dev", "stage", "prod")]
    [string]$Profile = "dev"
)

# Configuration
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = (Get-Item "$ScriptDir\..\..\..\.." ).FullName

# Module paths
$BaseNetwork = Join-Path $ProjectRoot "base_network"
$VpcPeeringSame = Join-Path $ProjectRoot "_learnings\vpc_connectivity\01_vpc_peering\01_same_region"
$VpcPeeringCross = Join-Path $ProjectRoot "_learnings\vpc_connectivity\01_vpc_peering\02_different_region"
$InfraSetup = Join-Path $ProjectRoot "_learnings\_aaditya_designers_corp\01_infra_setup"

# Function to print colored output
function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Blue
    Write-Host "  $Message" -ForegroundColor Blue
    Write-Host "============================================================" -ForegroundColor Blue
    Write-Host ""
}

function Write-SuccessMessage {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-WarningMessage {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-ErrorMessage {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Function to run terraform in a directory
function Invoke-Terraform {
    param(
        [string]$Directory,
        [string]$TerraformAction,
        [string]$StepName
    )

    Write-Header $StepName
    Write-Host "Directory: $Directory"
    Write-Host "Action: $TerraformAction"
    Write-Host "Profile: $Profile"
    Write-Host ""

    Push-Location $Directory

    try {
        # Initialize if needed
        if (-not (Test-Path ".terraform")) {
            Write-Host "Initializing Terraform..."
            terraform init
            if ($LASTEXITCODE -ne 0) { throw "Terraform init failed" }
        }

        switch ($TerraformAction) {
            "plan" {
                terraform plan -var="profile=$Profile"
            }
            "apply" {
                terraform apply -var="profile=$Profile" -auto-approve
            }
            "destroy" {
                terraform destroy -var="profile=$Profile" -auto-approve
            }
        }

        if ($LASTEXITCODE -ne 0) {
            throw "Terraform $TerraformAction failed"
        }

        Write-SuccessMessage "$StepName completed!"
    }
    finally {
        Pop-Location
    }
}

# Check terraform is installed
try {
    $null = Get-Command terraform -ErrorAction Stop
}
catch {
    Write-ErrorMessage "Terraform is not installed!"
    Write-Host "Please install Terraform: https://www.terraform.io/downloads"
    exit 1
}

Write-Header "Aaditya Designers Corp - Infrastructure Deployment"
Write-Host "Action:  $Action"
Write-Host "Profile: $Profile"
Write-Host "Project Root: $ProjectRoot"

# Confirm destroy action
if ($Action -eq "destroy") {
    Write-WarningMessage "This will DESTROY all infrastructure!"
    $confirm = Read-Host "Are you sure? (yes/no)"
    if ($confirm -ne "yes") {
        Write-Host "Aborted."
        exit 0
    }
}

# Execute based on action
try {
    if ($Action -eq "destroy") {
        # Destroy in REVERSE order
        Invoke-Terraform -Directory $InfraSetup -TerraformAction "destroy" -StepName "Step 4/4: Infrastructure Setup"
        Invoke-Terraform -Directory $VpcPeeringCross -TerraformAction "destroy" -StepName "Step 3/4: VPC Peering (Cross-Region)"
        Invoke-Terraform -Directory $VpcPeeringSame -TerraformAction "destroy" -StepName "Step 2/4: VPC Peering (Same Region)"
        Invoke-Terraform -Directory $BaseNetwork -TerraformAction "destroy" -StepName "Step 1/4: Base Network"
    }
    else {
        # Apply/Plan in FORWARD order
        Invoke-Terraform -Directory $BaseNetwork -TerraformAction $Action -StepName "Step 1/4: Base Network"
        Invoke-Terraform -Directory $VpcPeeringSame -TerraformAction $Action -StepName "Step 2/4: VPC Peering (Same Region)"
        Invoke-Terraform -Directory $VpcPeeringCross -TerraformAction $Action -StepName "Step 3/4: VPC Peering (Cross-Region)"
        Invoke-Terraform -Directory $InfraSetup -TerraformAction $Action -StepName "Step 4/4: Infrastructure Setup"
    }

    Write-Header "Deployment Complete!"
    Write-Host "All steps completed successfully!" -ForegroundColor Green
}
catch {
    Write-ErrorMessage "Deployment failed: $_"
    exit 1
}
