# Input parameters
param(
    [string]$WorkspaceName,
    [string]$ResourceGroup
)

$ErrorActionPreference = "Stop"

# Get the specified workspace
Write-Output ("Getting workspace {0} in resource group {1}" -f $WorkspaceName, $ResourceGroup)
$workspace = Get-AzSynapseWorkspace -ResourceGroupName $ResourceGroup -Name $WorkspaceName
if (-not($workspace)) { throw "Could not find workspace" }

# Get the list of stopped triggers based on imported references
Write-Output "Getting all triggers in workspace"
$triggers = Get-AzSynapseTrigger -WorkspaceObject $workspace
Write-Output ("Found {0} triggers" -f $triggers.Count)
if (-not($triggers)) { exit }

# Continue only if there are triggers to be found
if ($triggers.Count -gt 0) {
    Write-Output "Looping through all triggers with runtime state 'Stopped' ..."
    $triggers = $triggers | Where-Object { $_.Properties.RuntimeState -eq "Stopped" }
    Write-Output ("Found {0} triggers with 'Stopped' runtime state" -f $triggers.Count)

    $startedTriggers =@()
    foreach ($t in $triggers) {
        Write-Output ("Starting {0} ..." -f $t.Name)
        try {
            $startedTriggers += $t.Name
            $result = Start-AzSynapseTrigger -WorkspaceName $WorkspaceName -Name $t.name -PassThru
            Write-Output ("Result of starting trigger {0}: {1}" -f $t.Name, $result)
        }

        catch {
            # Capture and display the error message
            $errorMessage = $_.Exception.Message
            Write-Error "Error: $errorMessage"
        }
    }

    Write-Output ("Number of started triggers {0}" -f $stoppedTrigger.Count)

    Write-Output "... done"
}