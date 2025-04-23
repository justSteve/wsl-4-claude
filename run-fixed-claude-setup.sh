#!/bin/bash
#
# Run the FIXED Claude Setup Script
# This script runs the fixed version of the Claude Code setup script
# that bypasses WSL version checks

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Running fixed Claude Code setup script...${NC}"

# Path to the fixed script
SCRIPT_PATH="./scripts/04-claude-setup-fixed.sh"

# Check if the script exists
if [ ! -f "$SCRIPT_PATH" ]; then
    echo -e "${RED}Error: Fixed setup script not found at $SCRIPT_PATH${NC}"
    echo "Please check that the file exists."
    exit 1
fi

# Make sure the script is executable
chmod +x "$SCRIPT_PATH"

# Run the fixed script
"$SCRIPT_PATH" "$@"

echo -e "${GREEN}Setup complete!${NC}"
