#!/bin/bash
#
# WSL4CLAUDE - Update to Improved Claude Setup
# ==================================================
# This script updates the main setup.sh to use the improved Claude setup script

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}==================================================${NC}"
echo -e "${BLUE}  Updating to Improved Claude Setup Script         ${NC}"
echo -e "${BLUE}==================================================${NC}"
echo ""

# Make the new script executable
echo "Making the improved Claude setup script executable..."
chmod +x scripts/04-claude-setup-fixed.sh

# Create a run script for the improved version
echo "Creating run script for the improved version..."
cat > run-improved-claude-setup.sh << 'EOL'
#!/bin/bash
#
# WSL4CLAUDE - Run Improved Claude Setup
# This script runs the improved Claude Code setup script directly

echo "Running improved Claude Code setup script..."
scripts/04-claude-setup-fixed.sh "$@"
EOL

chmod +x run-improved-claude-setup.sh

# Update the setup.sh to use the improved script
echo "Updating main setup.sh to use the improved script..."
cp setup.sh setup.sh.backup
sed -i 's|scripts/04-claude-setup.sh|scripts/04-claude-setup-fixed.sh|g' setup.sh

# Verify the changes
CHANGED=$(grep -c "scripts/04-claude-setup-fixed.sh" setup.sh)
if [ "$CHANGED" -gt 0 ]; then
    echo -e "${GREEN}Successfully updated setup.sh to use the improved script!${NC}"
else
    echo -e "${RED}Failed to update setup.sh. Manual intervention required.${NC}"
    echo "Please edit setup.sh and replace 'scripts/04-claude-setup.sh' with 'scripts/04-claude-setup-fixed.sh'"
    exit 1
fi

echo -e "${GREEN}Update complete!${NC}"
echo ""
echo "The following changes have been made:"
echo "1. Added improved Claude setup script at scripts/04-claude-setup-fixed.sh"
echo "2. Updated main setup.sh to use the improved script"
echo "3. Created run-improved-claude-setup.sh for direct execution"
echo "4. Backed up original setup.sh to setup.sh.backup"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. To run the improved script directly:"
echo "   ./run-improved-claude-setup.sh"
echo ""
echo "2. Or to run the full setup with the improved script:"
echo "   ./setup.sh"
echo ""
echo "3. After running the improved script, you should:"
echo "   a) Close and reopen your WSL terminal"
echo "   b) Run: source ~/.bashrc"
echo "   c) Try running 'claude' command"
echo ""
echo "4. If you still have issues, run the verification script:"
echo "   ~/verify-claude.sh"
