#!/bin/bash
#
# Developer tools installation script
# This script installs and configures developer tools required for the environment

set -e  # Exit immediately if a command exits with a non-zero status

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Installing developer tools...${NC}"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Function to check if a package is installed
is_installed() {
    dpkg -l "$1" &> /dev/null
}

# Function to install a package if it's not already installed
install_if_needed() {
    local package=$1
    if ! is_installed "$package"; then
        echo "Installing $package..."
        sudo apt-get install -y "$package"
        echo -e "${GREEN}$package installed successfully.${NC}"
    else
        echo -e "${GREEN}$package is already installed.${NC}"
    fi
}

# Update package list
echo "Updating package list..."
sudo apt-get update

# Install Node.js and npm
echo "Setting up Node.js and npm..."
if ! command -v node &> /dev/null; then
    echo "Installing Node.js and npm..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
    echo -e "${GREEN}Node.js and npm installed successfully.${NC}"
    node -v
    npm -v
else
    echo -e "${GREEN}Node.js is already installed.${NC}"
    node -v
    npm -v
fi

# Install Python and pip
echo "Setting up Python and pip..."
install_if_needed "python3"
install_if_needed "python3-pip"
install_if_needed "python3-venv"

# Create Python aliases if they don't exist
if ! grep -q "alias python=" ~/.bashrc; then
    echo "Adding Python aliases to .bashrc..."
    echo "# Python aliases" >> ~/.bashrc
    echo "alias python=python3" >> ~/.bashrc
    echo "alias pip=pip3" >> ~/.bashrc
fi

if [ -f ~/.zshrc ] && ! grep -q "alias python=" ~/.zshrc; then
    echo "Adding Python aliases to .zshrc..."
    echo "# Python aliases" >> ~/.zshrc
    echo "alias python=python3" >> ~/.zshrc
    echo "alias pip=pip3" >> ~/.zshrc
fi

# Install jq for JSON processing
echo "Installing jq for JSON processing..."
install_if_needed "jq"

# Install text editors
echo "Installing text editors..."
install_if_needed "vim"
install_if_needed "nano"

# Install Visual Studio Code Server for WSL if not already installed
echo "Checking for Visual Studio Code Server..."
if ! command -v code &> /dev/null; then
    echo "Installing Visual Studio Code Server for WSL..."
    curl -fsSL https://code-server.dev/install.sh | sh
    echo -e "${GREEN}Visual Studio Code Server installed successfully.${NC}"
else
    echo -e "${GREEN}Visual Studio Code or Code Server is already installed.${NC}"
fi

# Install Python virtual environment tools
echo "Installing Python virtualenv tools..."
pip3 install --user virtualenv
pip3 install --user pipenv

# Set up Python path in .bashrc and .zshrc if not already there
if ! grep -q "export PATH=\$HOME/.local/bin:\$PATH" ~/.bashrc; then
    echo "Adding Python user bin to PATH in .bashrc..."
    echo "# Add Python user bin to PATH" >> ~/.bashrc
    echo "export PATH=\$HOME/.local/bin:\$PATH" >> ~/.bashrc
fi

if [ -f ~/.zshrc ] && ! grep -q "export PATH=\$HOME/.local/bin:\$PATH" ~/.zshrc; then
    echo "Adding Python user bin to PATH in .zshrc..."
    echo "# Add Python user bin to PATH" >> ~/.zshrc
    echo "export PATH=\$HOME/.local/bin:\$PATH" >> ~/.zshrc
fi

# Install httpie - a user-friendly curl alternative
echo "Installing httpie..."
install_if_needed "httpie"

# Install tldr for command examples
echo "Installing tldr..."
npm install -g tldr

# Install Docker if not already installed
echo "Checking for Docker..."
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    
    # Add user to the docker group
    sudo usermod -aG docker $USER
    
    echo -e "${GREEN}Docker installed successfully.${NC}"
    echo -e "${YELLOW}Note: You may need to log out and log back in to use Docker without sudo.${NC}"
else
    echo -e "${GREEN}Docker is already installed.${NC}"
fi

# Set up a Python virtual environment specifically for Claude Code
echo "Setting up Python virtual environment for Claude Code..."
mkdir -p ~/projects/claude/venv
cd ~/projects/claude
python3 -m venv venv/claude-code
source venv/claude-code/bin/activate
pip install wheel setuptools pip --upgrade
pip install anthropic httpx requests
deactivate

# Create a helper script to activate the Claude environment
cat > ~/projects/claude/activate-claude.sh << 'EOL'
#!/bin/bash
# Activate the Claude Code Python environment
source ~/projects/claude/venv/claude-code/bin/activate
echo -e "\033[0;34mClaude Code Python environment activated.\033[0m"
echo "Use 'deactivate' to exit the environment."
EOL
chmod +x ~/projects/claude/activate-claude.sh

# Add an alias for the helper script
if ! grep -q "alias claude-env=" ~/.bashrc; then
    echo "Adding Claude environment alias to .bashrc..."
    echo "# Claude environment alias" >> ~/.bashrc
    echo "alias claude-env='source ~/projects/claude/activate-claude.sh'" >> ~/.bashrc
fi

if [ -f ~/.zshrc ] && ! grep -q "alias claude-env=" ~/.zshrc; then
    echo "Adding Claude environment alias to .zshrc..."
    echo "# Claude environment alias" >> ~/.zshrc
    echo "alias claude-env='source ~/projects/claude/activate-claude.sh'" >> ~/.zshrc
fi

# Create a project template for Claude Code
echo "Creating project template for Claude Code..."
mkdir -p ~/projects/claude/template
cat > ~/projects/claude/template/README.md << 'EOL'
# Claude Code Project

This is a template project for working with Claude Code.

## Getting Started

1. Clone this template
2. Activate the Claude environment: `claude-env`
3. Start using Claude Code with your project

## Project Structure

- `src/` - Source code
- `docs/` - Documentation
- `tests/` - Test files
- `CLAUDE.md` - Claude Code configuration

## Claude Code Configuration

Claude Code will automatically scan this repository and create a CLAUDE.md file with information about the project structure and technologies used.
EOL

# Create template src, docs, and tests directories
mkdir -p ~/projects/claude/template/src
mkdir -p ~/projects/claude/template/docs
mkdir -p ~/projects/claude/template/tests

# Create a simple template source file
cat > ~/projects/claude/template/src/main.py << 'EOL'
def main():
    """
    Main entry point for the application.
    """
    print("Hello from Claude Code!")

if __name__ == "__main__":
    main()
EOL

echo -e "${GREEN}Developer tools installation complete!${NC}"
echo "You can now use the following commands:"
echo "  - node: Run Node.js"
echo "  - python: Run Python 3"
echo "  - pip: Install Python packages"
echo "  - claude-env: Activate the Claude Code Python environment"
echo ""
echo -e "${YELLOW}Note: Some changes may require restarting your terminal or WSL.${NC}"
exit 0