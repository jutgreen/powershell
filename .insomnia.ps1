Clear-Host
Write-Output "Moving mouse..."
Add-Type -AssemblyName System.Windows.Forms
$WShell = New-Object -ComObject "Wscript.Shell"

$PlusOrMinus = 1
while ($true) {

$p = [System.Windows.Forms.Cursor]::Position
$x = $p.X + $PlusOrMinus
$y = $p.Y + $PlusOrMinus
[System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
Start-Sleep -Seconds 180
$PlusOrMinus *= -1
$WShell.sendkeys("{SCROLLLOCK}") # presses SCROLLLOCK key
Write-Host "Mouse moved x=$x y=$y & pressed SCROLLLOCK"
}