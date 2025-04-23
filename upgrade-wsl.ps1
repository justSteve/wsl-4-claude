# PowerShell script to upgrade WSL 1 to WSL 2
# Run this script from PowerShell with Administrator privileges

Write-Host "WSL 1 to WSL 2 Upgrade Script" -ForegroundColor Green
Write-Host "==============================" -ForegroundColor Green
Write-Host ""

# Check if running as Administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please right-click on PowerShell and select 'Run as administrator'." -ForegroundColor Red
    exit
}

# Check current WSL version
Write-Host "Checking current WSL version..." -ForegroundColor Yellow
$wslList = wsl --list --verbose
Write-Host $wslList

# Step 1: Enable Virtual Machine Platform
Write-Host "`nStep 1: Enabling Virtual Machine Platform..." -ForegroundColor Yellow
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Step 2: Enable WSL feature if not already enabled
Write-Host "`nStep 2: Enabling Windows Subsystem for Linux..." -ForegroundColor Yellow
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

# Step 3: Download the Linux kernel update package
Write-Host "`nStep 3: Downloading WSL2 Linux kernel update package..." -ForegroundColor Yellow
$kernelUpdateUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
$kernelUpdateFile = "$env:TEMP\wsl_update_x64.msi"

try {
    Invoke-WebRequest -Uri $kernelUpdateUrl -OutFile $kernelUpdateFile -UseBasicParsing
    Write-Host "Download complete. Installing the update..." -ForegroundColor Green
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$kernelUpdateFile`" /quiet" -Wait
    Write-Host "WSL2 Linux kernel update package installed." -ForegroundColor Green
}
catch {
    Write-Host "Failed to download or install the WSL2 Linux kernel update package." -ForegroundColor Red
    Write-Host "Please download it manually from: https://aka.ms/wsl2kernel" -ForegroundColor Red
}

# Step 4: Set WSL 2 as default
Write-Host "`nStep 4: Setting WSL 2 as default..." -ForegroundColor Yellow
wsl --set-default-version 2

# Step 5: Convert existing distro to WSL 2
Write-Host "`nStep 5: Converting existing distributions to WSL 2..." -ForegroundColor Yellow
$distros = (wsl --list).Split("`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "Windows Subsystem for Linux Distributions:" -and $_ -ne "" }

foreach ($distro in $distros) {
    if ($distro -ne "Windows Subsystem for Linux Distributions:") {
        $distroName = $distro.Split(" ")[0]
        Write-Host "Converting $distroName to WSL 2..." -ForegroundColor Yellow
        wsl --set-version $distroName 2
    }
}

# Final check
Write-Host "`nFinal WSL version check:" -ForegroundColor Yellow
wsl --list --verbose

Write-Host "`nWSL 2 Upgrade Process Complete!" -ForegroundColor Green
Write-Host "You may need to restart your computer for changes to take effect." -ForegroundColor Yellow
Write-Host "After restarting, verify your WSL version with 'wsl --list --verbose'"