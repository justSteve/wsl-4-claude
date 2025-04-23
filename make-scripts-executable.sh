#!/bin/bash
#
# WSL4CLAUDE - Make Scripts Executable
# ===========================================================
#
# This simple script ensures all shell scripts are executable
#

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Making WSL4CLAUDE scripts executable...${NC}"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Make all .sh files in the repo executable
find "$SCRIPT_DIR" -name "*.sh" -exec chmod +x {} \;

echo -e "${GREEN}Done! All shell scripts are now executable.${NC}"
