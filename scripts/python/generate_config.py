#!/usr/bin/env python3
"""
Centralized configuration generator for WSL Claude Code environment.
This script manages secrets and generates configuration files for the setup scripts.
"""

import json
import os
import sys
import argparse

# Define the path to secrets folder and config directory
SECRETS_DIR = os.path.expanduser("~/secrets")
CONFIG_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "config")

def ensure_secrets_file():
    """
    Ensure the centralized secrets file exists.
    Creates the file and directory if they don't exist.
    Sets proper permissions (600) for security.
    Returns the path to the secrets file.
    """
    # Path to the centralized secrets file
    secrets_file = os.path.join(SECRETS_DIR, "secrets.json")
    
    # Create the secrets directory if it doesn't exist
    os.makedirs(SECRETS_DIR, exist_ok=True)
    
    # Check if the secrets file exists
    if not os.path.exists(secrets_file):
        print(f"Creating new secrets file at {secrets_file}")
        # Create an empty secrets file
        with open(secrets_file, 'w') as f:
            json.dump({}, f, indent=2)
        
        # Set appropriate permissions (readable only by the owner)
        os.chmod(secrets_file, 0o600)
        
    return secrets_file

def load_secret(secret_name, default_value=""):
    """
    Load a secret from the centralized secrets.json file.
    Falls back to default value if the secret doesn't exist.
    Handles various error conditions gracefully.
    """
    # Path to the centralized secrets file
    secrets_file = os.path.join(SECRETS_DIR, "secrets.json")
    
    # Check if the secrets file exists
    if os.path.exists(secrets_file):
        try:
            # Load the JSON file
            with open(secrets_file, 'r') as f:
                secrets = json.load(f)
            
            # Return the secret if it exists in the file
            if secret_name in secrets:
                return secrets[secret_name]
            else:
                print(f"Secret {secret_name} not found in secrets file, using default value")
                return default_value
        except json.JSONDecodeError:
            print(f"Error: secrets file is not valid JSON")
            return default_value
        except Exception as e:
            print(f"Error loading secrets file: {e}")
            return default_value
    else:
        print(f"Secrets file not found at {secrets_file}, using default value")
        return default_value

def update_secret(secret_name, secret_value):
    """
    Update or add a secret in the centralized secrets.json file.
    Creates the file if it doesn't exist.
    Preserves existing secrets when updating.
    """
    # Ensure the secrets file exists
    secrets_file = ensure_secrets_file()
    
    # Load current secrets
    try:
        with open(secrets_file, 'r') as f:
            secrets = json.load(f)
    except json.JSONDecodeError:
        # If the file is not valid JSON, start with an empty dict
        secrets = {}
    
    # Update the secret
    secrets[secret_name] = secret_value
    
    # Write back to the file
    with open(secrets_file, 'w') as f:
        json.dump(secrets, f, indent=2)
    
    print(f"Updated secret: {secret_name}")

def create_git_config():
    """
    Create the Git configuration JSON file.
    Pulls sensitive values from the centralized secrets file.
    Non-sensitive values are set as constants.
    """
    output_file = os.path.join(CONFIG_DIR, "03-git-config.json")
    
    # Create config directory if it doesn't exist
    os.makedirs(CONFIG_DIR, exist_ok=True)
    
    # Define the configuration with sensitive data from secrets
    config = {
        "git_user_name": load_secret("github_username"),
        "git_user_email": load_secret("github_email"),
        "github_token": load_secret("github_token"),
        "generate_ssh_key": True,
        "ssh_key_type": "ed25519",
        "git_default_branch": "main",
        "git_editor": "nano",
        "setup_global_gitignore": True,
        "create_clone_helper": True
    }
    
    # Write the configuration to the output file
    with open(output_file, 'w') as f:
        json.dump(config, f, indent=2)
    
    print(f"Created Git configuration file at {output_file}")

def create_claude_config():
    """
    Create the Claude Code configuration JSON file.
    Pulls sensitive values from the centralized secrets file.
    Non-sensitive values are set as constants.
    """
    output_file = os.path.join(CONFIG_DIR, "04-claude-setup.json")
    
    # Create config directory if it doesn't exist
    os.makedirs(CONFIG_DIR, exist_ok=True)
    
    # Define the configuration
    config = {
        "installation_method": "npm",
        "binary_url": "",
        "default_model": "claude-3-opus-20240229",
        "temperature": "0.7",
        "max_tokens": "4096",
        "log_level": "info",
        "setup_aliases": "true",
        "create_project_templates": "true",
        "anthropic_api_key": load_secret("anthropic_api_key")
    }
    
    # Write the configuration to the output file
    with open(output_file, 'w') as f:
        json.dump(config, f, indent=2)
    
    print(f"Created Claude configuration file at {output_file}")

def create_credentials_config():
    """
    Create the credentials configuration JSON file.
    Pulls sensitive values from the centralized secrets file.
    Non-sensitive values are set as constants.
    """
    output_file = os.path.join(CONFIG_DIR, "06-lx-credentials.json")
    
    # Create config directory if it doesn't exist
    os.makedirs(CONFIG_DIR, exist_ok=True)
    
    # Define the configuration with sensitive data from secrets
    config = {
        "github_username": load_secret("github_username"),
        "github_email": load_secret("github_email"),
        "github_token": load_secret("github_token"),
        "openai_api_key": load_secret("openai_api_key"),
        "anthropic_api_key": load_secret("anthropic_api_key"),
        "credential_file_location": "${HOME}/.config/claude-code/credentials",
        "add_to_bashrc": True,
        "encrypt_credentials": False,
        "wsl_distro_name": load_secret("wsl_distro_name", "Ubuntu")
    }
    
    # Write the configuration to the output file
    with open(output_file, 'w') as f:
        json.dump(config, f, indent=2)
    
    print(f"Created credentials configuration file at {output_file}")

def check_required_secrets():
    """
    Check if all required secrets are available.
    Returns a list of missing secrets.
    """
    # List of required secrets
    required_secrets = [
        "github_username", 
        "github_email", 
        "github_token",
        "anthropic_api_key"
    ]
    
    # Check for missing secrets
    missing_secrets = []
    for secret in required_secrets:
        if not load_secret(secret):  # Empty string is falsy
            missing_secrets.append(secret)
    
    return missing_secrets

def interactive_setup():
    """
    Interactively set up missing secrets.
    """
    # Ensure secrets file exists
    ensure_secrets_file()
    
    # Check for missing secrets
    missing_secrets = check_required_secrets()
    
    # If there are missing secrets, prompt the user to provide them
    if missing_secrets:
        print("The following secrets are missing:")
        for secret in missing_secrets:
            print(f"  - {secret}")
        
        # Ask if the user wants to input the secrets now
        create_now = input("Would you like to input these secrets now? (y/n): ")
        if create_now.lower() in ['y', 'yes']:
            for secret in missing_secrets:
                value = input(f"Enter value for {secret}: ")
                update_secret(secret, value)
    else:
        print("All required secrets are available")

def main():
    """
    Main function to parse arguments and run the appropriate actions.
    """
    parser = argparse.ArgumentParser(description='Generate configuration files for WSL Claude Code environment')
    parser.add_argument('--all', action='store_true', help='Generate all configuration files')
    parser.add_argument('--git', action='store_true', help='Generate Git configuration')
    parser.add_argument('--claude', action='store_true', help='Generate Claude Code configuration')
    parser.add_argument('--creds', action='store_true', help='Generate credentials configuration')
    parser.add_argument('--interactive', action='store_true', help='Run interactive setup for missing secrets')
    parser.add_argument('--update-secret', nargs=2, metavar=('NAME', 'VALUE'), help='Update a secret')
    
    args = parser.parse_args()
    
    # Make sure the secrets file exists
    ensure_secrets_file()
    
    # Handle updating a secret
    if args.update_secret:
        update_secret(args.update_secret[0], args.update_secret[1])
    
    # Handle interactive setup
    if args.interactive:
        interactive_setup()
    
    # Generate configurations
    if args.all or args.git:
        create_git_config()
    
    if args.all or args.claude:
        create_claude_config()
    
    if args.all or args.creds:
        create_credentials_config()
    
    # If no generation options specified, show help
    if not (args.all or args.git or args.claude or args.creds or args.interactive or args.update_secret):
        parser.print_help()

if __name__ == "__main__":
    main()
