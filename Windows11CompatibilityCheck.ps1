#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Windows 11 Compatibility Information Gathering Script
.DESCRIPTION
    Gathers comprehensive system information to diagnose Windows 11 upgrade compatibility issues.
    This script checks TPM, CPU, UEFI/BIOS mode, Secure Boot, RAM, storage, and other relevant details.
.NOTES
    Must be run as Administrator
#>

# Set up output formatting - Save to current directory instead of Desktop
$OutputFile = ".\Win11_Compatibility_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$Separator = "=" * 80

# Function to write both to console and file
function Write-Output-Both {
    param([string]$Message)
    Write-Host $Message
    Add-Content -Path $OutputFile -Value $Message
}

# Clear file if it exists
if (Test-Path $OutputFile) { Remove-Item $OutputFile }

# Header
Write-Output-Both $Separator
Write-Output-Both "WINDOWS 11 COMPATIBILITY CHECK REPORT"
Write-Output-Both "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Output-Both "Computer Name: $env:COMPUTERNAME"
Write-Output-Both $Separator
Write-Output-Both ""

# ============================================================================
# TPM INFORMATION
# ============================================================================
Write-Output-Both "TPM (TRUSTED PLATFORM MODULE) STATUS"
Write-Output-Both $("-" * 80)

try {
    $TPM = Get-Tpm -ErrorAction Stop
    Write-Output-Both "TPM Present: $($TPM.TpmPresent)"
    Write-Output-Both "TPM Ready: $($TPM.TpmReady)"
    Write-Output-Both "TPM Enabled: $($TPM.TpmEnabled)"
    Write-Output-Both "TPM Activated: $($TPM.TpmActivated)"
    
    # Get TPM version using WMI
    $TPMVersion = Get-WmiObject -Namespace "Root\CIMv2\Security\MicrosoftTpm" -Class Win32_Tpm -ErrorAction SilentlyContinue
    if ($TPMVersion) {
        $SpecVersion = $TPMVersion.SpecVersion
        Write-Output-Both "TPM Spec Version: $SpecVersion"
        
        if ($SpecVersion -like "2.0*" -or $SpecVersion -like "2.*") {
            Write-Output-Both "✓ TPM 2.0 DETECTED - Meets Windows 11 requirement"
        } elseif ($SpecVersion -like "1.2*") {
            Write-Output-Both "✗ TPM 1.2 DETECTED - Does NOT meet Windows 11 requirement (needs TPM 2.0)"
        } else {
            Write-Output-Both "⚠ Unknown TPM version - Please verify manually"
        }
    }
} catch {
    Write-Output-Both "✗ ERROR: Unable to detect TPM - TPM may not be present or enabled in BIOS"
    Write-Output-Both "Error details: $($_.Exception.Message)"
}
Write-Output-Both ""

# ============================================================================
# CPU INFORMATION
# ============================================================================
Write-Output-Both "CPU INFORMATION"
Write-Output-Both $("-" * 80)

$CPU = Get-WmiObject -Class Win32_Processor
Write-Output-Both "CPU Name: $($CPU.Name.Trim())"
Write-Output-Both "CPU Manufacturer: $($CPU.Manufacturer)"
Write-Output-Both "CPU Architecture: $($CPU.AddressWidth)-bit"
Write-Output-Both "Number of Cores: $($CPU.NumberOfCores)"
Write-Output-Both "Number of Logical Processors: $($CPU.NumberOfLogicalProcessors)"
Write-Output-Both "Max Clock Speed: $($CPU.MaxClockSpeed) MHz"
Write-Output-Both "CPU Socket: $($CPU.SocketDesignation)"
Write-Output-Both "CPU Family: $($CPU.Family)"
Write-Output-Both "CPU Model: $($CPU.Model)"
Write-Output-Both "CPU Stepping: $($CPU.Stepping)"

# Check for virtualization support
Write-Output-Both "Virtualization Enabled in Firmware: $($CPU.VirtualizationFirmwareEnabled)"

Write-Output-Both ""
Write-Output-Both "NOTE: Windows 11 requires:"
Write-Output-Both "  - Intel: 8th generation (Coffee Lake) or newer"
Write-Output-Both "  - AMD: Ryzen 2000 series or newer"
Write-Output-Both "  Please verify your CPU model against Microsoft's compatibility list"
Write-Output-Both ""

# ============================================================================
# MOTHERBOARD INFORMATION
# ============================================================================
Write-Output-Both "MOTHERBOARD INFORMATION"
Write-Output-Both $("-" * 80)

$Board = Get-WmiObject -Class Win32_BaseBoard
Write-Output-Both "Manufacturer: $($Board.Manufacturer)"
Write-Output-Both "Product: $($Board.Product)"
Write-Output-Both "Version: $($Board.Version)"
Write-Output-Both "Serial Number: $($Board.SerialNumber)"
Write-Output-Both ""

# ============================================================================
# BIOS/UEFI INFORMATION
# ============================================================================
Write-Output-Both "BIOS/UEFI INFORMATION"
Write-Output-Both $("-" * 80)

$BIOS = Get-WmiObject -Class Win32_BIOS
Write-Output-Both "BIOS Manufacturer: $($BIOS.Manufacturer)"
Write-Output-Both "BIOS Version: $($BIOS.SMBIOSBIOSVersion)"
Write-Output-Both "BIOS Release Date: $($BIOS.ReleaseDate)"

# Check if system is UEFI or Legacy BIOS
try {
    $FirmwareType = (Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\SecureBoot\State" -ErrorAction Stop).UEFISecureBootEnabled
    Write-Output-Both "Firmware Type: UEFI"
    Write-Output-Both "✓ UEFI MODE - Meets Windows 11 requirement"
} catch {
    Write-Output-Both "Firmware Type: Legacy BIOS"
    Write-Output-Both "✗ LEGACY BIOS DETECTED - Windows 11 requires UEFI"
}

# Check Secure Boot status
try {
    $SecureBoot = Confirm-SecureBootUEFI -ErrorAction Stop
    if ($SecureBoot) {
        Write-Output-Both "Secure Boot: ENABLED"
        Write-Output-Both "✓ Secure Boot is enabled - Meets Windows 11 requirement"
    } else {
        Write-Output-Both "Secure Boot: DISABLED"
        Write-Output-Both "⚠ Secure Boot is supported but disabled - Can be enabled in BIOS"
    }
} catch {
    Write-Output-Both "Secure Boot: NOT SUPPORTED or system is in Legacy BIOS mode"
    Write-Output-Both "✗ Secure Boot not available - Windows 11 requires Secure Boot capability"
}
Write-Output-Both ""

# ============================================================================
# MEMORY (RAM) INFORMATION
# ============================================================================
Write-Output-Both "MEMORY (RAM) INFORMATION"
Write-Output-Both $("-" * 80)

$TotalRAM = [math]::Round((Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
Write-Output-Both "Total Physical Memory: $TotalRAM GB"

if ($TotalRAM -ge 4) {
    Write-Output-Both "✓ RAM meets Windows 11 minimum requirement (4GB)"
} else {
    Write-Output-Both "✗ RAM does NOT meet Windows 11 minimum requirement (4GB needed)"
}

$MemoryModules = Get-WmiObject -Class Win32_PhysicalMemory
Write-Output-Both "Number of Memory Modules: $($MemoryModules.Count)"
foreach ($Module in $MemoryModules) {
    $Size = [math]::Round($Module.Capacity / 1GB, 2)
    Write-Output-Both "  - Module: $Size GB @ $($Module.Speed) MHz (Slot: $($Module.DeviceLocator))"
}
Write-Output-Both ""

# ============================================================================
# STORAGE INFORMATION
# ============================================================================
Write-Output-Both "STORAGE INFORMATION"
Write-Output-Both $("-" * 80)

$Disks = Get-WmiObject -Class Win32_DiskDrive
foreach ($Disk in $Disks) {
    $SizeGB = [math]::Round($Disk.Size / 1GB, 2)
    Write-Output-Both "Disk: $($Disk.Model)"
    Write-Output-Both "  Size: $SizeGB GB"
    Write-Output-Both "  Interface: $($Disk.InterfaceType)"
    Write-Output-Both "  Partitions: $($Disk.Partitions)"
    
    # Get partition style (GPT or MBR)
    $DiskNumber = $Disk.Index
    try {
        $PartitionStyle = (Get-Disk -Number $DiskNumber -ErrorAction Stop).PartitionStyle
        Write-Output-Both "  Partition Style: $PartitionStyle"
        
        if ($PartitionStyle -eq "GPT") {
            Write-Output-Both "  ✓ GPT partition style - Compatible with UEFI"
        } else {
            Write-Output-Both "  ✗ MBR partition style - May need conversion to GPT for UEFI boot"
        }
    } catch {
        Write-Output-Both "  Partition Style: Unable to determine"
    }
    Write-Output-Both ""
}

$SystemDrive = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='$env:SystemDrive'"
$FreeSpaceGB = [math]::Round($SystemDrive.FreeSpace / 1GB, 2)
Write-Output-Both "System Drive ($env:SystemDrive) Free Space: $FreeSpaceGB GB"

if ($FreeSpaceGB -ge 64) {
    Write-Output-Both "✓ Sufficient free space for Windows 11 (64GB minimum)"
} else {
    Write-Output-Both "⚠ May need more free space for Windows 11 installation (64GB recommended)"
}
Write-Output-Both ""

# ============================================================================
# GRAPHICS INFORMATION
# ============================================================================
Write-Output-Both "GRAPHICS INFORMATION"
Write-Output-Both $("-" * 80)

$GPU = Get-WmiObject -Class Win32_VideoController
foreach ($Card in $GPU) {
    Write-Output-Both "Graphics Card: $($Card.Name)"
    Write-Output-Both "  Driver Version: $($Card.DriverVersion)"
    Write-Output-Both "  Video Memory: $([math]::Round($Card.AdapterRAM / 1GB, 2)) GB"
    Write-Output-Both "  Resolution: $($Card.CurrentHorizontalResolution) x $($Card.CurrentVerticalResolution)"
}
Write-Output-Both ""
Write-Output-Both "NOTE: Windows 11 requires DirectX 12 compatible graphics with WDDM 2.0 driver"
Write-Output-Both ""

# ============================================================================
# OPERATING SYSTEM INFORMATION
# ============================================================================
Write-Output-Both "CURRENT OPERATING SYSTEM"
Write-Output-Both $("-" * 80)

$OS = Get-WmiObject -Class Win32_OperatingSystem
Write-Output-Both "OS: $($OS.Caption)"
Write-Output-Both "Version: $($OS.Version)"
Write-Output-Both "Build: $($OS.BuildNumber)"
Write-Output-Both "Architecture: $($OS.OSArchitecture)"
Write-Output-Both "Install Date: $([Management.ManagementDateTimeConverter]::ToDateTime($OS.InstallDate))"
Write-Output-Both ""

# ============================================================================
# SUMMARY
# ============================================================================
Write-Output-Both $Separator
Write-Output-Both "SUMMARY - KEY WINDOWS 11 REQUIREMENTS"
Write-Output-Both $Separator
Write-Output-Both ""
Write-Output-Both "Windows 11 requires ALL of the following:"
Write-Output-Both "  1. TPM 2.0 (Trusted Platform Module)"
Write-Output-Both "  2. UEFI firmware (not Legacy BIOS)"
Write-Output-Both "  3. Secure Boot capability"
Write-Output-Both "  4. Compatible CPU (Intel 8th gen+ or AMD Ryzen 2000+)"
Write-Output-Both "  5. 4GB RAM minimum (8GB recommended)"
Write-Output-Both "  6. 64GB storage minimum"
Write-Output-Both "  7. DirectX 12 compatible graphics"
Write-Output-Both "  8. 720p display (9 inches or larger)"
Write-Output-Both ""
Write-Output-Both "NEXT STEPS:"
Write-Output-Both "  - Review the report above to identify which requirements are not met"
Write-Output-Both "  - Check BIOS/UEFI settings for:"
Write-Output-Both "    * TPM/fTPM/PTT settings (may need to be enabled)"
Write-Output-Both "    * Secure Boot settings"
Write-Output-Both "    * UEFI boot mode (may need to disable Legacy/CSM mode)"
Write-Output-Both "  - Consider hardware upgrades if CPU or motherboard is incompatible"
Write-Output-Both ""
Write-Output-Both $Separator
Write-Output-Both "Report saved to: $(Resolve-Path $OutputFile)"
Write-Output-Both $Separator

# Open the report file
Write-Host ""
Write-Host "Opening report file..." -ForegroundColor Green
Start-Process notepad.exe $OutputFile