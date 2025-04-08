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
