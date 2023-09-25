
param (
    [string]$SubscriptionId,
    [string]$ResourceGroupName,
    [string]$WorkspaceName,
    [string]$BicepParameterPath,
    [string]$WorkspaceTemplateParamaterPath,
    [string]$UpdatedParameterPath
)

# Retrieve bicep parameters
$bicepParams = Get-Content -Path $BicepParameterPath -Raw | ConvertFrom-Json

# Retrieve Synapse workspace template parameters
$workspaceTemplateParams = Get-Content -Path $WorkspaceTemplateParamaterPath -Raw | ConvertFrom-Json

# Set necessary variables
$sparkPoolName = $bicepParams.parameters.sparkPoolName.value
$sparkPoolId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Synapse/workspaces/$WorkspaceName/bigDataPools/$sparkPoolName"
$sparkPoolEndpoint = "https://$WorkspaceName.dev.azuresynapse.net/livyApi/versions/2019-11-01-preview/sparkPools/$sparkPoolName"

# Set workspace name
$workspaceTemplateParams.parameters.workspaceName.value = $WorkspaceName

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
        $workspaceTemplateParams.parameters.$parameterKey.value = $sparkPoolName
        continue
    }

    if ($parameterKey -like "*notebookSparkPoolIdRef") {
        $workspaceTemplateParams.parameters.$parameterKey.value = $sparkPoolId
        continue
    }

    if ($parameterKey -like "*notebookSparkPoolEndpointRef") {
        $workspaceTemplateParams.parameters.$parameterKey.value = $sparkPoolEndpoint
        continue
    }

    # Override spark pool resource parameters

    if ($parameterKey -like "*sparkPoolResourceName") {
        $workspaceTemplateParams.parameters.$parameterKey.value = "$WorkspaceName/$sparkPoolName"
        continue
    }

    if ($parameterKey -like "*_delayInMinutes") {
        $workspaceTemplateParams.parameters.$parameterKey.value = $bicepParams.parameters.sparkPoolDelayInMinutes.value
        continue
    }

    if ($parameterKey -like "*_maxNodeCount") {
        $workspaceTemplateParams.parameters.$parameterKey.value = $bicepParams.parameters.sparkPoolMaxNodeCount.value
        continue
    }

    if (($parameterKey -like "*_minNodeCount") -or ($parameterKey -like "*_nodeCount")) {
        $workspaceTemplateParams.parameters.$parameterKey.value = $bicepParams.parameters.sparkPoolMinNodeCount.value
        continue
    }

    if ($parameterKey -like "*_nodeSize") {
        $workspaceTemplateParams.parameters.$parameterKey.value = $bicepParams.parameters.nodeSize.value
        continue
    }

    if ($parameterKey -like "*_sparkVersion") {
        $workspaceTemplateParams.parameters.$parameterKey.value = $bicepParams.parameters.sparkVersion.value
        continue
    }
}

$workspaceTemplateParams | ConvertTo-Json | Out-File $UpdatedParameterPath