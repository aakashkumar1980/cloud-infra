# Extract component_version from locals.tf
$content = Get-Content -Path "..\locals.tf" -Raw
if ($content -match 'component_version\s*=\s*"([^"]+)"') {
    Write-Output $matches[1]
}
