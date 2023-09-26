param(
    [string]$ARMTemplatePath,
    [string]$UpdatedTemplatePath,
    [string]$WorkspaceName,
    [string]$SparkPoolName
)

# Read arm template
$armTemplate = Get-Content -Path $ARMTemplatePath -Raw | ConvertFrom-Json


$initialPoolDeployed = $false

foreach ($resource in $armTemplate.resources) {
    # Only deploy the first spark pool - disable deployment for all subsequent pools
    if ($resource.type -eq "Microsoft.Synapse/workspaces/bigDataPools") {
        $conditionValue = -not $initialPoolDeployed
        Add-Member -InputObject $resource -MemberType NoteProperty -Name "condition" -Value $conditionValue
        $initialPoolDeployed = $true
    }

    # Replace old Synapse workspace references with new environment references
    $updatedDependencies = @()
    foreach ($dependency in $resource.dependsOn) {
        if ($dependency -like "*s037-cost-management*") {
            $updatedDependencies += $dependency.replace("s037-cost-management", $WorkspaceName)
            continue
        }

        if (($dependency -like "*bigDataPools*")) {
            $updatedDependencies += "[concat(variables('workspaceId'), '/bigDataPools/$SparkPoolName')]"
            continue
        }

        $updatedDependencies += $dependency
    }

    $resource.dependsOn = updatedDependencies
}

$armTemplate | ConvertTo-Json -Depth 20 | Out-File $UpdatedTemplatePath