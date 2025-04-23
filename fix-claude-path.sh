#!/bin/bash
#
# WSL4CLAUDE - Fix Claude Code PATH Issues
# ===========================================================
#
# This script diagnoses and fixes Claude Code path issues

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}==================================================${NC}"
echo -e "${BLUE}  Fixing Claude Code PATH Issues                  ${NC}"
echo -e "${BLUE}==================================================${NC}"
echo ""

# Load NVM if available
if [ -d "$HOME/.nvm" ]; then
    echo "Loading NVM environment..."
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

# Find Claude executable
echo "Searching for Claude Code executable..."
NVM_BIN="$NVM_DIR/versions/node/$(nvm current)/bin"
GLOBAL_NODE_BIN="/usr/local/bin"
HOME_NODE_BIN="$HOME/.npm-global/bin"
NPM_BIN="$(npm config get prefix)/bin"

CLAUDE_LOCATIONS=(
    "$NVM_BIN/claude"
    "$GLOBAL_NODE_BIN/claude"
    "$HOME_NODE_BIN/claude"
    "$NPM_BIN/claude"
    "$HOME/.nvm/versions/node/*/bin/claude"
)

CLAUDE_PATH=""
for location in "${CLAUDE_LOCATIONS[@]}"; do
    # Handle glob expansion
    if [[ $location == *"*"* ]]; then
        for expanded_path in $location; do
            if [ -f "$expanded_path" ]; then
                CLAUDE_PATH="$expanded_path"
                echo -e "${GREEN}Found Claude at: $CLAUDE_PATH${NC}"
                break 2
            fi
        done
    elif [ -f "$location" ]; then
        CLAUDE_PATH="$location"
        echo -e "${GREEN}Found Claude at: $CLAUDE_PATH${NC}"
        break
    fi
done

if [ -z "$CLAUDE_PATH" ]; then
    echo -e "${YELLOW}Claude executable not found. Searching globally...${NC}"
    CLAUDE_PATH=$(find "$HOME" -name "claude" -type f -executable 2>/dev/null | head -n 1)
    
    if [ -z "$CLAUDE_PATH" ]; then
        echo -e "${RED}Could not find Claude executable. Let's check if it's installed...${NC}"
        
        # Check in npm global packages
        echo "Checking npm global packages..."
        if npm list -g | grep -q claude; then
            echo -e "${GREEN}Claude appears to be installed globally via npm.${NC}"
            
            # Try to get its path
            NPM_ROOT=$(npm root -g)
            NPM_BIN_DIR=$(dirname "$NPM_ROOT")
            echo "npm bin directory should be: $NPM_BIN_DIR/bin"
            
            if [ -f "$NPM_BIN_DIR/bin/claude" ]; then
                CLAUDE_PATH="$NPM_BIN_DIR/bin/claude"
                echo -e "${GREEN}Found Claude at: $CLAUDE_PATH${NC}"
            fi
        else
            echo -e "${RED}Claude does not appear to be installed via npm.${NC}"
            echo "Would you like to install Claude Code again? (y/n)"
            read -r reinstall
            
            if [[ $reinstall =~ ^[Yy]$ ]]; then
                echo "Installing Claude Code..."
                npm install -g @anthropic-ai/claude-code
                
                # Check if installation was successful
                if npm list -g | grep -q claude; then
                    echo -e "${GREEN}Claude Code successfully installed!${NC}"
                    NPM_ROOT=$(npm root -g)
                    NPM_BIN_DIR=$(dirname "$NPM_ROOT")
                    CLAUDE_PATH="$NPM_BIN_DIR/bin/claude"
                else
                    echo -e "${RED}Installation failed.${NC}"
                    exit 1
                fi
            else
                echo "Skipping reinstallation."
                exit 1
            fi
        fi
    else
        echo -e "${GREEN}Found Claude at: $CLAUDE_PATH${NC}"
    fi
fi

# Update the claudecode wrapper script
if [ -n "$CLAUDE_PATH" ]; then
    echo "Updating claudecode wrapper script..."
    mkdir -p "$HOME/bin"
    
    cat > "$HOME/bin/claudecode" << EOL
#!/bin/bash
#
# Claude Code Wrapper Script
# This script runs Claude Code with the appropriate environment variables and NVM

# Load NVM and Node.js
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"

# Check if API key is set
if [ -z "\$ANTHROPIC_API_KEY" ]; then
    echo "ANTHROPIC_API_KEY is not set. Please set it with:"
    echo "export ANTHROPIC_API_KEY=your_api_key_here"
    exit 1
fi

# Get environment type
ENV_TYPE=\${ENV_TYPE:-development}
echo "Running Claude Code in \$ENV_TYPE environment..."

# Run Claude Code directly from its path
$CLAUDE_PATH "\$@"
EOL

    chmod +x "$HOME/bin/claudecode"
    echo -e "${GREEN}Updated claudecode wrapper script.${NC}"
    
    # Make sure ~/bin is in the PATH
    if ! grep -q "export PATH=\$HOME/bin:\$PATH" ~/.bashrc; then
        echo "Adding ~/bin to PATH in .bashrc..."
        echo '# Add bin directory to PATH' >> ~/.bashrc
        echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
    fi
    
    echo -e "${BLUE}Please refresh your shell by running:${NC}"
    echo "source ~/.bashrc"
    echo ""
    echo -e "${BLUE}Then try running Claude Code again:${NC}"
    echo "claudecode"
    echo ""
    echo -e "${YELLOW}Don't forget to set your API key:${NC}"
    echo "export ANTHROPIC_API_KEY=your_api_key_here"
else
    echo -e "${RED}Could not locate Claude executable.${NC}"
    echo "Please try running the installation script again."
    exit 1
fi

# Create a simple script to verify installation
cat > "$HOME/verify-claude.sh" << EOF
#!/bin/bash
echo "Verifying Claude Code installation..."
echo "NVM status:"
command -v nvm

echo "Node.js version:"
node -v

echo "NPM version:"
npm -v

echo "Claude location:"
which claude

echo "PATH environment variable:"
echo \$PATH

echo "Global npm packages:"
npm list -g --depth=0
EOF

chmod +x "$HOME/verify-claude.sh"
echo -e "${GREEN}Created verification script at ~/verify-claude.sh${NC}"
echo "If you continue to have issues, please run this script and share the output."
