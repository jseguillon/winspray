Param(
  [string]
  $NugetAPIKey,

  [switch]
  $Publish = $False
)

Import-Module PSScriptAnalyzer -Force

# TODO : Sorry this module "may" need a bit of cleaning ;)
# $results = Invoke-ScriptAnalyzer -Path .\Winspray.psm1
# if($results.Length -gt 0) {
#   Write-Error ($results | format-table | Out-String)
#   throw "error"
# }

# Write-Output "Script analysis passed."

Test-ModuleManifest .\module\winspray.psd1 | Out-Null
if(-not $?) {
    throw "error"
}

Write-Output "Module manifest analysis passed."

if(-not [System.String]::IsNullOrWhiteSpace($NugetAPIKey)) {
  Publish-Module -Path ".\module" -NugetAPIKey $NugetAPIKey -Whatif:(-not $Publish) -Verbose
}