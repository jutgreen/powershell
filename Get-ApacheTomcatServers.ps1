$servers = Get-Content D:\Development\PowerShell\_inputs\servers-all.txt | Where-Object {$_.Trim() -ne ''}

Clear-Host
ForEach ($server in $servers){
    Write-Host $server -ForegroundColor Cyan
    Invoke-Command -ComputerName $server {Get-Service -Name Tomcat* -ErrorAction SilentlyContinue}
}
