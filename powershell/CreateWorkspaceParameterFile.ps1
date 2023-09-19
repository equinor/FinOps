
param (
    [string]$ParameterPath,
    [string]$WorkspaceTemplateParamaterPath,
    [string]$workspaceName
)

# $connectionString = "Integrated Security=False;Encrypt=True;Connection Timeout=30;Data Source=tcp:s037-cost-management.sql.azuresynapse.net,1433;Initial Catalog=@{linkedService().DBName}"
# $connectionString.replace("s037-cost-management", "finops-synapse-dev")

# Write-Host $connectionString

$synapseParams = Get-Content -Path $ParameterPath -Raw | ConvertFrom-Json
$workspaceTemplateParams = Get-Content -Path $WorkspaceTemplateParamaterPath -Raw | ConvertFrom-Json

foreach ($parameter in $workspaceTemplateParams.parameters.PSObject.Properties) {
    $parameterKey = $parameter.Name
    $parameterValue = $parameter.Value.value
    Write-Host $parameterKey
    if ($parameterKey -contains "s037-cost-management") {
        Write-Host $parameterKey -ForegroundColor green
    }
}

$updatedWorkspaceParams = $workspaceTemplateParams | ConvertTo-Json