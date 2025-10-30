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
    
    # Get TPM version using CIM
    $TPMVersion = Get-CimInstance -Namespace "Root\CIMv2\Security\MicrosoftTpm" -ClassName Win32_Tpm -ErrorAction SilentlyContinue
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

$CPU = Get-CimInstance -ClassName Win32_Processor
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
try {
    $VirtEnabled = $CPU.VirtualizationFirmwareEnabled
    if ($null -ne $VirtEnabled) {
        Write-Output-Both "Virtualization Enabled in Firmware: $VirtEnabled"
    } else {
        Write-Output-Both "Virtualization Enabled in Firmware: Unable to determine"
    }
} catch {
    Write-Output-Both "Virtualization Enabled in Firmware: Unable to determine"
}

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

$Board = Get-CimInstance -ClassName Win32_BaseBoard
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

$BIOS = Get-CimInstance -ClassName Win32_BIOS
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

$TotalRAM = [math]::Round((Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
Write-Output-Both "Total Physical Memory: $TotalRAM GB"

if ($TotalRAM -ge 4) {
    Write-Output-Both "✓ RAM meets Windows 11 minimum requirement (4GB)"
} else {
    Write-Output-Both "✗ RAM does NOT meet Windows 11 minimum requirement (4GB needed)"
}

$MemoryModules = Get-CimInstance -ClassName Win32_PhysicalMemory
Write-Output-Both "Number of Memory Modules: $($MemoryModules.Count)"

# Function to convert SMBIOSMemoryType to readable format
function Get-MemoryType {
    param([int]$TypeCode)
    switch ($TypeCode) {
        0 { return "Unknown" }
        1 { return "Other" }
        2 { return "DRAM" }
        3 { return "Synchronous DRAM" }
        4 { return "Cache DRAM" }
        5 { return "EDO" }
        6 { return "EDRAM" }
        7 { return "VRAM" }
        8 { return "SRAM" }
        9 { return "RAM" }
        10 { return "ROM" }
        11 { return "Flash" }
        12 { return "EEPROM" }
        13 { return "FEPROM" }
        14 { return "EPROM" }
        15 { return "CDRAM" }
        16 { return "3DRAM" }
        17 { return "SDRAM" }
        18 { return "SGRAM" }
        19 { return "RDRAM" }
        20 { return "DDR" }
        21 { return "DDR2" }
        22 { return "DDR2 FB-DIMM" }
        24 { return "DDR3" }
        25 { return "FBD2" }
        26 { return "DDR4" }
        27 { return "LPDDR" }
        28 { return "LPDDR2" }
        29 { return "LPDDR3" }
        30 { return "LPDDR4" }
        31 { return "Logical non-volatile device" }
        32 { return "HBM" }
        33 { return "HBM2" }
        34 { return "DDR5" }
        35 { return "LPDDR5" }
        default { return "Unknown ($TypeCode)" }
    }
}

foreach ($Module in $MemoryModules) {
    $Size = [math]::Round($Module.Capacity / 1GB, 2)
    $MemType = Get-MemoryType -TypeCode $Module.SMBIOSMemoryType
    $Speed = if ($Module.Speed) { "$($Module.Speed) MHz" } else { "Unknown" }
    Write-Output-Both "  - Module: $Size GB $MemType @ $Speed (Slot: $($Module.DeviceLocator))"
}
Write-Output-Both ""

# ============================================================================
# STORAGE INFORMATION
# ============================================================================
Write-Output-Both "STORAGE INFORMATION"
Write-Output-Both $("-" * 80)

# Get the system drive letter to identify boot disk
$SystemDriveLetter = $env:SystemDrive
$BootDiskNumber = $null

# Find which physical disk contains the system drive
try {
    $SystemPartition = Get-Partition | Where-Object { $_.DriveLetter -eq $SystemDriveLetter.TrimEnd(':') } | Select-Object -First 1
    if ($SystemPartition) {
        $BootDiskNumber = $SystemPartition.DiskNumber
    }
} catch {
    # Fallback: try to find boot partition
    $BootDiskNumber = (Get-Disk | Where-Object { $_.IsBoot -eq $true } | Select-Object -First 1).Number
}

$Disks = Get-CimInstance -ClassName Win32_DiskDrive
$DiskIndex = 0

foreach ($Disk in $Disks) {
    $SizeGB = [math]::Round($Disk.Size / 1GB, 2)
    $DiskNumber = $Disk.Index

    # Determine if this is the boot disk
    $IsBootDisk = ($DiskNumber -eq $BootDiskNumber)
    $BootIndicator = if ($IsBootDisk) { " [BOOT DISK]" } else { "" }

    Write-Output-Both "Disk ${DiskNumber}: $($Disk.Model)${BootIndicator}"
    Write-Output-Both "  Size: $SizeGB GB"

    # Detect drive type (SSD vs HDD)
    try {
        $PhysicalDisk = Get-PhysicalDisk -DeviceNumber $DiskNumber -ErrorAction Stop
        $MediaType = $PhysicalDisk.MediaType

        switch ($MediaType) {
            "SSD" {
                Write-Output-Both "  Drive Type: SSD (Solid State Drive)"
                Write-Output-Both "  ✓ SSD detected - Excellent performance for Windows 11"
            }
            "HDD" {
                Write-Output-Both "  Drive Type: HDD (Hard Disk Drive)"
                Write-Output-Both "  ⚠ HDD detected - Consider upgrading to SSD for better performance"
            }
            "SCM" {
                Write-Output-Both "  Drive Type: SCM (Storage Class Memory)"
            }
            default {
                Write-Output-Both "  Drive Type: $MediaType"
            }
        }

        # Detect bus type (NVMe, SATA, USB, etc.)
        $BusType = $PhysicalDisk.BusType
        switch ($BusType) {
            "NVMe" {
                Write-Output-Both "  Bus Type: NVMe"
                Write-Output-Both "  ✓ NVMe interface - Maximum performance"
            }
            "SATA" {
                Write-Output-Both "  Bus Type: SATA"
                if ($MediaType -eq "SSD") {
                    Write-Output-Both "  ⚠ SATA SSD - Good performance (NVMe would be faster)"
                }
            }
            "USB" {
                Write-Output-Both "  Bus Type: USB (External Drive)"
                if ($IsBootDisk) {
                    Write-Output-Both "  ⚠ WARNING: Booting from USB drive (not recommended for Windows 11)"
                }
            }
            "RAID" {
                Write-Output-Both "  Bus Type: RAID"
            }
            default {
                Write-Output-Both "  Bus Type: $BusType"
            }
        }

        # Get SMART health status
        $HealthStatus = $PhysicalDisk.HealthStatus
        $OperationalStatus = $PhysicalDisk.OperationalStatus

        Write-Output-Both "  Health Status: $HealthStatus"

        if ($HealthStatus -eq "Healthy") {
            Write-Output-Both "  ✓ Drive is healthy (SMART status OK)"
        } elseif ($HealthStatus -eq "Warning") {
            Write-Output-Both "  ⚠ WARNING: Drive health issue detected - Backup data immediately!"
        } elseif ($HealthStatus -eq "Unhealthy") {
            Write-Output-Both "  ✗ CRITICAL: Drive is failing - Replace immediately and backup data!"
        } else {
            Write-Output-Both "  Operational Status: $OperationalStatus"
        }

    } catch {
        Write-Output-Both "  Drive Type: Unable to determine"
        Write-Output-Both "  Interface: $($Disk.InterfaceType)"
    }

    Write-Output-Both "  Partitions: $($Disk.Partitions)"

    # Get partition style (GPT or MBR)
    try {
        $PartitionStyle = (Get-Disk -Number $DiskNumber -ErrorAction Stop).PartitionStyle
        Write-Output-Both "  Partition Style: $PartitionStyle"

        if ($PartitionStyle -eq "GPT") {
            Write-Output-Both "  ✓ GPT partition style - Compatible with UEFI"
        } else {
            Write-Output-Both "  ✗ MBR partition style - May need conversion to GPT for UEFI boot"
            if ($IsBootDisk) {
                Write-Output-Both "  ⚠ Boot disk is MBR - Conversion to GPT required for Windows 11 UEFI boot"
            }
        }
    } catch {
        Write-Output-Both "  Partition Style: Unable to determine"
    }

    Write-Output-Both ""
    $DiskIndex++
}

# System drive free space information
$SystemDrive = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$SystemDriveLetter'"
$FreeSpaceGB = [math]::Round($SystemDrive.FreeSpace / 1GB, 2)
$TotalSpaceGB = [math]::Round($SystemDrive.Size / 1GB, 2)
Write-Output-Both "System Drive ($SystemDriveLetter) Space:"
Write-Output-Both "  Total: $TotalSpaceGB GB"
Write-Output-Both "  Free: $FreeSpaceGB GB"
Write-Output-Both "  Used: $([math]::Round($TotalSpaceGB - $FreeSpaceGB, 2)) GB"

if ($FreeSpaceGB -ge 64) {
    Write-Output-Both "✓ Sufficient free space for Windows 11 (64GB minimum)"
} else {
    Write-Output-Both "⚠ May need more free space for Windows 11 installation (64GB recommended)"
}
Write-Output-Both ""

# ============================================================================
# NETWORK ADAPTER INFORMATION
# ============================================================================
Write-Output-Both "NETWORK ADAPTER INFORMATION"
Write-Output-Both $("-" * 80)

# Get all network adapters
$NetworkAdapters = Get-NetAdapter -ErrorAction SilentlyContinue

if ($NetworkAdapters) {
    # Check for Wi-Fi adapters
    $WiFiAdapters = $NetworkAdapters | Where-Object { $_.InterfaceDescription -match "Wi-Fi|Wireless|802\.11" }

    if ($WiFiAdapters) {
        Write-Output-Both "Wi-Fi Adapters:"
        foreach ($Adapter in $WiFiAdapters) {
            Write-Output-Both "  Name: $($Adapter.Name)"
            Write-Output-Both "  Description: $($Adapter.InterfaceDescription)"
            Write-Output-Both "  Status: $($Adapter.Status)"

            # Detect Wi-Fi version (802.11ax = Wi-Fi 6/6E, 802.11ac = Wi-Fi 5, etc.)
            $WiFiStandard = "Unknown"
            $AdapterDesc = $Adapter.InterfaceDescription

            if ($AdapterDesc -match "802\.11ax|Wi-Fi 6E|AX|WiFi 6E") {
                $WiFiStandard = "Wi-Fi 6E (802.11ax)"
                Write-Output-Both "  Wi-Fi Version: $WiFiStandard"
                Write-Output-Both "  ✓ Wi-Fi 6E - Latest standard with 6GHz support, excellent for Windows 11"
            } elseif ($AdapterDesc -match "Wi-Fi 6|AX\d+|802\.11ax") {
                $WiFiStandard = "Wi-Fi 6 (802.11ax)"
                Write-Output-Both "  Wi-Fi Version: $WiFiStandard"
                Write-Output-Both "  ✓ Wi-Fi 6 - Modern standard, excellent for Windows 11"
            } elseif ($AdapterDesc -match "802\.11ac|AC\d+|Wi-Fi 5") {
                $WiFiStandard = "Wi-Fi 5 (802.11ac)"
                Write-Output-Both "  Wi-Fi Version: $WiFiStandard"
                Write-Output-Both "  ⚠ Wi-Fi 5 - Good performance, but Wi-Fi 6 recommended for best experience"
            } elseif ($AdapterDesc -match "802\.11n|Wi-Fi 4") {
                $WiFiStandard = "Wi-Fi 4 (802.11n)"
                Write-Output-Both "  Wi-Fi Version: $WiFiStandard"
                Write-Output-Both "  ⚠ Wi-Fi 4 - Older standard, consider upgrading to Wi-Fi 6"
            } elseif ($AdapterDesc -match "802\.11g") {
                $WiFiStandard = "Wi-Fi 3 (802.11g)"
                Write-Output-Both "  Wi-Fi Version: $WiFiStandard"
                Write-Output-Both "  ⚠ Wi-Fi 3 - Very old standard, upgrade recommended"
            } else {
                Write-Output-Both "  Wi-Fi Version: Unable to determine from adapter name"
            }

            # Get link speed if connected
            if ($Adapter.Status -eq "Up") {
                $LinkSpeed = $Adapter.LinkSpeed
                Write-Output-Both "  Current Link Speed: $LinkSpeed"
            }

            Write-Output-Both ""
        }
    } else {
        Write-Output-Both "Wi-Fi: No Wi-Fi adapter detected"
        Write-Output-Both ""
    }

    # Check for Ethernet adapters
    $EthernetAdapters = $NetworkAdapters | Where-Object {
        $_.InterfaceDescription -match "Ethernet|Gigabit|LAN|Network Controller" -and
        $_.InterfaceDescription -notmatch "Wireless|Wi-Fi|Bluetooth|Virtual|VMware|Hyper-V|VPN"
    }

    if ($EthernetAdapters) {
        Write-Output-Both "Ethernet Adapters:"
        foreach ($Adapter in $EthernetAdapters) {
            Write-Output-Both "  Name: $($Adapter.Name)"
            Write-Output-Both "  Description: $($Adapter.InterfaceDescription)"
            Write-Output-Both "  Status: $($Adapter.Status)"

            # Get link speed
            $LinkSpeed = $Adapter.LinkSpeed
            if ($LinkSpeed) {
                Write-Output-Both "  Link Speed: $LinkSpeed"

                # Parse speed and provide feedback
                if ($LinkSpeed -match "(\d+\.?\d*)\s*(Gbps|Mbps)") {
                    $SpeedValue = [decimal]$matches[1]
                    $SpeedUnit = $matches[2]

                    if ($SpeedUnit -eq "Gbps") {
                        if ($SpeedValue -ge 10) {
                            Write-Output-Both "  ✓ 10 Gbps or higher - Excellent network performance"
                        } elseif ($SpeedValue -ge 2.5) {
                            Write-Output-Both "  ✓ 2.5/5 Gbps - Very good for modern networking"
                        } elseif ($SpeedValue -ge 1) {
                            Write-Output-Both "  ✓ 1 Gbps (Gigabit) - Good network performance"
                        }
                    } elseif ($SpeedUnit -eq "Mbps" -and $SpeedValue -lt 1000) {
                        Write-Output-Both "  ⚠ Below 1 Gbps - Consider upgrading to Gigabit Ethernet"
                    }
                }
            } else {
                Write-Output-Both "  Link Speed: Not connected or unavailable"
            }

            Write-Output-Both ""
        }
    } else {
        Write-Output-Both "Ethernet: No Ethernet adapter detected"
        Write-Output-Both ""
    }
} else {
    Write-Output-Both "Unable to retrieve network adapter information"
    Write-Output-Both ""
}

# Check for Bluetooth
Write-Output-Both "Bluetooth:"
try {
    # Method 1: Check via WMI for Bluetooth devices
    $BluetoothDevices = Get-CimInstance -Namespace "root\cimv2" -ClassName Win32_PnPEntity -ErrorAction SilentlyContinue |
                        Where-Object { $_.Name -match "Bluetooth" -and $_.Status -eq "OK" }

    if ($BluetoothDevices) {
        Write-Output-Both "  ✓ Bluetooth adapter detected"

        # Try to get Bluetooth version
        $BluetoothVersion = "Unknown"
        foreach ($Device in $BluetoothDevices) {
            $DeviceName = $Device.Name

            # Detect Bluetooth version from device name
            if ($DeviceName -match "5\.\d+|Bluetooth 5") {
                $BluetoothVersion = "Bluetooth 5.x"
                Write-Output-Both "  Version: $BluetoothVersion"
                Write-Output-Both "  ✓ Bluetooth 5.x - Modern standard with improved range and speed"
                break
            } elseif ($DeviceName -match "4\.\d+|Bluetooth 4|LE") {
                $BluetoothVersion = "Bluetooth 4.x (Low Energy supported)"
                Write-Output-Both "  Version: $BluetoothVersion"
                Write-Output-Both "  ✓ Bluetooth 4.x - Good for Windows 11"
                break
            } elseif ($DeviceName -match "3\.\d+|Bluetooth 3") {
                $BluetoothVersion = "Bluetooth 3.x"
                Write-Output-Both "  Version: $BluetoothVersion"
                Write-Output-Both "  ⚠ Bluetooth 3.x - Older version, consider upgrade for better device support"
                break
            }
        }

        if ($BluetoothVersion -eq "Unknown") {
            Write-Output-Both "  Version: Unable to determine from device information"
            Write-Output-Both "  Device(s): $($BluetoothDevices[0].Name)"
        }
    } else {
        Write-Output-Both "  ⚠ No Bluetooth adapter detected"
        Write-Output-Both "    Bluetooth is useful for wireless peripherals (mice, keyboards, headphones)"
    }
} catch {
    Write-Output-Both "  Unable to determine Bluetooth status"
}
Write-Output-Both ""

# ============================================================================
# BATTERY INFORMATION (For Laptops)
# ============================================================================
Write-Output-Both "BATTERY INFORMATION"
Write-Output-Both $("-" * 80)

# Check if system has a battery (laptop/tablet)
$Battery = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue

if ($Battery) {
    Write-Output-Both "Battery Status: Battery detected (Laptop/Tablet)"
    Write-Output-Both ""

    foreach ($Batt in $Battery) {
        Write-Output-Both "Battery: $($Batt.Name)"
        Write-Output-Both "  Chemistry: $($Batt.Chemistry)"
        Write-Output-Both "  Status: $($Batt.Status)"

        # Get design capacity and full charge capacity
        $DesignCapacity = $Batt.DesignCapacity
        $FullChargeCapacity = $Batt.FullChargeCapacity

        if ($DesignCapacity -and $FullChargeCapacity) {
            Write-Output-Both "  Design Capacity: $DesignCapacity mWh"
            Write-Output-Both "  Full Charge Capacity: $FullChargeCapacity mWh"

            # Calculate battery health percentage
            $BatteryHealth = [math]::Round(($FullChargeCapacity / $DesignCapacity) * 100, 1)
            Write-Output-Both "  Battery Health: ${BatteryHealth}%"

            # Provide feedback based on health
            if ($BatteryHealth -ge 90) {
                Write-Output-Both "  ✓ Excellent battery health (90-100%)"
            } elseif ($BatteryHealth -ge 80) {
                Write-Output-Both "  ✓ Good battery health (80-89%)"
            } elseif ($BatteryHealth -ge 60) {
                Write-Output-Both "  ⚠ Fair battery health (60-79%) - Battery is degrading"
            } elseif ($BatteryHealth -ge 40) {
                Write-Output-Both "  ⚠ Poor battery health (40-59%) - Consider battery replacement soon"
            } else {
                Write-Output-Both "  ✗ Critical battery health (below 40%) - Battery replacement recommended"
            }

            # Calculate capacity loss
            $CapacityLoss = $DesignCapacity - $FullChargeCapacity
            $CapacityLossPercent = [math]::Round((($DesignCapacity - $FullChargeCapacity) / $DesignCapacity) * 100, 1)
            Write-Output-Both "  Capacity Lost: $CapacityLoss mWh (${CapacityLossPercent}% degradation)"
        } else {
            Write-Output-Both "  Battery capacity information not available"
        }

        # Get current charge level
        $EstimatedChargeRemaining = $Batt.EstimatedChargeRemaining
        if ($null -ne $EstimatedChargeRemaining) {
            Write-Output-Both "  Current Charge Level: ${EstimatedChargeRemaining}%"
        }

        # Get estimated runtime
        $EstimatedRunTime = $Batt.EstimatedRunTime
        if ($EstimatedRunTime -and $EstimatedRunTime -ne 71582788) {
            # 71582788 means "calculating" or "unknown"
            $Hours = [math]::Floor($EstimatedRunTime / 60)
            $Minutes = $EstimatedRunTime % 60
            Write-Output-Both "  Estimated Runtime: ${Hours}h ${Minutes}m"
        }

        Write-Output-Both ""
    }

    # Additional battery report recommendation
    Write-Output-Both "NOTE: For detailed battery history, run 'powercfg /batteryreport' in Command Prompt"
    Write-Output-Both "      The report will be saved to C:\Windows\System32\battery-report.html"
} else {
    Write-Output-Both "Battery Status: No battery detected (Desktop PC)"
    Write-Output-Both "  This system appears to be a desktop computer"
}
Write-Output-Both ""

# ============================================================================
# GRAPHICS INFORMATION
# ============================================================================
Write-Output-Both "GRAPHICS INFORMATION"
Write-Output-Both $("-" * 80)

$GPU = Get-CimInstance -ClassName Win32_VideoController
foreach ($Card in $GPU) {
    Write-Output-Both "Graphics Card: $($Card.Name)"
    Write-Output-Both "  Driver Version: $($Card.DriverVersion)"

    # Handle GPU memory more reliably
    if ($Card.AdapterRAM -and $Card.AdapterRAM -gt 0) {
        $VramGB = [math]::Round($Card.AdapterRAM / 1GB, 2)
        Write-Output-Both "  Video Memory: $VramGB GB"
    } else {
        Write-Output-Both "  Video Memory: Unable to determine"
    }

    Write-Output-Both "  Resolution: $($Card.CurrentHorizontalResolution) x $($Card.CurrentVerticalResolution)"
}
Write-Output-Both ""

# Check DirectX version
try {
    # Use dxdiag with longer wait time
    $DxDiagPath = "$env:TEMP\dxdiag_win11check.txt"

    # Remove old file if exists
    if (Test-Path $DxDiagPath) { Remove-Item $DxDiagPath -Force }

    # Run dxdiag
    $null = Start-Process -FilePath "dxdiag" -ArgumentList "/t", $DxDiagPath -NoNewWindow -PassThru

    # Wait for the file to be created and populated (dxdiag can take a few seconds)
    $MaxWait = 15
    $Waited = 0
    while (-not (Test-Path $DxDiagPath) -and $Waited -lt $MaxWait) {
        Start-Sleep -Seconds 1
        $Waited++
    }

    # Give it extra time to finish writing
    Start-Sleep -Seconds 2

    if (Test-Path $DxDiagPath) {
        $DxContent = Get-Content $DxDiagPath

        # Try multiple regex patterns for DirectX version
        $DxVersion = $null

        # Look specifically for the line that says "DirectX Version: DirectX XX"
        # This appears in the System Information section of dxdiag output
        foreach ($line in $DxContent) {
            # Pattern 1: "DirectX Version: DirectX 12" (most reliable from dxdiag /t output)
            if ($line -match "^\s*DirectX Version:\s*DirectX\s+(\d+)") {
                $DxVersion = $matches[1]
                break
            }
        }

        # If not found, try alternative patterns
        if (-not $DxVersion) {
            $DxContentRaw = $DxContent -join "`n"

            # Pattern 2: Look for "DirectX 12" followed by optional "Ultimate" or similar
            if ($DxContentRaw -match "DirectX Version:\s*DirectX\s+(\d+)\s*(?:Ultimate)?") {
                $DxVersion = $matches[1]
            }
        }

        if ($DxVersion) {
            Write-Output-Both "DirectX Version: DirectX $DxVersion"

            if ([int]$DxVersion -ge 12) {
                Write-Output-Both "✓ DirectX 12 or higher detected - Meets Windows 11 requirement"
            } else {
                Write-Output-Both "✗ DirectX version below 12 - May not meet Windows 11 requirement"
            }
        } else {
            Write-Output-Both "DirectX Version: Unable to determine from dxdiag output"
            Write-Output-Both "⚠ Note: Windows 10/11 systems typically include DirectX 12"
            Write-Output-Both "   You can verify manually by running 'dxdiag' and checking the System tab"
        }

        # Clean up temp file
        Remove-Item $DxDiagPath -ErrorAction SilentlyContinue
    } else {
        Write-Output-Both "DirectX Version: Unable to generate diagnostic report (dxdiag timeout)"
        Write-Output-Both "⚠ Note: Windows 10/11 systems typically include DirectX 12"
    }
} catch {
    Write-Output-Both "DirectX Version: Unable to determine (Error: $($_.Exception.Message))"
    Write-Output-Both "⚠ Note: Windows 10/11 systems typically include DirectX 12"
}

Write-Output-Both ""
Write-Output-Both "NOTE: Windows 11 requires DirectX 12 compatible graphics with WDDM 2.0 driver"
Write-Output-Both ""

# ============================================================================
# DISPLAY INFORMATION
# ============================================================================
Write-Output-Both "DISPLAY INFORMATION"
Write-Output-Both $("-" * 80)

# Get display information from WMI
$Monitors = Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorBasicDisplayParams -ErrorAction SilentlyContinue

if ($Monitors) {
    $MonitorCount = ($Monitors | Measure-Object).Count
    Write-Output-Both "Number of Displays: $MonitorCount"
    Write-Output-Both ""

    $MonitorIndex = 1
    foreach ($Monitor in $Monitors) {
        Write-Output-Both "Display ${MonitorIndex}:"

        # Get display size in inches (diagonal)
        if ($Monitor.MaxHorizontalImageSize -and $Monitor.MaxVerticalImageSize) {
            $WidthCm = $Monitor.MaxHorizontalImageSize
            $HeightCm = $Monitor.MaxVerticalImageSize
            $DiagonalInches = [math]::Round([math]::Sqrt([math]::Pow($WidthCm, 2) + [math]::Pow($HeightCm, 2)) / 2.54, 1)
            Write-Output-Both "  Screen Size: $DiagonalInches inches (diagonal)"

            if ($DiagonalInches -ge 9) {
                Write-Output-Both "  ✓ Screen size meets Windows 11 requirement (9 inches or larger)"
            } else {
                Write-Output-Both "  ✗ Screen size below Windows 11 requirement (needs 9 inches or larger)"
            }
        }

        $MonitorIndex++
    }
    Write-Output-Both ""
}

# Get video controller resolution and refresh rate
$VideoControllers = Get-CimInstance -ClassName Win32_VideoController
foreach ($Controller in $VideoControllers) {
    if ($Controller.CurrentHorizontalResolution -and $Controller.CurrentVerticalResolution) {
        $HRes = $Controller.CurrentHorizontalResolution
        $VRes = $Controller.CurrentVerticalResolution
        $RefreshRate = $Controller.CurrentRefreshRate

        Write-Output-Both "Active Display (via $($Controller.Name)):"
        Write-Output-Both "  Resolution: $HRes x $VRes"

        # Check against Windows 11 minimum (720p = 1280x720)
        if ($HRes -ge 1280 -and $VRes -ge 720) {
            Write-Output-Both "  ✓ Resolution meets Windows 11 minimum requirement (720p / 1280x720)"
        } else {
            Write-Output-Both "  ✗ Resolution below Windows 11 minimum requirement (needs 720p / 1280x720)"
        }

        if ($RefreshRate) {
            Write-Output-Both "  Refresh Rate: $RefreshRate Hz"
        }

        # Check for HDR support using multiple methods
        $HDRDetected = $false
        $HDRMethod = ""

        try {
            # Method 1: Check Graphics Driver Configuration registry (Windows 10 method)
            # HDR/Advanced Color settings are stored in the "00" subkeys under Configuration
            $GraphicsConfigPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Configuration"
            if (Test-Path $GraphicsConfigPath) {
                # Get all "00" subkeys where display settings are stored
                $ConfigKeys = Get-ChildItem -Path $GraphicsConfigPath -Recurse -ErrorAction SilentlyContinue |
                              Where-Object { $_.PSChildName -eq "00" }

                foreach ($Key in $ConfigKeys) {
                    $AdvancedColorEnabled = (Get-ItemProperty -Path $Key.PSPath -Name "AdvancedColorEnabled" -ErrorAction SilentlyContinue).AdvancedColorEnabled
                    if ($AdvancedColorEnabled -eq 1) {
                        $HDRDetected = $true
                        $HDRMethod = "Advanced Color (HDR) Configuration"
                        break
                    }
                }
            }

            # Method 2: Check DWM registry (Desktop Window Manager)
            if (-not $HDRDetected) {
                $DWMPath = "HKCU:\Software\Microsoft\Windows\DWM"
                if (Test-Path $DWMPath) {
                    $UseHDR = (Get-ItemProperty -Path $DWMPath -Name "UseHDR" -ErrorAction SilentlyContinue).UseHDR
                    if ($UseHDR -eq 1) {
                        $HDRDetected = $true
                        $HDRMethod = "DWM Settings"
                    }
                }
            }

            # Method 3: Check VideoSettings registry
            if (-not $HDRDetected) {
                $ColorControlPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\VideoSettings"
                if (Test-Path $ColorControlPath) {
                    $EnableHDR = (Get-ItemProperty -Path $ColorControlPath -Name "EnableHDR" -ErrorAction SilentlyContinue).EnableHDR
                    if ($EnableHDR -eq 1) {
                        $HDRDetected = $true
                        $HDRMethod = "Video Settings"
                    }
                }
            }

            # Output results
            if ($HDRDetected) {
                Write-Output-Both "  ✓ HDR/Advanced Color is currently ENABLED (detected via $HDRMethod)"
            } else {
                # Check if display is HDR capable even if not enabled
                $DisplayConfig = Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorColorCharacteristics -ErrorAction SilentlyContinue
                if ($DisplayConfig) {
                    Write-Output-Both "  ⚠ HDR: Unable to detect automatically via registry"
                    Write-Output-Both "    NOTE: HDR detection may not work on all Windows 11 systems"
                    Write-Output-Both "    Please manually verify: Settings > System > Display > HDR"
                } else {
                    Write-Output-Both "  HDR: Not detected or not supported"
                    Write-Output-Both "    (Verify manually at Settings > System > Display > HDR)"
                }
            }
        } catch {
            Write-Output-Both "  HDR Support: Unable to determine (Error: $($_.Exception.Message))"
            Write-Output-Both "    Please verify manually at Settings > System > Display > HDR"
        }

        Write-Output-Both ""
    }
}

Write-Output-Both "NOTE: Windows 11 requires a display with 720p resolution (1280x720), 9 inches or larger"
Write-Output-Both ""

# ============================================================================
# AUDIO INFORMATION
# ============================================================================
Write-Output-Both "AUDIO INFORMATION"
Write-Output-Both $("-" * 80)

# Get audio devices
$AudioDevices = Get-CimInstance -ClassName Win32_SoundDevice -ErrorAction SilentlyContinue

if ($AudioDevices) {
    $AudioDeviceCount = ($AudioDevices | Measure-Object).Count
    Write-Output-Both "Audio Devices Detected: $AudioDeviceCount"
    Write-Output-Both ""

    $DeviceIndex = 1
    $HDAAudioFound = $false

    foreach ($Device in $AudioDevices) {
        Write-Output-Both "Audio Device ${DeviceIndex}: $($Device.Name)"
        Write-Output-Both "  Manufacturer: $($Device.Manufacturer)"
        Write-Output-Both "  Status: $($Device.Status)"

        # Check for High Definition Audio support
        $DeviceName = $Device.Name

        if ($DeviceName -match "High Definition Audio|HD Audio|HDA|Intel Display Audio|NVIDIA High Definition Audio|AMD High Definition Audio|Realtek High Definition Audio") {
            Write-Output-Both "  ✓ High Definition Audio (HDA) supported"
            $HDAAudioFound = $true
        } elseif ($DeviceName -match "USB Audio|Bluetooth|Headset|Speakers") {
            Write-Output-Both "  Type: USB/Bluetooth/External Audio Device"
        } else {
            Write-Output-Both "  Type: Standard Audio Device"
        }

        # Get driver information
        if ($Device.DriverVersion) {
            Write-Output-Both "  Driver Version: $($Device.DriverVersion)"
        }

        Write-Output-Both ""
        $DeviceIndex++
    }

    # Overall HDA status
    if ($HDAAudioFound) {
        Write-Output-Both "✓ High Definition Audio is supported on this system"
        Write-Output-Both "  Windows 11 audio requirements are met"
    } else {
        Write-Output-Both "⚠ High Definition Audio not explicitly detected"
        Write-Output-Both "  Note: Most modern audio devices support HDA"
        Write-Output-Both "  Windows 11 requires DirectX 9 or later audio (WDDM driver)"
    }
} else {
    Write-Output-Both "⚠ No audio devices detected"
    Write-Output-Both "  Note: Audio is not strictly required for Windows 11, but recommended"
    Write-Output-Both "  Check Device Manager to ensure audio drivers are installed"
}

Write-Output-Both ""

# Additional check: Look for audio endpoints (playback/recording devices)
try {
    # Check for audio endpoints via registry (alternative method)
    $AudioEndpoints = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio" -ErrorAction SilentlyContinue

    if ($AudioEndpoints) {
        $RenderDevices = (Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render" -ErrorAction SilentlyContinue | Measure-Object).Count
        $CaptureDevices = (Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Capture" -ErrorAction SilentlyContinue | Measure-Object).Count

        if ($RenderDevices -gt 0) {
            Write-Output-Both "Audio Playback Endpoints: $RenderDevices device(s)"
        }
        if ($CaptureDevices -gt 0) {
            Write-Output-Both "Audio Recording Endpoints: $CaptureDevices device(s)"
        }
    }
} catch {
    # Silently continue if unable to check endpoints
}

Write-Output-Both ""
Write-Output-Both "NOTE: Windows 11 requires DirectX 9 or later with WDDM driver for audio"
Write-Output-Both ""

# ============================================================================
# OPERATING SYSTEM INFORMATION
# ============================================================================
Write-Output-Both "CURRENT OPERATING SYSTEM"
Write-Output-Both $("-" * 80)

$OS = Get-CimInstance -ClassName Win32_OperatingSystem
Write-Output-Both "OS: $($OS.Caption)"
Write-Output-Both "Version: $($OS.Version)"
Write-Output-Both "Build: $($OS.BuildNumber)"
Write-Output-Both "Architecture: $($OS.OSArchitecture)"
Write-Output-Both "Install Date: $($OS.InstallDate)"
Write-Output-Both ""

# ============================================================================
# SECURITY FEATURES
# ============================================================================
Write-Output-Both "SECURITY FEATURES"
Write-Output-Both $("-" * 80)

# Check Windows Defender status
Write-Output-Both "Windows Defender (Antivirus):"
try {
    # Try to get Windows Defender status using Get-MpComputerStatus
    $DefenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue

    if ($DefenderStatus) {
        $AntivirusEnabled = $DefenderStatus.AntivirusEnabled
        $RealTimeProtectionEnabled = $DefenderStatus.RealTimeProtectionEnabled
        $AntivirusSignatureLastUpdated = $DefenderStatus.AntivirusSignatureLastUpdated

        if ($AntivirusEnabled) {
            Write-Output-Both "  ✓ Windows Defender is ENABLED"
        } else {
            Write-Output-Both "  ✗ Windows Defender is DISABLED"
        }

        if ($RealTimeProtectionEnabled) {
            Write-Output-Both "  ✓ Real-time protection is ENABLED"
        } else {
            Write-Output-Both "  ⚠ Real-time protection is DISABLED"
        }

        if ($AntivirusSignatureLastUpdated) {
            $DaysSinceUpdate = ((Get-Date) - $AntivirusSignatureLastUpdated).Days
            Write-Output-Both "  Signature Last Updated: $($AntivirusSignatureLastUpdated.ToString('yyyy-MM-dd HH:mm:ss'))"

            if ($DaysSinceUpdate -eq 0) {
                Write-Output-Both "  ✓ Definitions are up to date (updated today)"
            } elseif ($DaysSinceUpdate -le 3) {
                Write-Output-Both "  ✓ Definitions are recent (updated $DaysSinceUpdate days ago)"
            } else {
                Write-Output-Both "  ⚠ Definitions are outdated (updated $DaysSinceUpdate days ago) - Update recommended"
            }
        }
    } else {
        # Fallback: Check via WMI
        $DefenderProduct = Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName AntiVirusProduct -ErrorAction SilentlyContinue |
                          Where-Object { $_.displayName -match "Defender|Windows Security" }

        if ($DefenderProduct) {
            Write-Output-Both "  Windows Defender detected but detailed status unavailable"
            Write-Output-Both "  Product: $($DefenderProduct.displayName)"
        } else {
            Write-Output-Both "  Unable to determine Windows Defender status"
        }
    }
} catch {
    Write-Output-Both "  Unable to check Windows Defender status (may require admin privileges)"
}
Write-Output-Both ""

# Check Windows Firewall status
Write-Output-Both "Windows Firewall:"
try {
    $FirewallProfiles = Get-NetFirewallProfile -ErrorAction SilentlyContinue

    if ($FirewallProfiles) {
        $AllEnabled = $true
        foreach ($Profile in $FirewallProfiles) {
            $ProfileName = $Profile.Name
            $ProfileEnabled = $Profile.Enabled

            if ($ProfileEnabled) {
                Write-Output-Both "  ✓ $ProfileName Profile: ENABLED"
            } else {
                Write-Output-Both "  ✗ $ProfileName Profile: DISABLED"
                $AllEnabled = $false
            }
        }

        if ($AllEnabled) {
            Write-Output-Both "  ✓ All firewall profiles are enabled - Good security posture"
        } else {
            Write-Output-Both "  ⚠ Some firewall profiles are disabled - Enable for better protection"
        }
    } else {
        Write-Output-Both "  Unable to retrieve firewall status"
    }
} catch {
    Write-Output-Both "  Unable to check Windows Firewall status (may require admin privileges)"
}
Write-Output-Both ""

# Check BitLocker compatibility
Write-Output-Both "BitLocker Compatibility:"
try {
    # Check if TPM is available (already checked earlier, but verify for BitLocker)
    $TPM = Get-Tpm -ErrorAction SilentlyContinue

    if ($TPM -and $TPM.TpmPresent -and $TPM.TpmReady) {
        Write-Output-Both "  ✓ TPM available and ready for BitLocker"

        # Check TPM version for BitLocker
        $TPMVersion = Get-CimInstance -Namespace "Root\CIMv2\Security\MicrosoftTpm" -ClassName Win32_Tpm -ErrorAction SilentlyContinue
        if ($TPMVersion) {
            $SpecVersion = $TPMVersion.SpecVersion
            if ($SpecVersion -like "2.0*" -or $SpecVersion -like "2.*") {
                Write-Output-Both "  ✓ TPM 2.0 detected - Fully compatible with BitLocker"
            } elseif ($SpecVersion -like "1.2*") {
                Write-Output-Both "  ✓ TPM 1.2 detected - Compatible with BitLocker (TPM 2.0 recommended)"
            }
        }

        # Check if BitLocker is supported on this Windows edition
        $OSCaption = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
        if ($OSCaption -match "Pro|Enterprise|Education") {
            Write-Output-Both "  ✓ Windows edition supports BitLocker ($($OSCaption))"

            # Check current BitLocker status on system drive
            $BitLockerVolume = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction SilentlyContinue
            if ($BitLockerVolume) {
                $ProtectionStatus = $BitLockerVolume.ProtectionStatus
                if ($ProtectionStatus -eq "On") {
                    Write-Output-Both "  ✓ BitLocker is currently ENABLED on system drive ($env:SystemDrive)"
                    Write-Output-Both "  Encryption: $($BitLockerVolume.EncryptionPercentage)% complete"
                } else {
                    Write-Output-Both "  ⚠ BitLocker is available but NOT enabled on system drive ($env:SystemDrive)"
                }
            }
        } else {
            Write-Output-Both "  ⚠ Windows Home edition detected - BitLocker requires Pro/Enterprise/Education"
            Write-Output-Both "    Note: Device Encryption may be available as an alternative"
        }
    } else {
        Write-Output-Both "  ✗ TPM not available or not ready"
        Write-Output-Both "    BitLocker requires TPM 1.2 or 2.0 for hardware-based encryption"
    }
} catch {
    Write-Output-Both "  Unable to determine BitLocker compatibility (may require admin privileges)"
}
Write-Output-Both ""

Write-Output-Both "NOTE: Strong security is important for Windows 11"
Write-Output-Both "      Enable Windows Defender, Firewall, and consider BitLocker for data protection"
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