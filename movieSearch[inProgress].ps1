Clear-Host
$Mdrive = 'M:'
$dlPath = 'S:'

#$search = Read-Host -Prompt "What movie/film would you like to locate?"
$i = Get-ChildItem "$Mdrive" -Directory -Name -Include Movies*, TV*, Videos*


$search = Read-Host -Prompt "What movie/film would you like to locate?"
foreach ($_ in $i) {
    Write-Host "Searching $Mdrive\$_" -NoNewline -ForegroundColor Cyan
    $find = Get-ChildItem -Path $Mdrive\$_ -File -Name -Recurse -Include *$search*
    
    if ($null -ne $find) {
        Write-Host `n $find -ForegroundColor Green -Separator "`n"
    }
    else {
        Write-Host " | none found" -ForegroundColor Red
    }
}

#################################################################

Clear-Host
$drives = @('M:','S:')
$includes = @('Movies*','TV*','Videos*','torrent*')
$excludes = @('A','An','The')
$search = Read-Host -Prompt "What movie/film would you like to locate?"
foreach ($drive in $drives) {
    $i = Get-ChildItem $drive -Directory -Name -Include $includes -Exclude $excludes -Recurse

foreach ($_ in $i) {
    Write-Host "Searching $drive\$_\" -ForegroundColor Cyan -NoNewline
    $find = Get-ChildItem -Path $drive\$_ -File -Name -Recurse -Include *$search*
    if ($null -ne $find) {
        Write-Host " | found something!" -ForegroundColor Green -NoNewline #-Separator `n
        Write-host `t $find -ForegroundColor White -Separator "`n`t"
    }
    else {
        Write-Host " | none found" -ForegroundColor Red
    }
}}
Pause ; Clear-Host



#if search equals exclude - error