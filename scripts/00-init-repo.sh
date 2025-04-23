#!/bin/bash
# Repository initialization script for WSL-4-Claude

# Color codes for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting repository initialization...${NC}"

# Define project directory
PROJECT_DIR="$HOME/wsl-4-claude"

# Check if project directory exists
if [ ! -d "$PROJECT_DIR" ]; then
    echo "Creating project directory at $PROJECT_DIR"
    mkdir -p "$PROJECT_DIR"
fi

# Navigate to project directory
cd "$PROJECT_DIR"

# Initialize git repository if not already initialized
if [ ! -d ".git" ]; then
    echo "Initializing git repository..."
    git init
    
    # Create .gitignore file
    cat > .gitignore << EOL
# WSL-4-Claude .gitignore

# Ignore local configuration files
config/local-*.conf

# Ignore credentials
.credentials/

# Ignore logs
logs/

# Ignore temporary files
*.tmp
*~
.DS_Store
EOL
    
    # Initial commit
    git add .
    git commit -m "Initial repository setup"
    
    echo "Git repository initialized with initial commit"
else
    echo "Git repository already initialized"
fi

# Create basic README if it doesn't exist
if [ ! -f "README.md" ]; then
    echo "Creating README.md file..."
    cat > README.md << EOL
# WSL for Claude Code

A best known configuration for WSL environments optimized for Claude Code and GitHub integration.

## Overview

This repository contains scripts and configuration for setting up a standardized
WSL (Windows Subsystem for Linux) environment optimized for Claude Code.

## Features

- Automated setup process
- Secure credential management
- Integration with GitHub
- Development tools pre-configuration

## Getting Started

Run the setup script to configure your environment:

\`\`\`bash
./setup.sh
\`\`\`

See the documentation in the 'docs' directory for more information.
EOL
    
    # Commit README
    git add README.md
    git commit -m "Add README.md"
    
    echo "README.md created and committed"
fi

# Create directory structure if it doesn't exist
for dir in scripts config docs windows logs .credentials; do
    if [ ! -d "$dir" ]; then
        echo "Creating $dir directory..."
        mkdir -p "$dir"
    fi
done

echo -e "${GREEN}Repository initialization complete!${NC}"
echo "You can now proceed with installing and configuring WSL components."
