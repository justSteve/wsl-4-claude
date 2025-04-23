#!/bin/bash
#
# WSL4CLAUDE - Install Claude Code with NVM
# ===========================================================
#
# This script is meant to be run from within WSL
# It installs Node.js via NVM and then installs Claude Code
#
# This approach ensures Node.js is cleanly installed in the WSL environment
# and avoids conflicts with Windows Node.js installations
#

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}==================================================${NC}"
echo -e "${BLUE}  Installing Claude Code with NVM for WSL2        ${NC}"
echo -e "${BLUE}==================================================${NC}"
echo ""

# First, determine if we are running in WSL
if ! grep -q "microsoft" /proc/version &>/dev/null; then
    echo -e "${RED}This script must be run inside WSL.${NC}"
    echo "Please run this script from within your WSL environment."
    exit 1
fi

# Create temporary directory for installation
TEMP_DIR="$HOME/.claude-install-temp"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Download or copy the required scripts
echo "Setting up installation scripts..."

# Create the Node.js installation script
echo "Creating Node.js NVM installation script..."
cat > "$TEMP_DIR/node-nvm-install.sh" << 'NODESCRIPT'
#!/bin/bash
#
# WSL4CLAUDE - Node.js Installation via NVM
# ===========================================================
# This script installs Node Version Manager (nvm) and Node.js in WSL,
# ensuring a clean installation isolated from Windows Node.js

set -e  # Exit immediately if a command exits with a non-zero status

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Setting up Node.js via NVM...${NC}"

# Check if nvm is already installed
if [ -d "$HOME/.nvm" ]; then
    echo -e "${YELLOW}NVM is already installed at $HOME/.nvm${NC}"
    
    # Check if nvm is in PATH and functioning
    if command -v nvm &>/dev/null || [ -s "$HOME/.nvm/nvm.sh" ]; then
        echo -e "${GREEN}NVM is properly configured in your PATH.${NC}"
    else
        echo -e "${YELLOW}NVM is installed but may not be in your PATH.${NC}"
        echo "Adding NVM to your PATH..."
        
        # Load NVM
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
        # Add NVM to .bashrc if not already there
        if ! grep -q "NVM_DIR" ~/.bashrc; then
            echo '# NVM Configuration' >> ~/.bashrc
            echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc
            echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' >> ~/.bashrc
            echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >> ~/.bashrc
        fi
        
        # Add NVM to .zshrc if it exists and doesn't have nvm config
        if [ -f ~/.zshrc ] && ! grep -q "NVM_DIR" ~/.zshrc; then
            echo '# NVM Configuration' >> ~/.zshrc
            echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc
            echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' >> ~/.zshrc
            echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >> ~/.zshrc
        fi
    fi
else
    # Install or update nvm
    echo "Installing NVM (Node Version Manager)..."
    
    # Download and run the nvm installation script
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    
    # Load NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    echo -e "${GREEN}NVM installed successfully!${NC}"
fi

# Verify nvm installation
if ! command -v nvm &>/dev/null; then
    echo -e "${YELLOW}Loading NVM from installation directory...${NC}"
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    if ! command -v nvm &>/dev/null; then
        echo -e "${RED}NVM installation failed or NVM is not in PATH.${NC}"
        echo "Please try again or install NVM manually."
        exit 1
    fi
fi

# Install Node.js using nvm
echo "Installing Node.js LTS version..."
nvm install --lts

# Use the installed Node.js version
nvm use --lts

# Verify Node.js installation
if ! command -v node &>/dev/null; then
    echo -e "${RED}Node.js installation failed.${NC}"
    exit 1
fi

# Display versions
NODE_VERSION=$(node -v)
NPM_VERSION=$(npm -v)
echo -e "${GREEN}Node.js installed successfully!${NC}"
echo "Node.js version: $NODE_VERSION"
echo "npm version: $NPM_VERSION"

# Check if Windows Node.js is in PATH
WINDOWS_NODE_PATH=$(find /mnt/c -path "*/nodejs*" -type d 2>/dev/null | head -n 1)
if [ -n "$WINDOWS_NODE_PATH" ]; then
    echo -e "${YELLOW}Windows Node.js installation detected at $WINDOWS_NODE_PATH${NC}"
    echo "This can cause conflicts. WSL will now use the NVM-installed Node.js instead."
    
    # Display PATH for debugging
    echo "Current PATH: $PATH"
    
    # Check if the Windows path is in the WSL PATH
    if echo "$PATH" | grep -q "/mnt/c.*nodejs"; then
        echo -e "${YELLOW}Windows Node.js path is in your WSL PATH.${NC}"
        echo "This might cause conflicts. Consider modifying your PATH to prioritize the WSL Node.js installation."
    fi
fi

# Create a sentinel file indicating this component has been configured
mkdir -p "$HOME/.claude"
touch "$HOME/.claude/.node_nvm_setup_complete"

echo -e "${GREEN}Node.js setup via NVM complete!${NC}"
echo ""
echo -e "${YELLOW}Node.js Environment:${NC}"
echo "  - NVM location: $HOME/.nvm"
echo "  - Node.js version: $NODE_VERSION"
echo "  - npm version: $NPM_VERSION"
echo ""
echo "Node.js is now installed and will be used for Claude Code installation."
NODESCRIPT

# Create the Claude Code installation script
echo "Creating Claude Code installation script..."
cat > "$TEMP_DIR/claude-setup.sh" << 'CLAUDESCRIPT'
#!/bin/bash
#
# WSL4CLAUDE - Claude Code Installation with NVM
# ===========================================================
# This script installs Claude Code using NVM-managed Node.js
# to avoid conflicts with Windows Node.js installations

set -e  # Exit immediately if a command exits with a non-zero status

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Installing Claude Code with NVM-managed Node.js...${NC}"

# Verify NVM is installed and load it
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Verify Node.js installation
if ! command -v node &>/dev/null; then
    echo -e "${RED}Node.js is not available in the current shell session.${NC}"
    echo "Please make sure NVM is properly loaded."
    exit 1
fi

NODE_VERSION=$(node -v)
NPM_VERSION=$(npm -v)
echo -e "${GREEN}Using Node.js version: $NODE_VERSION${NC}"
echo -e "${GREEN}Using npm version: $NPM_VERSION${NC}"

# Create claude code directory
CLAUDE_DIR="$HOME/projects/claude/claude-code"
mkdir -p "$CLAUDE_DIR"

# Now install Claude Code using the NVM-managed Node.js
echo "Installing Claude Code CLI..."
npm install -g @anthropic-ai/claude-code --quiet

# Check if installation was successful
if ! command -v claude &>/dev/null; then
    echo -e "${RED}Claude Code installation failed.${NC}"
    echo "Trying alternative installation approach..."
    
    # Alternative installation approach
    echo "Trying alternative installation with npm..."
    npm install -g @anthropic-ai/claude-code --prefer-offline --no-audit --no-fund
    
    # Check again
    if ! command -v claude &>/dev/null; then
        echo -e "${RED}All installation attempts failed.${NC}"
        echo "Please check npm logs for more details."
        exit 1
    fi
fi

# Display Claude Code version
CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "Unknown")
echo -e "${GREEN}Claude Code installed successfully!${NC}"
echo "Claude Code version: $CLAUDE_VERSION"

# Create a wrapper script for Claude Code
echo "Creating Claude Code wrapper script..."
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

# Run Claude Code
claude "\$@"
EOL

# Make the wrapper script executable
chmod +x "$HOME/bin/claudecode"

# Add wrapper script to PATH if not already there
if ! grep -q "export PATH=\$HOME/bin:\$PATH" ~/.bashrc; then
    echo "Adding bin directory to PATH in .bashrc..."
    echo "# Add bin directory to PATH" >> ~/.bashrc
    echo "export PATH=\$HOME/bin:\$PATH" >> ~/.bashrc
fi

if [ -f ~/.zshrc ] && ! grep -q "export PATH=\$HOME/bin:\$PATH" ~/.zshrc; then
    echo "Adding bin directory to PATH in .zshrc..."
    echo "# Add bin directory to PATH" >> ~/.zshrc
    echo "export PATH=\$HOME/bin:\$PATH" >> ~/.zshrc
fi

# Create configuration directory and base config
echo "Setting up Claude Code configuration..."
mkdir -p ~/.claude/logs
CONFIG_FILE=~/.claude/config.json

cat > "$CONFIG_FILE" << EOJSON
{
  "model": "claude-3-opus-20240229",
  "temperature": 0.7,
  "maxTokens": 4096,
  "terminal": {
    "theme": "auto",
    "bell": true,
    "notifications": true
  },
  "logging": {
    "level": "info",
    "file": "~/.claude/logs/claude.log"
  },
  "aliases": {
    "tidy": "Format and clean up this code",
    "explain": "Explain what this code does",
    "test": "Write tests for this code",
    "doc": "Write documentation for this code"
  },
  "autoLoad": true,
  "openaiCompatibilityMode": false
}
EOJSON

echo -e "${GREEN}Configuration file created at $CONFIG_FILE${NC}"

# Create commands directory
mkdir -p ~/.claude/commands

# Create example commands
cat > ~/.claude/commands/analyze-repo.md << EOMD
# Analyze Repository

Analyze the current repository and provide insights:

1. Identify the main technologies used
2. Suggest code quality improvements
3. Identify potential security issues
4. Recommend testing strategies
EOMD

cat > ~/.claude/commands/create-api.md << EOMD
# Create API

Create a RESTful API with the following:

1. Define endpoints for: {0}
2. Implement proper error handling
3. Add input validation
4. Include authentication if needed
5. Write tests for each endpoint
EOMD

cat > ~/.claude/commands/optimize.md << EOMD
# Optimize Code

Analyze and optimize the provided code:

1. Identify performance bottlenecks
2. Reduce complexity
3. Improve readability
4. Suggest better algorithms or data structures
EOMD

echo -e "${GREEN}Custom commands created in ~/.claude/commands.${NC}"

# Create a sentinel file indicating this component has been configured
mkdir -p "$HOME/.claude"
touch "$HOME/.claude/.claude_setup_complete"

echo -e "${GREEN}Claude Code setup complete!${NC}"
CLAUDESCRIPT

# Make scripts executable
chmod +x "$TEMP_DIR/node-nvm-install.sh"
chmod +x "$TEMP_DIR/claude-setup.sh"

# Run the Node.js installation script
echo -e "${BLUE}Step 1: Installing Node.js via NVM...${NC}"
"$TEMP_DIR/node-nvm-install.sh"
if [ $? -ne 0 ]; then
    echo -e "${RED}Node.js installation failed. Aborting.${NC}"
    exit 1
fi

# Run the Claude Code installation script
echo -e "${BLUE}Step 2: Installing Claude Code...${NC}"
"$TEMP_DIR/claude-setup.sh"
if [ $? -ne 0 ]; then
    echo -e "${RED}Claude Code installation failed. Aborting.${NC}"
    exit 1
fi

# Clean up temp directory
echo "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

echo ""
echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}  Claude Code installation complete!              ${NC}"
echo -e "${GREEN}==================================================${NC}"
echo ""
echo -e "${YELLOW}IMPORTANT: To start using Claude Code:${NC}"
echo ""
echo "1. Start a new shell session or run:"
echo "   source ~/.bashrc"
echo ""
echo "2. Set your ANTHROPIC_API_KEY in your environment:"
echo "   export ANTHROPIC_API_KEY=your_api_key_here"
echo ""
echo "3. Run Claude Code with:"
echo "   claudecode"
echo ""
echo "For more information, see the documentation at:"
echo "https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/overview"
