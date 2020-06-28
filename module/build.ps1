Param(
  [string]
  $NugetAPIKey,

  [switch]
  $Publish = $False
)

Import-Module PSScriptAnalyzer -Force

$Tag = git describe
$ModuleVersion = $Tag.Split("-")[0]
$PreRelease = $Tag.Split("-")[1]
$ReleaseNote = git tag -l --format='%(contents)' $Tag
$ReleaseNoteAsString = $ReleaseNote -join "`r`n"
(Get-Content -path .\winspray.psd1.tpl -Raw).Replace("MODULE_VERSION", "$ModuleVersion").Replace("MODULE_PRE_RELEASE", "$PreRelease").Replace("MODULE_RELEASE_NOTE", "$ReleaseNoteAsString") > .\winspray\winspray.psd1

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
