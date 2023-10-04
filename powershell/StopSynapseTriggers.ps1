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

# Get the list of triggers if the workspace 
Write-Output "Getting all triggers in workspace"
$triggers = Get-AzSynapseTrigger -WorkspaceObject $workspace
Write-Output ("Found {0} triggers" -f $triggers.Count)
if (-not($triggers)) { exit }

# Continue only if there are triggers to be found
if ($triggers.Count -gt 0) {
    Write-Output "Looping through all triggers ..."
    $triggers = $triggers | Where-Object { $_.Properties.RuntimeState -eq "Started" }
    Write-Output ("Found {0} triggers with 'Started' runtime state" -f $triggers.Count)

    $stoppedTrigger =@()
    foreach ($t in $triggers) {
        Write-Output ("Stopping {0} ..." -f $t.Name)
        try {
            $stoppedTrigger += $t.Name
            $result = Stop-AzSynapseTrigger -WorkspaceName $WorkspaceName -Name $t.name -PassThru
            Write-Output ("Result of stopping trigger {0}: {1}" -f $t.Name, $result)
        }

        catch {
            Write-Output ("Something went wrong with {0}" -f $t.Name)
            Write-Warning $Error[0]
            Write-Output $_
        }
    }

    Write-Output ("Number of stopped triggers {0}" -f $stoppedTrigger.Count)

    $stoppedTrigger | Export-Csv -Path $StoredTriggerPath -NoTypeInformation

    Write-Output "... done"
}