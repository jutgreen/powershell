$serviceName = 'xbl*', 'xbox*'
$serviceStatus = Get-Service -Name $serviceName | where -Property Status -ne 'Running' | foreach {$_.name + ' ' + $_.Status}
$arrService = Get-Service -Name $serviceName

if ($arrService.Status -ne 'Running') {

    Start-Service $ServiceName
    Write-Host $serviceStatus `n -ForegroundColor Red -Separator `n
    Write-Host 'Xbox service(s) starting' `n
    Start-Sleep -seconds 30
    $arrService.Refresh()
    if ($arrService.Status -eq 'Running') {
        Write-Host 'Xbox service(s) now Running'
    }
}
else {
    Write-Host 'Xbox services are running'
}