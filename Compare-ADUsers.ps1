# enter first AD user 
$user1 = Read-Host "Enter the identity of the first AD User" 

# enter second AD user 
$user2 = Read-Host "Enter the identity of the second AD User" 

# change to working directory path
Set-Location D:\Development\PowerShell

# set AD user object types
$objects = @{
    ReferenceObject = .\Get-UserGroupMembership.ps1 $user1 | Select-Object group
    DifferenceObject = .\Get-UserGroupMembership.ps1 $user2 | Select-Object group
}

# compare AD user objects
Compare-Object @objects #-IncludeEqual -ExcludeDifferent

