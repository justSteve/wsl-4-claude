#!/bin/bash

# WSL-4-Claude Setup Script
# This script creates the necessary directory structure and prepares your WSL environment

set -e  # Exit on error

# Color codes for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Creating WSL environment for Claude Code...${NC}"

# Define base directories
WSL_PROJECT_DIR="$HOME/wsl-4-claude"
WINDOWS_SOURCE_DIR="/mnt/c/Users/${USER,,}/OneDrive/Code/wsl-4-claude"

# Check if source directory exists or can be created
if [ ! -d "$WINDOWS_SOURCE_DIR" ]; then
    echo -e "${YELLOW}Windows source directory not found at: $WINDOWS_SOURCE_DIR${NC}"
    echo -e "Please enter the path to your Windows source directory (e.g., /mnt/c/Users/YourName/OneDrive/Code/wsl-4-claude):"
    read WINDOWS_SOURCE_DIR
    
    if [ ! -d "$WINDOWS_SOURCE_DIR" ]; then
        echo "Source directory does not exist. Creating a minimal template structure."
        mkdir -p "$WSL_PROJECT_DIR"
    fi
else
    echo "Found Windows source directory at: $WINDOWS_SOURCE_DIR"
fi

# Create directory structure in WSL
echo "Creating directory structure in WSL..."
mkdir -p "$WSL_PROJECT_DIR"/{scripts,config,docs,windows,logs}

# Create scripts directory and subdirectories
mkdir -p "$WSL_PROJECT_DIR/scripts"

# Copy files from Windows to WSL (if they exist)
if [ -d "$WINDOWS_SOURCE_DIR" ]; then
    echo "Copying files from Windows to WSL..."
    
    # Copy main setup script
    if [ -f "$WINDOWS_SOURCE_DIR/setup.sh" ]; then
        cp "$WINDOWS_SOURCE_DIR/setup.sh" "$WSL_PROJECT_DIR/"
        chmod +x "$WSL_PROJECT_DIR/setup.sh"
    else
        # Create a basic setup.sh if it doesn't exist
        cat > "$WSL_PROJECT_DIR/setup.sh" << 'EOL'
#!/bin/bash
# Main setup script for WSL-4-Claude environment

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting WSL-4-Claude setup...${NC}"

# Run each component script in order
for script in scripts/[0-9][0-9]-*.sh; do
    if [ -f "$script" ]; then
        echo -e "${YELLOW}Running $script...${NC}"
        bash "$script"
        echo ""
    fi
done

echo -e "${GREEN}Setup complete!${NC}"
EOL
        chmod +x "$WSL_PROJECT_DIR/setup.sh"
    fi
    
    # Copy component scripts
    for script in 00-init-repo.sh 01-wsl-setup.sh 02-dev-tools.sh 03-git-config.sh 04-claude-setup.sh 06-lx-credentials.sh 99-validation.sh; do
        if [ -f "$WINDOWS_SOURCE_DIR/$script" ]; then
            cp "$WINDOWS_SOURCE_DIR/$script" "$WSL_PROJECT_DIR/scripts/"
            chmod +x "$WSL_PROJECT_DIR/scripts/$script"
        fi
    done
    
    # Copy Windows script (if present)
    if [ -f "$WINDOWS_SOURCE_DIR/05-win-credentials.ps1" ]; then
        cp "$WINDOWS_SOURCE_DIR/05-win-credentials.ps1" "$WSL_PROJECT_DIR/windows/"
    fi
    
    # Copy component scripts from scripts directory (if they exist)
    if [ -d "$WINDOWS_SOURCE_DIR/scripts" ]; then
        for script in 00-init-repo.sh 01-wsl-setup.sh 02-dev-tools.sh 03-git-config.sh 04-claude-setup.sh 06-lx-credentials.sh 99-validation.sh; do
            if [ -f "$WINDOWS_SOURCE_DIR/scripts/$script" ]; then
                cp "$WINDOWS_SOURCE_DIR/scripts/$script" "$WSL_PROJECT_DIR/scripts/"
                chmod +x "$WSL_PROJECT_DIR/scripts/$script"
            fi
        done
    fi
    
    # Copy config files and documentation (if they exist)
    if [ -d "$WINDOWS_SOURCE_DIR/config" ]; then
        cp -r "$WINDOWS_SOURCE_DIR/config"/* "$WSL_PROJECT_DIR/config"/
    fi
    
    if [ -d "$WINDOWS_SOURCE_DIR/docs" ]; then
        cp -r "$WINDOWS_SOURCE_DIR/docs"/* "$WSL_PROJECT_DIR/docs"/
    fi
else
    # Create placeholder files if Windows source doesn't exist
    echo "Creating placeholder script files..."
    
    # Create placeholder component scripts
    for script in 00-init-repo.sh 01-wsl-setup.sh 02-dev-tools.sh 03-git-config.sh 04-claude-setup.sh 06-lx-credentials.sh 99-validation.sh; do
        cat > "$WSL_PROJECT_DIR/scripts/$script" << EOL
#!/bin/bash
# Placeholder for $script
echo "This is a placeholder for $script"
# TODO: Implement $script functionality
EOL
        chmod +x "$WSL_PROJECT_DIR/scripts/$script"
    done
    
    # Create placeholder Windows script
    cat > "$WSL_PROJECT_DIR/windows/05-win-credentials.ps1" << EOL
# Placeholder for Windows credential management script
Write-Host "This is a placeholder for Windows credential management"
# TODO: Implement Windows credential management
EOL
    
    # Create placeholder README
    cat > "$WSL_PROJECT_DIR/README.md" << EOL
# WSL for Claude Code

A best known configuration for WSL environments optimized for Claude Code and GitHub integration.

This is a placeholder README file. Please update with project details.
EOL
fi

# Make all script files executable
find "$WSL_PROJECT_DIR" -name "*.sh" -exec chmod +x {} \;

echo -e "${GREEN}WSL environment setup complete!${NC}"
echo -e "Project directory: ${YELLOW}$WSL_PROJECT_DIR${NC}"
echo ""
echo "Next steps:"
echo "1. Customize the scripts in the scripts/ directory"
echo "2. Run ./setup.sh to execute the setup process"
echo "3. Use the Windows script for credential management"
echo ""
echo "For more information, see the documentation in the docs/ directory."
