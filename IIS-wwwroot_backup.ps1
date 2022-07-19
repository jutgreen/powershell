<#
.SYNOPSIS
   Script to backup and decrypt current configuration files for Hedgehog web server configuration. 
.DESCRIPTION
   Creates backup of HedgehogDisclosureMaintenance.exe.config & web.config files and decrypts. Intended to be used as a comparison reference during Disclosure Site upgrades.
.PARAMETER <Parameter_Name>
   None
.INPUTS
   None
.OUTPUTS
   Backup of config files stored in: E:\archive\[date]_temp
.NOTES
   Version:        1.0
   Author:         Justin Greeen
   Creation Date:  2019JAN10
   Purpose/Change: Initial script development
.EXAMPLE
   None
#>

# create [date]_temp directory if doesn't already exist
$foldername = (Get-Date).tostring("yyyyMMdd") + "wwwroot"
$path = "E:\iis_backup\$foldername"
if (!(Test-Path $path)) {
    New-Item -ItemType Directory -Force -Path $path
}
# copy existing config files to temp directory and decrypt
Copy-Item 'C:\inetpub\wwwroot' $path
