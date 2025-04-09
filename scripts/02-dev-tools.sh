#!/bin/bash

# 02-dev-tools.sh - Install development tools for WSL environment

echo "Starting Developer Tools Installation..."

# Update package lists
echo "Updating package lists..."
sudo apt update

# Install essential build tools
echo "Installing build essentials..."
sudo apt install -y build-essential

# Install Git if not already installed
if ! command -v git &> /dev/null; then
    echo "Installing Git..."
    sudo apt install -y git
else
    echo "Git is already installed."
fi

# Install text editors
echo "Installing text editors..."
sudo apt install -y vim nano

# Check for VS Code or Code Server
if command -v code &> /dev/null || command -v code-server &> /dev/null; then
    echo "Checking for Visual Studio Code Server..."
    echo "Visual Studio Code or Code Server is already installed."
else
    echo "Installing VS Code Server..."
    # You may want to update this with the specific installation method for Code Server
    # This is a placeholder
    echo "NOTE: VS Code Server installation skipped. Please install manually if needed."
fi

# Python environment setup - Using venv instead of direct pip
echo "Installing Python virtualenv tools..."

# Make sure python3-full and python3-venv are installed
sudo apt install -y python3-full python3-venv pipx

# Create a dedicated environment directory for Claude tools
CLAUDE_ENV_DIR="$HOME/.claude-env"

# Check if environment already exists
if [ ! -d "$CLAUDE_ENV_DIR" ]; then
    echo "Creating Python virtual environment for Claude tools..."
    python3 -m venv "$CLAUDE_ENV_DIR"
    
    # Activate the environment and install packages
    echo "Installing Python packages in virtual environment..."
    source "$CLAUDE_ENV_DIR/bin/activate"
    pip install --upgrade pip
    pip install virtualenv pipenv poetry jupyter pandas numpy matplotlib requests
    deactivate
    
    # Add environment activation to .bashrc if not already there
    if ! grep -q "claude-env" "$HOME/.bashrc"; then
        echo "Adding environment activation to .bashrc..."
        echo "" >> "$HOME/.bashrc"
        echo "# Activate Claude Python environment" >> "$HOME/.bashrc"
        echo "if [ -f \"$CLAUDE_ENV_DIR/bin/activate\" ]; then" >> "$HOME/.bashrc"
        echo "    source \"$CLAUDE_ENV_DIR/bin/activate\"" >> "$HOME/.bashrc"
        echo "fi" >> "$HOME/.bashrc"
    fi
else
    echo "Claude Python environment already exists at $CLAUDE_ENV_DIR"
fi

# Node.js installation (using nvm for better version management)
echo "Setting up Node.js environment..."

# Check if nvm is installed
if [ ! -d "$HOME/.nvm" ]; then
    echo "Installing nvm (Node Version Manager)..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
    
    # Load nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Install latest LTS version of Node.js
    echo "Installing Node.js LTS version..."
    nvm install --lts
else
    echo "nvm is already installed."
    # Load nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Check if Node.js is installed
    if ! command -v node &> /dev/null; then
        echo "Installing Node.js LTS version..."
        nvm install --lts
    else
        echo "Node.js is already installed: $(node --version)"
    fi
fi

# Install global npm packages
echo "Installing global npm packages..."
npm install -g typescript ts-node

# Docker check (not installing - requires manual setup)
if command -v docker &> /dev/null; then
    echo "Docker is already installed."
else
    echo "NOTE: Docker is not installed. If needed, please install manually following Docker's official documentation."
fi

echo "✅ Developer Tools Installation completed"
exit 0