$Profilepowershellget = "$env:userprofile\AppData\Local\Microsoft\Windows\PowerShell\PowerShellGet\"
 
if(-Not(Test-Path $Profilepowershellget)){
    New-Item $Profilepowershellget -ItemType Directory
}

$Url = 'https://dist.nuget.org/win-x86-commandline/v5.1.0/nuget.exe'
$OutputFile =  "$Profilepowershellget\nuget.exe"
$StartTime = Get-Date

$wc = New-Object System.Net.WebClient
$wc.DownloadFile($Url, $OutputFile)

Write-Output "Time taken: $((Get-Date).Subtract($StartTime).Seconds) second(s)"

Unblock-File $OutputFile 