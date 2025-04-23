# WSL4CLAUDE - Run Claude Code Installation in WSL
# ===========================================================
#
# This PowerShell script copies the installer script to WSL and runs it
#

Write-Host "WSL4CLAUDE - Running Claude Code Installation in WSL" -ForegroundColor Cyan
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

# If no distribution is found, offer to install Ubuntu
if (-not $defaultDistro -or $defaultDistro -eq "") {
    Write-Host "No WSL distribution found." -ForegroundColor Yellow
    Write-Host "Would you like to install Ubuntu in WSL? (Y/N)" -ForegroundColor Yellow
    $installUbuntu = Read-Host
    
    if ($installUbuntu -eq "Y" -or $installUbuntu -eq "y") {
        Write-Host "Installing Ubuntu in WSL..." -ForegroundColor Cyan
        wsl --install -d Ubuntu
        
        # Wait for installation to complete
        Write-Host "Please complete the Ubuntu setup process in the new window." -ForegroundColor Yellow
        Write-Host "After setting up your username and password, close that window and press Enter to continue." -ForegroundColor Yellow
        Read-Host
    } else {
        Write-Host "Please install a WSL distribution and try again." -ForegroundColor Red
        exit 1
    }
}

# Get the path to the install script in this repository
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "install-claude-with-nvm.sh"
if (-not (Test-Path $scriptPath)) {
    Write-Host "Could not find the install script at: $scriptPath" -ForegroundColor Red
    Write-Host "Please make sure you're running this script from the repository directory." -ForegroundColor Red
    exit 1
}

# Copy the script to the WSL home directory
Write-Host "Copying installation script to WSL..." -ForegroundColor Cyan

# Convert Windows paths to WSL paths and ensure scripts have correct line endings
Write-Host "Attempting to create directory in WSL..." -ForegroundColor Yellow
$result = wsl mkdir -p ~/wsl-4-claude 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error creating directory in WSL: $result" -ForegroundColor Red
    Write-Host "Trying alternative approach..." -ForegroundColor Yellow
    
    # Try running WSL with a specific distribution
    if ($distros -like "*Ubuntu*") {
        $ubuntuDistro = $distros | Where-Object { $_ -like "*Ubuntu*" } | Select-Object -First 1
        Write-Host "Using distribution: $ubuntuDistro" -ForegroundColor Green
        wsl -d $ubuntuDistro mkdir -p ~/wsl-4-claude
    } else {
        Write-Host "Could not create directory in WSL. Please ensure your WSL installation is working correctly." -ForegroundColor Red
        exit 1
    }
}

# Create a temporary file with Unix line endings
Write-Host "Preparing installer script..." -ForegroundColor Cyan
$tempFile = "$env:TEMP\install-claude-with-nvm.sh"
Get-Content $scriptPath | ForEach-Object { $_ -replace "`r`n", "`n" } | Set-Content -Encoding utf8 -Path $tempFile -NoNewline

# Try to copy the script to WSL
Write-Host "Copying script to WSL..." -ForegroundColor Cyan
try {
    $wslTempPath = wsl wslpath -u "$(($tempFile -replace '\\', '\\') -replace ':', '')"
    $copyCommand = "cat $wslTempPath > ~/wsl-4-claude/install-claude-with-nvm.sh && chmod +x ~/wsl-4-claude/install-claude-with-nvm.sh"
    
    # Try with default distribution first
    $result = wsl bash -c "$copyCommand" 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        # If that fails, try with a specific Ubuntu distribution
        if ($distros -like "*Ubuntu*") {
            $ubuntuDistro = $distros | Where-Object { $_ -like "*Ubuntu*" } | Select-Object -First 1
            Write-Host "Trying with distribution: $ubuntuDistro" -ForegroundColor Yellow
            wsl -d $ubuntuDistro bash -c "$copyCommand"
        } else {
            throw "Failed to copy script to WSL"
        }
    }
} catch {
    Write-Host "Error copying script to WSL: $_" -ForegroundColor Red
    Write-Host "Alternative approach: Directly writing script to WSL..." -ForegroundColor Yellow
    
    $scriptContent = Get-Content -Path $scriptPath -Raw
    $scriptContent = $scriptContent -replace "`r`n", "`n"
    
    # Write script content directly using echo
    $tempScriptFile = "$env:TEMP\temp_script_content.txt"
    $scriptContent | Set-Content -Path $tempScriptFile -Encoding utf8 -NoNewline
    
    # Use a heredoc approach
    $wslCommand = "cat > ~/wsl-4-claude/install-claude-with-nvm.sh << 'EOL'"
    $wslCommand += "`n$scriptContent`nEOL`n"
    $wslCommand += "chmod +x ~/wsl-4-claude/install-claude-with-nvm.sh"
    
    if ($distros -like "*Ubuntu*") {
        $ubuntuDistro = $distros | Where-Object { $_ -like "*Ubuntu*" } | Select-Object -First 1
        wsl -d $ubuntuDistro bash -c "$wslCommand"
    } else {
        wsl bash -c "$wslCommand"
    }
}

# Run the installation script in WSL
Write-Host "Running installation script in WSL..." -ForegroundColor Cyan
Write-Host "This may take a few minutes..." -ForegroundColor Yellow
Write-Host ""

try {
    # Try with default distribution first
    $result = wsl bash -c "~/wsl-4-claude/install-claude-with-nvm.sh" 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        # If that fails, try with a specific Ubuntu distribution
        if ($distros -like "*Ubuntu*") {
            $ubuntuDistro = $distros | Where-Object { $_ -like "*Ubuntu*" } | Select-Object -First 1
            Write-Host "Trying with distribution: $ubuntuDistro" -ForegroundColor Yellow
            wsl -d $ubuntuDistro bash -c "~/wsl-4-claude/install-claude-with-nvm.sh"
        } else {
            throw "Failed to run script in WSL"
        }
    }
} catch {
    Write-Host "Error running installation script in WSL: $_" -ForegroundColor Red
    Write-Host "Installation failed. Please try running WSL directly and running the script manually:" -ForegroundColor Red
    Write-Host "  wsl" -ForegroundColor Yellow
    Write-Host "  ~/wsl-4-claude/install-claude-with-nvm.sh" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "=============================================================" -ForegroundColor Green
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host "=============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "To use Claude Code, open your WSL terminal and run:" -ForegroundColor Yellow
Write-Host "  source ~/.bashrc" -ForegroundColor Yellow
Write-Host "  export ANTHROPIC_API_KEY=your_api_key_here" -ForegroundColor Yellow
Write-Host "  claudecode" -ForegroundColor Yellow
Write-Host ""
Write-Host "You can also launch WSL directly by running:" -ForegroundColor Yellow
Write-Host "  wsl" -ForegroundColor Yellow
Write-Host ""
