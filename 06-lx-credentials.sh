#!/bin/bash
#
# Linux/WSL credential management script
# This script sets up credentials for the Claude WSL Environment

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

# Determine the environment file path
if [ "$ENV_TYPE" == "dev" ]; then
    ENV_FILE="$REPO_ROOT/config/.dev.env"
    ENV_EXAMPLE="$REPO_ROOT/config/dev.env.example"
    echo -e "${YELLOW}Using development environment configuration${NC}"
else
    ENV_FILE="$REPO_ROOT/config/.prod.env"
    ENV_EXAMPLE="$REPO_ROOT/config/prod.env.example"
    echo -e "${YELLOW}Using production environment configuration${NC}"
fi

# Check if environment file exists, if not create from template
if [ ! -f "$ENV_FILE" ]; then
    if [ -f "$ENV_EXAMPLE" ]; then
        cp "$ENV_EXAMPLE" "$ENV_FILE"
        echo -e "${GREEN}Created new environment file from template: $ENV_FILE${NC}"
    else
        echo -e "${RED}Template file not found: $ENV_EXAMPLE${NC}"
        echo "Please run the repository initialization script first."
        exit 1
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

# Function to prompt for a credential value
prompt_credential() {
    local prompt_text=$1
    local default_value=$2
    local value=""
    
    if [ -z "$default_value" ]; then
        read -p "$prompt_text: " value
    else
        read -p "$prompt_text [$default_value]: " value
        if [ -z "$value" ]; then
            value="$default_value"
        fi
    fi
    
    echo "$value"
}

# Get existing values from environment file
ANTHROPIC_API_KEY=$(get_env_value "ANTHROPIC_API_KEY" "$ENV_FILE")
GITHUB_USERNAME=$(get_env_value "GITHUB_USERNAME" "$ENV_FILE")
GITHUB_EMAIL=$(get_env_value "GITHUB_EMAIL" "$ENV_FILE")
WSL_DISTRO_NAME=$(get_env_value "WSL_DISTRO_NAME" "$ENV_FILE")

# Prompt for credentials
echo "Please enter your credentials:"
echo ""

ANTHROPIC_API_KEY=$(prompt_credential "Anthropic API Key" "$ANTHROPIC_API_KEY")
GITHUB_USERNAME=$(prompt_credential "GitHub Username" "$GITHUB_USERNAME")
GITHUB_EMAIL=$(prompt_credential "GitHub Email" "$GITHUB_EMAIL")
WSL_DISTRO_NAME=$(prompt_credential "WSL Distribution Name" "$WSL_DISTRO_NAME")

# Update environment file
update_env_file "ANTHROPIC_API_KEY" "$ANTHROPIC_API_KEY" "$ENV_FILE"
update_env_file "GITHUB_USERNAME" "$GITHUB_USERNAME" "$ENV_FILE"
update_env_file "GITHUB_EMAIL" "$GITHUB_EMAIL" "$ENV_FILE"
update_env_file "WSL_DISTRO_NAME" "$WSL_DISTRO_NAME" "$ENV_FILE"
update_env_file "ENV_TYPE" "$ENV_TYPE" "$ENV_FILE"

echo -e "${GREEN}Updated environment file: $ENV_FILE${NC}"

# Determine shell configuration file
SHELL_CONFIG=""
if [ -f "$HOME/.zshrc" ] && [ "$SHELL" = *"zsh"* ]; then
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

# Create credentials directory
CREDS_DIR="$HOME/.claude-creds"
mkdir -p "$CREDS_DIR"
chmod 700 "$CREDS_DIR"

# Store credentials in files
CREDS_FILE="$CREDS_DIR/${ENV_TYPE}.env"
cat > "$CREDS_FILE" << EOL
# Claude WSL Environment - $ENV_TYPE Environment
export ENV_TYPE="$ENV_TYPE"
export ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY"
export GITHUB_USERNAME="$GITHUB_USERNAME"
export GITHUB_EMAIL="$GITHUB_EMAIL"
export WSL_DISTRO_NAME="$WSL_DISTRO_NAME"
EOL
chmod 600 "$CREDS_FILE"

echo -e "${GREEN}Stored credentials in: $CREDS_FILE${NC}"

# Check if GPG is available for encryption
if command -v gpg &> /dev/null; then
    echo "GPG is available. Would you like to encrypt your credentials? (y/n)"
    read -r encrypt
    if [[ $encrypt =~ ^[Yy]$ ]]; then
        # Check if the user has a GPG key
        if ! gpg --list-secret-keys | grep -q "sec"; then
            echo "No GPG keys found. Would you like to generate one? (y/n)"
            read -r generate
            if [[ $generate =~ ^[Yy]$ ]]; then
                # Generate GPG key
                gpg --full-generate-key
            else
                echo "Skipping encryption."
                encrypt="n"
            fi
        fi
        
        if [[ $encrypt =~ ^[Yy]$ ]]; then
            # Get the user's GPG key ID
            GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format LONG | grep -oP "sec.*rsa.*/\K[A-Z0-9]*" | head -1)
            
            if [ -n "$GPG_KEY_ID" ]; then
                # Encrypt the credentials file
                gpg --recipient "$GPG_KEY_ID" --encrypt "$CREDS_FILE"
                rm "$CREDS_FILE"  # Remove the unencrypted file
                echo -e "${GREEN}Credentials encrypted with GPG key: $GPG_KEY_ID${NC}"
                echo "Encrypted credentials stored in: $CREDS_FILE.gpg"
                
                # Create a helper script to load encrypted credentials
                LOAD_SCRIPT="$CREDS_DIR/load-${ENV_TYPE}.sh"
                cat > "$LOAD_SCRIPT" << EOL
#!/bin/bash
#
# Load encrypted credentials for Claude WSL Environment
# This script decrypts and loads the $ENV_TYPE environment credentials

# Decrypt the credentials
gpg --quiet --decrypt "$CREDS_FILE.gpg" | source /dev/stdin

# Display environment information
echo "Claude WSL Environment - \$ENV_TYPE Environment"
echo "GitHub Username: \$GITHUB_USERNAME"
echo "GitHub Email: \$GITHUB_EMAIL"
echo "ANTHROPIC_API_KEY: \${ANTHROPIC_API_KEY:0:3}...\${ANTHROPIC_API_KEY:(-3)}"
EOL
                chmod 700 "$LOAD_SCRIPT"
                
                # Add source command to shell configuration
                if ! grep -q "# Claude WSL Environment - $ENV_TYPE" "$SHELL_CONFIG"; then
                    cat >> "$SHELL_CONFIG" << EOL

# Claude WSL Environment - $ENV_TYPE
alias load-claude-$ENV_TYPE='source "$LOAD_SCRIPT"'
EOL
                    echo -e "${GREEN}Added alias to $SHELL_CONFIG: load-claude-$ENV_TYPE${NC}"
                else
                    echo -e "${YELLOW}Claude WSL Environment configuration already exists in $SHELL_CONFIG.${NC}"
                fi
            else
                echo -e "${RED}No GPG key found. Skipping encryption.${NC}"
                encrypt="n"
            fi
        fi
    else
        encrypt="n"
    fi
else
    echo -e "${YELLOW}GPG not available. Skipping encryption.${NC}"
    encrypt="n"
fi

# If not encrypting, add source command to shell configuration
if [[ $encrypt != "y" ]]; then
    if ! grep -q "# Claude WSL Environment - $ENV_TYPE" "$SHELL_CONFIG"; then
        cat >> "$SHELL_CONFIG" << EOL

# Claude WSL Environment - $ENV_TYPE
alias load-claude-$ENV_TYPE='source "$CREDS_FILE"'
if [ "\$ENV_TYPE" = "$ENV_TYPE" ] || [ -z "\$ENV_TYPE" ]; then
    source "$CREDS_FILE"
fi
EOL
        echo -e "${GREEN}Added source command to $SHELL_CONFIG${NC}"
    else
        echo -e "${YELLOW}Claude WSL Environment configuration already exists in $SHELL_CONFIG.${NC}"
    fi
fi

# Create a function to switch between environments
if ! grep -q "function claude-env" "$SHELL_CONFIG"; then
    cat >> "$SHELL_CONFIG" << 'EOL'

# Function to switch between Claude environments
claude-env() {
    local env_type=$1
    if [ "$env_type" = "dev" ] || [ "$env_type" = "prod" ]; then
        alias_name="load-claude-$env_type"
        if alias "$alias_name" &>/dev/null; then
            eval "$alias_name"
            echo "Switched to $env_type environment"
        else
            echo "Environment alias not found: $alias_name"
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

# Create activation script for automatic environment loading in WSL
ACTIVATE_SCRIPT="$HOME/.claude-activate.sh"
cat > "$ACTIVATE_SCRIPT" << EOL
#!/bin/bash
#
# Claude WSL Environment Activation Script
# This script automatically loads Claude environment on WSL startup

# Check if we're running in WSL
if grep -q Microsoft /proc/version || grep -q microsoft /proc/version; then
    # Check if ENV_TYPE is already set (e.g., by the WSL bridge script)
    if [ -z "\$ENV_TYPE" ]; then
        # Default to $ENV_TYPE if not set
        ENV_TYPE="$ENV_TYPE"
    fi
    
    # Load credentials
    CREDS_FILE="\$HOME/.claude-creds/\$ENV_TYPE.env"
    CREDS_FILE_GPG="\$HOME/.claude-creds/\$ENV_TYPE.env.gpg"
    LOAD_SCRIPT="\$HOME/.claude-creds/load-\$ENV_TYPE.sh"
    
    if [ -f "\$LOAD_SCRIPT" ]; then
        source "\$LOAD_SCRIPT"
    elif [ -f "\$CREDS_FILE" ]; then
        source "\$CREDS_FILE"
        echo "Claude WSL Environment - \$ENV_TYPE Environment"
        echo "GitHub Username: \$GITHUB_USERNAME"
        echo "GitHub Email: \$GITHUB_EMAIL"
        echo "ANTHROPIC_API_KEY: \${ANTHROPIC_API_KEY:0:3}...\${ANTHROPIC_API_KEY:(-3)}"
    elif [ -f "\$CREDS_FILE_GPG" ]; then
        echo "Encrypted credentials found. Run 'load-claude-\$ENV_TYPE' to load them."
    else
        echo "No Claude credentials found for \$ENV_TYPE environment."
        echo "Please run the credential management script: ./scripts/06-lx-credentials.sh \$ENV_TYPE"
    fi
fi
EOL
chmod 700 "$ACTIVATE_SCRIPT"

# Add activation script to shell configuration
if ! grep -q "# Claude WSL Environment Activation" "$SHELL_CONFIG"; then
    cat >> "$SHELL_CONFIG" << EOL

# Claude WSL Environment Activation
if [ -f "\$HOME/.claude-activate.sh" ]; then
    source "\$HOME/.claude-activate.sh"
fi
EOL
    echo -e "${GREEN}Added activation script to $SHELL_CONFIG${NC}"
fi

# Create a script to verify the credentials are working
VERIFY_SCRIPT="$CREDS_DIR/verify-${ENV_TYPE}.sh"
cat > "$VERIFY_SCRIPT" << EOL
#!/bin/bash
#
# Verify Claude WSL Environment Credentials
# This script checks that the credentials are working correctly

# Load credentials
source "$CREDS_FILE" 2>/dev/null || echo "Error loading credentials"

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

# Create a script to install "pass" password manager for more secure credential storage
if ! command -v pass &> /dev/null; then
    PASS_INSTALL_SCRIPT="$CREDS_DIR/install-pass.sh"
    cat > "$PASS_INSTALL_SCRIPT" << 'EOL'
#!/bin/bash
#
# Install "pass" Password Manager
# This script installs the "pass" password manager for more secure credential storage

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Installing 'pass' password manager...${NC}"

# Check if pass is already installed
if command -v pass &> /dev/null; then
    echo -e "${GREEN}pass is already installed.${NC}"
    exit 0
fi

# Install pass
sudo apt-get update
sudo apt-get install -y pass

# Check if installation was successful
if command -v pass &> /dev/null; then
    echo -e "${GREEN}pass installed successfully!${NC}"
    
    # Check if GPG key exists
    if ! gpg --list-secret-keys | grep -q "sec"; then
        echo -e "${YELLOW}No GPG keys found. Generating a new GPG key...${NC}"
        gpg --full-generate-key
    fi
    
    # Get the user's GPG key ID
    GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format LONG | grep -oP "sec.*rsa.*/\K[A-Z0-9]*" | head -1)
    
    if [ -n "$GPG_KEY_ID" ]; then
        # Initialize pass
        pass init "$GPG_KEY_ID"
        echo -e "${GREEN}pass initialized with GPG key: $GPG_KEY_ID${NC}"
        
        # Display usage instructions
        echo ""
        echo -e "${YELLOW}Usage:${NC}"
        echo "  pass insert anthropic/api-key  # Store API key"
        echo "  pass anthropic/api-key         # Retrieve API key"
        echo ""
        echo "For more information, run: pass help"
    else
        echo -e "${RED}Failed to get GPG key ID. Please initialize pass manually.${NC}"
    fi
else
    echo -e "${RED}Failed to install pass.${NC}"
fi
EOL
    chmod 700 "$PASS_INSTALL_SCRIPT"
    
    echo -e "${YELLOW}Would you like to install the 'pass' password manager for more secure credential storage? (y/n)${NC}"
    read -r install_pass
    if [[ $install_pass =~ ^[Yy]$ ]]; then
        $PASS_INSTALL_SCRIPT
    else
        echo "You can install pass later by running: $PASS_INSTALL_SCRIPT"
    fi
fi

# Done
echo -e "${GREEN}Linux/WSL credential management setup complete!${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Restart your shell or run: source $SHELL_CONFIG"
echo "2. Verify your credentials with: $VERIFY_SCRIPT"
echo "3. Switch between environments with: claude-env [dev|prod]"
echo ""
echo "To use Claude Code with these credentials, navigate to your project directory and run:"
echo "  claudecode"
exit 0