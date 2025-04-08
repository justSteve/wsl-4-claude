#!/bin/bash
#
# Main setup script for Claude WSL Environment
# This script orchestrates the entire installation process

set -e  # Exit immediately if a command exits with a non-zero status

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Display banner
echo -e "${BLUE}"
echo "==============================================="
echo "       Claude WSL Environment Setup"
echo "==============================================="
echo -e "${NC}"
echo "This script will set up a WSL environment optimized for"
echo "Claude Code integration with GitHub repositories."
echo ""
echo -e "${YELLOW}Note: Some steps may require administrator privileges.${NC}"
echo ""

# Check if running in WSL
if grep -q Microsoft /proc/version || grep -q microsoft /proc/version; then
    echo -e "${GREEN}Running in WSL environment. Proceeding...${NC}"
else
    echo -e "${YELLOW}Not running in WSL. Some scripts may need to be run from Windows.${NC}"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup aborted."
        exit 1
    fi
fi

# Function to run a script and check its exit status
run_script() {
    local script=$1
    local description=$2
    
    echo -e "\n${BLUE}=== $description ===${NC}"
    
    if [ -f "$script" ]; then
        chmod +x "$script"
        if "$script"; then
            echo -e "${GREEN}✅ $description completed successfully${NC}"
            return 0
        else
            echo -e "${RED}❌ $description failed${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Script not found: $script${NC}"
        return 1
    fi
}

# Main installation process
echo -e "\n${BLUE}Starting installation process...${NC}"

# 1. Repository initialization
run_script "./scripts/00-init-repo.sh" "Repository Initialization"

# 2. WSL Base Setup
run_script "./scripts/01-wsl-setup.sh" "WSL Base Configuration"

# 3. Developer Tools Installation
run_script "./scripts/02-dev-tools.sh" "Developer Tools Installation"

# 4. Git and GitHub Configuration
run_script "./scripts/03-git-config.sh" "Git and GitHub Configuration"

# 5. Claude Code Installation
run_script "./scripts/04-claude-setup.sh" "Claude Code Installation"

# 6. Environment Validation
run_script "./scripts/99-validation.sh" "Environment Validation"

# Display completion message
echo -e "\n${GREEN}=== Installation Complete ===${NC}"
echo -e "Your Claude WSL Environment has been set up successfully."
echo -e "\n${YELLOW}Next Steps:${NC}"
echo "1. Configure your credentials using the scripts in the scripts directory:"
echo "   - For Windows: ./scripts/05-win-credentials.ps1"
echo "   - For Linux/WSL: ./scripts/06-lx-credentials.sh"
echo ""
echo "2. Review the documentation in the docs directory for usage instructions."
echo ""
echo -e "${BLUE}Thank you for using Claude WSL Environment!${NC}"