#!/bin/bash
#
# Claude Code Setup Manager
# Script to manage Claude Code setup in WSL
# Options: check, fromscratch, refresh

set -e  # Exit immediately if a command exits with a non-zero status

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Set default paths
WINDOWS_PATH="/mnt/c/Users/steve/OneDrive/Code/wsl-4-claude"
REPO_ROOT="$WINDOWS_PATH"
SCRIPT_DIR="$REPO_ROOT/scripts"

# Show usage information
show_usage() {
    echo -e "${BLUE}Claude Code Setup Manager${NC}"
    echo ""
    echo "Usage: setup-claudecode.sh [OPTION]"
    echo ""
    echo "Options:"
    echo "  check        - Check current Claude Code setup status"
    echo "  fromscratch  - Perform a complete fresh installation"
    echo "  refresh      - Update existing installation"
    echo "  help         - Show this help message"
    echo ""
    echo "Example: setup-claudecode.sh check"
}

# Check current setup
check_setup() {
    echo -e "${BLUE}Checking Claude Code setup...${NC}"
    
    # Check if Claude Code is installed
    if command -v claude &> /dev/null; then
        echo -e "${GREEN}✓ Claude Code is installed${NC}"
        echo "Version: $(claude --version 2>&1 || echo 'Unknown')"
    else
        echo -e "${RED}✗ Claude Code is not installed${NC}"
    fi
    
    # Check if configuration directory exists
    if [ -d "$HOME/.claude" ]; then
        echo -e "${GREEN}✓ Claude configuration directory exists${NC}"
        
        # Check if config file exists
        if [ -f "$HOME/.claude/config.json" ]; then
            echo -e "${GREEN}✓ Configuration file exists${NC}"
            
            # Display key configuration settings
            echo -e "${YELLOW}Configuration settings:${NC}"
            if command -v jq &> /dev/null; then
                echo "Model: $(jq -r '.model // "Not set"' "$HOME/.claude/config.json")"
                echo "Temperature: $(jq -r '.temperature // "Not set"' "$HOME/.claude/config.json")"
                echo "Max Tokens: $(jq -r '.maxTokens // "Not set"' "$HOME/.claude/config.json")"
            else
                echo "Install jq for detailed config information: sudo apt install jq"
            fi
        else
            echo -e "${RED}✗ Configuration file is missing${NC}"
        fi
    else
        echo -e "${RED}✗ Claude configuration directory is missing${NC}"
    fi
    
    # Check if API key is set
    if [ -n "$ANTHROPIC_API_KEY" ]; then
        echo -e "${GREEN}✓ ANTHROPIC_API_KEY is set${NC}"
        echo "Key (masked): ${ANTHROPIC_API_KEY:0:3}...${ANTHROPIC_API_KEY:(-3)}"
    else
        echo -e "${RED}✗ ANTHROPIC_API_KEY is not set${NC}"
    fi
    
    # Check if project structure exists
    if [ -d "$HOME/projects/claude" ]; then
        echo -e "${GREEN}✓ Claude projects directory exists${NC}"
    else
        echo -e "${RED}✗ Claude projects directory is missing${NC}"
    fi
    
    echo -e "${BLUE}Check complete.${NC}"
}

# Setup from scratch
setup_fromscratch() {
    echo -e "${BLUE}Setting up Claude Code from scratch...${NC}"
    
    # Confirm action
    echo -e "${YELLOW}This will perform a complete fresh installation of Claude Code.${NC}"
    echo -e "${YELLOW}Any existing setup will be removed.${NC}"
    echo ""
    read -p "Do you want to continue? (y/n): " confirm
    
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Setup cancelled.${NC}"
        return
    fi
    
    # Remove existing Claude Code setup
    echo "Removing existing Claude Code setup..."
    
    # Remove global npm packages if installed via npm
    if command -v npm &> /dev/null; then
        echo "Checking for npm installations..."
        if npm list -g claude-cli &> /dev/null; then
            echo "Removing Claude Code npm package..."
            npm uninstall -g claude-cli
        fi
    fi
    
    # Remove configuration directory
    if [ -d "$HOME/.claude" ]; then
        echo "Removing configuration directory..."
        rm -rf "$HOME/.claude"
    fi
    
    # Remove bin directory files related to Claude
    if [ -f "$HOME/bin/claudecode" ]; then
        echo "Removing Claude Code wrapper script..."
        rm -f "$HOME/bin/claudecode"
    fi
    
    # Remove project directory (but ask first)
    if [ -d "$HOME/projects/claude" ]; then
        echo -e "${YELLOW}Claude projects directory exists at $HOME/projects/claude${NC}"
        read -p "Do you want to remove it? (y/n): " remove_projects
        
        if [[ $remove_projects =~ ^[Yy]$ ]]; then
            echo "Removing Claude projects directory..."
            rm -rf "$HOME/projects/claude"
        else
            echo "Keeping Claude projects directory."
        fi
    fi
    
    # Run setup scripts in sequence
    echo "Running setup scripts..."
    
    # First check if the setup script is available
    if [ -f "$SCRIPT_DIR/01-wsl-setup-fixed.sh" ]; then
        echo "Running WSL setup script..."
        bash "$SCRIPT_DIR/01-wsl-setup-fixed.sh"
    else
        echo "Running original WSL setup script..."
        bash "$SCRIPT_DIR/01-wsl-setup.sh"
    fi
    
    echo "Running developer tools setup script..."
    bash "$SCRIPT_DIR/02-dev-tools.sh"
    
    echo "Running Git configuration script..."
    bash "$SCRIPT_DIR/03-git-config.sh"
    
    echo "Running Claude Code setup script..."
    bash "$SCRIPT_DIR/04-claude-setup.sh"
    
    echo "Running Linux credentials setup script..."
    bash "$SCRIPT_DIR/06-lx-credentials.sh"
    
    echo "Running validation script..."
    if [ -f "$SCRIPT_DIR/99-validation.sh" ]; then
        bash "$SCRIPT_DIR/99-validation.sh"
    else
        echo -e "${YELLOW}Validation script not found. Skipping validation.${NC}"
    fi
    
    echo -e "${GREEN}Claude Code setup complete!${NC}"
    echo "Please restart your terminal or run 'source ~/.bashrc' to apply changes."
}

# Refresh existing setup
refresh_setup() {
    echo -e "${BLUE}Refreshing Claude Code setup...${NC}"
    
    # Confirm action
    echo -e "${YELLOW}This will update your existing Claude Code setup.${NC}"
    echo -e "${YELLOW}Your configuration and credentials will be preserved.${NC}"
    echo ""
    read -p "Do you want to continue? (y/n): " confirm
    
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Refresh cancelled.${NC}"
        return
    fi
    
    # Check if Claude Code is already installed
    if ! command -v claude &> /dev/null; then
        echo -e "${YELLOW}Claude Code does not appear to be installed.${NC}"
        read -p "Would you prefer to run a full setup instead? (y/n): " full_setup
        
        if [[ $full_setup =~ ^[Yy]$ ]]; then
            setup_fromscratch
            return
        fi
    fi
    
    # Update Claude Code
    echo "Updating Claude Code..."
    
    # If installed via npm, update the package
    if command -v npm &> /dev/null && npm list -g claude-cli &> /dev/null; then
        echo "Updating Claude Code npm package..."
        npm update -g claude-cli
    else
        # Otherwise, run the Claude setup script
        echo "Running Claude Code setup script..."
        bash "$SCRIPT_DIR/04-claude-setup.sh"
    fi
    
    # Update credentials if needed
    echo "Checking credentials..."
    if [ -z "$ANTHROPIC_API_KEY" ]; then
        echo -e "${YELLOW}ANTHROPIC_API_KEY is not set.${NC}"
        echo "Running Linux credentials setup script..."
        bash "$SCRIPT_DIR/06-lx-credentials.sh"
    fi
    
    echo -e "${GREEN}Claude Code refresh complete!${NC}"
    check_setup
}

# Main script logic
if [ $# -eq 0 ]; then
    show_usage
    exit 0
fi

option=$1

case $option in
    check)
        check_setup
        ;;
    fromscratch)
        setup_fromscratch
        ;;
    refresh)
        refresh_setup
        ;;
    help)
        show_usage
        ;;
    *)
        echo -e "${RED}Unknown option: $option${NC}"
        show_usage
        exit 1
        ;;
esac

exit 0
