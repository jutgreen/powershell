function Get-WebAppPool {
    param([string]$name)
    if ($name) {
        Get-ChildItem IIS:\AppPools | Where-Object Name -like $name
    }
    else {
        Get-ChildItem IIS:\AppPools
    }
}
