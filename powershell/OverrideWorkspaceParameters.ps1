
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
    }

    # Override spark pool references in notebook artifacts

    if ($parameterKey -like "*notebookSparkPoolNameRef") {
        $workspaceTemplateParams.parameters.$parameterKey.value = $bicepParams.parameters.$sparkPoolNameKey.value
    }

    if ($parameterKey -like "*notebookSparkPoolIdRef") {
        $workspaceTemplateParams.parameters.$parameterKey.value = $bicepParams.parameters.$sparkPoolIdKey.value
    }

    if ($parameterKey -like "*notebookSparkPoolEndpointRef") {
        $workspaceTemplateParams.parameters.$parameterKey.value = $bicepParams.parameters.$sparkPoolEndpointKey.value
    }
}

$updatedWorkspaceParams = $workspaceTemplateParams | ConvertTo-Json

Write-Host $updatedWorkspaceParams
