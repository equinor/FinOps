param(
    [string]$ARMTemplatePath,
    [string]$UpdatedTemplatePath,
    [string]$WorkspaceName,
    [string]$BicepParameterPath
)

# Read arm template
$armTemplate = Get-Content -Path $ARMTemplatePath -Raw | ConvertFrom-Json

# Read bicep parameters
$bicepParams = Get-Content -Path $BicepParameterPath -Raw | ConvertFrom-Json
$sparkPoolName = $bicepParams.parameters.sparkPoolName.value

$initialPoolDeployed = $false

foreach ($resource in $armTemplate.resources) {
    # Only deploy the first spark pool - disable deployment for all subsequent pools
    if ($resource.type -eq "Microsoft.Synapse/workspaces/bigDataPools") {
        $resource.name = "[concat(parameters('workspaceName'), '/$sparkPoolName')]"
        $conditionValue = -not $initialPoolDeployed
        Add-Member -InputObject $resource -MemberType NoteProperty -Name "condition" -Value $conditionValue
        $initialPoolDeployed = $true
    }

    # Update named resources including a reference to the Synapse workspace
    if ($resource.name -like "*s037-cost-management*") {
        $resource.name = $resource.name.replace("s037-cost-management", $WorkspaceName)
    }

    # Replace old Synapse workspace references with new environment references
    $updatedDependencies = @()
    foreach ($dependency in $resource.dependsOn) {
        if ($dependency -like "*s037-cost-management*") {
            $updatedDependencies += $dependency.replace("s037-cost-management", $WorkspaceName)
            continue
        }

        if (($dependency -like "*bigDataPools*")) {
            $updatedDependencies += "[concat(variables('workspaceId'), '/bigDataPools/$sparkPoolName')]"
            continue
        }

        $updatedDependencies += $dependency
    }

    $resource.dependsOn = $updatedDependencies
}

$armTemplate | ConvertTo-Json -Depth 20 | Out-File $UpdatedTemplatePath