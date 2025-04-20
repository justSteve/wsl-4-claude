#!/bin/bash
#
# Fix for hwclock issue in .bashrc
# Run this script to fix the hwclock issue causing WSL lockup

echo "Fixing hwclock issue in .bashrc..."

# Check if .bashrc exists
if [ ! -f ~/.bashrc ]; then
    echo "Error: ~/.bashrc file not found."
    exit 1
fi

# Create a backup
cp ~/.bashrc ~/.bashrc.backup.$(date +%Y%m%d%H%M%S)
echo "Created backup of .bashrc"

# Remove the hwclock line from .bashrc
sed -i '/sudo hwclock -s/d' ~/.bashrc

# Add a safer alternative
if grep -q "# Sync time with Windows" ~/.bashrc; then
    # If the comment exists but the command line was removed, add a safer version
    sed -i '/# Sync time with Windows/a\\    # Time sync handled by WSL automatically' ~/.bashrc
fi

echo "Fixed .bashrc script. The hwclock command has been removed."
echo "Please restart your WSL session for changes to take effect."
echo "You can do this by running 'exit' and then starting a new WSL terminal."
exit 0