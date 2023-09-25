param(
    [string]$ARMTemplatePath,
    [string]$UpdatedTemplatePath
)

# Read arm template
$armTemplate = Get-Content -Path $ARMTemplatePath -Raw | ConvertFrom-Json

# Only deploy the first spark pool - disable deployment for all subsequent pools
$initialPoolDeployed = $false

foreach ($resource in $armTemplate.resources) {
    if ($resource.type -eq "Microsoft.Synapse/workspaces/bigDataPools") {
        $resource.condition = -not $initialPoolDeployed
        $initialPoolDeployed = $true
    }
}

$armTemplate | ConvertTo-Json | Out-File $UpdatedTemplatePath