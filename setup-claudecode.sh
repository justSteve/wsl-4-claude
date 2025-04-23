#!/bin/bash
#
# Claude Code Setup Manager
# Simple wrapper script to access the main setup script
./config
# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Set path to the actual script
WINDOWS_PATH="/mnt/c/Users/steve/OneDrive/Code/wsl-4-claude"
SCRIPT_PATH="$WINDOWS_PATH/scripts/setup-claudecode.sh"

# Check if the script exists
if [ ! -f "$SCRIPT_PATH" ]; then
    echo -e "${RED}Error: Setup script not found at $SCRIPT_PATH${NC}"
    echo "Please check the path and ensure the setup script exists."
    exit 1
fi

# Make sure the script is executable
chmod +x "$SCRIPT_PATH" 2>/dev/null

# Pass all arguments to the main script
"$SCRIPT_PATH" "$@"
