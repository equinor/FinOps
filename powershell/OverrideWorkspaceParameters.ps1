
param (
    [string]$WorkspaceName,
    [string]$BicepParameterPath,
    [string]$WorkspaceTemplateParamaterPath
)

# Retrieve bicep parameters
$bicepParams = Get-Content -Path $BicepParameterPath -Raw | ConvertFrom-Json
$sparkPoolNameKey = "sparkPoolName"
$sparkPoolIdKey = "sparkPoolId"
$sparkPoolEndpointKey = "sparkPoolEndpoint"
$sparkPoolNodeSizeKey = "nodeSize"
$sparkPoolMinNodeCountKey = "sparkPoolMinNodeCount"
$sparkPoolMaxNodeCountKey = "sparkPoolMaxNodeCount"
$sparkPoolDelayInMinutesKey = "sparkPoolDelayInMinutes"
$sparkVersionKey = "sparkVersion"

# Retrieve Synapse workspace template parameters
$workspaceTemplateParams = Get-Content -Path $WorkspaceTemplateParamaterPath -Raw | ConvertFrom-Json

# Set workspace name
$workspaceKey = "workspaceName"
$workspaceTemplateParams.parameters.$workspaceKey.value = $WorkspaceName

foreach ($parameter in $workspaceTemplateParams.parameters.PSObject.Properties) {
    $parameterKey = $parameter.Name
    $parameterValue = $parameter.Value.value

    # Override data lake references

    if ($parameterKey -like "s037-cost-management*") {
        $workspaceTemplateParams.parameters.$parameterKey.value = $parameterValue.replace("s037-cost-management", $WorkspaceName)
        continue
    }

    # Override spark pool references in notebook artifacts

    if ($parameterKey -like "*notebookSparkPoolNameRef") {
        $workspaceTemplateParams.parameters.$parameterKey.value = $bicepParams.parameters.$sparkPoolNameKey.value
        continue
    }

    if ($parameterKey -like "*notebookSparkPoolIdRef") {
        $workspaceTemplateParams.parameters.$parameterKey.value = $bicepParams.parameters.$sparkPoolIdKey.value
        continue
    }

    if ($parameterKey -like "*notebookSparkPoolEndpointRef") {
        $workspaceTemplateParams.parameters.$parameterKey.value = $bicepParams.parameters.$sparkPoolEndpointKey.value
        continue
    }

    # Override spark pool resource parameters

    if ($parameterKey -like "*sparkPoolResourceName") {
        $workspaceTemplateParams.parameters.$parameterKey.value = "$WorkspaceName/$($bicepParams.parameters.$sparkPoolNameKey.value)"
        continue
    }

    if ($parameterKey -like "*_delayInMinutes") {
        $workspaceTemplateParams.parameters.$parameterKey.value = $bicepParams.parameters.$sparkPoolDelayInMinutesKey.value
        continue
    }

    if ($parameterKey -like "*_maxNodeCount") {
        $workspaceTemplateParams.parameters.$parameterKey.value = $bicepParams.parameters.$sparkPoolMaxNodeCountKey.value
        continue
    }

    if (($parameterKey -like "*_minNodeCount") -or ($parameterKey -like "*_nodeCount")) {
        $workspaceTemplateParams.parameters.$parameterKey.value = $bicepParams.parameters.$sparkPoolMinNodeCountKey.value
        continue
    }

    if ($parameterKey -like "*_nodeSize") {
        $workspaceTemplateParams.parameters.$parameterKey.value = $bicepParams.parameters.$sparkPoolNodeSizeKey.value
        continue
    }

    if ($parameterKey -like "*_sparkVersion") {
        $workspaceTemplateParams.parameters.$parameterKey.value = $bicepParams.parameters.$sparkVersionKey.value
        continue
    }
}

$updatedWorkspaceParams | Set-Content -Path "./test.json"

$updatedWorkspaceParams = $workspaceTemplateParams | ConvertTo-Json

#Write-Host $updatedWorkspaceParams

$test = Get-Content -Path "./test.json" -Raw | ConvertTo-Json

Write-Host "Test"
Write-Host $test