#!/bin/bash
#
# WSL4CLAUDE - Preparation Script
# ===============================
# This script prepares the WSL environment for Claude Code installation
# It handles common prerequisites, fixing permissions, and initial setup
#
# Usage: ./wsl-prep.sh [--help] [--copy-to-home]
#
# Options:
#   --help          Show this help message
#   --copy-to-home  Also copy this script to your WSL home directory

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Process command-line arguments
HELP=false
COPY_TO_HOME=false

for arg in "$@"; do
  case $arg in
    --help)
      HELP=true
      ;;
    --copy-to-home)
      COPY_TO_HOME=true
      ;;
  esac
done

if [ "$HELP" = true ]; then
    echo "WSL4CLAUDE - Preparation Script"
    echo "Usage: ./wsl-prep.sh [--help] [--copy-to-home]"
    echo ""
    echo "Options:"
    echo "  --help          Show this help message"
    echo "  --copy-to-home  Also copy this script to your WSL home directory"
    echo ""
    echo "This script prepares your WSL environment for Claude Code installation by:"
    echo "  1. Checking WSL version and prerequisites"
    echo "  2. Fixing script permissions"
    echo "  3. Setting up the directory structure"
    echo "  4. Verifying Node.js installation"
    echo "  5. Fixing common issues with line endings and paths"
    echo ""
    exit 0
fi

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "${BLUE}======================================"
echo -e " WSL4CLAUDE - Preparation Script"
echo -e "======================================${NC}"
echo ""

# Step 1: Check WSL version
echo -e "${BLUE}Step 1: Checking WSL version...${NC}"
echo "Detecting WSL version..."
WSL_VERSION=$(uname -r | grep -o "WSL2" || echo "WSL1")

if [[ "$WSL_VERSION" == "WSL1" ]]; then
    echo -e "${YELLOW}WARNING: You appear to be running WSL 1, but WSL 2 is recommended.${NC}"
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
    echo -e "${GREEN}✓ WSL 2 detected. Proceeding with setup...${NC}"
fi

# Step 2: Fix script permissions
echo -e "\n${BLUE}Step 2: Fixing script permissions...${NC}"
echo "Making all scripts executable..."

# Fix permissions for scripts in the current directory
if [ -d "$SCRIPT_DIR/scripts" ]; then
    echo "Making scripts in /scripts directory executable..."
    chmod +x "$SCRIPT_DIR"/scripts/*.sh
    echo -e "${GREEN}✓ Scripts in /scripts directory are now executable${NC}"
fi

# Make housekeeping scripts in root directory executable
echo "Making housekeeping scripts in root directory executable..."
chmod +x "$SCRIPT_DIR"/*.sh
echo -e "${GREEN}✓ Housekeeping scripts are now executable${NC}"

# Step 3: Set up directory structure
echo -e "\n${BLUE}Step 3: Setting up directory structure...${NC}"

# Create projects directory structure if it doesn't exist
echo "Creating projects directory structure..."
mkdir -p "$HOME/projects/github"
mkdir -p "$HOME/projects/claude"
mkdir -p "$HOME/projects/claude/template"
echo -e "${GREEN}✓ Projects directory structure created${NC}"

# Step 4: Verify Node.js installation
echo -e "\n${BLUE}Step 4: Verifying Node.js installation...${NC}"

# Check if Node.js is installed
if command -v node &> /dev/null; then
    NODE_VERSION=$(node -v)
    echo -e "${GREEN}✓ Node.js is installed (Version: $NODE_VERSION)${NC}"
    
    # Check npm as well
    if command -v npm &> /dev/null; then
        NPM_VERSION=$(npm -v)
        echo -e "${GREEN}✓ npm is installed (Version: $NPM_VERSION)${NC}"
    else
        echo -e "${YELLOW}WARNING: npm is not installed, but Node.js is.${NC}"
        echo "This is unusual. You may need to reinstall Node.js."
        echo "Recommendation: sudo apt update && sudo apt install nodejs npm -y"
    fi
else
    echo -e "${YELLOW}Node.js is not installed.${NC}"
    echo "Node.js is required for Claude Code installation."
    echo ""
    echo "Would you like to install Node.js now? (y/n)"
    read -r install_node
    
    if [[ $install_node =~ ^[Yy]$ ]]; then
        echo "Installing Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
        
        # Check if installation was successful
        if command -v node &> /dev/null; then
            NODE_VERSION=$(node -v)
            echo -e "${GREEN}✓ Node.js installed successfully (Version: $NODE_VERSION)${NC}"
        else
            echo -e "${RED}Node.js installation failed.${NC}"
            echo "Please install Node.js manually:"
            echo "  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -"
            echo "  sudo apt-get install -y nodejs"
        fi
    else
        echo "Skipping Node.js installation."
        echo "Note: You will need to install Node.js before running the Claude Code setup."
    fi
fi

# Step 5: Fix common issues
echo -e "\n${BLUE}Step 5: Fixing common issues...${NC}"

# Check for dos2unix utility
if ! command -v dos2unix &> /dev/null; then
    echo "Installing dos2unix utility for line ending conversion..."
    sudo apt-get update
    sudo apt-get install -y dos2unix
fi

# Fix line endings in script files
echo "Fixing line endings in script files..."
if command -v dos2unix &> /dev/null; then
    find "$SCRIPT_DIR" -name "*.sh" -exec dos2unix {} \; 2>/dev/null
    echo -e "${GREEN}✓ Line endings fixed in script files${NC}"
else
    echo -e "${YELLOW}WARNING: dos2unix not available. Line endings may cause issues.${NC}"
fi

# Check for jq utility (used in some scripts)
if ! command -v jq &> /dev/null; then
    echo "Installing jq utility for JSON processing..."
    sudo apt-get update
    sudo apt-get install -y jq
    echo -e "${GREEN}✓ jq installed for JSON processing${NC}"
else
    echo -e "${GREEN}✓ jq is already installed${NC}"
fi

# Check if zstd is installed (used by WSL for file compression)
if ! command -v zstd &> /dev/null; then
    echo "Installing zstd utility for file compression..."
    sudo apt-get update
    sudo apt-get install -y zstd
    echo -e "${GREEN}✓ zstd installed for file compression${NC}"
else
    echo -e "${GREEN}✓ zstd is already installed${NC}"
fi

# Create .wslconfig in Windows home if it doesn't exist
echo "Checking for .wslconfig in Windows home..."
WIN_HOME=$(wslpath "$(cmd.exe /c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r')")
WSLCONFIG_PATH="$WIN_HOME/.wslconfig"

if [ -f "$WSLCONFIG_PATH" ]; then
    echo -e "${GREEN}✓ .wslconfig exists in Windows home directory${NC}"
else
    echo "Creating .wslconfig in Windows home directory..."
    cat > "$WSLCONFIG_PATH" << 'EOL'
[wsl2]
memory=8GB
processors=4
localhostForwarding=true
EOL
    echo -e "${GREEN}✓ .wslconfig created in Windows home directory${NC}"
    echo -e "${YELLOW}Note: You may need to restart WSL for these settings to take effect.${NC}"
fi

# Copy this script to the home directory if requested
if [ "$COPY_TO_HOME" = true ]; then
    echo -e "\n${BLUE}Copying preparation script to home directory...${NC}"
    cp "$0" "$HOME/wsl-prep.sh"
    chmod +x "$HOME/wsl-prep.sh"
    echo -e "${GREEN}✓ Script copied to $HOME/wsl-prep.sh${NC}"
    echo "You can run it from your home directory with: ~/wsl-prep.sh"
fi

# Provide summary and next steps
echo ""
echo -e "${BLUE}========================================"
echo -e " WSL Preparation Complete"
echo -e "========================================${NC}"
echo ""
echo -e "${GREEN}Your WSL environment is now prepared for Claude Code installation.${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Run the Claude Code setup script:"
echo "   ./run-claude-setup.sh"
echo ""
echo "2. Configure credentials:"
echo "   ./scripts/06-lx-credentials.sh"
echo "   And in PowerShell: ./scripts/05-win-credentials.ps1"
echo ""
echo "3. Validate your installation:"
echo "   ./scripts/99-validation.sh"
echo ""
echo "4. Start using Claude Code:"
echo "   claude"
echo ""
echo -e "${BLUE}========================================${NC}"

# Save a timestamp to indicate this prep was completed
mkdir -p "$HOME/.wsl4claude"
date > "$HOME/.wsl4claude/.prep_completed"

exit 0
