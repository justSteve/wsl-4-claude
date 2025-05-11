#!/bin/bash
#
# WSL4CLAUDE - Architecture Fix
# ===========================================================
#
# This script properly corrects the architecture of the WSL4Claude setup
# by ensuring scripts are managed within WSL rather than run from Windows paths
#

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}==================================================${NC}"
echo -e "${BLUE}  WSL4CLAUDE - Architecture Fix                   ${NC}"
echo -e "${BLUE}==================================================${NC}"
echo ""

# First, check if we're running in WSL
if ! grep -q "microsoft" /proc/version &>/dev/null; then
    echo -e "${RED}Error: This script must be run inside WSL.${NC}"
    echo "Please run this script from within your WSL environment."
    exit 1
fi

# Determine the Windows repo path and WSL installation path
WINDOWS_REPO_PATH="/mnt/c/Users/steve/OneDrive/Code/wsl-4-claude"
WSL_INSTALL_PATH="$HOME/wsl-4-claude"

echo "Checking for Windows repo path at: $WINDOWS_REPO_PATH"
if [ ! -d "$WINDOWS_REPO_PATH" ]; then
    echo -e "${YELLOW}Windows repository path not found at: $WINDOWS_REPO_PATH${NC}"
    echo "Please enter the path to your Windows repository (e.g., /mnt/c/Users/YourName/OneDrive/Code/wsl-4-claude):"
    read WINDOWS_REPO_PATH
    
    if [ ! -d "$WINDOWS_REPO_PATH" ]; then
        echo -e "${RED}Error: The specified directory does not exist.${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}Found Windows repository at: $WINDOWS_REPO_PATH${NC}"

# Create WSL installation directory
echo "Creating WSL installation directory at: $WSL_INSTALL_PATH"
mkdir -p "$WSL_INSTALL_PATH"

# Copy all necessary files from Windows to WSL
echo "Copying files from Windows repository to WSL installation directory..."

# Create directory structure
mkdir -p "$WSL_INSTALL_PATH"/{scripts,config,docs,logs,windows}

# Copy scripts with proper line endings and make them executable
echo "Copying and fixing scripts..."
find "$WINDOWS_REPO_PATH" -name "*.sh" -type f | while read -r script; do
    relative_path="${script#$WINDOWS_REPO_PATH/}"
    target_dir=$(dirname "$WSL_INSTALL_PATH/$relative_path")
    
    # Create target directory if it doesn't exist
    mkdir -p "$target_dir"
    
    # Copy script with proper line endings
    cat "$script" | tr -d '\r' > "$WSL_INSTALL_PATH/$relative_path"
    
    # Make script executable
    chmod +x "$WSL_INSTALL_PATH/$relative_path"
    
    echo "Copied: $relative_path"
done

# Copy PowerShell scripts to Windows directory
echo "Copying PowerShell scripts..."
find "$WINDOWS_REPO_PATH" -name "*.ps1" -type f | while read -r ps_script; do
    relative_path="${ps_script#$WINDOWS_REPO_PATH/}"
    target_dir=$(dirname "$WSL_INSTALL_PATH/windows/$relative_path")
    
    # Create target directory if it doesn't exist
    mkdir -p "$target_dir"
    
    # Copy PowerShell script
    cp "$ps_script" "$WSL_INSTALL_PATH/windows/$relative_path"
    
    echo "Copied: windows/$relative_path"
done

# Copy configuration files
echo "Copying configuration files..."
if [ -d "$WINDOWS_REPO_PATH/config" ]; then
    cp -r "$WINDOWS_REPO_PATH/config/"* "$WSL_INSTALL_PATH/config/"
fi

# Copy documentation files
echo "Copying documentation files..."
if [ -d "$WINDOWS_REPO_PATH/docs" ]; then
    cp -r "$WINDOWS_REPO_PATH/docs/"* "$WSL_INSTALL_PATH/docs/"
fi

# Copy README and other markdown files
echo "Copying markdown files..."
find "$WINDOWS_REPO_PATH" -name "*.md" -type f -not -path "*/\.*" | while read -r md_file; do
    relative_path="${md_file#$WINDOWS_REPO_PATH/}"
    
    # Skip if file is in a subdirectory that's already covered
    if [[ "$relative_path" != docs/* && "$relative_path" != config/* ]]; then
        cp "$md_file" "$WSL_INSTALL_PATH/$relative_path"
        echo "Copied: $relative_path"
    fi
done

# Create a launcher script in the WSL home directory
echo "Creating launcher script..."
cat > "$HOME/launch-claude-setup.sh" << EOL
#!/bin/bash
#
# WSL4CLAUDE - Launcher Script
# ===========================================================
#
# This script launches the WSL4Claude setup from the WSL home directory
#

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "\${BLUE}==================================================${NC}"
echo -e "\${BLUE}  WSL4CLAUDE - Launcher                          ${NC}"
echo -e "\${BLUE}==================================================${NC}"
echo ""

# Change to the installation directory
cd "$WSL_INSTALL_PATH"

# Run the setup script
echo -e "\${YELLOW}Running WSL4Claude setup...${NC}"
./setup.sh "\$@"

echo ""
echo -e "\${GREEN}Setup complete!${NC}"
echo "You can now use Claude Code in your WSL environment."
EOL

chmod +x "$HOME/launch-claude-setup.sh"

# Create a direct claude setup script
echo "Creating direct Claude setup script..."
cat > "$HOME/setup-claude.sh" << EOL
#!/bin/bash
#
# WSL4CLAUDE - Direct Claude Setup
# ===========================================================
#
# This script directly runs the Claude Code setup
#

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "\${BLUE}==================================================${NC}"
echo -e "\${BLUE}  WSL4CLAUDE - Direct Claude Setup               ${NC}"
echo -e "\${BLUE}==================================================${NC}"
echo ""

# Change to the installation directory
cd "$WSL_INSTALL_PATH"

# Run just the Claude setup script
echo -e "\${YELLOW}Running Claude Code setup...${NC}"
./scripts/04-claude-setup-fixed.sh

echo ""
echo -e "\${GREEN}Claude Code setup complete!${NC}"
echo "To use Claude Code, you need to:"
echo "1. Close and reopen your terminal or run: source ~/.bashrc"
echo "2. Set your API key: export ANTHROPIC_API_KEY=your_api_key_here"
echo "3. Run the 'claude' command"
EOL

chmod +x "$HOME/setup-claude.sh"

echo -e "${GREEN}Architecture fix complete!${NC}"
echo ""
echo "The WSL4Claude setup has been properly organized to run within WSL."
echo "All scripts have been copied to: $WSL_INSTALL_PATH"
echo ""
echo -e "${YELLOW}To use the fixed setup:${NC}"
echo ""
echo "1. Run the launcher script from your WSL home directory:"
echo "   ~/launch-claude-setup.sh"
echo ""
echo "2. Or run the direct Claude setup:"
echo "   ~/setup-claude.sh"
echo ""
echo "3. The scripts will now execute within WSL properly, without"
echo "   referencing files directly from the Windows filesystem."
echo ""
echo -e "${BLUE}==================================================${NC}"
