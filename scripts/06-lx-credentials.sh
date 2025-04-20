#!/bin/bash
#
# Linux/WSL credential management script
# This script sets up credentials for the Claude WSL Environment
# Updated to use JSON config files when available

set -e  # Exit immediately if a command exits with a non-zero status

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Process environment parameter
ENV_TYPE="dev"
if [ $# -gt 0 ]; then
    if [ "$1" == "prod" ]; then
        ENV_TYPE="prod"
    elif [ "$1" == "dev" ]; then
        ENV_TYPE="dev"
    else
        echo -e "${RED}Invalid environment type: $1${NC}"
        echo "Usage: $0 [dev|prod]"
        exit 1
    fi
fi

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}  Linux/WSL Credential Management for Claude  ${NC}"
echo -e "${BLUE}===============================================${NC}"
echo ""
echo -e "Environment: ${YELLOW}$ENV_TYPE${NC}"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Define config files
CONFIG_DIR="$REPO_ROOT/config"
JSON_CONFIG="$CONFIG_DIR/06-lx-credentials.json"
ENV_FILE="$CONFIG_DIR/.${ENV_TYPE}.env"
ENV_EXAMPLE="$CONFIG_DIR/${ENV_TYPE}.env.example"

# Function to get value from JSON file
get_json_value() {
    local key=$1
    local default=$2
    local value=""
    
    # Check if jq is installed
    if command -v jq &> /dev/null; then
        # Use jq to extract value if file exists
        if [ -f "$JSON_CONFIG" ]; then
            value=$(jq -r ".$key // \"\"" "$JSON_CONFIG" 2>/dev/null)
        fi
    else
        # Fallback to grep if jq not available
        if [ -f "$JSON_CONFIG" ]; then
            value=$(grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$JSON_CONFIG" | sed 's/"'$key'"[[:space:]]*:[[:space:]]*"\(.*\)"/\1/' 2>/dev/null)
        fi
    fi
    
    # Return value or default
    if [ -z "$value" ] || [ "$value" = "null" ]; then
        echo "$default"
    else
        echo "$value"
    fi
}

# Check if JSON config file exists, create it if not
if [ ! -f "$JSON_CONFIG" ]; then
    echo "Creating JSON config file..."
    mkdir -p "$CONFIG_DIR"
    cat > "$JSON_CONFIG" << EOL
{
  "github_username": "",
  "github_email": "",
  "github_token": "",
  "openai_api_key": "",
  "anthropic_api_key": "",
  "credential_file_location": "${HOME}/.config/claude-code/credentials",
  "add_to_bashrc": true,
  "encrypt_credentials": false,
  "wsl_distro_name": ""
}
EOL
    echo -e "${GREEN}Created JSON config file: $JSON_CONFIG${NC}"
fi

# Check if environment file exists, if not create from template
if [ ! -f "$ENV_FILE" ]; then
    if [ -f "$ENV_EXAMPLE" ]; then
        cp "$ENV_EXAMPLE" "$ENV_FILE"
        echo -e "${GREEN}Created new environment file from template: $ENV_FILE${NC}"
    else
        # Create basic env file
        mkdir -p "$CONFIG_DIR"
        cat > "$ENV_FILE" << EOL
# Claude WSL Environment - $ENV_TYPE configuration
ENV_TYPE=$ENV_TYPE
GITHUB_USERNAME=
GITHUB_EMAIL=
ANTHROPIC_API_KEY=
WSL_DISTRO_NAME=
EOL
        echo -e "${GREEN}Created new environment file: $ENV_FILE${NC}"
    fi
fi

# Function to get a value from the environment file
get_env_value() {
    local key=$1
    local file=$2
    local value=""
    
    if [ -f "$file" ]; then
        value=$(grep "^$key=" "$file" | cut -d'=' -f2-)
    fi
    
    echo "$value"
}

# Function to update a key-value pair in the environment file
update_env_file() {
    local key=$1
    local value=$2
    local file=$3
    
    if grep -q "^$key=" "$file"; then
        # Update existing key
        sed -i "s|^$key=.*|$key=$value|" "$file"
    else
        # Add new key
        echo "$key=$value" >> "$file"
    fi
}

# Function to update a key-value pair in the JSON file
update_json_file() {
    local key=$1
    local value=$2
    local file=$3
    
    # Check if jq is installed
    if command -v jq &> /dev/null; then
        # Create a temporary file with the updated value
        jq ".$key = \"$value\"" "$file" > "$file.tmp"
        mv "$file.tmp" "$file"
    else
        # Fallback if jq not available (less reliable)
        if grep -q "\"$key\":" "$file"; then
            sed -i "s|\"$key\":[[:space:]]*\"[^\"]*\"|\"$key\": \"$value\"|" "$file"
        else
            # This is a simplistic approach and might break with complex JSON
            # Insert before the closing brace
            sed -i "s|}|,\n  \"$key\": \"$value\"\n}|" "$file"
        fi
    fi
}

# Function to prompt for a credential value if not in JSON
prompt_credential() {
    local key=$1
    local prompt_text=$2
    local json_key=$3
    
    # First try to get from JSON
    local value=$(get_json_value "$json_key" "")
    
    # If not in JSON, try env file
    if [ -z "$value" ]; then
        value=$(get_env_value "$key" "$ENV_FILE")
    fi
    
    # If still empty, prompt user
    if [ -z "$value" ]; then
        read -p "$prompt_text: " input_value
        value="$input_value"
        
        # Update both JSON and env file
        update_json_file "$json_key" "$value" "$JSON_CONFIG"
    else
        echo -e "Using $prompt_text from config: ${value:0:3}...${value:(-3)}"
    fi
    
    # Update env file
    update_env_file "$key" "$value" "$ENV_FILE"
    
    echo "$value"
}

# Get credentials from JSON or prompt
ANTHROPIC_API_KEY=$(prompt_credential "ANTHROPIC_API_KEY" "Anthropic API Key" "anthropic_api_key")
GITHUB_USERNAME=$(prompt_credential "GITHUB_USERNAME" "GitHub Username" "github_username")
GITHUB_EMAIL=$(prompt_credential "GITHUB_EMAIL" "GitHub Email" "github_email")
GITHUB_TOKEN=$(prompt_credential "GITHUB_TOKEN" "GitHub Token" "github_token")
OPENAI_API_KEY=$(prompt_credential "OPENAI_API_KEY" "OpenAI API Key" "openai_api_key")
WSL_DISTRO_NAME=$(prompt_credential "WSL_DISTRO_NAME" "WSL Distribution Name" "wsl_distro_name")

# Get configuration options from JSON
ENCRYPT_CREDENTIALS=$(get_json_value "encrypt_credentials" "false")
ADD_TO_BASHRC=$(get_json_value "add_to_bashrc" "true")
CREDS_FILE_LOCATION=$(get_json_value "credential_file_location" "${HOME}/.config/claude-code/credentials")

# Expand variables in credential file location
CREDS_FILE_LOCATION=$(eval echo "$CREDS_FILE_LOCATION")

# Create credentials directory
CREDS_DIR=$(dirname "$CREDS_FILE_LOCATION")
mkdir -p "$CREDS_DIR"
chmod 700 "$CREDS_DIR"

# Store credentials in file
echo "Creating credentials file at $CREDS_FILE_LOCATION..."
cat > "$CREDS_FILE_LOCATION" << EOL
# Claude WSL Environment - $ENV_TYPE Environment
# Generated by 06-lx-credentials.sh script

export ENV_TYPE="$ENV_TYPE"
export ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY"
export GITHUB_USERNAME="$GITHUB_USERNAME"
export GITHUB_EMAIL="$GITHUB_EMAIL"
export GITHUB_TOKEN="$GITHUB_TOKEN"
export OPENAI_API_KEY="$OPENAI_API_KEY"
export WSL_DISTRO_NAME="$WSL_DISTRO_NAME"
EOL
chmod 600 "$CREDS_FILE_LOCATION"

echo -e "${GREEN}Stored credentials in: $CREDS_FILE_LOCATION${NC}"

# Determine shell configuration file
SHELL_CONFIG=""
if [ -f "$HOME/.zshrc" ] && [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_CONFIG="$HOME/.zshrc"
    echo "Using zsh configuration: $SHELL_CONFIG"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
    echo "Using bash configuration: $SHELL_CONFIG"
else
    echo -e "${RED}No supported shell configuration file found.${NC}"
    echo "Please add the environment variables manually to your shell configuration."
    exit 1
fi

# Encrypt credentials if requested
if [ "$ENCRYPT_CREDENTIALS" = "true" ]; then
    if command -v gpg &> /dev/null; then
        echo "GPG is available. Encrypting credentials..."
        
        # Check if the user has a GPG key
        if ! gpg --list-secret-keys | grep -q "sec"; then
            echo "No GPG keys found. Generating a new key..."
            gpg --full-generate-key
        fi
        
        # Get the user's GPG key ID
        GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format LONG | grep -oP "sec.*rsa.*/\K[A-Z0-9]*" | head -1)
        
        if [ -n "$GPG_KEY_ID" ]; then
            # Encrypt the credentials file
            gpg --recipient "$GPG_KEY_ID" --encrypt "$CREDS_FILE_LOCATION"
            mv "$CREDS_FILE_LOCATION.gpg" "$CREDS_FILE_LOCATION.gpg"
            rm "$CREDS_FILE_LOCATION"  # Remove the unencrypted file
            echo -e "${GREEN}Credentials encrypted with GPG key: $GPG_KEY_ID${NC}"
            
            # Create a helper script to load encrypted credentials
            LOAD_SCRIPT="$CREDS_DIR/load-${ENV_TYPE}.sh"
            cat > "$LOAD_SCRIPT" << EOL
#!/bin/bash
#
# Load encrypted credentials for Claude WSL Environment
# This script decrypts and loads the $ENV_TYPE environment credentials

# Decrypt the credentials
gpg --quiet --decrypt "$CREDS_FILE_LOCATION.gpg" | source /dev/stdin

# Display environment information
echo "Claude WSL Environment - \$ENV_TYPE Environment"
echo "GitHub Username: \$GITHUB_USERNAME"
echo "GitHub Email: \$GITHUB_EMAIL"
echo "ANTHROPIC_API_KEY: \${ANTHROPIC_API_KEY:0:3}...\${ANTHROPIC_API_KEY:(-3)}"
EOL
            chmod 700 "$LOAD_SCRIPT"
            
            # Add source command to shell configuration if requested
            if [ "$ADD_TO_BASHRC" = "true" ]; then
                if ! grep -q "# Claude WSL Environment - $ENV_TYPE" "$SHELL_CONFIG"; then
                    cat >> "$SHELL_CONFIG" << EOL

# Claude WSL Environment - $ENV_TYPE
alias load-claude-$ENV_TYPE='source "$LOAD_SCRIPT"'
EOL
                    echo -e "${GREEN}Added alias to $SHELL_CONFIG: load-claude-$ENV_TYPE${NC}"
                else
                    echo -e "${YELLOW}Claude WSL Environment configuration already exists in $SHELL_CONFIG.${NC}"
                fi
            fi
        else
            echo -e "${RED}No GPG key found. Skipping encryption.${NC}"
            ENCRYPT_CREDENTIALS="false"
        fi
    else
        echo -e "${YELLOW}GPG not available. Skipping encryption.${NC}"
        ENCRYPT_CREDENTIALS="false"
        
        # Update JSON config to reflect reality
        update_json_file "encrypt_credentials" "false" "$JSON_CONFIG"
    fi
fi

# Add credentials to shell config if not encrypted and if requested
if [ "$ENCRYPT_CREDENTIALS" = "false" ] && [ "$ADD_TO_BASHRC" = "true" ]; then
    if ! grep -q "# Claude WSL Environment - $ENV_TYPE" "$SHELL_CONFIG"; then
        cat >> "$SHELL_CONFIG" << EOL

# Claude WSL Environment - $ENV_TYPE
if [ "\$ENV_TYPE" = "$ENV_TYPE" ] || [ -z "\$ENV_TYPE" ]; then
    source "$CREDS_FILE_LOCATION"
fi
EOL
        echo -e "${GREEN}Added source command to $SHELL_CONFIG${NC}"
    else
        echo -e "${YELLOW}Claude WSL Environment configuration already exists in $SHELL_CONFIG.${NC}"
    fi
fi

# Create a function to switch between environments
if [ "$ADD_TO_BASHRC" = "true" ] && ! grep -q "function claude-env" "$SHELL_CONFIG"; then
    cat >> "$SHELL_CONFIG" << 'EOL'

# Function to switch between Claude environments
claude-env() {
    local env_type=$1
    if [ "$env_type" = "dev" ] || [ "$env_type" = "prod" ]; then
        if [ -f "$HOME/.config/claude-code/credentials-$env_type" ]; then
            source "$HOME/.config/claude-code/credentials-$env_type"
            echo "Switched to $env_type environment"
        elif [ -f "$HOME/.config/claude-code/credentials" ]; then
            source "$HOME/.config/claude-code/credentials"
            echo "Switched to default environment"
        else
            echo "Environment credentials not found"
            echo "Please run the credential management script for this environment."
        fi
    else
        echo "Invalid environment type: $env_type"
        echo "Usage: claude-env [dev|prod]"
    fi
}
EOL
    echo -e "${GREEN}Added environment switching function to $SHELL_CONFIG${NC}"
fi

# Create a verification script
VERIFY_SCRIPT="$CREDS_DIR/verify-credentials.sh"
cat > "$VERIFY_SCRIPT" << EOL
#!/bin/bash
#
# Verify Claude WSL Environment Credentials
# This script checks that the credentials are working correctly

# Load credentials
if [ -f "$CREDS_FILE_LOCATION" ]; then
    source "$CREDS_FILE_LOCATION"
elif [ -f "$CREDS_FILE_LOCATION.gpg" ]; then
    echo "Encrypted credentials found. Decrypting..."
    gpg --quiet --decrypt "$CREDS_FILE_LOCATION.gpg" | source /dev/stdin
else
    echo "Credentials file not found at $CREDS_FILE_LOCATION"
    exit 1
fi

# Display environment information
echo "Claude WSL Environment - \$ENV_TYPE Environment"
echo "GitHub Username: \$GITHUB_USERNAME"
echo "GitHub Email: \$GITHUB_EMAIL"
echo "ANTHROPIC_API_KEY: \${ANTHROPIC_API_KEY:0:3}...\${ANTHROPIC_API_KEY:(-3)}"
echo ""

# Check GitHub credentials
echo "Checking GitHub credentials..."
if [ -n "\$GITHUB_USERNAME" ] && [ -n "\$GITHUB_EMAIL" ]; then
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        echo "✅ GitHub SSH connection successful!"
    else
        echo "❌ GitHub SSH connection failed. Make sure your SSH key is added to GitHub."
    fi
else
    echo "❌ GitHub credentials not found."
fi

# Check Anthropic API Key
echo ""
echo "Checking Anthropic API Key..."
if [ -n "\$ANTHROPIC_API_KEY" ]; then
    # Make a simple API call to check if the key is valid
    if command -v curl &> /dev/null; then
        HTTP_STATUS=\$(curl -s -o /dev/null -w "%{http_code}" -H "Content-Type: application/json" -H "x-api-key: \$ANTHROPIC_API_KEY" -H "anthropic-version: 2023-06-01" https://api.anthropic.com/v1/models)
        
        if [ "\$HTTP_STATUS" = "200" ]; then
            echo "✅ Anthropic API Key is valid!"
        else
            echo "❌ Anthropic API Key validation failed. Status code: \$HTTP_STATUS"
        fi
    else
        echo "❓ Cannot verify API key: curl is not installed."
    fi
else
    echo "❌ Anthropic API Key not found."
fi
EOL
chmod 700 "$VERIFY_SCRIPT"

echo -e "${GREEN}Created verification script: $VERIFY_SCRIPT${NC}"

# Done
echo -e "${GREEN}Linux/WSL credential management setup complete!${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Restart your shell or run: source $SHELL_CONFIG"
echo "2. Verify your credentials with: $VERIFY_SCRIPT"
echo "3. Switch between environments with: claude-env [dev|prod]"
echo ""
echo "Your credentials are now stored in: $CREDS_FILE_LOCATION"
echo "Your configuration is stored in: $JSON_CONFIG"
echo ""
echo "To modify settings, edit the JSON config file and re-run this script."
exit 0
