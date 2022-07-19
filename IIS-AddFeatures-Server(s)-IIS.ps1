<#
.SYNOPSIS
   Installs IIS centric Windows Features if not already installed.
.DESCRIPTION
   Checks if the requested IIS centric Windows Feature is already installed or not, if not then installed the requested Windows Feature. 
   The purpose of this script is to assist in keeping Windows Feature parity on same servers across multiple environments.
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

function AddFeatureIfMissing {
    param([string] $featureName)
    if ((Get-WindowsFeature $featureName).Installed -eq $false) {
        Add-WindowsFeature $featureName -WhatIf
    }
}
    
AddFeatureIfMissing "Web-Filtering"
AddFeatureIfMissing "Web-Windows-Auth"
AddFeatureIfMissing "Web-ASP"
AddFeatureIfMissing "Web-Net-Ext45"
AddFeatureIfMissing "Web-Asp-Net45"
AddFeatureIfMissing "Web-ISAPI-Filter"
AddFeatureIfMissing "NET-Framework-45-Features"
AddFeatureIfMissing "NET-Framework-45-Core"
AddFeatureIfMissing "NET-Framework-45-ASPNET"
AddFeatureIfMissing "NET-WCF-Services45"
AddFeatureIfMissing "NET-WCF-HTTP-Activation45"
AddFeatureIfMissing "NET-WCF-TCP-PortSharing45"
AddFeatureIfMissing "HTTP Activation"