#!/bin/bash
#
# Run the Claude Code setup script
# This wrapper script executes the setup script with proper permissions
#

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Running Claude Code setup script...${NC}"

# Make the script executable
chmod +x scripts/04-claude-setup.sh

# Run the script
./scripts/04-claude-setup.sh

# Check the result
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Claude Code setup completed successfully!${NC}"
    echo "You should now be able to use Claude Code."
    echo ""
    echo "To check your installation, run: claude --version"
    echo "To start Claude Code, run: claude"
else
    echo -e "${RED}Claude Code setup failed.${NC}"
    echo "Please check the logs for more information."
fi
