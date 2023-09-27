# Input parameters
param(
    [string]$WorkspaceName,
    [string]$ResourceGroup,
    [string]$Action
)

# Get the specified workspace
Write-Output ("Getting workspace {0} in resource group {1}" -f $WorkspaceName, $ResourceGroup)
$workspace = Get-AzSynapseWorkspace -ResourceGroupName $ResourceGroup -Name $WorkspaceName
if (-not($workspace)) { throw "Could not find workspace" }

# Get the list of triggers if the workspace 
Write-Output "Getting triggers"
$triggers = Get-AzSynapseTrigger -WorkspaceObject $workspace
Write-Output ("Found {0} triggers" -f $triggers.Count)
if (-not($triggers)) { exit }

# Continue only if there are triggers to be found
if ($triggers.Count -gt 0) {
    $runtimeState = $action -eq "stop" ? "Stopped" : "Started"

    Write-Output "Looping through triggers ..."
    $triggers = $triggers | Where-Object { $_.Properties.RuntimeState -eq $runtimeState }
    Write-Output ("Found {0} triggers" -f $triggers.Count)

    foreach ($t in $triggers) {
        Write-Output ("{0} {1} ..." -f $action -eq "stop" ? "Stopping" : "Starting", $t.Name);
        try {
            
            if ($action -eq "stop") {
                $result = Stop-AzSynapseTrigger -WorkspaceName $WorkspaceName -Name $t.name
                Write-Output ("Result of stopping trigger {0}: {1}" -f $t.Name, $result)
            }

            if ($action -eq "start") {
                $result = Start-AzSynapseTrigger -WorkspaceName $WorkspaceName -Name $t.name
                Write-Output ("Result of starting trigger {0}: {1}" -f $t.Name, $result)
            }
        }

        catch {
            Write-Output ("Something went wrong with {0}" -f $t.Name)
            Write-Output $_
        }
    }

    Write-Output "... done"
}