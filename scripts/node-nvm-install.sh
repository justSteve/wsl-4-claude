#!/bin/bash
#
# WSL4CLAUDE - Node.js Installation via NVM
# ===========================================================
# MODIFIABLE: YES - This script can be run independently to install or update Node.js
# COMPONENT: Node.js Setup via NVM
# DEPENDS: Basic Linux utilities
#
# This script installs Node Version Manager (nvm) and Node.js in WSL,
# ensuring a clean installation isolated from Windows Node.js
#
# USAGE:
#   As standalone:  ./node-nvm-install.sh [--help] [--update]
#   In setup chain: Called by setup.sh or before Claude Code installation
#
# OPTIONS:
#   --help    Show this help message
#   --update  Update existing configuration instead of creating new

# Process command-line arguments
if [[ "$1" == "--help" ]]; then
    echo "WSL4CLAUDE - Node.js Installation via NVM"
    echo "Usage: ./node-nvm-install.sh [--help] [--update]"
    echo ""
    echo "Options:"
    echo "  --help    Show this help message"
    echo "  --update  Update existing Node.js/nvm installation"
    echo ""
    echo "This script installs Node Version Manager (nvm) and Node.js in WSL,"
    echo "ensuring a clean installation isolated from Windows Node.js."
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

echo -e "${BLUE}Setting up Node.js via NVM...${NC}"

# Check if nvm is already installed
if [ -d "$HOME/.nvm" ] && [ "$UPDATE_MODE" = false ]; then
    echo -e "${YELLOW}NVM is already installed at $HOME/.nvm${NC}"
    echo "If you want to update the existing installation, run with --update flag."
    
    # Check if nvm is in PATH and functioning
    if command -v nvm &>/dev/null || [ -s "$HOME/.nvm/nvm.sh" ]; then
        echo -e "${GREEN}NVM is properly configured in your PATH.${NC}"
    else
        echo -e "${YELLOW}NVM is installed but may not be in your PATH.${NC}"
        echo "Adding NVM to your PATH..."
        
        # Load NVM
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
        # Add NVM to .bashrc if not already there
        if ! grep -q "NVM_DIR" ~/.bashrc; then
            echo '# NVM Configuration' >> ~/.bashrc
            echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc
            echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' >> ~/.bashrc
            echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >> ~/.bashrc
        fi
        
        # Add NVM to .zshrc if it exists and doesn't have nvm config
        if [ -f ~/.zshrc ] && ! grep -q "NVM_DIR" ~/.zshrc; then
            echo '# NVM Configuration' >> ~/.zshrc
            echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc
            echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' >> ~/.zshrc
            echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >> ~/.zshrc
        fi
    fi
else
    # Install or update nvm
    echo "Installing NVM (Node Version Manager)..."
    
    # Download and run the nvm installation script
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    
    # Load NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    echo -e "${GREEN}NVM installed successfully!${NC}"
fi

# Verify nvm installation
if ! command -v nvm &>/dev/null; then
    echo -e "${YELLOW}Loading NVM from installation directory...${NC}"
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    if ! command -v nvm &>/dev/null; then
        echo -e "${RED}NVM installation failed or NVM is not in PATH.${NC}"
        echo "Please try again or install NVM manually."
        exit 1
    fi
fi

# Install or update Node.js using nvm
if [ "$UPDATE_MODE" = true ]; then
    echo "Updating Node.js to latest LTS version..."
    nvm install --lts
else
    echo "Installing Node.js LTS version..."
    nvm install --lts
fi

# Use the installed Node.js version
nvm use --lts

# Verify Node.js installation
if ! command -v node &>/dev/null; then
    echo -e "${RED}Node.js installation failed.${NC}"
    exit 1
fi

# Display versions
NODE_VERSION=$(node -v)
NPM_VERSION=$(npm -v)
echo -e "${GREEN}Node.js installed successfully!${NC}"
echo "Node.js version: $NODE_VERSION"
echo "npm version: $NPM_VERSION"

# Check if Windows Node.js is in PATH
WINDOWS_NODE_PATH=$(find /mnt/c -path "*/nodejs*" -type d 2>/dev/null | head -n 1)
if [ -n "$WINDOWS_NODE_PATH" ]; then
    echo -e "${YELLOW}Windows Node.js installation detected at $WINDOWS_NODE_PATH${NC}"
    echo "This can cause conflicts. WSL will now use the NVM-installed Node.js instead."
    
    # Display PATH for debugging
    echo "Current PATH: $PATH"
    
    # Check if the Windows path is in the WSL PATH
    if echo "$PATH" | grep -q "/mnt/c.*nodejs"; then
        echo -e "${YELLOW}Windows Node.js path is in your WSL PATH.${NC}"
        echo "This might cause conflicts. Consider modifying your PATH to prioritize the WSL Node.js installation."
    fi
fi

# Install global npm packages
echo "Installing essential npm packages globally..."
npm install -g npm@latest
npm install -g n
npm install -g yarn

# Create a sentinel file indicating this component has been configured
mkdir -p "$HOME/.claude"
touch "$HOME/.claude/.node_nvm_setup_complete"

echo -e "${GREEN}Node.js setup via NVM complete!${NC}"
echo ""
echo -e "${YELLOW}Node.js Environment:${NC}"
echo "  - NVM location: $HOME/.nvm"
echo "  - Node.js version: $NODE_VERSION"
echo "  - npm version: $NPM_VERSION"
echo "  - Global packages installed: npm, n, yarn"
echo ""
echo "If you're installing Claude Code next, it will use this Node.js installation."

# Function to be used when script is sourced by the main setup
node_nvm_setup_status() {
    if [[ -f "$HOME/.claude/.node_nvm_setup_complete" ]]; then
        echo "Node.js via NVM: Installed and configured"
        return 0
    else
        echo "Node.js via NVM: Not configured"
        return 1
    fi
}

# This ensures the script can both run standalone and be sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being run directly
    exit 0
else
    # Script is being sourced - export the status function
    export -f node_nvm_setup_status
fi
