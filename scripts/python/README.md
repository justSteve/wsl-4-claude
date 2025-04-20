# Configuration Generator for WSL Claude Code Environment

This directory contains Python scripts for generating configuration files used by the WSL Claude Code setup scripts. The main purpose is to separate sensitive information (stored in `~/secrets`) from the configuration logic (stored in this repository).

## Main Features

- Centralized secrets management in a single JSON file (`~/secrets/secrets.json`)
- Generation of configuration files for different setup scripts
- Interactive mode for setting up missing secrets
- Command-line interface for automation

## Usage

### Basic Usage

To interactively set up all configuration files:

```bash
python3 generate_config.py --interactive --all
```

### Command-Line Options

- `--all`: Generate all configuration files
- `--git`: Generate only Git configuration
- `--claude`: Generate only Claude Code configuration
- `--creds`: Generate only credentials configuration
- `--interactive`: Run interactive setup for missing secrets
- `--update-secret NAME VALUE`: Update a specific secret

### Examples

Update a single secret:

```bash
python3 generate_config.py --update-secret github_token your-token-here
```

Generate just the Git configuration:

```bash
python3 generate_config.py --git
```

### Required Secrets

The following secrets are required for a complete setup:

- `github_username`: Your GitHub username
- `github_email`: Your GitHub email
- `github_token`: Your GitHub personal access token
- `anthropic_api_key`: Your Anthropic API key for Claude

Optional secrets:

- `openai_api_key`: Your OpenAI API key (if using OpenAI services)
- `wsl_distro_name`: Your WSL distribution name (defaults to "Ubuntu")

## Security Notes

- The secrets file is stored in `~/secrets/secrets.json` and is excluded from Git
- The file permissions are set to 600 (readable only by the owner)
- Never commit sensitive information to the repository
