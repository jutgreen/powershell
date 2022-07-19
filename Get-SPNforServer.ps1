$server = "serverName"

Clear
Write-Host $server -ForegroundColor Cyan -NoNewline
Get-ADComputer -Identity $server -Properties * | Select-Object ServicePrincipalName, ServicePrincipalNames | Format-List
