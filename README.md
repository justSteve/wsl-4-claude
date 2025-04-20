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
- Python 3.6 or higher

### Installation

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

## Configuration

The project uses a secure configuration approach that separates sensitive information from the code:

1. **Secrets Management**: All sensitive information is stored in `~/secrets/secrets.json`
2. **Configuration Generation**: Python scripts generate the necessary config files
3. **Logging**: All operations are logged for easy troubleshooting

### Managing Secrets

You can update your secrets:

```bash
python3 scripts/python/generate_config.py --update-secret github_token your-new-token
```

Or run the interactive configuration:

```bash
python3 scripts/python/generate_config.py --interactive
```

### Environment Types

The system supports different environment types (dev/prod):

```bash
# Configure development environment
./scripts/06-lx-credentials.sh dev

# Configure production environment
./scripts/06-lx-credentials.sh prod
```

## Documentation

See the `scripts/python/README.md` file for detailed information about the configuration system.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details
