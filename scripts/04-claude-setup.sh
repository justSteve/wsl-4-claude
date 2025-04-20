#!/bin/bash
#
# Claude Code installation and configuration script
# This script installs and configures Claude Code CLI
# Updated to use JSON config files when available

set -e  # Exit immediately if a command exits with a non-zero status

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Setting up Claude Code...${NC}"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Define config files
CONFIG_DIR="$REPO_ROOT/config"
JSON_CONFIG="$CONFIG_DIR/04-claude-setup.json"
ENV_FILE="$CONFIG_DIR/.env"

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

# Function to update a key-value pair in the JSON file
update_json_file() {
    local key=$1
    local value=$2
    local file=$3
    
    # Check if jq is installed
    if command -v jq &> /dev/null; then
        # Create a temporary file with the updated value
        jq ".$key = \"$value\"" "$file" > "$file.tmp"
        mv "$file.tmp" "$file"
    else
        # Fallback if jq not available (less reliable)
        if grep -q "\"$key\":" "$file"; then
            sed -i "s|\"$key\":[[:space:]]*\"[^\"]*\"|\"$key\": \"$value\"|" "$file"
        else
            # This is a simplistic approach and might break with complex JSON
            # Insert before the closing brace
            sed -i "s|}|,\n  \"$key\": \"$value\"\n}|" "$file"
        fi
    fi
}

# Create JSON config file if it doesn't exist
if [ ! -f "$JSON_CONFIG" ]; then
    echo "Creating JSON config file..."
    mkdir -p "$CONFIG_DIR"
    cat > "$JSON_CONFIG" << EOL
{
  "installation_method": "npm",
  "binary_url": "",
  "default_model": "claude-3-opus-20240229",
  "temperature": "0.7",
  "max_tokens": "4096",
  "log_level": "info",
  "setup_aliases": "true",
  "create_project_templates": "true"
}
EOL
    echo -e "${GREEN}Created JSON config file: $JSON_CONFIG${NC}"
fi

# Load environment variables if available
if [ -f "$ENV_FILE" ]; then
    echo "Loading environment variables from $ENV_FILE..."
    source "$ENV_FILE"
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo -e "${RED}npm is not installed. Please run the developer tools script first.${NC}"
    exit 1
fi

# Check if anthropic API key is set
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo -e "${YELLOW}ANTHROPIC_API_KEY is not set in the environment.${NC}"
    echo "You will need to set this variable before using Claude Code."
    echo "Please run the credential management scripts after completing this setup."
fi

# Get configuration from JSON
INSTALLATION_METHOD=$(get_json_value "installation_method" "npm")
BINARY_URL=$(get_json_value "binary_url" "")
DEFAULT_MODEL=$(get_json_value "default_model" "claude-3-opus-20240229")
TEMPERATURE=$(get_json_value "temperature" "0.7")
MAX_TOKENS=$(get_json_value "max_tokens" "4096")
LOG_LEVEL=$(get_json_value "log_level" "info")
SETUP_ALIASES=$(get_json_value "setup_aliases" "true")
CREATE_TEMPLATES=$(get_json_value "create_project_templates" "true")

# Create claude code directory
CLAUDE_DIR="$HOME/projects/claude/claude-code"
mkdir -p "$CLAUDE_DIR"

# Clone the Claude Code repository if it exists
if [ ! -d "$CLAUDE_DIR/repo" ]; then
    echo "Checking for the Claude Code repository..."
    if git ls-remote --exit-code https://github.com/anthropics/claude-code.git &> /dev/null; then
        echo "Cloning the Claude Code repository..."
        git clone https://github.com/anthropics/claude-code.git "$CLAUDE_DIR/repo"
    else
        echo -e "${YELLOW}Claude Code repository not found or not publicly available.${NC}"
        echo "Will use standalone installation approach instead."
        mkdir -p "$CLAUDE_DIR/repo"
    fi
fi

# Create Claude Code installation script
echo "Creating Claude Code installation script..."
cat > "$CLAUDE_DIR/install.sh" << EOL
#!/bin/bash
#
# Claude Code Installation Script
# This script installs Claude Code CLI

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "\${BLUE}Installing Claude Code CLI...\${NC}"

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo -e "\${RED}npm is not installed. Please install Node.js and npm first.\${NC}"
    exit 1
fi

# Determine the installation method
INSTALLATION_METHOD="$INSTALLATION_METHOD"
BINARY_URL="$BINARY_URL"

if [ "\$INSTALLATION_METHOD" = "local" ] && [ -f ./repo/package.json ]; then
    echo "Installing from local repository..."
    cd ./repo
    npm install
    npm link
    cd ..
elif [ "\$INSTALLATION_METHOD" = "binary" ] && [ ! -z "\$BINARY_URL" ]; then
    echo "Installing from binary URL: \$BINARY_URL..."
    curl -L "\$BINARY_URL" -o ./claude-code-cli
    chmod +x ./claude-code-cli
    mkdir -p "\$HOME/bin"
    mv ./claude-code-cli "\$HOME/bin/claude"
else
    echo "Installing from npm registry..."
    if npm list -g claude-cli &> /dev/null; then
        echo "Updating existing Claude Code installation..."
        npm update -g claude-cli
    else
        echo "Installing Claude Code..."
        npm install -g claude-cli
    fi
fi

# Check if installation was successful
if command -v claude &> /dev/null; then
    echo -e "\${GREEN}Claude Code installed successfully!\${NC}"
    echo "You can now use the 'claude' command to interact with Claude Code."
    
    # Display Claude Code version
    echo "Claude Code version:"
    claude --version
else
    echo -e "\${RED}Claude Code installation failed.\${NC}"
    echo "Please check the installation logs and try again."
    exit 1
fi

# Create configuration directory
mkdir -p ~/.claude

# Add completion for claude command if not already present
if [ -f ~/.zshrc ] && ! grep -q "claude completion" ~/.zshrc; then
    echo "Adding Claude Code completion to zsh..."
    echo '# Claude Code completion' >> ~/.zshrc
    echo 'if command -v claude &> /dev/null; then' >> ~/.zshrc
    echo '  eval "\$(claude completion zsh)"' >> ~/.zshrc
    echo 'fi' >> ~/.zshrc
fi

if ! grep -q "claude completion" ~/.bashrc; then
    echo "Adding Claude Code completion to bash..."
    echo '# Claude Code completion' >> ~/.bashrc
    echo 'if command -v claude &> /dev/null; then' >> ~/.bashrc
    echo '  eval "\$(claude completion bash)"' >> ~/.bashrc
    echo 'fi' >> ~/.bashrc
fi

# Display instructions for setting up API key
echo ""
echo -e "\${YELLOW}Next Steps:\${NC}"
echo "Make sure your ANTHROPIC_API_KEY environment variable is set."
echo "You may need to run the credential management scripts to set up this variable."
echo ""
echo "Once your API key is set, you can use Claude Code by navigating to your project directory and running:"
echo "  claude"
EOL

# Make the installation script executable
chmod +x "$CLAUDE_DIR/install.sh"

# Create Claude Code configuration script
echo "Creating Claude Code configuration script..."
cat > "$CLAUDE_DIR/configure.sh" << EOL
#!/bin/bash
#
# Claude Code Configuration Script
# This script configures Claude Code CLI settings

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "\${BLUE}Configuring Claude Code CLI...\${NC}"

# Check if Claude Code is installed
if ! command -v claude &> /dev/null; then
    echo -e "\${RED}Claude Code is not installed. Please run the installation script first.\${NC}"
    exit 1
fi

# Create Claude Code configuration directory
mkdir -p ~/.claude

# Create Claude Code configuration file
CONFIG_FILE=~/.claude/config.json

# Configuration values from setup
DEFAULT_MODEL="$DEFAULT_MODEL"
TEMPERATURE="$TEMPERATURE"
MAX_TOKENS="$MAX_TOKENS"
LOG_LEVEL="$LOG_LEVEL"

# Check if the configuration file already exists
if [ -f "\$CONFIG_FILE" ]; then
    echo -e "\${YELLOW}Configuration file already exists at \$CONFIG_FILE.\${NC}"
    echo "Would you like to overwrite it? (y/n)"
    read -r overwrite
    if [[ ! \$overwrite =~ ^[Yy]\$ ]]; then
        echo "Skipping configuration file creation."
    else
        # Create the configuration file
        cat > "\$CONFIG_FILE" << EOJSON
{
  "model": "\$DEFAULT_MODEL",
  "temperature": \$TEMPERATURE,
  "maxTokens": \$MAX_TOKENS,
  "terminal": {
    "theme": "auto",
    "bell": true,
    "notifications": true
  },
  "logging": {
    "level": "\$LOG_LEVEL",
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
        echo -e "\${GREEN}Configuration file created at \$CONFIG_FILE.\${NC}"
    fi
else
    # Create the configuration file
    cat > "\$CONFIG_FILE" << EOJSON
{
  "model": "\$DEFAULT_MODEL",
  "temperature": \$TEMPERATURE,
  "maxTokens": \$MAX_TOKENS,
  "terminal": {
    "theme": "auto",
    "bell": true,
    "notifications": true
  },
  "logging": {
    "level": "\$LOG_LEVEL",
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
    echo -e "\${GREEN}Configuration file created at \$CONFIG_FILE.\${NC}"
fi

# Create logs directory
mkdir -p ~/.claude/logs

# Display configured settings
echo ""
echo -e "\${YELLOW}Claude Code Settings:\${NC}"
echo "  - Model: \$DEFAULT_MODEL"
echo "  - Temperature: \$TEMPERATURE"
echo "  - Max Tokens: \$MAX_TOKENS" 
echo "  - Theme: auto (follows terminal theme)"
echo "  - Log level: \$LOG_LEVEL"
echo "  - Log file: ~/.claude/logs/claude.log"
echo ""
echo "You can modify these settings by editing the configuration file at \$CONFIG_FILE."
echo "Or you can update settings in the config JSON file at $JSON_CONFIG and rerun setup."
echo "Configuration changes will take effect the next time you start Claude Code."

# Add custom commands
SETUP_ALIASES="$SETUP_ALIASES"
if [[ \$SETUP_ALIASES =~ ^(true|yes|y|1)\$ ]]; then
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

    echo -e "\${GREEN}Custom commands created in ~/.claude/commands.\${NC}"
    echo "You can use these commands by typing:"
    echo "  /analyze-repo"
    echo "  /create-api <endpoints>"
    echo "  /optimize"
    echo "in Claude Code."
else
    echo "Skipping custom command creation (disabled in config)."
fi

echo -e "\${GREEN}Claude Code configuration complete!\${NC}"
echo "You can now use Claude Code with your preferred settings."
EOL

# Make the configuration script executable
chmod +x "$CLAUDE_DIR/configure.sh"

# Create a wrapper script for Claude Code
echo "Creating Claude Code wrapper script..."
mkdir -p "$HOME/bin"
cat > "$HOME/bin/claudecode" << EOL
#!/bin/bash
#
# Claude Code Wrapper Script
# This script runs Claude Code with the appropriate environment variables

# Check if API key is set
if [ -z "\$ANTHROPIC_API_KEY" ]; then
    echo "ANTHROPIC_API_KEY is not set. Please run the credential management scripts first."
    exit 1
fi

# Get environment type
ENV_TYPE=\${ENV_TYPE:-development}
echo "Running Claude Code in \$ENV_TYPE environment..."

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

# Run the installation script
echo "Running Claude Code installation script..."
cd "$CLAUDE_DIR"
./install.sh

# Check if installation was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Claude Code installation successful!${NC}"
    # Update JSON config with non-interactive
    echo "Running configuration script..."
    ./configure.sh
else
    echo -e "${RED}Claude Code installation failed.${NC}"
    echo "Please check the installation logs and try again."
    exit 1
fi

# Create project templates if enabled
CREATE_TEMPLATES="$CREATE_TEMPLATES"
if [[ $CREATE_TEMPLATES =~ ^(true|yes|y|1)$ ]]; then
    echo "Creating additional files for Claude Code projects..."

    # Create template directory
    mkdir -p "$HOME/projects/claude/template"
    
    # Create a template .claude.yml file
    cat > "$CLAUDE_DIR/template.claude.yml" << 'EOL'
# Claude Code Project Configuration
version: 1.0

# Project information
project:
  name: "My Claude Project"
  description: "A project using Claude Code"

# Configuration for Claude Code
claude:
  # File patterns to include in context
  include:
    - "**/*.js"
    - "**/*.ts"
    - "**/*.py"
    - "**/*.md"
  
  # File patterns to exclude from context
  exclude:
    - "node_modules/**"
    - "dist/**"
    - "build/**"
    - ".git/**"
  
  # Maximum number of files to include in context
  maxFiles: 100
  
  # Maximum file size to include (in bytes)
  maxFileSize: 1000000

# GitHub integration settings
github:
  enabled: true
  repositories:
    - owner: "your-username"
      name: "your-repository"
EOL

    # Copy the template to a convenient location
    cp "$CLAUDE_DIR/template.claude.yml" "$HOME/projects/claude/template/.claude.yml"
    
    echo -e "${GREEN}Project templates created in $HOME/projects/claude/template${NC}"
else
    echo "Skipping project template creation (disabled in config)."
fi

echo -e "${GREEN}Claude Code setup complete!${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Run the credential management scripts to set up your API key:"
echo "   - For Windows: ./scripts/05-win-credentials.ps1"
echo "   - For Linux/WSL: ./scripts/06-lx-credentials.sh"
echo ""
echo "2. Once your API key is set, you can use Claude Code by navigating to your project directory and running:"
echo "   claudecode"
echo ""
echo "3. If you want to create a new Claude Code project, you can use the template at:"
echo "   ~/projects/claude/template"
echo ""
echo "4. For more information, see the Claude Code documentation at:"
echo "   https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/overview"
exit 0
