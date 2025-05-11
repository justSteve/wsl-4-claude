# WSL4CLAUDE - Run Architecture Fix in WSL
# ===========================================================
#
# This PowerShell script deploys the architecture fix to WSL
#

Write-Host "WSL4CLAUDE - Running Architecture Fix in WSL" -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""

# Check if WSL is installed
try {
    $wslCheck = wsl --list
    if ($LASTEXITCODE -ne 0) {
        Write-Host "WSL does not appear to be installed or running." -ForegroundColor Red
        Write-Host "Please install WSL2 first using 'wsl --install' from an admin PowerShell." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Error checking WSL status: $_" -ForegroundColor Red
    Write-Host "Please install WSL2 first using 'wsl --install' from an admin PowerShell." -ForegroundColor Red
    exit 1
}

Write-Host "WSL is installed. Checking distributions..." -ForegroundColor Green

# Get all WSL distributions
$distros = (wsl --list) -replace "`0", "" | Where-Object { $_ -match "\S" } | ForEach-Object { $_.Trim() }
$defaultDistro = $distros | Select-Object -First 1

if ($defaultDistro -eq "Windows Subsystem for Linux Distributions:") {
    # Skip the header line if it exists
    $defaultDistro = $distros | Select-Object -Skip 1 | Select-Object -First 1
}

Write-Host "Found WSL distribution: $defaultDistro" -ForegroundColor Green

# Get the path to the architecture fix script in this repository
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "wsl-architecture-fix.sh"
if (-not (Test-Path $scriptPath)) {
    Write-Host "Could not find the architecture fix script at: $scriptPath" -ForegroundColor Red
    Write-Host "Please make sure you're running this script from the repository directory." -ForegroundColor Red
    exit 1
}

# Create a temporary file with Unix line endings
Write-Host "Preparing architecture fix script..." -ForegroundColor Cyan
$tempFile = "$env:TEMP\wsl-architecture-fix.sh"
Get-Content $scriptPath | ForEach-Object { $_ -replace "`r`n", "`n" } | Set-Content -Encoding utf8 -Path $tempFile -NoNewline

# Deploy the script to WSL
Write-Host "Deploying script to WSL..." -ForegroundColor Cyan
try {
    # Convert Windows path to WSL path
    $wslTempPath = wsl wslpath -u "$(($tempFile -replace '\\', '\\') -replace ':', '')"
    
    # Copy the script to WSL home directory
    $copyCommand = "cat $wslTempPath > ~/wsl-architecture-fix.sh && chmod +x ~/wsl-architecture-fix.sh"
    wsl bash -c $copyCommand
    
    # Now run the architecture fix script in WSL
    Write-Host "Running architecture fix script in WSL..." -ForegroundColor Cyan
    wsl bash -c "~/wsl-architecture-fix.sh"
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to run architecture fix script in WSL"
    }
} catch {
    Write-Host "Error running architecture fix in WSL: $_" -ForegroundColor Red
    Write-Host "Please try running WSL directly and running the script manually:" -ForegroundColor Red
    Write-Host "  wsl" -ForegroundColor Yellow
    Write-Host "  ~/wsl-architecture-fix.sh" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "=============================================================" -ForegroundColor Green
Write-Host "Architecture fix deployment complete!" -ForegroundColor Green
Write-Host "=============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "The WSL4Claude setup has been properly organized to run within WSL." -ForegroundColor Yellow
Write-Host "To use the setup scripts, open your WSL terminal and run:" -ForegroundColor Yellow
Write-Host "  ~/launch-claude-setup.sh" -ForegroundColor Yellow
Write-Host ""
Write-Host "Or to set up Claude Code directly:" -ForegroundColor Yellow
Write-Host "  ~/setup-claude.sh" -ForegroundColor Yellow
Write-Host ""
Write-Host "You can open a WSL terminal by running:" -ForegroundColor Yellow
Write-Host "  wsl" -ForegroundColor Yellow
Write-Host ""
