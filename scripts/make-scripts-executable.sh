#!/bin/bash
#
# Make all scripts executable
# This script sets the executable permission on all bash and Python scripts

set -e  # Exit immediately if a command exits with a non-zero status

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Make bash scripts executable
echo "Making bash scripts executable..."
find "$REPO_ROOT" -name "*.sh" -type f -exec chmod +x {} \;

# Make Python scripts executable
echo "Making Python scripts executable..."
find "$REPO_ROOT/scripts/python" -name "*.py" -type f -exec chmod +x {} \;

echo "All scripts are now executable."
