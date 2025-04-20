#!/bin/bash
#
# Git and GitHub configuration script
# This script sets up Git and GitHub integration
# Updated to use JSON config files when available

set -e  # Exit immediately if a command exits with a non-zero status

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Setting up Git and GitHub configuration...${NC}"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Define config files
CONFIG_DIR="$REPO_ROOT/config"
ENV_FILE="$CONFIG_DIR/.env"
JSON_CONFIG="$CONFIG_DIR/03-git-config.json"

# Function to get value from JSON file
get_json_value() {
    local key=$1
    local default=$2
    local value=""
    
    # Check if jq is installed
    if command -v jq &> /dev/null; then
        # Use jq to extract value if file exists
        if [ -f "$JSON_CONFIG" ]; then
            value=$(jq -r ".$key // \"\"" "$JSON_CONFIG" 2>/dev/null)
        fi
    else
        # Fallback to grep if jq not available
        if [ -f "$JSON_CONFIG" ]; then
            value=$(grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$JSON_CONFIG" | sed 's/"'$key'"[[:space:]]*:[[:space:]]*"\(.*\)"/\1/' 2>/dev/null)
        fi
    fi
    
    # Return value or default
    if [ -z "$value" ] || [ "$value" = "null" ]; then
        echo "$default"
    else
        echo "$value"
    fi
}

# Load environment variables if available
if [ -f "$ENV_FILE" ]; then
    echo "Loading environment variables from $ENV_FILE..."
    source "$ENV_FILE"
fi

# Function to prompt for user input if not already set
prompt_if_empty() {
    local var_name=$1
    local prompt_text=$2
    local json_key=$3
    local var_value=${!var_name}
    
    # Try to get from JSON if empty
    if [ -z "$var_value" ]; then
        local json_value=$(get_json_value "$json_key" "")
        if [ ! -z "$json_value" ]; then
            eval "$var_name='$json_value'"
            echo "Using $var_name from config: $json_value"
            return
        fi
    fi
    
    # Prompt user if still empty
    if [ -z "$var_value" ]; then
        read -p "$prompt_text: " input
        eval "$var_name='$input'"
        
        # Update env file
        if [ -f "$ENV_FILE" ]; then
            if grep -q "^$var_name=" "$ENV_FILE"; then
                sed -i "s/^$var_name=.*/$var_name=$input/" "$ENV_FILE"
            else
                echo "$var_name=$input" >> "$ENV_FILE"
            fi
        fi
        
        # Update JSON file if it exists
        if [ -f "$JSON_CONFIG" ] && command -v jq &> /dev/null; then
            # Create a temporary file with the updated value
            jq ".$json_key = \"$input\"" "$JSON_CONFIG" > "$JSON_CONFIG.tmp"
            mv "$JSON_CONFIG.tmp" "$JSON_CONFIG"
        fi
    fi
}

# Create environment file if it doesn't exist
if [ ! -f "$ENV_FILE" ]; then
    echo "Creating environment file..."
    mkdir -p "$CONFIG_DIR"
    if [ -f "$CONFIG_DIR/template.env" ]; then
        cp "$CONFIG_DIR/template.env" "$ENV_FILE"
    else
        touch "$ENV_FILE"
    fi
}

# Create JSON config file if it doesn't exist
if [ ! -f "$JSON_CONFIG" ]; then
    echo "Creating JSON config file..."
    mkdir -p "$CONFIG_DIR"
    cat > "$JSON_CONFIG" << EOL
{
  "git_user_name": "",
  "git_user_email": "",
  "github_token": "",
  "generate_ssh_key": true,
  "ssh_key_type": "ed25519",
  "git_default_branch": "main",
  "git_editor": "nano",
  "setup_global_gitignore": true,
  "create_clone_helper": true
}
EOL
fi

# Prompt for GitHub information if not set
prompt_if_empty "GITHUB_USERNAME" "Enter your GitHub username" "git_user_name"
prompt_if_empty "GITHUB_EMAIL" "Enter your GitHub email" "git_user_email"

# Configure Git with user information
echo "Configuring Git user information..."
git config --global user.name "$GITHUB_USERNAME"
git config --global user.email "$GITHUB_EMAIL"

# Get Git configuration options from JSON
GIT_DEFAULT_BRANCH=$(get_json_value "git_default_branch" "main")
GIT_EDITOR=$(get_json_value "git_editor" "nano")

# Configure Git defaults
echo "Configuring Git defaults..."
git config --global init.defaultBranch "$GIT_DEFAULT_BRANCH"
git config --global core.editor "$GIT_EDITOR"
git config --global pull.rebase false
git config --global fetch.prune true

# Configure Git aliases
echo "Configuring Git aliases..."
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status
git config --global alias.unstage 'reset HEAD --'
git config --global alias.last 'log -1 HEAD'
git config --global alias.visual '!gitk'
git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

# Check if SSH key setup is enabled
GENERATE_SSH_KEY=$(get_json_value "generate_ssh_key" "true")
SSH_KEY_TYPE=$(get_json_value "ssh_key_type" "ed25519")

if [ "$GENERATE_SSH_KEY" = "true" ]; then
    # Set up SSH key for GitHub if it doesn't exist
    SSH_KEY_PATH="$HOME/.ssh/id_$SSH_KEY_TYPE"
    if [ ! -f "$SSH_KEY_PATH" ]; then
        echo "Setting up SSH key for GitHub..."
        
        # Create .ssh directory if it doesn't exist
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
        
        # Generate SSH key
        ssh-keygen -t "$SSH_KEY_TYPE" -C "$GITHUB_EMAIL" -f "$SSH_KEY_PATH" -N ""
        
        # Start ssh-agent and add the key
        eval "$(ssh-agent -s)"
        ssh-add "$SSH_KEY_PATH"
        
        # Display the public key for adding to GitHub
        echo -e "${YELLOW}Please add the following SSH key to your GitHub account:${NC}"
        echo -e "${YELLOW}https://github.com/settings/keys${NC}"
        echo ""
        cat "$SSH_KEY_PATH.pub"
        echo ""
        
        # Add GitHub to known hosts
        ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts
        
        echo -e "${YELLOW}After adding the key to GitHub, press any key to continue...${NC}"
        read -n 1 -s
    else
        echo -e "${GREEN}SSH key already exists at $SSH_KEY_PATH.${NC}"
    fi

    # Test GitHub SSH connection
    echo "Testing GitHub SSH connection..."
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        echo -e "${GREEN}GitHub SSH connection successful!${NC}"
    else
        echo -e "${YELLOW}GitHub SSH connection not verified.${NC}"
        echo "This may be because the key hasn't been added to GitHub yet."
        echo "Please add your SSH key to GitHub and try again."
        echo "You can view your public key with: cat $SSH_KEY_PATH.pub"
    fi
else
    echo "SSH key generation skipped (disabled in config)."
fi

# Set up Git credential helper for HTTPS
echo "Setting up Git credential helper..."
git config --global credential.helper cache
git config --global credential.helper 'cache --timeout=3600'

# Check if global gitignore setup is enabled
SETUP_GLOBAL_GITIGNORE=$(get_json_value "setup_global_gitignore" "true")

if [ "$SETUP_GLOBAL_GITIGNORE" = "true" ]; then
    # Create a global .gitignore file if it doesn't exist
    GLOBAL_GITIGNORE="$HOME/.gitignore_global"
    if [ ! -f "$GLOBAL_GITIGNORE" ]; then
        echo "Creating global .gitignore file..."
        cat > "$GLOBAL_GITIGNORE" << 'EOL'
# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Editor files
.vscode/
.idea/
*.swp
*.swo
*~

# Python files
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
*.egg-info/
.installed.cfg
*.egg

# Node.js files
node_modules/
npm-debug.log
yarn-error.log
yarn-debug.log
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Credentials
*.pem
*.key
EOL
        
        # Configure Git to use the global gitignore file
        git config --global core.excludesfile "$GLOBAL_GITIGNORE"
        echo -e "${GREEN}Global .gitignore created and configured.${NC}"
    else
        echo -e "${GREEN}Global .gitignore already exists at $GLOBAL_GITIGNORE.${NC}"
    fi
else
    echo "Global gitignore setup skipped (disabled in config)."
fi

# Check if clone helper setup is enabled
CREATE_CLONE_HELPER=$(get_json_value "create_clone_helper" "true")

if [ "$CREATE_CLONE_HELPER" = "true" ]; then
    # Create a script to clone repositories conveniently
    CLONE_SCRIPT="$HOME/bin/gh-clone"
    mkdir -p "$HOME/bin"
    if [ ! -f "$CLONE_SCRIPT" ]; then
        echo "Creating GitHub clone helper script..."
        cat > "$CLONE_SCRIPT" << 'EOL'
#!/bin/bash
#
# GitHub Clone Helper
# Clones a GitHub repository and sets up a working directory

# Check if a repository is provided
if [ -z "$1" ]; then
    echo "Usage: gh-clone <username>/<repository> [directory]"
    exit 1
fi

# Parse the repository information
REPO=$1
if [[ $REPO != *"/"* ]]; then
    echo "Repository must be in the format <username>/<repository>"
    exit 1
fi

# Extract username and repository name
USERNAME=$(echo $REPO | cut -d'/' -f1)
REPONAME=$(echo $REPO | cut -d'/' -f2)

# Determine the directory to clone into
if [ -z "$2" ]; then
    DIR="$HOME/projects/github/$REPONAME"
else
    DIR="$2"
fi

# Create the directory if it doesn't exist
mkdir -p "$(dirname "$DIR")"

# Clone the repository
echo "Cloning $USERNAME/$REPONAME into $DIR..."
git clone "git@github.com:$USERNAME/$REPONAME.git" "$DIR"

# Change to the directory
cd "$DIR"

# Display repository information
echo "Repository cloned successfully!"
echo "Repository: $USERNAME/$REPONAME"
echo "Directory: $DIR"
echo "Current branch: $(git rev-parse --abbrev-ref HEAD)"
echo "Latest commit: $(git log -1 --oneline)"
echo ""
echo "To begin working, run:"
echo "  cd $DIR"
EOL
        
        # Make the script executable
        chmod +x "$CLONE_SCRIPT"
        
        # Add bin directory to PATH if not already there
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
        
        echo -e "${GREEN}GitHub clone helper script created and configured.${NC}"
        echo "You can now use 'gh-clone username/repository' to clone repositories."
    else
        echo -e "${GREEN}GitHub clone helper script already exists at $CLONE_SCRIPT.${NC}"
    fi
else
    echo "Clone helper setup skipped (disabled in config)."
fi

# Create a template for .github folder with issue templates and workflows
CREATE_GITHUB_TEMPLATES=$(get_json_value "create_github_templates" "true")

if [ "$CREATE_GITHUB_TEMPLATES" = "true" ]; then
    echo "Creating GitHub templates in your projects directory..."
    GITHUB_TEMPLATES="$HOME/projects/github/templates"
    mkdir -p "$GITHUB_TEMPLATES/.github/ISSUE_TEMPLATE"
    mkdir -p "$GITHUB_TEMPLATES/.github/workflows"

    # Create issue templates
    cat > "$GITHUB_TEMPLATES/.github/ISSUE_TEMPLATE/bug_report.md" << 'EOL'
---
name: Bug report
about: Create a report to help us improve
title: '[BUG] '
labels: bug
assignees: ''

---

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Screenshots**
If applicable, add screenshots to help explain your problem.

**Environment:**
 - OS: [e.g. WSL Ubuntu 20.04]
 - Browser [e.g. chrome, safari]
 - Version [e.g. 22]

**Additional context**
Add any other context about the problem here.
EOL

    cat > "$GITHUB_TEMPLATES/.github/ISSUE_TEMPLATE/feature_request.md" << 'EOL'
---
name: Feature request
about: Suggest an idea for this project
title: '[FEATURE] '
labels: enhancement
assignees: ''

---

**Is your feature request related to a problem? Please describe.**
A clear and concise description of what the problem is. Ex. I'm always frustrated when [...]

**Describe the solution you'd like**
A clear and concise description of what you want to happen.

**Describe alternatives you've considered**
A clear and concise description of any alternative solutions or features you've considered.

**Additional context**
Add any other context or screenshots about the feature request here.
EOL

    # Create workflow template
    cat > "$GITHUB_TEMPLATES/.github/workflows/main.yml" << 'EOL'
name: CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.10'
        
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
        
    - name: Lint with flake8
      run: |
        pip install flake8
        # stop the build if there are Python syntax errors or undefined names
        flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics
        
    - name: Test with pytest
      run: |
        pip install pytest
        if [ -d tests ]; then pytest; fi
EOL

    # Create a README.md for the templates
    cat > "$GITHUB_TEMPLATES/README.md" << 'EOL'
# GitHub Templates

This directory contains templates for GitHub repositories, including:

- Issue templates
- Workflow templates

## Usage

To use these templates in a new repository:

1. Copy the `.github` directory to your repository
2. Customize the templates as needed
3. Commit and push the changes

## Issue Templates

- `bug_report.md`: Template for bug reports
- `feature_request.md`: Template for feature requests

## Workflow Templates

- `main.yml`: Basic CI workflow for Python projects
EOL

    echo -e "${GREEN}GitHub templates created in $GITHUB_TEMPLATES.${NC}"
    echo "You can copy these templates to your repositories as needed."
else
    echo "GitHub templates setup skipped (disabled in config)."
fi

echo -e "${GREEN}Git and GitHub configuration complete!${NC}"
exit 0
