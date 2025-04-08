# Windows Credential Management Script for Claude WSL Environment
# This script manages credentials for the Claude WSL Environment in Windows
# Run this script from PowerShell as Administrator

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("dev", "prod")]
    [string]$Environment = "dev"
)

# Define colors for output
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    else {
        $input | Write-Output
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Green {
    param([string]$text)
    Write-ColorOutput Green $text
}

function Write-Blue {
    param([string]$text)
    Write-ColorOutput Blue $text
}

function Write-Yellow {
    param([string]$text)
    Write-ColorOutput Yellow $text
}

function Write-Red {
    param([string]$text)
    Write-ColorOutput Red $text
}

# Display header
Write-Blue "==============================================="
Write-Blue "  Windows Credential Management for Claude WSL"
Write-Blue "==============================================="
Write-Output ""

# Get the script directory
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Parent $scriptPath
$repoRoot = Split-Path -Parent $scriptDir

# Determine environment file path
$envFilePath = ""
if ($Environment -eq "dev") {
    $envFilePath = Join-Path $repoRoot "config\.dev.env"
    Write-Yellow "Using development environment configuration"
} else {
    $envFilePath = Join-Path $repoRoot "config\.prod.env"
    Write-Yellow "Using production environment configuration"
}

# Check if environment file exists, if not create from template
if (-not (Test-Path $envFilePath)) {
    $templatePath = ""
    if ($Environment -eq "dev") {
        $templatePath = Join-Path $repoRoot "config\dev.env.example"
    } else {
        $templatePath = Join-Path $repoRoot "config\prod.env.example"
    }

    if (Test-Path $templatePath) {
        Copy-Item -Path $templatePath -Destination $envFilePath
        Write-Green "Created new environment file from template: $envFilePath"
    } else {
        Write-Red "Template file not found: $templatePath"
        Write-Red "Please run the repository initialization script first."
        exit 1
    }
}

# Function to prompt for credential value
function Get-CredentialValue {
    param(
        [string]$promptText,
        [string]$defaultValue = ""
    )

    if ([string]::IsNullOrEmpty($defaultValue)) {
        $value = Read-Host -Prompt $promptText
    } else {
        $value = Read-Host -Prompt "$promptText (default: $defaultValue, press Enter to keep)"
        if ([string]::IsNullOrEmpty($value)) {
            $value = $defaultValue
        }
    }
    return $value
}

# Function to update environment file with a key-value pair
function Update-EnvFile {
    param(
        [string]$filePath,
        [string]$key,
        [string]$value
    )

    $content = Get-Content -Path $filePath -Raw
    if ($content -match "(?m)^$key=.*$") {
        $content = $content -replace "(?m)^$key=.*$", "$key=$value"
    } else {
        $content += "`n$key=$value"
    }
    Set-Content -Path $filePath -Value $content
}

# Function to store credential in Windows Credential Manager
function Set-WindowsCredential {
    param(
        [string]$credentialName,
        [string]$username,
        [string]$secret
    )

    try {
        # Check if credential exists
        $credential = cmdkey /list:$credentialName 2>$null
        if ($credential -like "*$credentialName*") {
            # Delete existing credential
            cmdkey /delete:$credentialName
        }

        # Add new credential
        cmdkey /add:$credentialName /user:$username /pass:$secret
        Write-Green "Credential '$credentialName' stored in Windows Credential Manager"
        return $true
    }
    catch {
        Write-Red "Failed to store credential in Windows Credential Manager: $_"
        return $false
    }
}

# Function to load existing values from environment file
function Get-EnvFileValue {
    param(
        [string]$filePath,
        [string]$key
    )

    if (Test-Path $filePath) {
        $content = Get-Content -Path $filePath -Raw
        if ($content -match "(?m)^$key=(.*)$") {
            return $matches[1]
        }
    }
    return ""
}

# Load existing values from environment file
$anthropicApiKey = Get-EnvFileValue -filePath $envFilePath -key "ANTHROPIC_API_KEY"
$githubUsername = Get-EnvFileValue -filePath $envFilePath -key "GITHUB_USERNAME"
$githubEmail = Get-EnvFileValue -filePath $envFilePath -key "GITHUB_EMAIL"
$wslDistroName = Get-EnvFileValue -filePath $envFilePath -key "WSL_DISTRO_NAME"

# Prompt for credentials
Write-Output "Please enter your credentials:"
Write-Output ""

$anthropicApiKey = Get-CredentialValue -promptText "Anthropic API Key" -defaultValue $anthropicApiKey
$githubUsername = Get-CredentialValue -promptText "GitHub Username" -defaultValue $githubUsername
$githubEmail = Get-CredentialValue -promptText "GitHub Email" -defaultValue $githubEmail
$wslDistroName = Get-CredentialValue -promptText "WSL Distribution Name" -defaultValue $wslDistroName

# Update environment file
Update-EnvFile -filePath $envFilePath -key "ANTHROPIC_API_KEY" -value $anthropicApiKey
Update-EnvFile -filePath $envFilePath -key "GITHUB_USERNAME" -value $githubUsername
Update-EnvFile -filePath $envFilePath -key "GITHUB_EMAIL" -value $githubEmail
Update-EnvFile -filePath $envFilePath -key "WSL_DISTRO_NAME" -value $wslDistroName
Update-EnvFile -filePath $envFilePath -key "ENV_TYPE" -value $Environment

# Store credentials in Windows Credential Manager
$credPrefix = "ClaudeWSL"
$credSuffix = if ($Environment -eq "dev") { "Dev" } else { "Prod" }

Set-WindowsCredential -credentialName "$credPrefix-Anthropic-$credSuffix" -username "api" -secret $anthropicApiKey
Set-WindowsCredential -credentialName "$credPrefix-GitHub-$credSuffix" -username $githubUsername -secret "token-placeholder"

# Create a PowerShell profile to set environment variables
$profileContent = @"
# Claude WSL Environment - $Environment Environment
# This section was added by the Claude WSL Environment setup script

# Function to get credentials from Windows Credential Manager
function Get-StoredCredential {
    param([string]`$targetName)

    `$output = cmdkey /list:`$targetName 2>`$null
    if (`$output -match 'User: (\S+)') {
        `$username = `$matches[1]
        return `$username
    }
    return `$null
}

# Set environment variables for Claude WSL Environment
`$env:CLAUDE_ENV_TYPE = "$Environment"
`$env:ANTHROPIC_API_KEY = "$anthropicApiKey"
`$env:GITHUB_USERNAME = "$githubUsername"
`$env:GITHUB_EMAIL = "$githubEmail"
`$env:WSL_DISTRO_NAME = "$wslDistroName"

# Function to start WSL with environment variables
function Start-ClaudeWSL {
    param(
        [Parameter(Mandatory=`$false)]
        [ValidateSet("dev", "prod")]
        [string]`$Environment = "$Environment"
    )

    `$envVars = "ENV_TYPE=`$Environment"
    `$envVars += " ANTHROPIC_API_KEY=`$env:ANTHROPIC_API_KEY"
    `$envVars += " GITHUB_USERNAME=`$env:GITHUB_USERNAME"
    `$envVars += " GITHUB_EMAIL=`$env:GITHUB_EMAIL"

    `$distro = if (`$env:WSL_DISTRO_NAME) { `$env:WSL_DISTRO_NAME } else { "Ubuntu-20.04" }
    
    Write-Host "Starting `$distro with Claude environment variables (`$Environment)..." -ForegroundColor Green
    wsl -d `$distro --exec /bin/bash -c "`$envVars /bin/bash"
}

# Create aliases
Set-Alias -Name claude-wsl -Value Start-ClaudeWSL
"@

# Determine profile path
$profilePath = $PROFILE.CurrentUserAllHosts
$profileDir = Split-Path -Parent $profilePath

# Create profile directory if it doesn't exist
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

# Check if profile exists
$profileExists = Test-Path $profilePath
if ($profileExists) {
    # Check if profile already contains Claude WSL Environment section
    $existingProfile = Get-Content -Path $profilePath -Raw
    if ($existingProfile -match "# Claude WSL Environment") {
        # Update existing section
        $updatedProfile = $existingProfile -replace "(?ms)# Claude WSL Environment.*?# Create aliases.*?`n", $profileContent
        Set-Content -Path $profilePath -Value $updatedProfile
        Write-Green "Updated Claude WSL Environment section in PowerShell profile"
    } else {
        # Append to existing profile
        Add-Content -Path $profilePath -Value "`n$profileContent"
        Write-Green "Added Claude WSL Environment section to PowerShell profile"
    }
} else {
    # Create new profile
    Set-Content -Path $profilePath -Value $profileContent
    Write-Green "Created PowerShell profile with Claude WSL Environment configuration"
}

# Create WSL bridge script that exports credentials from Windows to WSL
$wslBridgeScript = @"
#!/bin/bash
#
# WSL Bridge Script for Claude WSL Environment
# This script imports credentials from Windows to WSL

# Get the WSL distribution name
WSL_DISTRO_NAME=`$(wslvar WSL_DISTRO_NAME 2>/dev/null || echo "Ubuntu-20.04")

# Get the environment type
ENV_TYPE=`$(wslvar CLAUDE_ENV_TYPE 2>/dev/null || echo "dev")

# Get the credentials
ANTHROPIC_API_KEY=`$(wslvar ANTHROPIC_API_KEY 2>/dev/null || echo "")
GITHUB_USERNAME=`$(wslvar GITHUB_USERNAME 2>/dev/null || echo "")
GITHUB_EMAIL=`$(wslvar GITHUB_EMAIL 2>/dev/null || echo "")

# Set environment variables for WSL
export WSL_DISTRO_NAME=`$WSL_DISTRO_NAME
export ENV_TYPE=`$ENV_TYPE
export ANTHROPIC_API_KEY=`$ANTHROPIC_API_KEY
export GITHUB_USERNAME=`$GITHUB_USERNAME
export GITHUB_EMAIL=`$GITHUB_EMAIL

# Display environment information
echo "Claude WSL Environment - `$ENV_TYPE Environment"
echo "WSL Distribution: `$WSL_DISTRO_NAME"
echo "GitHub Username: `$GITHUB_USERNAME"
echo "GitHub Email: `$GITHUB_EMAIL"
echo "ANTHROPIC_API_KEY: `${ANTHROPIC_API_KEY:0:3}...`${ANTHROPIC_API_KEY:(-3)}"

# Export environment variables to the shell
exec bash
"@

# Create the bridge script
$wslHome = wsl -d $wslDistroName -e /bin/bash -c "echo \$HOME"
$bridgeScriptPath = "\\wsl$\$wslDistroName$wslHome\.claude-wsl-bridge.sh"
Set-Content -Path $bridgeScriptPath -Value $wslBridgeScript -Encoding utf8
wsl -d $wslDistroName -e chmod +x "$wslHome/.claude-wsl-bridge.sh"

Write-Green "Created WSL bridge script at $wslHome/.claude-wsl-bridge.sh"

# Done
Write-Green "Windows credential management setup complete!"
Write-Yellow "To start WSL with Claude environment variables, run:"
Write-Yellow "  claude-wsl"
Write-Yellow "in PowerShell."
Write-Yellow "Or start WSL normally and run:"
Write-Yellow "  ~/.claude-wsl-bridge.sh"
Write-Output ""