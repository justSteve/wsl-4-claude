# WSL4CLAUDE - Fix Claude Code PATH issues
# ===========================================================
#
# This PowerShell script copies the path fix script to WSL and runs it
#

Write-Host "WSL4CLAUDE - Fixing Claude Code PATH issues in WSL" -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""

# Check if WSL is installed
try {
    $wslCheck = wsl --list
    if ($LASTEXITCODE -ne 0) {
        Write-Host "WSL does not appear to be installed or running." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Error checking WSL status: $_" -ForegroundColor Red
    exit 1
}

# Get the path to the fix script in this repository
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "fix-claude-path.sh"
if (-not (Test-Path $scriptPath)) {
    Write-Host "Could not find the fix script at: $scriptPath" -ForegroundColor Red
    exit 1
}

# Copy the script to the WSL home directory
Write-Host "Copying fix script to WSL..." -ForegroundColor Cyan

# Create a temporary file with Unix line endings
$tempFile = "$env:TEMP\fix-claude-path.sh"
Get-Content $scriptPath | ForEach-Object { $_ -replace "`r`n", "`n" } | Set-Content -Encoding utf8 -Path $tempFile -NoNewline

# Try to copy the script to WSL
try {
    # Use WSL to convert Windows path to WSL path
    $wslPath = wsl wslpath -u "'$($tempFile -replace '\\', '/' -replace ' ', '\ ')'"
    $wslPath = $wslPath -replace "'", ""
    
    $copyCommand = "cat $wslPath > ~/fix-claude-path.sh && chmod +x ~/fix-claude-path.sh"
    wsl bash -c "$copyCommand"
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to copy script to WSL"
    }
} catch {
    Write-Host "Error copying script to WSL: $_" -ForegroundColor Red
    
    # Alternative approach - write directly using heredoc
    Write-Host "Using alternative approach to copy script..." -ForegroundColor Yellow
    
    $scriptContent = Get-Content -Path $scriptPath -Raw
    $scriptContent = $scriptContent -replace "`r`n", "`n"
    
    $tempScriptFile = "$env:TEMP\temp_script_content.txt"
    $scriptContent | Set-Content -Path $tempScriptFile -Encoding utf8 -NoNewline
    
    # Use a different approach with echo
    $tempScriptContent = Get-Content -Path $tempScriptFile -Raw
    $encodedScript = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($tempScriptContent))
    
    $wslCommand = "echo $encodedScript | base64 -d > ~/fix-claude-path.sh && chmod +x ~/fix-claude-path.sh"
    wsl bash -c "$wslCommand"
}

# Run the fix script in WSL
Write-Host "Running fix script in WSL..." -ForegroundColor Cyan
wsl bash -c "~/fix-claude-path.sh"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Fix script encountered errors. You may need to run it manually in WSL." -ForegroundColor Red
    Write-Host "Open WSL and run:" -ForegroundColor Yellow
    Write-Host "  ~/fix-claude-path.sh" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "=============================================================" -ForegroundColor Green
Write-Host "Fix script completed!" -ForegroundColor Green
Write-Host "=============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "To use Claude Code, open your WSL terminal and run:" -ForegroundColor Yellow
Write-Host "  source ~/.bashrc" -ForegroundColor Yellow
Write-Host "  export ANTHROPIC_API_KEY=your_api_key_here" -ForegroundColor Yellow
Write-Host "  claudecode" -ForegroundColor Yellow
Write-Host ""
