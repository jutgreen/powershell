Import-Module ActiveDirectory
$userlist = Get-Content "D:\PDS-ADusers.txt"

foreach ($username in $userlist) {
    Write-Host `n$username
    $grplist = (Get-ADUser $username –Properties MemberOf).MemberOf
    foreach ($group in $grplist) {
        (Get-ADGroup $group).name 
    }
}