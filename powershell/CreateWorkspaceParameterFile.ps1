
param (
    [string]$WorkspaceName,
    [string]$ParameterPath,
    [string]$WorkspaceTemplateParamaterPath
)

$synapseParams = Get-Content -Path $ParameterPath -Raw | ConvertFrom-Json
$workspaceTemplateParams = Get-Content -Path $WorkspaceTemplateParamaterPath -Raw | ConvertFrom-Json

foreach ($parameter in $workspaceTemplateParams.parameters.PSObject.Properties) {
    $parameterKey = $parameter.Name
    $parameterValue = $parameter.Value.value
    if ($parameterKey -like "s037-cost-management*") {
        $workspaceTemplateParams.parameters.$parameterKey.value = $parameterValue.replace("s037-cost-management", $WorkspaceName)
    }
}

$updatedWorkspaceParams = $workspaceTemplateParams | ConvertTo-Json

Write-Host $updatedWorkspaceParams