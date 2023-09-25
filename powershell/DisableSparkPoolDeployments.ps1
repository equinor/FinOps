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
        $conditionValue = -not $initialPoolDeployed
        Add-Member -InputObject $resource -MemberType NoteProperty -Name "condition" -Value $conditionValue
        $initialPoolDeployed = $true
    }
}

$armTemplate | ConvertTo-Json -Depth 20 | Out-File $UpdatedTemplatePath