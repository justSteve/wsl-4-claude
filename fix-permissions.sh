#!/bin/bash
#
# Fix permissions for all scripts
# This script ensures all scripts in the repository have execution permissions

# Make scripts in /scripts directory executable
echo "Making scripts in /scripts directory executable..."
chmod +x scripts/*.sh

# Make housekeeping scripts in root directory executable
echo "Making housekeeping scripts in root directory executable..."
chmod +x *.sh

# Ensure our PATH fix script is executable
echo "Making PATH fix script executable..."
chmod +x fix-wsl-claude-path.sh

echo "All scripts are now executable."
echo "You can now run the setup with: ./run-claude-setup.sh"
