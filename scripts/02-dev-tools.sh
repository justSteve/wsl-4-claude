#!/bin/bash
#
# WSL4CLAUDE - Development Tools Installation
# ===========================================
# MODIFIABLE: YES - This script can be run independently to install or update dev tools
# COMPONENT: Development Environment Setup
# DEPENDS: Base WSL installation
#
# This script installs and configures development tools needed for Claude Code
# including Python, Node.js, text editors, and build tools.
#
# USAGE:
#   As standalone:  ./02-dev-tools.sh [--help] [--update]
#   In setup chain: Called by setup.sh in sequence
#
# OPTIONS:
#   --help    Show this help message
#   --update  Update existing tools instead of fresh installation

# Process command-line arguments
if [[ "$1" == "--help" ]]; then
    echo "WSL4CLAUDE - Development Tools Installation"
    echo "Usage: ./02-dev-tools.sh [--help] [--update]"
    echo ""
    echo "Options:"
    echo "  --help    Show this help message"
    echo "  --update  Update existing tools instead of fresh installation"
    echo ""
    echo "This script can be run independently to install or update development tools,"
    echo "or as part of the overall WSL environment setup chain."
    exit 0
fi

UPDATE_MODE=false
if [[ "$1" == "--update" ]]; then
    UPDATE_MODE=true
fi

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting Developer Tools Installation...${NC}"

# Update package lists
echo "Updating package lists..."
sudo apt update

# Install essential build tools
echo "Installing build essentials..."
sudo apt install -y build-essential

# Install Git if not already installed
if ! command -v git &> /dev/null; then
    echo "Installing Git..."
    sudo apt install -y git
else
    echo -e "${GREEN}Git is already installed.${NC}"
    
    if [[ "$UPDATE_MODE" == true ]]; then
        echo "Updating Git to latest version..."
        sudo apt install --only-upgrade git
    fi
fi

# Install text editors
echo "Installing text editors..."
sudo apt install -y vim nano

# Check for VS Code or Code Server
if command -v code &> /dev/null || command -v code-server &> /dev/null; then
    echo -e "${GREEN}Visual Studio Code or Code Server is already installed.${NC}"
else
    echo "Installing VS Code Server..."
    # You may want to update this with the specific installation method for Code Server
    # This is a placeholder
    echo -e "${YELLOW}NOTE: VS Code Server installation skipped. Please install manually if needed.${NC}"
fi

# Python environment setup - Using venv instead of direct pip
echo "Installing Python virtualenv tools..."

# Make sure python3-full and python3-venv are installed
sudo apt install -y python3-full python3-venv pipx

# Create a dedicated environment directory for Claude tools
CLAUDE_ENV_DIR="$HOME/.claude-env"

# Check if environment already exists
if [ ! -d "$CLAUDE_ENV_DIR" ]; then
    echo "Creating Python virtual environment for Claude tools..."
    python3 -m venv "$CLAUDE_ENV_DIR"
    
    # Activate the environment and install packages
    echo "Installing Python packages in virtual environment..."
    source "$CLAUDE_ENV_DIR/bin/activate"
    pip install --upgrade pip
    pip install virtualenv pipenv poetry jupyter pandas numpy matplotlib requests
    deactivate
    
    # Add environment activation to .bashrc if not already there
    if ! grep -q "claude-env" "$HOME/.bashrc"; then
        echo "Adding environment activation to .bashrc..."
        echo "" >> "$HOME/.bashrc"
        echo "# Activate Claude Python environment" >> "$HOME/.bashrc"
        echo "if [ -f \"$CLAUDE_ENV_DIR/bin/activate\" ]; then" >> "$HOME/.bashrc"
        echo "    source \"$CLAUDE_ENV_DIR/bin/activate\"" >> "$HOME/.bashrc"
        echo "fi" >> "$HOME/.bashrc"
    fi
else
    echo -e "${GREEN}Claude Python environment already exists at $CLAUDE_ENV_DIR${NC}"
    
    if [[ "$UPDATE_MODE" == true ]]; then
        echo "Updating Python packages in virtual environment..."
        source "$CLAUDE_ENV_DIR/bin/activate"
        pip install --upgrade pip
        pip install --upgrade virtualenv pipenv poetry jupyter pandas numpy matplotlib requests
        deactivate
    fi
fi

# Node.js installation (using nvm for better version management)
echo "Setting up Node.js environment..."

# Check if nvm is installed
if [ ! -d "$HOME/.nvm" ]; then
    echo "Installing nvm (Node Version Manager)..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
    
    # Load nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Install latest LTS version of Node.js
    echo "Installing Node.js LTS version..."
    nvm install --lts
else
    echo -e "${GREEN}nvm is already installed.${NC}"
    # Load nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Check if Node.js is installed
    if ! command -v node &> /dev/null; then
        echo "Installing Node.js LTS version..."
        nvm install --lts
    else
        echo -e "${GREEN}Node.js is already installed: $(node --version)${NC}"
        
        if [[ "$UPDATE_MODE" == true ]]; then
            echo "Checking for Node.js updates..."
            nvm install --lts --reinstall-packages-from=current
        fi
    fi
fi

# Install global npm packages
echo "Installing global npm packages..."
if [[ "$UPDATE_MODE" == true ]]; then
    npm update -g typescript ts-node
else
    npm install -g typescript ts-node
fi

# Install jq for JSON processing
if ! command -v jq &> /dev/null; then
    echo "Installing jq for JSON processing..."
    sudo apt install -y jq
else
    echo -e "${GREEN}jq is already installed.${NC}"
fi

# Docker check (not installing - requires manual setup)
if command -v docker &> /dev/null; then
    echo -e "${GREEN}Docker is already installed.${NC}"
else
    echo -e "${YELLOW}NOTE: Docker is not installed. If needed, please install manually following Docker's official documentation.${NC}"
fi

# Create a sentinel file indicating this component has been configured
mkdir -p "$HOME/.wsl4claude"
touch "$HOME/.wsl4claude/.dev_tools_installed"

echo -e "${GREEN}✅ Developer Tools Installation completed${NC}"

# Function to be used when script is sourced by the main setup
dev_tools_status() {
    if [[ -f "$HOME/.wsl4claude/.dev_tools_installed" ]]; then
        echo "Development Tools: Installed"
        return 0
    else
        echo "Development Tools: Not installed"
        return 1
    fi
}

# This ensures the script can both run standalone and be sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being run directly
    exit 0
else
    # Script is being sourced - export the status function
    export -f dev_tools_status
fi
