#!/bin/bash
#
# WSL4CLAUDE - Quick Path Fix for Claude Code
# ===========================================================
#
# This script fixes the PATH issue with Claude Code in WSL

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}==================================================${NC}"
echo -e "${BLUE}  Fixing Claude Code PATH Issues - Quick Fix      ${NC}"
echo -e "${BLUE}==================================================${NC}"
echo ""

# Check where claude is actually installed
POTENTIAL_PATHS=(
  "$HOME/.npm-global/bin"
  "$HOME/.nvm/versions/node/*/bin"
  "/usr/local/bin"
  "/usr/bin"
  "$HOME/.local/bin"
  "$(npm config get prefix)/bin"
)

CLAUDE_PATH=""
for path in "${POTENTIAL_PATHS[@]}"; do
  # Handle glob expansion
  if [[ $path == *"*"* ]]; then
    for expanded_path in $path; do
      if [ -f "$expanded_path/claude" ]; then
        CLAUDE_PATH="$expanded_path/claude"
        echo -e "${GREEN}Found Claude at: $CLAUDE_PATH${NC}"
        break 2
      fi
    done
  elif [ -f "$path/claude" ]; then
    CLAUDE_PATH="$path/claude"
    echo -e "${GREEN}Found Claude at: $CLAUDE_PATH${NC}"
    break
  fi
done

if [ -z "$CLAUDE_PATH" ]; then
  echo -e "${RED}Could not find Claude executable.${NC}"
  echo "Let's check if it's installed as an npm package..."
  
  if npm list -g | grep -q claude; then
    echo -e "${GREEN}Claude is installed as an npm package.${NC}"
    NPM_PREFIX=$(npm config get prefix)
    CLAUDE_PATH="$NPM_PREFIX/bin/claude"
    echo -e "${GREEN}Expected Claude path: $CLAUDE_PATH${NC}"
  else
    echo -e "${RED}Claude is not installed as an npm package.${NC}"
    echo "Would you like to install it now? (y/n)"
    read -r install_claude
    if [[ $install_claude =~ ^[Yy]$ ]]; then
      echo "Installing Claude Code..."
      npm install -g @anthropic-ai/claude-code
      
      if npm list -g | grep -q claude; then
        echo -e "${GREEN}Claude Code installed successfully!${NC}"
        NPM_PREFIX=$(npm config get prefix)
        CLAUDE_PATH="$NPM_PREFIX/bin/claude"
      else
        echo -e "${RED}Installation failed.${NC}"
        exit 1
      fi
    else
      echo "Exiting without installing Claude."
      exit 1
    fi
  fi
fi

# Get the directory containing claude
CLAUDE_DIR=$(dirname "$CLAUDE_PATH")

# Check if the directory is already in PATH
if [[ ":$PATH:" == *":$CLAUDE_DIR:"* ]]; then
  echo -e "${YELLOW}$CLAUDE_DIR is already in your PATH.${NC}"
  echo "Something else might be wrong. Let's create symbolic links."
  
  # Create symbolic links in /usr/local/bin
  echo "Creating symbolic link in /usr/local/bin..."
  sudo ln -sf "$CLAUDE_PATH" /usr/local/bin/claude
  
  echo -e "${GREEN}Created symbolic link: /usr/local/bin/claude -> $CLAUDE_PATH${NC}"
else
  echo -e "${RED}$CLAUDE_DIR is not in your PATH.${NC}"
  echo "Adding it to your PATH..."
  
  # Add to both .bashrc and .profile to ensure it's loaded
  if ! grep -q "export PATH=\"$CLAUDE_DIR:\$PATH\"" ~/.bashrc; then
    echo "# Add Claude Code directory to PATH" >> ~/.bashrc
    echo "export PATH=\"$CLAUDE_DIR:\$PATH\"" >> ~/.bashrc
    echo -e "${GREEN}Added to ~/.bashrc${NC}"
  fi
  
  if ! grep -q "export PATH=\"$CLAUDE_DIR:\$PATH\"" ~/.profile; then
    echo "# Add Claude Code directory to PATH" >> ~/.profile
    echo "export PATH=\"$CLAUDE_DIR:\$PATH\"" >> ~/.profile
    echo -e "${GREEN}Added to ~/.profile${NC}"
  fi
  
  # Also create symbolic links for immediate use
  echo "Creating symbolic link in /usr/local/bin..."
  sudo ln -sf "$CLAUDE_PATH" /usr/local/bin/claude
  
  echo -e "${GREEN}Created symbolic link: /usr/local/bin/claude -> $CLAUDE_PATH${NC}"
  
  # Update PATH for current session
  export PATH="$CLAUDE_DIR:$PATH"
  echo -e "${GREEN}PATH updated for current session.${NC}"
fi

# Create an alias file for both bash and zsh
ALIAS_FILE="$HOME/.claude_aliases"
cat > "$ALIAS_FILE" << EOL
# Claude Code aliases
alias claudecode="claude"
alias cc="claude"
# Export the Claude path for easy reference
export CLAUDE_EXECUTABLE="$CLAUDE_PATH"
EOL

# Source the alias file from .bashrc and .zshrc if they exist
if ! grep -q "source $ALIAS_FILE" ~/.bashrc; then
  echo "# Source Claude Code aliases" >> ~/.bashrc
  echo "if [ -f \"$ALIAS_FILE\" ]; then" >> ~/.bashrc
  echo "  source \"$ALIAS_FILE\"" >> ~/.bashrc
  echo "fi" >> ~/.bashrc
  echo -e "${GREEN}Added alias sourcing to ~/.bashrc${NC}"
fi

if [ -f ~/.zshrc ] && ! grep -q "source $ALIAS_FILE" ~/.zshrc; then
  echo "# Source Claude Code aliases" >> ~/.zshrc
  echo "if [ -f \"$ALIAS_FILE\" ]; then" >> ~/.zshrc
  echo "  source \"$ALIAS_FILE\"" >> ~/.zshrc
  echo "fi" >> ~/.zshrc
  echo -e "${GREEN}Added alias sourcing to ~/.zshrc${NC}"
fi

# Verify that claude is now accessible
echo "Verifying Claude installation..."
if [ -f "/usr/local/bin/claude" ]; then
  echo -e "${GREEN}Claude is now accessible via /usr/local/bin/claude${NC}"
else
  echo -e "${RED}Failed to create symbolic link in /usr/local/bin${NC}"
fi

echo -e "${BLUE}==================================================${NC}"
echo -e "${GREEN}Fix completed! Please take these steps:${NC}"
echo ""
echo "1. Close and reopen your WSL terminal"
echo "2. Try running 'claude' again"
echo ""
echo "If that doesn't work, try running:"
echo "   source ~/.bashrc"
echo "   claude"
echo ""
echo "If you still have issues, you can always run Claude using the full path:"
echo "   $CLAUDE_PATH"
echo "${BLUE}==================================================${NC}"
