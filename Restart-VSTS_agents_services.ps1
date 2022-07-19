<#
.SYNOPSIS
    Restart TFS Build Agents on Build Servers if agents are not running
<Overview of script>
.DESCRIPTION
  In the event that some/all Build Agents on a TFS Build Server are not running, 
  this script will check if the Build Agents associated Windows Services are running
  and if Service is not running then it will be started.
.PARAMETER <Parameter_Name>
    <Brief description of parameter input required. Repeat this attribute if required>
.INPUTS
  <Inputs if any, otherwise state None>
.OUTPUTS
  <Outputs if any, otherwise state None - example: Log file stored in C:\Windows\Temp\<name>.log>
.NOTES
  Version:        1.0
  Author:         Justin Green
  Creation Date:  28FEB2019
  Purpose/Change: Initial script development
.EXAMPLE
  <Example goes here. Repeat this attribute for more than one example>
#>

$serviceName = 'vso*','vsts*'
$serviceStatus = Get-Service -Name $serviceName | Where-Object -Property Status -ne 'Running' | ForEach-Object {$_.name + ' ' + $_.Status}
$arrService = Get-Service -Name $serviceName

if ($arrService.Status -ne 'Running') {

    Start-Service $ServiceName
    Write-Host $serviceStatus `n -ForegroundColor Red -Separator `n
    write-host 'Build Agent service(s) starting'
    Start-Sleep -seconds 60
    $arrService.Refresh()
    if ($arrService.Status -eq 'Running') {
        Write-Host 'Build Agent service(s) now Running'
    } else {
    Write-Host 'All Build Agent services are running'
    }
}