<#
.SYNOPSIS
   Grabs last 3 days of logs for appName on serverName, compresses and emails to user
.DESCRIPTION
   Run with A-Account. Script will grab last 3 days of logs for appName on serverName. 
   Copies logs locally to D:\temp\appNameLogs\, compresses to .zip, emails to recipient(s) listed in $To & $cc variables, then cleans up the temp directory. 
.PARAMETER <Parameter_Name>
   None
.INPUTS
   n/a
.OUTPUTS
   .zip archive emailed to $To & $cc variables, original output to temp directory is cleaned up automatically
.NOTES
   Version:        1.0
   Author:         Justin Greeen
   Date:           2021JAN28
   Purpose/Change: Initial script development

   Version:        1.1
   Author:         Justin Greeen
   Date:           2022APR13
   Purpose/Change: restructured to send email via newer versions of PowerShell
   Note:           still not ideal solution as Send-MailMessage is 'obsolete'
.EXAMPLE
   None
#>

$destDir = "D:\temp\appNameLogs"
$filterDate = (Get-Date).AddDays(-2)

New-Item -ItemType Directory -Force -Path $destDir
Get-ChildItem -Path "\\serverName\E$\appName\Logs" -Recurse -Exclude Archive | Where-Object { $_.LastWriteTime -ge $filterDate } | Copy-Item -Destination $destDir -Force -PassThru -Verbose
Compress-Archive -Path $destDir -Force -DestinationPath $destDir\appNameLogs.zip

#region | email generation
$recipList = @('human1@domain.com', 'human2@domain.com', 'human3@domain.com', 'distributionList@domain.com')
$fromList = @('serverName@domain.com')
#endregion

function Submit-SendEmail {
   $WarningPreference = 'SilentlyContinue'
   $msgParams = @{
      To         = $recipList[2]
      Cc         = $recipList[0,1,3]
      From       = $fromList[0]
      Subject    = "3 days of logs from serverName"
      Body       = ".zip archive attached"
      BodyAsHtml = $true
      Attachment = "$destDir\appNameLogs.zip"
      SMTPServer = "147.234.3.200" #fake smtp server
   }
   if ([string]::IsNullOrWhiteSpace($recipList)) {
      Clear-Host
      Write-Host "No email will be sent. "-ForegroundColor Red
      Pause ; Clear-Host
   }
   else {
      Send-MailMessage @msgParams
      Clear-Host
      Write-Host "3 days of logs from serverName has been sent as .zip archive. " -ForegroundColor green
      Write-Host `n"This result will auto clear in 5 seconds..." 
      Start-Sleep -s 5
   }
}
#endregion | Functions

Submit-SendEmail
Remove-Item $destDir -Recurse
Clear-Host
