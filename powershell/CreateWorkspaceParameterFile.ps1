
param (
    [string]$WorkspaceName,
    [string]$BicepParameterPath,
    [string]$WorkspaceTemplateParamaterPath
)

$bicepParams = Get-Content -Path $BicepParameterPath -Raw | ConvertFrom-Json
$workspaceTemplateParams = Get-Content -Path $WorkspaceTemplateParamaterPath -Raw | ConvertFrom-Json

# Set workspace name
$workspaceKey = "workspaceName"
$workspaceTemplateParams.parameters.$WorkspaceKey.value = $WorkspaceName

foreach ($parameter in $workspaceTemplateParams.parameters.PSObject.Properties) {
    $parameterKey = $parameter.Name
    $parameterValue = $parameter.Value.value

    if ($parameterKey -like "s037-cost-management*") {
        $workspaceTemplateParams.parameters.$parameterKey.value = $parameterValue.replace("s037-cost-management", $WorkspaceName)
    }

    if ($parameterKey -like "*sparkPoolName") {
        
    }
}

$updatedWorkspaceParams = $workspaceTemplateParams | ConvertTo-Json

Write-Host $updatedWorkspaceParams