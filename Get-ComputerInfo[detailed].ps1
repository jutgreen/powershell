$remoteSystem = "localhost" #default "localhost"

$computerSystem = Get-CimInstance CIM_ComputerSystem -ComputerName $remoteSystem
$computerBIOS = Get-CimInstance CIM_BIOSElement -ComputerName $remoteSystem
$computerOS = Get-CimInstance CIM_OperatingSystem -ComputerName $remoteSystem
$computerCPU = Get-CimInstance CIM_Processor -ComputerName $remoteSystem
$computerHDD = Get-CimInstance Win32_LogicalDisk -Filter "Description = 'Local Fixed Disk'" -ComputerName $remoteSystem
Clear-Host

Write-Host "System Information for: " $computerSystem.Name -BackgroundColor DarkCyan
"Manufacturer: " + $computerSystem.Manufacturer
"Model: " + $computerSystem.Model
"Serial Number: " + $computerBIOS.SerialNumber
"CPU: " + $computerCPU.Name

foreach ($hdd in $computerHDD){
"HDD " + $hdd.DeviceID + "\ Capacity: "  + "{0:N2}" -f ($hdd.Size/1GB) + "GB"
"HDD " + $hdd.DeviceID + "\ Space: " + "{0:P2}" -f ($hdd.FreeSpace/$hdd.Size) + " Free (" + "{0:N2}" -f ($hdd.FreeSpace/1GB) + "GB)"
}

"RAM: " + "{0:N2}" -f ($computerSystem.TotalPhysicalMemory/1GB) + "GB"
"Operating System: " + $computerOS.caption + ", Service Pack: " + $computerOS.ServicePackMajorVersion
"User logged In: " + $computerSystem.UserName
"Last Reboot: " + $computerOS.LastBootUpTime
