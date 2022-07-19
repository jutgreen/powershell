$emailAddress = Read-Host -Prompt 'input email address in question'
$u = Get-ADUser -Filter { EmailAddress -eq $emailAddress } ; $sam = $u.SamAccountName
Write-Host "EIN of user is $sam"