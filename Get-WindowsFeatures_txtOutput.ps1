$path = "D:\Development\PowerShell\_outputs\Get-WindowsFeatures"
$Servers = "serverName1","serverName2","serverName3"

If(!(Test-Path $path))
{
    New-Item -ItemType Directory -Force -Path $path
}

foreach ($Server in $Servers)
{
   Get-WindowsFeature -ComputerName $server | Where-Object Installed | Out-File $path\$server'_'$(get-date -f ddMMMyyyy).txt 
}