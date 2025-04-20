#!/bin/bash
#
# Prepare configuration files for WSL environment setup
# This script runs the Python configuration generator and prepares the environment

set -e  # Exit immediately if a command exits with a non-zero status

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Preparing configuration for WSL Claude Code environment...${NC}"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Python 3 is not installed. Please install Python 3 first.${NC}"
    exit 1
fi

# Run the Python configuration generator interactively
echo -e "${YELLOW}Running configuration generator...${NC}"
python3 "$SCRIPT_DIR/python/generate_config.py" --interactive --all

# Check if the configuration files were created
if [ ! -f "$REPO_ROOT/config/03-git-config.json" ] || 
   [ ! -f "$REPO_ROOT/config/04-claude-setup.json" ] || 
   [ ! -f "$REPO_ROOT/config/06-lx-credentials.json" ]; then
    echo -e "${RED}Failed to create all configuration files. Please check for errors.${NC}"
    exit 1
fi

echo -e "${GREEN}Configuration prepared successfully!${NC}"
echo -e "${YELLOW}You can now run './setup.sh' to set up your WSL environment.${NC}"
