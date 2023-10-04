# Input parameters
param(
    [string]$WorkspaceName,
    [string]$ResourceGroup,
    [string]$StoredTriggerPath
)

# Get the specified workspace
Write-Output ("Getting workspace {0} in resource group {1}" -f $WorkspaceName, $ResourceGroup)
$workspace = Get-AzSynapseWorkspace -ResourceGroupName $ResourceGroup -Name $WorkspaceName
if (-not($workspace)) { throw "Could not find workspace" }

# Import trigger references stopped before deployment
$stoppedTriggers = Import-Csv -Path $StoredTriggerPath | ForEach-Object { $_.PSObject.Properties.Value }

# Get the list of stopped triggers based on imported references
Write-Output "Getting triggers stopped before deployment"
$triggers = Get-AzSynapseTrigger -WorkspaceObject $workspace 
$triggers = $triggers | Where-Object { $stoppedTriggers -contains $_.Properties.Name }
Write-Output ("Found {0} stopped triggers" -f $triggers.Count)
if (-not($triggers)) { exit }

# Continue only if there are triggers to be found
if ($triggers.Count -gt 0) {
    Write-Output "Looping through all triggers with runtime state 'Stopped' ..."
    $triggers = $triggers | Where-Object { $_.Properties.RuntimeState -eq "Stopped" }
    Write-Output ("Found {0} triggers with 'Stopped' runtime state" -f $triggers.Count)

    foreach ($t in $triggers) {
        Write-Output ("Starting {0} ..." -f $t.Name)
        try {
            $result = Start-AzSynapseTrigger -WorkspaceName $WorkspaceName -Name $t.name -PassThru
            Write-Output ("Result of starting trigger {0}: {1}" -f $t.Name, $result)
        }

        catch {
            Write-Output ("Something went wrong with {0}" -f $t.Name)
            Write-Warning $Error[0]
            Write-Output $_
        }
    }

    Write-Output "... done"
}