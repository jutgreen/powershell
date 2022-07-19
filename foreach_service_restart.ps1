# Example Windows Services
$serviceName = Get-Service -Name 'xbl*', 'xbox*'

$serviceName | ForEach {
    while ($_.Status -ne "Running") {
        Start-Service $ServiceName
        Write-Host "$($_.Name) $($_.Status)" -ForegroundColor red ' not running'
        Write-Host 'Build Agent service(s) starting'
        Start-Sleep -seconds 60
        $_.Refresh()
        if ($_.Status -eq 'Running') {
            Write-Host 'Service(s) now Running'
        } 
    }}