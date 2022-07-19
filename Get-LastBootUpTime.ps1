<#
.SYNOPSIS
   Checks last boot up time for specified list of servers.
.DESCRIPTION
   Parses list of servers based on text file supplied for $server and checks last boot up time for each server in list.
.PARAMETER <Parameter_Name>
   None
.INPUTS
   List of servers to check located at: D:\Development\PowerShell\_inputs\servers-all.txt
.OUTPUTS
   Terminal output
.NOTES
   Version:        1.0
   Author:         Justin Greeen
   Creation Date:  2020MAR04
   Purpose/Change: Initial script development
  
.EXAMPLE
   None
#>

$server = Get-Content "D:\Development\PowerShell\_inputs\servers-all.txt"
Get-CimInstance -ComputerName $server -ClassName win32_operatingsystem | Select-Object csname, lastbootuptime | Sort-Object csname | Format-Table -AutoSize # | Out-File D:\Last_Boot-$Server.txt