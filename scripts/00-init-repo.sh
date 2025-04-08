#!/bin/bash
#
# Repository initialization script
# This script sets up the repository structure and initializes Git

set -e  # Exit immediately if a command exits with a non-zero status

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Initializing repository structure...${NC}"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$REPO_ROOT"

# Create directory structure if it doesn't exist
echo "Creating directory structure..."
mkdir -p scripts config docs .github/workflows

# Check if Git is already initialized
if [ -d ".git" ]; then
    echo -e "${YELLOW}Git repository already initialized.${NC}"
else
    echo "Initializing Git repository..."
    git init
    echo -e "${GREEN}Git repository initialized.${NC}"
fi

# Create .gitignore file
echo "Creating .gitignore file..."
cat > .gitignore << 'EOL'
# Environment variables and secrets
.env
*.env
!*.example

# Personal configuration files
.vscode/
.idea/

# Logs
*.log
logs/

# Temporary files
*.tmp
*~
.DS_Store

# WSL specific
*.swp
EOL

# Generate LICENSE file if it doesn't exist
if [ ! -f "LICENSE" ]; then
    echo "Creating MIT LICENSE file..."
    cat > LICENSE << 'EOL'
MIT License

Copyright (c) 2025 

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOL
fi

# Create template environment files
echo "Creating environment templates..."
mkdir -p config

# Create template.env
cat > config/template.env << 'EOL'
# Claude API Configuration
ANTHROPIC_API_KEY=your_api_key_here

# GitHub Configuration
GITHUB_USERNAME=your_github_username
GITHUB_EMAIL=your_github_email

# WSL Configuration
WSL_DISTRO_NAME=Ubuntu-20.04
EOL

# Create dev.env.example
cat > config/dev.env.example << 'EOL'
# Development Environment Configuration
ANTHROPIC_API_KEY=your_dev_api_key_here
GITHUB_USERNAME=your_github_username
GITHUB_EMAIL=your_github_email
WSL_DISTRO_NAME=Ubuntu-20.04
ENV_TYPE=development
EOL

# Create prod.env.example
cat > config/prod.env.example << 'EOL'
# Production Environment Configuration
ANTHROPIC_API_KEY=your_prod_api_key_here
GITHUB_USERNAME=your_github_username
GITHUB_EMAIL=your_github_email
WSL_DISTRO_NAME=Ubuntu-20.04
ENV_TYPE=production
EOL

# Create initial GitHub action for validation
echo "Setting up GitHub workflow..."
mkdir -p .github/workflows
cat > .github/workflows/validate.yml << 'EOL'
name: Validate Environment Setup

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Check script permissions
        run: |
          chmod +x ./setup.sh
          chmod +x ./scripts/*.sh
          
      - name: Validate script syntax
        run: |
          for script in ./scripts/*.sh; do
            bash -n "$script" || exit 1
          done
          
      - name: Check for sensitive information
        run: |
          ! grep -r "ANTHROPIC_API_KEY=[^your]" --include="*.sh" --include="*.env" .
          ! grep -r "GITHUB_TOKEN=[^your]" --include="*.sh" --include="*.env" .
EOL

# Create basic documentation files
echo "Creating documentation files..."
mkdir -p docs

# Create USAGE.md
cat > docs/USAGE.md << 'EOL'
# Usage Guide

This document provides detailed instructions for using the Claude WSL Environment.

## Getting Started

After installation, your WSL environment will be configured with all the necessary tools for working with Claude Code and GitHub repositories.

## Working with Claude Code

1. Open your WSL terminal
2. Navigate to your project directory
3. Run the Claude Code CLI with `claude`
4. Follow the prompts to authenticate with your Anthropic account

## GitHub Integration

The environment is configured to work seamlessly with GitHub:

1. Your SSH keys are set up for authentication
2. Git is configured with your user information
3. Common Git aliases are configured for convenience

## Switching Between Dev and Prod

To switch between development and production environments:

For Windows:
```powershell
.\scripts\05-win-credentials.ps1 dev  # For development
.\scripts\05-win-credentials.ps1 prod # For production
```

For Linux/WSL:
```bash
./scripts/06-lx-credentials.sh dev  # For development
./scripts/06-lx-credentials.sh prod # For production
```

## Updating Your Environment

To update your environment to the latest version:

1. Pull the latest changes from the repository
2. Run the setup script again

```bash
git pull
./setup.sh
```
EOL

# Create CREDENTIALS.md
cat > docs/CREDENTIALS.md << 'EOL'
# Credential Management Guide

This document explains how to securely manage your credentials in the Claude WSL Environment.

## API Keys

The environment uses the following API keys:

- **ANTHROPIC_API_KEY**: Used for authenticating with the Claude API

## Development vs. Production

The environment supports separate development and production credentials:

- **Development**: Used for testing and development work
- **Production**: Used for production-ready code

## Windows Credential Management

On Windows, credentials are managed using the Windows Credential Manager:

1. Run the Windows credential script:
   ```powershell
   .\scripts\05-win-credentials.ps1 dev  # For development
   .\scripts\05-win-credentials.ps1 prod # For production
   ```

2. The script will:
   - Store your API keys in the Windows Credential Manager
   - Set up environment variables that point to the stored credentials
   - Create a PowerShell profile with the necessary configuration

## Linux/WSL Credential Management

In WSL, credentials are managed using environment variables and optional encryption:

1. Run the Linux credential script:
   ```bash
   ./scripts/06-lx-credentials.sh dev  # For development
   ./scripts/06-lx-credentials.sh prod # For production
   ```

2. The script will:
   - Store your API keys in encrypted files using GPG (if available)
   - Configure your shell profile (.bashrc or .zshrc) with the necessary environment variables
   - Set up automatic loading of credentials when you start WSL

## Security Best Practices

- Never commit your API keys to the repository
- Rotate your API keys periodically
- Use different API keys for development and production
- Limit the permissions of your API keys to only what is necessary
EOL

# Create TROUBLESHOOTING.md
cat > docs/TROUBLESHOOTING.md << 'EOL'
# Troubleshooting Guide

This document provides solutions for common issues you might encounter when using the Claude WSL Environment.

## Installation Issues

### WSL Installation Fails

**Problem**: The WSL installation script fails with an error.

**Solution**:
1. Ensure you have enabled WSL in Windows Features
2. Try running the following commands in PowerShell as Administrator:
   ```powershell
   dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
   ```
3. Restart your computer
4. Re-run the setup script

### Package Installation Errors

**Problem**: You see errors when installing packages.

**Solution**:
1. Update your package lists:
   ```bash
   sudo apt update
   ```
2. Try running the specific installation script again

## Credential Issues

### API Key Not Recognized

**Problem**: Claude Code says your API key is invalid or not found.

**Solution**:
1. Verify your API key in the Anthropic Console
2. Re-run the credential setup script
3. Check that your environment variables are correctly set:
   ```bash
   echo $ANTHROPIC_API_KEY
   ```

### Windows-WSL Credential Sync Issues

**Problem**: Credentials set in Windows aren't available in WSL.

**Solution**:
1. Make sure you've run both the Windows and Linux credential scripts
2. Check that your WSL distribution is properly configured
3. Try restarting your WSL instance:
   ```powershell
   wsl --shutdown
   wsl
   ```

## Claude Code Issues

### Authentication Fails

**Problem**: Claude Code fails to authenticate with your Anthropic account.

**Solution**:
1. Verify that you have a valid Anthropic account with API access
2. Check that your API key has the necessary permissions
3. Re-run the Claude setup script

### GitHub Integration Issues

**Problem**: Claude Code cannot access your GitHub repositories.

**Solution**:
1. Verify your SSH key setup:
   ```bash
   ssh -T git@github.com
   ```
2. Check that your repositories are properly cloned
3. Re-run the Git configuration script

## Getting More Help

If you continue to experience issues:

1. Check for updated documentation in the repository
2. Open an issue on the GitHub repository
3. Consult the Claude Code documentation at the Anthropic website
EOL

# Make a commit if this is a new repository
if [ -d ".git" ]; then
    echo "Committing initial repository structure..."
    git add .
    git commit -m "Initial repository structure" || echo -e "${YELLOW}Note: Initial commit not created. This is normal if there are no changes.${NC}"
fi

echo -e "${GREEN}Repository initialization complete!${NC}"
exit 0