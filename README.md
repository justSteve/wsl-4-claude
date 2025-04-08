# Claude WSL Environment

A "best known configuration" for WSL environments optimized for running Claude Code with GitHub integration.

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

## Quick Start

### Prerequisites

- Windows 10 version 2004+ or Windows 11
- Admin access to your machine
- An Anthropic account with Claude API access

### Installation

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/claude-wsl-env.git
   cd claude-wsl-env
   ```

2. Run the setup script:
   ```
   ./setup.sh
   ```

3. Follow the on-screen prompts to complete the installation.

## Configuration

After installation, you'll need to configure your credentials:

1. For development:
   ```
   cp config/dev.env.example config/.dev.env
   ```
   Edit `.dev.env` with your development API keys

2. For production:
   ```
   cp config/prod.env.example config/.prod.env
   ```
   Edit `.prod.env` with your production API keys

3. Run the credential setup:
   ```
   ./scripts/05-win-credentials.ps1 dev  # For Windows
   ./scripts/06-lx-credentials.sh dev    # For Linux/WSL
   ```

## Documentation

- [Usage Guide](docs/USAGE.md): Detailed usage instructions
- [Credential Management](docs/CREDENTIALS.md): How to manage your API keys
- [Troubleshooting](docs/TROUBLESHOOTING.md): Common issues and solutions

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details