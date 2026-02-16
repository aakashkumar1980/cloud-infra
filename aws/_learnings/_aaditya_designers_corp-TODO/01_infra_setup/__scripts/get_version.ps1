# Extract component_version from locals.tf and company from tags.yaml
# Outputs: VERSION|COMPANY

# Get version from locals.tf
$localsContent = Get-Content -Path "locals.tf" -Raw
$version = ""
if ($localsContent -match 'component_version\s*=\s*"([^"]+)"') {
    $version = $matches[1]
}

# Get company from tags.yaml (3 levels up to aws/configs)
$tagsPath = "..\..\..\configs\tags.yaml"
$company = ""
if (Test-Path $tagsPath) {
    $tagsContent = Get-Content -Path $tagsPath -Raw
    if ($tagsContent -match 'company:\s*(\S+)') {
        $company = $matches[1]
    }
}

Write-Output "$version|$company"
