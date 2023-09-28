
param (
    [string]$WorkspaceName,
    [string]$WorkspaceTemplateParameterPath,
)


# Retrieve Synapse workspace template parameters
$workspaceTemplateParams = Get-Content -Path $WorkspaceTemplateParameterPath -Raw | ConvertFrom-Json

foreach ($parameter in $workspaceTemplateParams.parameters.PSObject.Properties) {
    $parameterKey = $parameter.Name
    $parameterValue = $parameter.Value.value

    # Override data lake references

    if ($parameterKey -like "*concat(parameters('workspaceName')*") {
        # $workspaceTemplateParams.parameters.$parameterKey.value = $parameterValue.replace("s037-cost-management", $WorkspaceName)
        # continue
        Write-Output ("$parameterKey")
    }
}

# $workspaceTemplateParams | ConvertTo-Json | Out-File $UpdatedParameterPath