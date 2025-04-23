# wsl-4-claude

A best known configuration for WSL environments optimized for Claude Code and GitHub integration

## Overview

This project provides a standardized, well-tested WSL environment specifically designed for interacting with Claude Code and GitHub repositories. The setup scripts create a reliable foundation that minimizes the need for Linux administration expertise while ensuring all necessary components are properly configured.

## Key Features

- **Automated WSL Setup**: Complete WSL installation and configuration
- **Developer Tools**: Essential tools pre-configured for web development
- **GitHub Integration**: Seamless GitHub configuration with SSH support
- **Claude Code Setup**: Full Claude Code CLI configuration
- **Credential Management**: Separate dev/prod environments with secure credential handling
- **Cross-Platform Support**: Scripts for both Windows and Linux environments
- **Comprehensive Documentation**: Detailed guides for all components
- **Secure Configuration**: Separation of code and sensitive credentials

## Quick Start

### Prerequisites

- Windows 10 version 2004+ or Windows 11
- Admin access to your machine
- An Anthropic account with Claude API access

### Installing Claude Code with NVM (Recommended)

If you're experiencing issues with Claude Code installation or conflicts between Windows and WSL Node.js, use our simplified NVM-based installer:

1. Clone this repository on your Windows machine:

   ```
   git clone https://github.com/yourusername/wsl-4-claude.git
   cd wsl-4-claude
   ```

2. Run the PowerShell installer script as Administrator:

   ```powershell
   .\run-wsl-install.ps1
   ```

This script will:
- Check if WSL is installed (and help you install it if needed)
- Copy the installer script to your WSL environment
- Run the installer inside WSL
- Install Node.js using Node Version Manager (NVM)
- Install Claude Code using the NVM-managed Node.js

After installation completes, you can use Claude Code in WSL by:

```bash
# Open WSL
wsl

# Set your API key
export ANTHROPIC_API_KEY=your_api_key_here

# Run Claude Code
claudecode
```

## Full Environment Setup

For a complete WSL environment setup beyond just Claude Code:

1. Clone this repository:

   ```
   git clone https://github.com/yourusername/wsl-4-claude.git
   cd wsl-4-claude
   ```

2. Prepare the configuration (this will prompt for necessary credentials):

   ```
   chmod +x scripts/prepare-config.sh
   ./scripts/prepare-config.sh
   ```

3. Run the setup script:

   ```
   chmod +x setup.sh
   ./setup.sh
   ```

4. Follow the on-screen prompts to complete the installation.

## Troubleshooting Claude Code

If you're experiencing issues with Claude Code installation in WSL:

1. **Check Node.js Environment**: Ensure Node.js is properly installed in WSL (not using Windows Node.js)
   ```bash
   which node
   which npm
   ```
   These should point to Linux paths (e.g., `/usr/bin/node`) not Windows paths (`/mnt/c/...`)

2. **Path Conflicts**: Windows Node.js might be in your WSL PATH, causing conflicts
   ```bash
   echo $PATH
   ```
   Look for any `/mnt/c/` paths related to Node.js

3. **Use the NVM Method**: Our NVM-based installation script resolves most common issues by ensuring a clean Node.js installation isolated from Windows

4. **Common Errors**:
   - If npm tries to install to Windows paths (`C:\Users\...`), this indicates path conflicts
   - If you see "invalid argument" errors, this is often due to WSL trying to use Windows Node.js

## Documentation

See the documentation files in the `docs` directory for detailed information about the setup process, configuration options, and troubleshooting tips.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details
