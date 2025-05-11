#!/bin/bash
#
# WSL4CLAUDE - Claude Code Installation and Configuration (IMPROVED)
# ===========================================================
# MODIFIABLE: YES - This script can be run independently to install or update Claude Code
# COMPONENT: Claude Code Setup
# DEPENDS: Node.js, npm
#
# This script installs and configures Claude Code CLI with improvements for
# WSL version detection, Node.js path identification, and dynamic PATH handling
#
# USAGE:
#   As standalone:  ./04-claude-setup-fixed.sh [--help] [--update]
#   In setup chain: Called by setup.sh in sequence
#
# OPTIONS:
#   --help    Show this help message
#   --update  Update existing configuration instead of creating new

# Process command-line arguments
if [[ "$1" == "--help" ]]; then
    echo "WSL4CLAUDE - Claude Code Installation and Configuration (IMPROVED)"
    echo "Usage: ./04-claude-setup-fixed.sh [--help] [--update]"
    echo ""
    echo "Options:"
    echo "  --help    Show this help message"
    echo "  --update  Update existing configuration instead of creating new"
    echo ""
    echo "This script is an improved version that properly handles WSL version detection,"
    echo "Node.js path identification, and dynamically manages PATH configuration."
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

echo -e "${BLUE}Setting up Claude Code...${NC}"

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

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo -e "${RED}npm is not installed. Please run the developer tools script first.${NC}"
    exit 1
fi

# Check if anthropic API key is set
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo -e "${YELLOW}ANTHROPIC_API_KEY is not set in the environment.${NC}"
    echo "You will need to set this variable before using Claude Code."
    echo "Please run the credential management scripts after completing this setup."
fi

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

# Clone the Claude Code repository if it exists
if [ ! -d "$CLAUDE_DIR/repo" ]; then
    echo "Checking for the Claude Code repository..."
    if git ls-remote --exit-code https://github.com/anthropics/claude-code.git &> /dev/null; then
        echo "Cloning the Claude Code repository..."
        git clone https://github.com/anthropics/claude-code.git "$CLAUDE_DIR/repo"
    else
        echo -e "${YELLOW}Claude Code repository not found or not publicly available.${NC}"
        echo "Will use standalone installation approach instead."
        mkdir -p "$CLAUDE_DIR/repo"
    fi
fi

# IMPROVED: Install Claude Code directly, without relying on hardcoded paths
echo "Installing Claude Code globally..."
npm install -g @anthropic-ai/claude-code --force

# Verify Claude Code CLI was installed and find its location
CLAUDE_BIN_PATH=""
if command -v claude &> /dev/null; then
    CLAUDE_BIN_PATH=$(which claude)
    echo -e "${GREEN}Claude Code installed successfully at ${CLAUDE_BIN_PATH}${NC}"
else
    echo -e "${YELLOW}Claude command not found in PATH. Searching for it...${NC}"
    # Try to find claude in common npm global directories
    for path in "$(npm config get prefix)/bin" "$HOME/.npm-global/bin" "$HOME/.nvm/versions/node/*/bin"; do
        # Handle glob expansion
        if [[ $path == *"*"* ]]; then
            for expanded_path in $path; do
                if [ -f "$expanded_path/claude" ]; then
                    CLAUDE_BIN_PATH="$expanded_path/claude"
                    echo -e "${GREEN}Found Claude at: $CLAUDE_BIN_PATH${NC}"
                    break 2
                fi
            done
        elif [ -f "$path/claude" ]; then
            CLAUDE_BIN_PATH="$path/claude"
            echo -e "${GREEN}Found Claude at: $CLAUDE_BIN_PATH${NC}"
            break
        fi
    done
    
    if [ -z "$CLAUDE_BIN_PATH" ]; then
        echo -e "${RED}Claude executable not found after installation.${NC}"
        echo "Installation may have failed or the executable is in an unexpected location."
        exit 1
    fi
fi

# Get npm bin directory - this is where global binaries are installed
NPM_BIN_DIR=$(npm bin -g)
echo -e "${GREEN}Node.js global bin directory: $NPM_BIN_DIR${NC}"

# IMPROVED: Use the actual location where claude is installed
CLAUDE_INSTALL_DIR=$(dirname "$CLAUDE_BIN_PATH")
echo -e "${GREEN}Claude Code installed at: $CLAUDE_INSTALL_DIR${NC}"

# Setup path configuration helpers
PATH_SETUP_FILE="$HOME/.claude_path_setup"

# Create a path setup file that can be sourced by shell configuration files
cat > "$PATH_SETUP_FILE" << EOL
#!/bin/bash
# Claude Code PATH Configuration
# This file is generated by the WSL4Claude setup and should be sourced by shell config files

# Add npm global bin directory to PATH if not already there
if [ -d "$NPM_BIN_DIR" ] && [[ ":\$PATH:" != *":$NPM_BIN_DIR:"* ]]; then
    export PATH="$NPM_BIN_DIR:\$PATH"
fi

# Add Claude Code directory to PATH if not already there
if [ -d "$CLAUDE_INSTALL_DIR" ] && [[ ":\$PATH:" != *":$CLAUDE_INSTALL_DIR:"* ]]; then
    export PATH="$CLAUDE_INSTALL_DIR:\$PATH"
fi

# Add ~/bin to PATH if not already there
if [ -d "\$HOME/bin" ] && [[ ":\$PATH:" != *":\$HOME/bin:"* ]]; then
    export PATH="\$HOME/bin:\$PATH"
fi

# Define a simple alias for claude
alias claude="$CLAUDE_BIN_PATH"

# This function ensures claude is available
ensure_claude() {
    if ! command -v claude &> /dev/null; then
        echo "Claude command not found. Using full path: $CLAUDE_BIN_PATH"
        alias claude="$CLAUDE_BIN_PATH"
    fi
}

# Run the ensure function
ensure_claude
EOL

chmod +x "$PATH_SETUP_FILE"

# Add the path setup to shell config files
for shell_config in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
    if [ -f "$shell_config" ]; then
        if ! grep -q "source $PATH_SETUP_FILE" "$shell_config"; then
            echo "" >> "$shell_config"
            echo "# Claude Code PATH setup" >> "$shell_config"
            echo "if [ -f \"$PATH_SETUP_FILE\" ]; then" >> "$shell_config"
            echo "    source \"$PATH_SETUP_FILE\"" >> "$shell_config"
            echo "fi" >> "$shell_config"
            echo -e "${GREEN}Added Claude Code PATH setup to $shell_config${NC}"
        else
            echo -e "${YELLOW}Claude Code PATH setup already in $shell_config${NC}"
        fi
    fi
done

# Source the path setup file to update the current shell
source "$PATH_SETUP_FILE"

# Create the claudecode wrapper script (IMPROVED: Uses dynamic path finding)
echo "Creating improved claudecode wrapper script..."
mkdir -p "$HOME/bin"

cat > "$HOME/bin/claudecode" << EOL
#!/bin/bash
#
# Claude Code Wrapper Script (Improved)
# This script runs Claude Code with the appropriate environment variables

# Source the Claude PATH setup file if it exists
if [ -f "$PATH_SETUP_FILE" ]; then
    source "$PATH_SETUP_FILE"
fi

# Check if API key is set
if [ -z "\$ANTHROPIC_API_KEY" ]; then
    echo "ANTHROPIC_API_KEY is not set. Please run the credential management scripts first."
    exit 1
fi

# Get environment type
ENV_TYPE=\${ENV_TYPE:-development}
echo "Running Claude Code in \$ENV_TYPE environment..."

# Try to find Claude in PATH, or use the known location
if command -v claude &> /dev/null; then
    claude "\$@"
else
    echo "Claude command not found in PATH. Using direct path."
    "$CLAUDE_BIN_PATH" "\$@"
fi
EOL

chmod +x "$HOME/bin/claudecode"

# Create an even simpler direct 'claude' script in ~/bin for reliability
cat > "$HOME/bin/claude" << EOL
#!/bin/bash
#
# Claude Code Direct Script
# This script directly executes Claude Code using the full path

# Execute Claude directly using the full path
"$CLAUDE_BIN_PATH" "\$@"
EOL

chmod +x "$HOME/bin/claude"

# Create configuration file
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
fi

# Create verification script that can be run to test/diagnose installation
cat > "$HOME/verify-claude.sh" << EOF
#!/bin/bash
# Claude Code Installation Verification Script

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "===== Claude Code Verification ====="

echo -e "\${YELLOW}Step 1: Check PATH configuration${NC}"
echo "Current PATH: $PATH"

echo -e "\${YELLOW}Step 2: Check Node.js installation${NC}"
if command -v node &> /dev/null; then
    echo -e "\${GREEN}Node.js installed:${NC} $(node -v)"
    echo "Node.js path: $(which node)"
else
    echo -e "\${RED}Node.js not found in PATH${NC}"
fi

echo -e "\${YELLOW}Step 3: Check npm installation${NC}"
if command -v npm &> /dev/null; then
    echo -e "\${GREEN}npm installed:${NC} $(npm -v)"
    echo "npm path: $(which npm)"
    echo "npm global directory: $(npm root -g)"
    echo "npm global bin directory: $(npm bin -g)"
else
    echo -e "\${RED}npm not found in PATH${NC}"
fi

echo -e "\${YELLOW}Step 4: Check Claude Code installation${NC}"
if command -v claude &> /dev/null; then
    echo -e "\${GREEN}Claude Code found in PATH${NC}"
    echo "Claude Code path: $(which claude)"
    echo "Claude Code version: $(claude --version 2>&1 || echo "Could not get version")"
else
    echo -e "\${RED}Claude Code not found in PATH${NC}"
    
    # Check for claude in known locations
    for path in "$HOME/bin/claude" "$(npm bin -g)/claude" "$HOME/.npm-global/bin/claude" "$HOME/.nvm/versions/node/*/bin/claude"; do
        # Handle glob expansion
        if [[ $path == *"*"* ]]; then
            for expanded_path in $path; do
                if [ -f "$expanded_path" ]; then
                    echo -e "\${YELLOW}Found Claude at:${NC} $expanded_path"
                    echo "But it's not in your PATH"
                    break
                fi
            done
        elif [ -f "$path" ]; then
            echo -e "\${YELLOW}Found Claude at:${NC} $path"
            echo "But it's not in your PATH"
            break
        fi
    done
fi

echo -e "\${YELLOW}Step 5: Check Claude PATH setup${NC}"
if [ -f "$PATH_SETUP_FILE" ]; then
    echo -e "\${GREEN}Claude PATH setup file exists:${NC} $PATH_SETUP_FILE"
    echo "Contents:"
    cat "$PATH_SETUP_FILE"
else
    echo -e "\${RED}Claude PATH setup file not found${NC}"
fi

echo -e "\${YELLOW}Step 6: Check shell configuration${NC}"
for config in ~/.bashrc ~/.zshrc ~/.profile; do
    if [ -f "$config" ]; then
        if grep -q "source $PATH_SETUP_FILE" "$config"; then
            echo -e "\${GREEN}$config includes Claude PATH setup${NC}"
        else
            echo -e "\${RED}$config does not include Claude PATH setup${NC}"
        fi
    fi
done

echo -e "\${YELLOW}Step 7: Try to run Claude directly${NC}"
if [ -f "$CLAUDE_BIN_PATH" ]; then
    echo -e "\${GREEN}Claude binary exists at:${NC} $CLAUDE_BIN_PATH"
    echo "Attempting to run directly..."
    "$CLAUDE_BIN_PATH" --version || echo -e "\${RED}Failed to run Claude directly${NC}"
else
    echo -e "\${RED}Claude binary not found at expected location: $CLAUDE_BIN_PATH${NC}"
fi

echo "===== Verification Complete ====="
echo ""
echo "If Claude is not working, try the following steps:"
echo "1. Close and reopen your terminal"
echo "2. Run: source ~/.bashrc"
echo "3. Try running claude again"
echo ""
echo "If that doesn't work, you can always run Claude directly using the path shown in this report."
EOF

chmod +x "$HOME/verify-claude.sh"

# Create a sentinel file indicating this component has been configured
mkdir -p "$HOME/.claude"
touch "$HOME/.claude/.claude_setup_complete"

echo -e "${GREEN}Claude Code setup complete!${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Run the credential management scripts to set up your API key:"
echo "   - For Windows: ./scripts/05-win-credentials.ps1"
echo "   - For Linux/WSL: ./scripts/06-lx-credentials.sh"
echo ""
echo "2. IMPORTANT: Close and reopen your terminal for PATH changes to take effect."
echo ""
echo "3. Once your API key is set, you can use Claude Code by navigating to your project directory and running:"
echo "   claude"
echo ""
echo "4. If you encounter any issues, run the verification script:"
echo "   ~/verify-claude.sh"
echo ""
echo "5. For more information, see the Claude Code documentation at:"
echo "   https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/overview"

# Function to be used when script is sourced by the main setup
claude_setup_status() {
    if [[ -f "$HOME/.claude/.claude_setup_complete" ]]; then
        echo "Claude Code: Installed and configured"
        return 0
    else
        echo "Claude Code: Not configured"
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
