$path = Read-Host 'Input path to web.config'
Set-Location C:\Windows\Microsoft.NET\Framework64\v4.0.30319
./aspnet_regiis -pef "connectionStrings" "$path"