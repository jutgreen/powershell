$path = "D:\Development\PowerShell\_outputs\Get-WindowsFeatures"
$Servers = "serverName1","serverName2","serverName3"

If(!(Test-Path $path))
{
    New-Item -ItemType Directory -Force -Path $path
}

foreach ($Server in $Servers)
{
   Get-WindowsFeature -ComputerName $server | Where-Object Installed | Select-Object Name,DisplayName,InstallState,FeatureType,Path | Export-Csv $path\$server'_'$(get-date -f ddMMMyyyy).csv 
}