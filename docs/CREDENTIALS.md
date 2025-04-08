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
