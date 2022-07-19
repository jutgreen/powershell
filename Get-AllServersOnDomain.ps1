<#
.SYNOPSIS
   Gathers all Servers in the domain that the script is run from. Saves to $servers variable.
.DESCRIPTION
   Gathers all Servers in the domain that the script is run from. Saves to $servers variable. 
.PARAMETER <Parameter_Name>
   None
.INPUTS
   n/a
.OUTPUTS
   n/a
.NOTES
   Version:        1.0
   Author:         Justin Greeen
   Creation Date:  2020MAR04
   Purpose/Change: Initial script development
.EXAMPLE
   None
#>

$servers = Get-ADComputer -Filter {(OperatingSystem -like "*Server*") -and (Enabled -eq $true)} -Properties OperatingSystem | Select-Object -ExpandProperty Name | Sort-Object