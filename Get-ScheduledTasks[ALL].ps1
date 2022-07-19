$remoteComputer = "serverName"

schtasks /query /s $remoteComputer /v /fo csv | ConvertFrom-CSV |
Select-Object -Property "HostName","TaskName","Task To Run","Comment","Run As User","Status","Stop Task If Runs X Hours and X Mins","Start Time","Repeat: Every","Repeat: Until: Time","Repeat: Until: Duration","Repeat: Stop If Still Running" |
Where-Object -FilterScript {$_.TaskName -ne "Microsoft*"} | Export-Csv D:\Development\PowerShell\_outputs\ScheduledJobsExport_$remoteComputer'_'$(get-date -f ddMMMyyyy).csv