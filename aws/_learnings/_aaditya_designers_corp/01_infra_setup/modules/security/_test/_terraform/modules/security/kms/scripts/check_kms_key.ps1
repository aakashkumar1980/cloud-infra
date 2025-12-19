<#
.SYNOPSIS
    Check if KMS key exists by alias name
.DESCRIPTION
    Returns JSON for Terraform external data source
    Output: { "exists": "true"|"false", "key_id": "<key-id>"|"" }
#>
param()

# Read input from stdin (Terraform passes JSON)
$inputJson = [Console]::In.ReadToEnd()
$input = $inputJson | ConvertFrom-Json

$aliasName = $input.alias_name
$profile = $input.profile
$region = $input.region

try {
    # Try to describe the key using the alias
    $result = aws kms describe-key --key-id $aliasName --profile $profile --region $region --output json 2>$null

    if ($LASTEXITCODE -eq 0 -and $result) {
        $keyMetadata = ($result | ConvertFrom-Json).KeyMetadata
        $keyId = $keyMetadata.KeyId
        $keyState = $keyMetadata.KeyState

        # Only return exists=true if key is Enabled (not pending deletion)
        if ($keyState -eq "Enabled") {
            @{ exists = "true"; key_id = $keyId } | ConvertTo-Json -Compress
        } else {
            @{ exists = "false"; key_id = "" } | ConvertTo-Json -Compress
        }
    } else {
        @{ exists = "false"; key_id = "" } | ConvertTo-Json -Compress
    }
} catch {
    @{ exists = "false"; key_id = "" } | ConvertTo-Json -Compress
}
