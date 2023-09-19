
param (
    [string]$ParameterPath
)

$json = Get-Content -Path $ParameterPath -Raw

Write-Host $json