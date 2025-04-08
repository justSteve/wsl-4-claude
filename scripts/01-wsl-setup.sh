#!/bin/bash
#
# WSL base configuration script
# This script configures the WSL environment with basic settings

set -e  # Exit immediately if a command exits with a non-zero status

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Setting up WSL base configuration...${NC}"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Check if running in WSL
if grep -q Microsoft /proc/version || grep -q microsoft /proc/version; then
    echo -e "${GREEN}Running in WSL environment. Proceeding with WSL setup...${NC}"
else
    echo -e "${YELLOW}Not running in WSL. Skipping WSL-specific configuration.${NC}"
    echo "If you are setting up a new WSL instance, please run the Windows setup script first."
    echo "This script should be run from within WSL after installation."
    exit 0
fi

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

# Install essential packages
echo "Installing essential packages..."
ESSENTIAL_PACKAGES="build-essential curl wget git unzip zip tar libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev"

for package in $ESSENTIAL_PACKAGES; do
    install_if_needed "$package"
done

# Configure locale
echo "Configuring locale..."
sudo apt-get install -y locales
sudo locale-gen en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Add locale to .bashrc if not already there
if ! grep -q "LC_ALL=en_US.UTF-8" ~/.bashrc; then
    echo "Adding locale settings to .bashrc..."
    echo "export LANG=en_US.UTF-8" >> ~/.bashrc
    echo "export LC_ALL=en_US.UTF-8" >> ~/.bashrc
fi

# Set up time synchronization with Windows
echo "Setting up time synchronization..."
if ! grep -q "hwclock" ~/.bashrc; then
    echo "# Sync time with Windows" >> ~/.bashrc
    echo "if [ -f /proc/sys/fs/binfmt_misc/WSLInterop ]; then" >> ~/.bashrc
    echo "    sudo hwclock -s" >> ~/.bashrc
    echo "fi" >> ~/.bashrc
fi

# Configure .wslconfig in Windows home if it doesn't exist
WIN_HOME=$(wslpath "$(wslvar USERPROFILE)")
WSLCONFIG_PATH="$WIN_HOME/.wslconfig"

if [ ! -f "$WSLCONFIG_PATH" ]; then
    echo "Creating .wslconfig in Windows home directory..."
    cat > "$WSLCONFIG_PATH" << 'EOL'
[wsl2]
memory=8GB
processors=4
localhostForwarding=true
EOL
    echo -e "${GREEN}.wslconfig created in Windows home directory.${NC}"
    echo -e "${YELLOW}Note: You may need to restart WSL for these settings to take effect.${NC}"
else
    echo -e "${YELLOW}.wslconfig already exists in Windows home directory. Skipping creation.${NC}"
fi

# Set up shell improvements
echo "Setting up shell improvements..."

# Install zsh if not already installed
install_if_needed "zsh"

# Install Oh My Zsh if not already installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo -e "${GREEN}Oh My Zsh installed successfully.${NC}"
else
    echo -e "${GREEN}Oh My Zsh is already installed.${NC}"
fi

# Add some useful aliases to .zshrc if they don't already exist
if [ -f "$HOME/.zshrc" ]; then
    if ! grep -q "# Claude WSL Environment aliases" "$HOME/.zshrc"; then
        echo "Adding useful aliases to .zshrc..."
        cat >> "$HOME/.zshrc" << 'EOL'

# Claude WSL Environment aliases
alias update='sudo apt update && sudo apt upgrade -y'
alias install='sudo apt install -y'
alias cls='clear'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'

# GitHub shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'
EOL
    fi
fi

# Add similar aliases to .bashrc if they don't already exist
if ! grep -q "# Claude WSL Environment aliases" "$HOME/.bashrc"; then
    echo "Adding useful aliases to .bashrc..."
    cat >> "$HOME/.bashrc" << 'EOL'

# Claude WSL Environment aliases
alias update='sudo apt update && sudo apt upgrade -y'
alias install='sudo apt install -y'
alias cls='clear'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'

# GitHub shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'
EOL
fi

# Create a projects directory structure
echo "Creating projects directory structure..."
mkdir -p "$HOME/projects/github"
mkdir -p "$HOME/projects/claude"

# Create an automatic message when opening terminal
if [ ! -f "$HOME/.welcome_message.sh" ]; then
    echo "Creating welcome message script..."
    cat > "$HOME/.welcome_message.sh" << 'EOL'
#!/bin/bash

# Welcome message for Claude WSL Environment
echo -e "\033[0;34m======================================\033[0m"
echo -e "\033[0;34m   Welcome to Claude WSL Environment  \033[0m"
echo -e "\033[0;34m======================================\033[0m"
echo ""
echo -e "\033[0;33mSystem Information:\033[0m"
echo -e "  - Hostname: $(hostname)"
echo -e "  - WSL Distribution: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')"
echo -e "  - Kernel: $(uname -r)"
echo ""
echo -e "\033[0;33mUseful Commands:\033[0m"
echo -e "  - claude: Start Claude Code CLI"
echo -e "  - update: Update system packages"
echo -e "  - gs: Git status"
echo ""
echo -e "\033[0;33mProject Directories:\033[0m"
echo -e "  - ~/projects/github: GitHub repositories"
echo -e "  - ~/projects/claude: Claude projects"
echo ""
echo -e "\033[0;34m======================================\033[0m"
EOL
    chmod +x "$HOME/.welcome_message.sh"

    # Add welcome message to .bashrc if not already there
    if ! grep -q "welcome_message.sh" "$HOME/.bashrc"; then
        echo "Adding welcome message to .bashrc..."
        echo "" >> "$HOME/.bashrc"
        echo "# Show welcome message" >> "$HOME/.bashrc"
        echo "if [ -f ~/.welcome_message.sh ]; then" >> "$HOME/.bashrc"
        echo "    ~/.welcome_message.sh" >> "$HOME/.bashrc"
        echo "fi" >> "$HOME/.bashrc"
    fi

    # Add welcome message to .zshrc if it exists and doesn't already have it
    if [ -f "$HOME/.zshrc" ] && ! grep -q "welcome_message.sh" "$HOME/.zshrc"; then
        echo "Adding welcome message to .zshrc..."
        echo "" >> "$HOME/.zshrc"
        echo "# Show welcome message" >> "$HOME/.zshrc"
        echo "if [ -f ~/.welcome_message.sh ]; then" >> "$HOME/.zshrc"
        echo "    ~/.welcome_message.sh" >> "$HOME/.zshrc"
        echo "fi" >> "$HOME/.zshrc"
    fi
fi

# Create a backup of the original .bashrc and .zshrc files if they don't exist
if [ ! -f "$HOME/.bashrc.orig" ]; then
    echo "Creating backup of .bashrc..."
    cp "$HOME/.bashrc" "$HOME/.bashrc.orig"
fi

if [ -f "$HOME/.zshrc" ] && [ ! -f "$HOME/.zshrc.orig" ]; then
    echo "Creating backup of .zshrc..."
    cp "$HOME/.zshrc" "$HOME/.zshrc.orig"
fi

echo -e "${GREEN}WSL base configuration complete!${NC}"
echo -e "${YELLOW}Note: Some changes may require restarting your terminal or WSL.${NC}"
exit 0