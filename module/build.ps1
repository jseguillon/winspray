Param(
  [string]
  $NugetAPIKey,

  [switch]
  $Publish = $False
)

Import-Module PSScriptAnalyzer -Force

# $results = Invoke-ScriptAnalyzer -Path .\Winspray.psm1
# if($results.Length -gt 0) {
#   Write-Error ($results | format-table | Out-String)
#   throw "error"
# }

# Write-Output "Script analysis passed."

Test-ModuleManifest .\winspray\winspray.psd1 | Out-Null
if(-not $?) {
    throw "error"
}

Write-Output "Module manifest analysis passed."

if(-not [System.String]::IsNullOrWhiteSpace($NugetAPIKey)) {
  Publish-Module -Force -Path ".\winspray" -NugetAPIKey $NugetAPIKey -Whatif:(-not $Publish) -Verbose
}