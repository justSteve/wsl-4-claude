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
