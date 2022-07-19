#region | help
<#
.SYNOPSIS
   Menu based script to choose from list of Value Stream Front-ends for connectivity status, browser to open report in and option to email report if desired.
.DESCRIPTION
   Parses list of servers (.txt file) based on $selection during FrontendMenu interaction. $URLListFile will be populated based on $selection chosen.  
.PARAMETER <Parameter_Name>
   None
.INPUTS
   List of servers to check located at: D:\Development\PowerShell\_inputs\*.txt
.OUTPUTS
   Text file output located at: D:\Development\PowerShell\_outputs\*.txt
.NOTES
   Version:     1.0.0
   Author:      Justin Greeen
   Date:        2021SEPT16
   ChangeNotes: -initial script development
                -replacement of individual scripts for each Value Stream & environment type
                -single, menu based, script to replace 6 individual scripts
                -can now maintain single script for consistency across Value Streams
                -server .txt files can now have blank lines if desired (for easier viewing)
                -email address to send report to can be choosen via menu, typed in, or skipped
                -typed in email addresses are validated against AD; must be Pima County employee
                -Submit-SendEmail now utilizes Parameter Array for additional flexibility
   Version:     1.1.0
   ChangeNotes: -script path is generated based on environment script is run via
                -added function to collect all variables created/used by script
                    -clear these variables at beginning/ending of script
   Version:	    1.1.1
   Date:	    2021OCT15
   ChangeNotes: -function [Get-UDVariable] modifications to clear variables without errors
		        -added support for commenting out lines via # in URLListFile(s)
   Additional:  -if viewing in VSCode, issue shown for $request (PSScriptAnalyzer(PSUseDeclaredVarsMoreThanAssignments)) is a false positive
.EXAMPLE
   None 
#>
#endregion | help
# clear all variables created/used by script
Get-UDVariable | Clear-Variable
# generate path based on environment used (VSCode, ISE, PowerShell)
$scriptPath = Switch ($Host.name) {
    'Visual Studio Code Host' { Split-Path $psEditor.GetEditorContext().CurrentFile.Path }
    'Windows PowerShell ISE Host' { Split-Path -Path $psISE.CurrentFile.FullPath }
    'ConsoleHost' { $PSScriptRoot }
}

#region | inputs/outputs/arrays/definedVariables
# remote file paths (foolproof)
$remotePath = "\\central.pima.gov\centralfs\ITD2\Relationship_Apps\Public Services\DB SysAdmin Team\_Shared Data\PowerShell\Development\PowerShell"
# base file paths
$inputPath = "$scriptPath\_inputs"
If (!(Test-Path $inputPath)) {
    New-Item -ItemType Directory -Force -Path $inputPath
    Copy-Item -Path $remotePath\*frontends*.txt -Destination $inputPath\
}

if ($inputPath -and $outputPath) {
    
}

$outputPath = "$scriptPath\_outputs"
# output HTML file location
$outputFile = "$outputPath\$($selection)_$(Get-Date -Format yyyyMMdd_HHmm).html"
# browser choices
$browserList = @('msedge', 'chrome')
# value stream lists
$vsList = @('admin_frontends-nonprod', 'admin_frontends-prod', 'cedjle_frontends-nonprod', 'cedjle_frontends-prod', 'pw_frontends-nonprod', 'pw_frontends-prod')
# email generation
$fromList = @('AdminVS_noreply@pima.gov', 'cedjleVS_noreply@pima.gov', 'PublicWorksVS_noreply@pima.gov')
$recipList = @('aisha.stoner@pima.gov', 'jason.larpenteur@pima.gov', 'john.bushman@pima.gov', 'justin.green@pima.gov', 'michael.bender@pima.gov', 'michael.green@pima.gov', 'nicholas.zaffino@pima.gov', 'peter.iadevaia@pima.gov', 'shaun.harris@pima.gov')
$subjectList = @('Admin Value Stream Non-Prod', 'Admin Value Stream Prod', 'CED/JLE Value Stream Non-Prod', 'CED/JLE Value Stream Prod', 'Public Works Value Stream Non-Prod', 'Public Works Value Stream Prod')
#endregion | inputs/outputs/arrays/definedVariables

#region | Functions
function Get-UDVariable {
    Get-Variable | Where-Object { (@(
                "FormatEnumerationLimit",
                "MaximumAliasCount",
                "MaximumDriveCount",
                "MaximumErrorCount",
                "MaximumFunctionCount",
                "MaximumVariableCount",
                "PGHome",
                "PGSE",
                "PGUICulture",
                "PGVersionTable",
                "PROFILE",
                "psEditor",
                "PSSessionOption"
            ) -notcontains $_.name) -and `
        (([psobject].Assembly.GetType('System.Management.Automation.SpecialVariables').GetFields('NonPublic,Static') | Where-Object FieldType -EQ ([string]) | ForEach-Object GetValue $null)) -notcontains $_.name
    }
}
function Show-BrowserMenu {
    param (
        [string]$Title = 'Choose A Browser'
    )
    Clear-Host
    Write-Host "======= $Title =======" `n
    Write-Host "1: Press '1' for Microsoft Edge."
    Write-Host "2: Press '2' for Google Chrome."
    Write-Host "0: Press '0' for neither (email report only)."
    Write-Host "Q: Press 'Q' to Quit." `n
}
function Show-FrontendMenu {
    param (
        [string]$Title = 'Validate Value Stream Front-ends'
    )
    Clear-Host
    Write-Host "=========== $Title ===========" `n
    Write-Host "1: Press '1' for Admin Non-Prod."
    Write-Host "2: Press '2' for Admin Prod."
    Write-Host "3: Press '3' for CED/JLE Non-Prod."
    Write-Host "4: Press '4' for CED/JLE Prod."
    Write-Host "5: Press '5' for Public Works Non-Prod."
    Write-Host "6: Press '6' for Public Works Prod."
    Write-Host "Q: Press 'Q' to Quit." `n
}
function Show-EmailRecipientsMenu {
    param (
        [string]$Title = "Email yo'self (or whatever, I don't care)"
    )
    Clear-Host
    Write-Host "======== $Title ========" `n
    Write-Host "1: Press '1' for Aisha Stoner."
    Write-Host "2: Press '2' for Jason Larpenteur."
    Write-Host "3: Press '3' for John Bushman."
    Write-Host "4: Press '4' for Justin Green."
    Write-Host "5: Press '5' for Michael Bender."
    Write-Host "6: Press '6' for Michael Green."
    Write-Host "7: Press '7' for Nicholas Zaffino."
    Write-Host "8: Press '8' for Peter Iadevaia."
    Write-Host "9: Press '9' for Shaun Harris." 
    Write-Host "Q: Press 'Q' to Quit." `n
    Write-Host "Not the human you're looking for? Type in an email address." -ForegroundColor White; Write-Host "HINT: must be a Pima County employee" `n -ForegroundColor Yellow
}
function Submit-SendEmail {
    $WarningPreference = 'SilentlyContinue'
    $msgParams = @{
        To         = $recip 
        From       = $from
        Subject    = "Website Availability Report | $subject Front-Ends"
        Body       = $outputReport
        BodyAsHtml = $true
        SmtpServer = "159.233.7.250"
    }
    if ([string]::IsNullOrWhiteSpace($recip)) {
        Clear-Host
        Write-Host "No email will be sent. "-ForegroundColor Red
        Pause ; Clear-Host
    }
    else {
        Send-MailMessage @msgParams
        Clear-Host
        Write-Host `n"Email will be sent to $recip. " `n -ForegroundColor Green
        Pause ; Clear-Host
    }
}
#endregion | Functions

#region | Show Browser & Frontend Menus
# Show-BrowserMenu
do {
    Show-BrowserMenu
    $browser = Read-Host "Select which browser to use"
    switch ($browser) {
        '1' {
            $browser = $($browserList[0])
        }
        '2' {
            $browser = $($browserList[1])
        }
        '0' {
            break
        }
        'q' {
            return
        }
        Default {
            Write-Host "You did not select a valid option, try again" -ForegroundColor Red
            Pause ; Clear-Host
        }  
    }
} until ((($browser -in $($browserList)) -or ($browser -eq '0')) -or ($browser -eq 'q'))
# Show-FrontendMenu
do {
    Show-FrontendMenu
    $selection = Read-Host "Select Value Stream environment to validate front-ends"
    switch ($selection) {
        '1' {
            Clear-Host ; Write-Host "Validating $($subjectList[0]) URLs" -ForegroundColor Magenta
            $selection = $($vsList[0])
            $URLListFile = "$inputPath\$selection.txt"
        }
        '2' {
            Clear-Host ; Write-Host "Validating $($subjectList[1]) URLs" -ForegroundColor Magenta
            $selection = $($vsList[1])
            $URLListFile = "$inputPath\$selection.txt"
        }
        '3' {
            Clear-Host ; Write-Host "Validating $($subjectList[2]) URLs" -ForegroundColor Magenta
            $selection = $($vsList[2])
            $URLListFile = "$inputPath\$selection.txt"
        }
        '4' {
            Clear-Host ; Write-Host "Validating $($subjectList[3]) URLs" -ForegroundColor Magenta
            $selection = $($vsList[3])
            $URLListFile = "$inputPath\$selection.txt"
        }
        '5' {
            Clear-Host ; Write-Host "Validating $($subjectList[4]) URLs" -ForegroundColor Magenta
            $selection = $($vsList[4])
            $URLListFile = "$inputPath\$selection.txt"
        }
        '6' {
            Clear-Host ; Write-Host "Validating $($subjectList[5]) URLs" -ForegroundColor Magenta
            $selection = $($vsList[5])
            $URLListFile = "$inputPath\$selection.txt"
        }
        'q' {
            return
        } Default {
            Write-Host "You did not select a valid option, try again." -ForegroundColor Red
            Pause ; Clear-Host
        } 
    } 
} until (($selection -in $($vsList)) -or ($selection -eq 'q'))
#endregion | Show Browser & Frontend Menus

#region | generate email 'from' address and 'subject' content based on $selection value
If ($selection -eq $vsList[0]) { ($from = $fromList[0]) -and ($subject = $subjectList[0]) | Out-Null }
ElseIf ($selection -eq $vsList[1]) { ($from = $fromList[0]) -and ($subject = $subjectList[1]) | Out-Null }
If ($selection -eq $vsList[2]) { ($from = $fromList[1]) -and ($subject = $subjectList[2]) | Out-Null }
ElseIf ($selection -eq $vsList[3]) { ($from = $fromList[1]) -and ($subject = $subjectList[3]) | Out-Null }
If ($selection -eq $vsList[4]) { ($from = $fromList[2]) -and ($subject = $subjectList[4]) | Out-Null }
ElseIf ($selection -eq $vsList[5]) { ($from = $fromList[2]) -and ($subject = $subjectList[5]) | Out-Null }
#endregion | generate email 'from' address and 'subject' content based on $selection value

#region | validate selected URL list for response status/time & create report
$URLList = Get-Content $URLListFile -ErrorAction SilentlyContinue | Where-Object { $_.Trim() -ne '' -and $_.Trim() -notmatch '^#.*' }
$result = @()
Foreach ($uri in $URLList) { 
    $time = try { 
        # request URI and measure response time
        Write-Host "Checking $uri"
        $null = $request
        $result1 = Measure-Command { $request = Invoke-WebRequest -Uri $uri }
        $result1.TotalMilliseconds
    }  
    catch { 
        <# if exception is generated, display status code from Execption.Response property
        (e.g. 500 server error or 404 not found) #> 
        $request = $_.Exception.Response 
        $time = -1 
    }   
    $result += [PSCustomObject] @{ 
        Time              = Get-Date; 
        Uri               = $uri; 
        StatusCode        = [int] $request.StatusCode; 
        StatusDescription = $request.StatusDescription; 
        ResponseLength    = $request.RawContentLength;  
        TimeTaken         = if ($null -ne $time) { $([math]::Round($time, 2)).ToString() + "ms" };
    } 
}
# create html output 
if ($null -ne $result) { 
    # output HTML file location
    $outputFile = "$outputPath\$($selection)_$(Get-Date -Format yyyyMMdd_HHmm).html"
    $outputReport = 
    "<html><head>
        <link rel=""icon"" type=""image/x-icon"" href=""images/favicon.ico"">
        <title>Website Availability Report</title>
        <body background-color:peachpuff><font color =""#99000"" face=""Arial""><h2>Website Availability Report | $subject</h2></font><h4>$(Get-Date -UFormat "%A %B %d, %Y %r")</h4><table border=1 cellpadding=3 cellspacing=0><tr bgcolor=lightblue align=center><td><b>URL</b></td><td><b>StatusCode</b></td><td><b>StatusDescription</b></td><td><b>ResponseLength</b></td><td><b>TimeTaken</b></td></tr>" 
    Foreach ($entry in $result) { 
        if ($entry.StatusCode -eq "401") {
            $outputReport += "<tr bgcolor=yellow>" 
        }
        elseif ($entry.StatusCode -eq "500" -And $entry.uri -Like "http://*/ABICluster*") {
            $outputReport += $($entry.StatusDescription = "ABI OK")
        }
        elseif ($entry.StatusCode -eq "200" -And $entry.ResponseLength -igt 1 -And $entry.uri -Like "https://pimainsights*") {
            $outputReport += $($entry.StatusDescription = "OK")
        }
        elseif ($entry.StatusCode -ne "200" -or $null -eq $entry.ResponseLength) { 
            $outputReport += "<tr bgcolor=red>" 
        }
        else { 
            $outputReport += "<tr>"
        } 
        $outputReport += "<td><a href ='$($entry.uri)' target='_blank'>$($entry.uri)</a></td><td align=center>$($entry.StatusCode)</td><td align=center>$($entry.StatusDescription)</td><td align=center>$($entry.ResponseLength)</td><td align=right>$($entry.TimeTaken)</td></tr>"
    } 
    $outputReport += "</table></body></html>" 
} $outputReport | Out-File $outputFile
#endregion | validate selected URL list for response status/time & create report

Clear-Host

#region | Show-EmailRecipientsMenu
do {
    Show-EmailRecipientsMenu
    #Clear-Variable $clearVariables
    Clear-Variable selection
    $selection = Read-Host -Prompt "Select/Input email address to send report to [ENTER to skip]"
    switch ($selection) {
        '' {
            if ([string]::IsNullOrEmpty($selection.ToString())) {
                Write-Host ""
                break
            } 
        }
        '1' {
            $selection = $($recipList[0])
            $recip = $selection
            break
        }
        '2' {
            $selection = $($recipList[1])
            $recip = $selection
            break
        }
        '3' {
            $selection = $($recipList[2])
            $recip = $selection
            break
        }
        '4' {
            $selection = $($recipList[3])
            $recip = $selection
            break
        }
        '5' {
            $selection = $($recipList[4])
            $recip = $selection
            break
        }
        '6' {
            $selection = $($recipList[5])
            $recip = $selection
            break
        }
        '7' {
            $selection = $($recipList[6])
            $recip = $selection
            break
        }
        '8' {
            $selection = $($recipList[7])
            $recip = $selection
            break
        }
        '9' {
            $recip = $selection
            $selection = $($recipList[8])
            break
        }
        'q' {
            return
        } 
        ($selection -as [System.Net.Mail.MailAddress]) {
            $i = ([ADSISearcher] "(UserPrincipalName=$selection)").FindOne()
            if ($null -ne $i) {
                $validEmail = ($i.Properties).userprincipalname
                $recip = $validEmail
                continue
            }
            else {
                $i = $null
                $validEmail = $null
                Write-Host "Nice try, that is not a Pima County employee, try again." -ForegroundColor Red
                Pause
            }
        }
        Default {
            Write-Host "You did not select a valid option, try again." -ForegroundColor Red
            Pause
        }
    }
} until ((($selection -in $($recipList)) -or ($selection -eq 'q')) -or ($selection -eq $validEmail) -or ([string]::IsNullOrEmpty($selection.ToString())))
#endregion | Show-EmailRecipientsMenu

Submit-SendEmail

if ($browser -ne "0") { Start-Process -FilePath $browser -ArgumentList "`"$outputFile`"" }

# delete output HTML file(s) if more than 7 days old
Get-ChildItem "$outputPath" -Recurse | Where-Object { ($_.Name -like "*_frontends-*" -and $_.Extension -eq ".html") -and $_.LastWriteTime -lt (Get-Date).AddDays(-7) } | Remove-Item
# clear all variables created/used by script
Get-UDVariable | Clear-Variable