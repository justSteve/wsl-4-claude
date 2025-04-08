#!/bin/bash
#
# Environment validation script
# This script validates the Claude WSL Environment setup

set -e  # Exit immediately if a command exits with a non-zero status

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Validating Claude WSL Environment...${NC}"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Display validation header
echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}       Claude WSL Environment Validation      ${NC}"
echo -e "${BLUE}===============================================${NC}"
echo ""

# Validation status
VALIDATION_OK=true

# Function to check if a command is available
check_command() {
    local cmd=$1
    local name=$2
    
    echo -n "Checking for $name... "
    if command -v $cmd &> /dev/null; then
        echo -e "${GREEN}✅ Found${NC}"
        return 0
    else
        echo -e "${RED}❌ Not found${NC}"
        VALIDATION_OK=false
        return 1
    fi
}

# Function to check if a file exists
check_file() {
    local file=$1
    local name=$2
    
    echo -n "Checking for $name... "
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ Found${NC}"
        return 0
    else
        echo -e "${RED}❌ Not found${NC}"
        VALIDATION_OK=false
        return 1
    fi
}

# Function to check if a directory exists
check_directory() {
    local dir=$1
    local name=$2
    
    echo -n "Checking for $name... "
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✅ Found${NC}"
        return 0
    else
        echo -e "${RED}❌ Not found${NC}"
        VALIDATION_OK=false
        return 1
    fi
}

# Check if running in WSL
echo -n "Checking if running in WSL... "
if grep -q Microsoft /proc/version || grep -q microsoft /proc/version; then
    echo -e "${GREEN}✅ Yes${NC}"
else
    echo -e "${YELLOW}⚠️ No${NC}"
    echo "This environment is not running in WSL. Some features may not work correctly."
fi

# Check for required commands
echo -e "\n${BLUE}Checking for required commands...${NC}"
check_command "git" "Git"
check_command "node" "Node.js"
check_command "npm" "npm"
check_command "python3" "Python 3"
check_command "pip3" "pip3"
check_command "zsh" "Zsh"
check_command "curl" "curl"
check_command "ssh" "SSH"

# Check for optional commands
echo -e "\n${BLUE}Checking for optional commands...${NC}"
check_command "claude" "Claude Code CLI" || echo "Claude Code CLI is not installed. You can install it by running the Claude setup script."
check_command "docker" "Docker" || echo "Docker is not installed. You can install it by running the developer tools script."
check_command "code" "VS Code Server" || echo "VS Code Server is not installed. You can install it by running the developer tools script."
check_command "gpg" "GPG" || echo "GPG is not installed. You can install it with: sudo apt-get install gpg"
check_command "pass" "pass" || echo "pass is not installed. You can install it with: sudo apt-get install pass"

# Check for required directories
echo -e "\n${BLUE}Checking for required directories...${NC}"
check_directory "$HOME/projects" "Projects directory"
check_directory "$HOME/projects/github" "GitHub projects directory"
check_directory "$HOME/projects/claude" "Claude projects directory"
check_directory "$HOME/bin" "bin directory"

# Check for credential files
echo -e "\n${BLUE}Checking for credential files...${NC}"
CREDS_DIR="$HOME/.claude-creds"
if check_directory "$CREDS_DIR" "Credentials directory"; then
    # Check if any credential files exist
    if [ -n "$(find "$CREDS_DIR" -name "*.env" -o -name "*.env.gpg" 2>/dev/null)" ]; then
        echo -e "${GREEN}✅ Credential files found${NC}"
    else
        echo -e "${YELLOW}⚠️ No credential files found${NC}"
        echo "Please run the credential management scripts to set up your credentials."
    fi
fi

# Check for shell configuration
echo -e "\n${BLUE}Checking shell configuration...${NC}"
if [ -f "$HOME/.zshrc" ] && [ "$SHELL" = *"zsh"* ]; then
    SHELL_CONFIG="$HOME/.zshrc"
    echo -e "${GREEN}✅ Using Zsh configuration${NC}"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
    echo -e "${GREEN}✅ Using Bash configuration${NC}"
else
    echo -e "${RED}❌ No supported shell configuration found${NC}"
    VALIDATION_OK=false
fi

if [ -n "$SHELL_CONFIG" ]; then
    # Check if Claude environment settings are in shell config
    echo -n "Checking for Claude environment in shell config... "
    if grep -q "Claude WSL Environment" "$SHELL_CONFIG"; then
        echo -e "${GREEN}✅ Found${NC}"
    else
        echo -e "${YELLOW}⚠️ Not found${NC}"
        echo "Please run the credential management scripts to set up your shell configuration."
    fi
fi

# Check for SSH keys
echo -e "\n${BLUE}Checking SSH keys...${NC}"
if [ -f "$HOME/.ssh/id_ed25519" ] || [ -f "$HOME/.ssh/id_rsa" ]; then
    echo -e "${GREEN}✅ SSH keys found${NC}"
    
    # Check if SSH keys are added to SSH agent
    echo -n "Checking if SSH keys are added to SSH agent... "
    if ssh-add -l &> /dev/null; then
        echo -e "${GREEN}✅ SSH keys added to agent${NC}"
    else
        echo -e "${YELLOW}⚠️ SSH keys not added to agent${NC}"
        echo "You can add your SSH keys to the agent with: ssh-add ~/.ssh/id_ed25519"
    fi
    
    # Check GitHub SSH connection
    echo -n "Testing GitHub SSH connection... "
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        echo -e "${GREEN}✅ GitHub SSH connection successful${NC}"
    else
        echo -e "${YELLOW}⚠️ GitHub SSH connection not verified${NC}"
        echo "Please add your SSH key to GitHub and try again."
    fi
else
    echo -e "${YELLOW}⚠️ No SSH keys found${NC}"
    echo "Please run the Git configuration script to set up your SSH keys."
fi

# Check for Claude Code configuration
echo -e "\n${BLUE}Checking Claude Code configuration...${NC}"
if [ -f "$HOME/.claude/config.json" ]; then
    echo -e "${GREEN}✅ Claude Code configuration found${NC}"
else
    echo -e "${YELLOW}⚠️ Claude Code configuration not found${NC}"
    echo "Please run the Claude setup script and configuration process."
fi

# Check for environment variables
echo -e "\n${BLUE}Checking environment variables...${NC}"
ENV_VARS_OK=true

check_env_var() {
    local var_name=$1
    local var_value=${!var_name}
    
    echo -n "Checking $var_name... "
    if [ -n "$var_value" ]; then
        echo -e "${GREEN}✅ Set${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️ Not set${NC}"
        ENV_VARS_OK=false
        return 1
    fi
}

check_env_var "ANTHROPIC_API_KEY"
check_env_var "GITHUB_USERNAME"
check_env_var "GITHUB_EMAIL"
check_env_var "WSL_DISTRO_NAME"
check_env_var "ENV_TYPE"

if [ "$ENV_VARS_OK" != "true" ]; then
    echo -e "${YELLOW}Some environment variables are not set.${NC}"
    echo "Please run the credential management scripts to set up your environment variables."
    echo "You may need to restart your shell or run: source ~/.claude-activate.sh"
fi

# Check template project
echo -e "\n${BLUE}Checking template project...${NC}"
if [ -d "$HOME/projects/claude/template" ]; then
    echo -e "${GREEN}✅ Template project found${NC}"
else
    echo -e "${YELLOW}⚠️ Template project not found${NC}"
    echo "Please run the developer tools script to set up the template project."
fi

# Display summary
echo -e "\n${BLUE}===============================================${NC}"
echo -e "${BLUE}               Validation Summary             ${NC}"
echo -e "${BLUE}===============================================${NC}"
echo ""

if [ "$VALIDATION_OK" = "true" ]; then
    echo -e "${GREEN}✅ Validation completed successfully!${NC}"
    echo "Your Claude WSL Environment is properly set up."
else
    echo -e "${YELLOW}⚠️ Validation completed with warnings or errors.${NC}"
    echo "Please address the issues mentioned above to ensure proper functionality."
    echo "You may need to re-run some of the setup scripts."
fi

# Create validation report
REPORT_FILE="$REPO_ROOT/validation-report.md"
echo "# Claude WSL Environment Validation Report" > "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "**Date:** $(date)" >> "$REPORT_FILE"
echo "**WSL Distribution:** $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')" >> "$REPORT_FILE"
echo "**Kernel:** $(uname -r)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "## System Information" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "- **Node.js:** $(node -v 2>/dev/null || echo 'Not installed')" >> "$REPORT_FILE"
echo "- **npm:** $(npm -v 2>/dev/null || echo 'Not installed')" >> "$REPORT_FILE"
echo "- **Python:** $(python3 --version 2>/dev/null || echo 'Not installed')" >> "$REPORT_FILE"
echo "- **Git:** $(git --version 2>/dev/null || echo 'Not installed')" >> "$REPORT_FILE"
echo "- **Shell:** $(echo $SHELL)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "## Claude Code Status" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
if command -v claude &> /dev/null; then
    echo "- **Claude Code:** Installed" >> "$REPORT_FILE"
    echo "- **Version:** $(claude --version 2>/dev/null || echo 'Unknown')" >> "$REPORT_FILE"
else
    echo "- **Claude Code:** Not installed" >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

echo "## Environment Variables" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "- **ANTHROPIC_API_KEY:** $(if [ -n "$ANTHROPIC_API_KEY" ]; then echo "Set"; else echo "Not set"; fi)" >> "$REPORT_FILE"
echo "- **GITHUB_USERNAME:** $(if [ -n "$GITHUB_USERNAME" ]; then echo "Set ($GITHUB_USERNAME)"; else echo "Not set"; fi)" >> "$REPORT_FILE"
echo "- **GITHUB_EMAIL:** $(if [ -n "$GITHUB_EMAIL" ]; then echo "Set ($GITHUB_EMAIL)"; else echo "Not set"; fi)" >> "$REPORT_FILE"
echo "- **WSL_DISTRO_NAME:** $(if [ -n "$WSL_DISTRO_NAME" ]; then echo "Set ($WSL_DISTRO_NAME)"; else echo "Not set"; fi)" >> "$REPORT_FILE"
echo "- **ENV_TYPE:** $(if [ -n "$ENV_TYPE" ]; then echo "Set ($ENV_TYPE)"; else echo "Not set"; fi)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "## Validation Result" >> "$REPORT_FILE"
if [ "$VALIDATION_OK" = "true" ]; then
    echo "**Status:** ✅ Validation successful" >> "$REPORT_FILE"
else
    echo "**Status:** ⚠️ Validation completed with warnings or errors" >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

echo -e "${GREEN}Validation report created: $REPORT_FILE${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. If there are any issues, address them using the appropriate setup scripts."
echo "2. Run this validation script again to ensure all issues are resolved."
echo "3. Once validation is successful, you can start using Claude Code in your projects."
echo ""
echo "To start a new project with Claude Code:"
echo "1. Copy the template project: cp -r ~/projects/claude/template ~/projects/claude/my-project"
echo "2. Navigate to the project: cd ~/projects/claude/my-project"
echo "3. Initialize Git: git init"
echo "4. Start using Claude Code: claudecode"
echo ""
exit 0