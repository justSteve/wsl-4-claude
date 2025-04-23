#!/bin/bash
#
# WSL4CLAUDE - Claude Code Installation and Configuration with NVM
# ===========================================================
# MODIFIABLE: YES - This script can be run independently to install or update Claude Code
# COMPONENT: Claude Code Setup with NVM-based Node.js
# DEPENDS: Node.js via NVM (installed by node-nvm-install.sh)
#
# This script installs and configures Claude Code CLI using NVM-managed Node.js
# to avoid conflicts with Windows Node.js installations
#
# USAGE:
#   As standalone:  ./04-claude-setup-nvm.sh [--help] [--update]
#   In setup chain: Called by setup.sh in sequence
#
# OPTIONS:
#   --help    Show this help message
#   --update  Update existing configuration instead of creating new

# Process command-line arguments
if [[ "$1" == "--help" ]]; then
    echo "WSL4CLAUDE - Claude Code Installation and Configuration with NVM"
    echo "Usage: ./04-claude-setup-nvm.sh [--help] [--update]"
    echo ""
    echo "Options:"
    echo "  --help    Show this help message"
    echo "  --update  Update existing configuration instead of creating new"
    echo ""
    echo "This script installs Node.js using NVM first, then installs Claude Code"
    echo "to ensure a clean environment isolated from Windows Node.js."
    exit 0
fi

UPDATE_MODE=false
if [[ "$1" == "--update" ]]; then
    UPDATE_MODE=true
fi

set -e  # Exit immediately if a command exits with a non-zero status

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Setting up Claude Code with NVM...${NC}"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Define config files
CONFIG_DIR="$REPO_ROOT/config"
JSON_CONFIG="$CONFIG_DIR/04-claude-setup.json"
ENV_FILE="$CONFIG_DIR/.env"

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

# Create JSON config file if it doesn't exist or if we're not in update mode
if [ ! -f "$JSON_CONFIG" ] || [ "$UPDATE_MODE" = false ]; then
    echo "Creating JSON config file..."
    mkdir -p "$CONFIG_DIR"
    cat > "$JSON_CONFIG" << EOL
{
  "installation_method": "npm",
  "binary_url": "",
  "default_model": "claude-3-opus-20240229",
  "temperature": "0.7",
  "max_tokens": "4096",
  "log_level": "info",
  "setup_aliases": "true",
  "create_project_templates": "true"
}
EOL
    echo -e "${GREEN}Created JSON config file: $JSON_CONFIG${NC}"
else
    echo -e "${YELLOW}Using existing JSON config file: $JSON_CONFIG${NC}"
fi

# Load environment variables if available
if [ -f "$ENV_FILE" ]; then
    echo "Loading environment variables from $ENV_FILE..."
    source "$ENV_FILE"
fi

# Check WSL version
echo "Checking WSL version..."
WSL_VERSION=$(uname -r | grep -o "WSL2" || echo "WSL1")
if [[ "$WSL_VERSION" == "WSL1" ]]; then
    echo -e "${YELLOW}WARNING: You appear to be running WSL 1, but WSL 2 is recommended.${NC}"
    echo "The script will continue, but some features may not work correctly."
    echo "For best results, consider upgrading to WSL 2 using these commands in PowerShell:"
    echo "  wsl --set-default-version 2"
    echo "  wsl --set-version Ubuntu 2"
    
    # Ask to continue
    read -p "Continue with WSL 1? (y/n): " continue_wsl1
    if [[ ! $continue_wsl1 =~ ^[Yy]$ ]]; then
        echo "Setup aborted. Please upgrade to WSL 2 and try again."
        exit 1
    fi
else
    echo -e "${GREEN}WSL 2 detected. Proceeding with setup...${NC}"
fi

# Verify NVM is installed and load it
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if ! command -v nvm &>/dev/null; then
    echo -e "${YELLOW}NVM not detected. Running Node.js NVM installation script...${NC}"
    
    # Check if the Node.js NVM install script exists
    NVM_SCRIPT="$SCRIPT_DIR/node-nvm-install.sh"
    if [ ! -f "$NVM_SCRIPT" ]; then
        echo -e "${RED}Node.js NVM installation script not found at $NVM_SCRIPT${NC}"
        echo "Please ensure the script exists and is executable."
        exit 1
    fi

    # Make sure the script is executable
    chmod +x "$NVM_SCRIPT"

    # Run the Node.js NVM installation script
    if [ "$UPDATE_MODE" = true ]; then
        "$NVM_SCRIPT" --update
    else
        "$NVM_SCRIPT"
    fi

    # Reload NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
else
    echo -e "${GREEN}NVM detected. Using existing installation.${NC}"
fi

# Verify Node.js installation
if ! command -v node &>/dev/null; then
    echo -e "${RED}Node.js is not available in the current shell session.${NC}"
    echo "Please make sure NVM is properly loaded."
    exit 1
fi

# Detect Node.js install directory
NODE_INSTALL_DIR=$(dirname "$(which node)" 2>/dev/null)
if [ -z "$NODE_INSTALL_DIR" ]; then
    echo -e "${RED}Could not detect Node.js installation directory.${NC}"
    exit 1
fi

echo -e "${GREEN}Using Node.js installation at $NODE_INSTALL_DIR${NC}"
echo "Node.js version: $(node -v)"
echo "npm version: $(npm -v)"

# Get configuration from JSON
INSTALLATION_METHOD=$(get_json_value "installation_method" "npm")
BINARY_URL=$(get_json_value "binary_url" "")
DEFAULT_MODEL=$(get_json_value "default_model" "claude-3-opus-20240229")
TEMPERATURE=$(get_json_value "temperature" "0.7")
MAX_TOKENS=$(get_json_value "max_tokens" "4096")
LOG_LEVEL=$(get_json_value "log_level" "info")
SETUP_ALIASES=$(get_json_value "setup_aliases" "true")
CREATE_TEMPLATES=$(get_json_value "create_project_templates" "true")

# Create claude code directory
CLAUDE_DIR="$HOME/projects/claude/claude-code"
mkdir -p "$CLAUDE_DIR"

# Now install Claude Code using the NVM-managed Node.js
echo -e "${BLUE}Installing Claude Code using NVM-managed Node.js...${NC}"

# Install Claude Code
echo "Installing Claude Code CLI..."
npm install -g @anthropic-ai/claude-code --quiet

# Check if installation was successful
if ! command -v claude &>/dev/null; then
    echo -e "${RED}Claude Code installation failed.${NC}"
    echo "Let's try an alternative approach..."
    
    # Alternative installation approach
    echo "Trying alternative installation with npm..."
    npm install -g @anthropic-ai/claude-code --prefer-offline --no-audit --no-fund
    
    # Check again
    if ! command -v claude &>/dev/null; then
        echo -e "${RED}All installation attempts failed.${NC}"
        echo "Please check npm logs for more details."
        exit 1
    fi
fi

# Display Claude Code version
CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "Unknown")
echo -e "${GREEN}Claude Code installed successfully!${NC}"
echo "Claude Code version: $CLAUDE_VERSION"

# Create Claude Code configuration script
echo "Creating Claude Code configuration script..."
cat > "$CLAUDE_DIR/configure.sh" << EOL
#!/bin/bash
#
# Claude Code Configuration Script
# This script configures Claude Code CLI settings

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "\${BLUE}Configuring Claude Code CLI...\${NC}"

# Load NVM and Node.js
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"

# Check if Claude Code is installed
if ! command -v claude &> /dev/null; then
    echo -e "\${RED}Claude Code is not installed. Please run the installation script first.\${NC}"
    exit 1
fi

# Create Claude Code configuration directory
mkdir -p ~/.claude

# Create Claude Code configuration file
CONFIG_FILE=~/.claude/config.json

# Configuration values from setup
DEFAULT_MODEL="$DEFAULT_MODEL"
TEMPERATURE="$TEMPERATURE"
MAX_TOKENS="$MAX_TOKENS"
LOG_LEVEL="$LOG_LEVEL"

# Check if the configuration file already exists
if [ -f "\$CONFIG_FILE" ]; then
    echo -e "\${YELLOW}Configuration file already exists at \$CONFIG_FILE.\${NC}"
    echo "Would you like to overwrite it? (y/n)"
    read -r overwrite
    if [[ ! \$overwrite =~ ^[Yy]\$ ]]; then
        echo "Skipping configuration file creation."
    else
        # Create the configuration file
        cat > "\$CONFIG_FILE" << EOJSON
{
  "model": "\$DEFAULT_MODEL",
  "temperature": \$TEMPERATURE,
  "maxTokens": \$MAX_TOKENS,
  "terminal": {
    "theme": "auto",
    "bell": true,
    "notifications": true
  },
  "logging": {
    "level": "\$LOG_LEVEL",
    "file": "~/.claude/logs/claude.log"
  },
  "aliases": {
    "tidy": "Format and clean up this code",
    "explain": "Explain what this code does",
    "test": "Write tests for this code",
    "doc": "Write documentation for this code"
  },
  "autoLoad": true,
  "openaiCompatibilityMode": false
}
EOJSON
        echo -e "\${GREEN}Configuration file created at \$CONFIG_FILE.\${NC}"
    fi
else
    # Create the configuration file
    cat > "\$CONFIG_FILE" << EOJSON
{
  "model": "\$DEFAULT_MODEL",
  "temperature": \$TEMPERATURE,
  "maxTokens": \$MAX_TOKENS,
  "terminal": {
    "theme": "auto",
    "bell": true,
    "notifications": true
  },
  "logging": {
    "level": "\$LOG_LEVEL",
    "file": "~/.claude/logs/claude.log"
  },
  "aliases": {
    "tidy": "Format and clean up this code",
    "explain": "Explain what this code does",
    "test": "Write tests for this code",
    "doc": "Write documentation for this code"
  },
  "autoLoad": true,
  "openaiCompatibilityMode": false
}
EOJSON
    echo -e "\${GREEN}Configuration file created at \$CONFIG_FILE.\${NC}"
fi

# Create logs directory
mkdir -p ~/.claude/logs

# Display configured settings
echo ""
echo -e "\${YELLOW}Claude Code Settings:\${NC}"
echo "  - Model: \$DEFAULT_MODEL"
echo "  - Temperature: \$TEMPERATURE"
echo "  - Max Tokens: \$MAX_TOKENS" 
echo "  - Theme: auto (follows terminal theme)"
echo "  - Log level: \$LOG_LEVEL"
echo "  - Log file: ~/.claude/logs/claude.log"
echo ""
echo "You can modify these settings by editing the configuration file at \$CONFIG_FILE."

# Add custom commands
SETUP_ALIASES="$SETUP_ALIASES"
if [[ \$SETUP_ALIASES =~ ^(true|yes|y|1)\$ ]]; then
    # Create commands directory
    mkdir -p ~/.claude/commands
    
    # Create example commands
    cat > ~/.claude/commands/analyze-repo.md << EOMD
# Analyze Repository

Analyze the current repository and provide insights:

1. Identify the main technologies used
2. Suggest code quality improvements
3. Identify potential security issues
4. Recommend testing strategies
EOMD

    cat > ~/.claude/commands/create-api.md << EOMD
# Create API

Create a RESTful API with the following:

1. Define endpoints for: {0}
2. Implement proper error handling
3. Add input validation
4. Include authentication if needed
5. Write tests for each endpoint
EOMD

    cat > ~/.claude/commands/optimize.md << EOMD
# Optimize Code

Analyze and optimize the provided code:

1. Identify performance bottlenecks
2. Reduce complexity
3. Improve readability
4. Suggest better algorithms or data structures
EOMD

    echo -e "\${GREEN}Custom commands created in ~/.claude/commands.\${NC}"
    echo "You can use these commands by typing:"
    echo "  /analyze-repo"
    echo "  /create-api <endpoints>"
    echo "  /optimize"
    echo "in Claude Code."
else
    echo "Skipping custom command creation (disabled in config)."
fi

echo -e "\${GREEN}Claude Code configuration complete!\${NC}"
echo "You can now use Claude Code with your preferred settings."
EOL

# Make the configuration script executable
chmod +x "$CLAUDE_DIR/configure.sh"

# Create a wrapper script for Claude Code
echo "Creating Claude Code wrapper script..."
mkdir -p "$HOME/bin"
cat > "$HOME/bin/claudecode" << EOL
#!/bin/bash
#
# Claude Code Wrapper Script
# This script runs Claude Code with the appropriate environment variables and NVM

# Load NVM and Node.js
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"

# Check if API key is set
if [ -z "\$ANTHROPIC_API_KEY" ]; then
    echo "ANTHROPIC_API_KEY is not set. Please run the credential management scripts first."
    exit 1
fi

# Get environment type
ENV_TYPE=\${ENV_TYPE:-development}
echo "Running Claude Code in \$ENV_TYPE environment..."

# Run Claude Code
claude "\$@"
EOL

# Make the wrapper script executable
chmod +x "$HOME/bin/claudecode"

# Add wrapper script to PATH if not already there
if ! grep -q "export PATH=\$HOME/bin:\$PATH" ~/.bashrc; then
    echo "Adding bin directory to PATH in .bashrc..."
    echo "# Add bin directory to PATH" >> ~/.bashrc
    echo "export PATH=\$HOME/bin:\$PATH" >> ~/.bashrc
fi

if [ -f ~/.zshrc ] && ! grep -q "export PATH=\$HOME/bin:\$PATH" ~/.zshrc; then
    echo "Adding bin directory to PATH in .zshrc..."
    echo "# Add bin directory to PATH" >> ~/.zshrc
    echo "export PATH=\$HOME/bin:\$PATH" >> ~/.zshrc
fi

# Create configuration directly
echo "Setting up Claude Code configuration..."
mkdir -p ~/.claude/logs
CONFIG_FILE=~/.claude/config.json

cat > "$CONFIG_FILE" << EOJSON
{
  "model": "$DEFAULT_MODEL",
  "temperature": $TEMPERATURE,
  "maxTokens": $MAX_TOKENS,
  "terminal": {
    "theme": "auto",
    "bell": true,
    "notifications": true
  },
  "logging": {
    "level": "$LOG_LEVEL",
    "file": "~/.claude/logs/claude.log"
  },
  "aliases": {
    "tidy": "Format and clean up this code",
    "explain": "Explain what this code does",
    "test": "Write tests for this code",
    "doc": "Write documentation for this code"
  },
  "autoLoad": true,
  "openaiCompatibilityMode": false
}
EOJSON

echo -e "${GREEN}Configuration file created at $CONFIG_FILE${NC}"

# Add custom commands if enabled
if [[ $SETUP_ALIASES =~ ^(true|yes|y|1)$ ]]; then
    # Create commands directory
    mkdir -p ~/.claude/commands
    
    # Create example commands
    cat > ~/.claude/commands/analyze-repo.md << EOMD
# Analyze Repository

Analyze the current repository and provide insights:

1. Identify the main technologies used
2. Suggest code quality improvements
3. Identify potential security issues
4. Recommend testing strategies
EOMD

    cat > ~/.claude/commands/create-api.md << EOMD
# Create API

Create a RESTful API with the following:

1. Define endpoints for: {0}
2. Implement proper error handling
3. Add input validation
4. Include authentication if needed
5. Write tests for each endpoint
EOMD

    cat > ~/.claude/commands/optimize.md << EOMD
# Optimize Code

Analyze and optimize the provided code:

1. Identify performance bottlenecks
2. Reduce complexity
3. Improve readability
4. Suggest better algorithms or data structures
EOMD

    echo -e "${GREEN}Custom commands created in ~/.claude/commands.${NC}"
fi

# Create project templates if enabled
CREATE_TEMPLATES="$CREATE_TEMPLATES"
if [[ $CREATE_TEMPLATES =~ ^(true|yes|y|1)$ ]]; then
    echo "Creating additional files for Claude Code projects..."

    # Create template directory
    mkdir -p "$HOME/projects/claude/template"
    
    # Create a template .claude.yml file
    cat > "$HOME/projects/claude/template/.claude.yml" << 'EOL'
# Claude Code Project Configuration
version: 1.0

# Project information
project:
  name: "My Claude Project"
  description: "A project using Claude Code"

# Configuration for Claude Code
claude:
  # File patterns to include in context
  include:
    - "**/*.js"
    - "**/*.ts"
    - "**/*.py"
    - "**/*.md"
  
  # File patterns to exclude from context
  exclude:
    - "node_modules/**"
    - "dist/**"
    - "build/**"
    - ".git/**"
  
  # Maximum number of files to include in context
  maxFiles: 100
  
  # Maximum file size to include (in bytes)
  maxFileSize: 1000000

# GitHub integration settings
github:
  enabled: true
  repositories:
    - owner: "your-username"
      name: "your-repository"
EOL
    
    echo -e "${GREEN}Project templates created in $HOME/projects/claude/template${NC}"
else
    echo "Skipping project template creation (disabled in config)."
fi

# Create a sentinel file indicating this component has been configured
mkdir -p "$HOME/.claude"
touch "$HOME/.claude/.claude_setup_complete"

echo -e "${GREEN}Claude Code setup with NVM complete!${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Run the credential management scripts to set up your API key:"
echo "   - For Windows: ./scripts/05-win-credentials.ps1"
echo "   - For Linux/WSL: ./scripts/06-lx-credentials.sh"
echo ""
echo "2. Once your API key is set, you can use Claude Code by navigating to your project directory and running:"
echo "   claudecode"
echo ""
echo "3. If you want to use Claude Code in a new shell session, make sure to source your shell configuration:"
echo "   source ~/.bashrc"
echo ""
echo "4. For more information, see the Claude Code documentation at:"
echo "   https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/overview"

# Function to be used when script is sourced by the main setup
claude_setup_status() {
    if [[ -f "$HOME/.claude/.claude_setup_complete" ]]; then
        echo "Claude Code with NVM: Installed and configured"
        return 0
    else
        echo "Claude Code with NVM: Not configured"
        return 1
    fi
}

# This ensures the script can both run standalone and be sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being run directly
    exit 0
else
    # Script is being sourced - export the status function
    export -f claude_setup_status
fi
