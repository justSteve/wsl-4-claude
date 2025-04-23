# WSL4CLAUDE - Updatable Components

This document describes the "updatable components" convention used in the WSL4CLAUDE project. These are specialized scripts that can be run both as part of the main setup chain and independently for maintenance and updates.

## Updatable Component Convention

Scripts that follow this convention have the following characteristics:

1. **Self-contained**: Can be executed independently with full functionality
2. **Command-line options**: Support at least `--help` and `--update` flags
3. **Status tracking**: Create sentinel files to track their configuration state
4. **Status function**: Provide a status function that can be used by other scripts
5. **Non-destructive updates**: Preserve existing configurations when possible
6. **Clear documentation**: Include metadata about their purpose and dependencies

## Component Header Format

Each updatable component script includes a standardized header:

```bash
# SCRIPT-NAME.sh
#
# WSL4CLAUDE - Component Description
# =================================
# MODIFIABLE: YES/NO - Can this script be run independently to update configuration?
# COMPONENT: What aspect of the environment does this script manage?
# DEPENDS: List of dependencies or prerequisites
#
# Detailed description of the script's purpose
#
# USAGE:
#   As standalone:  ./SCRIPT-NAME.sh [--help] [--update]
#   In setup chain: Called by setup.sh in sequence
```

## Dual Execution Mode

Updatable components detect whether they are being run directly or sourced by another script:

```bash
# Function to be used when script is sourced by the main setup
component_status() {
    # Check if component is configured and return 0/1 accordingly
}

# This ensures the script can both run standalone and be sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being run directly
    :
else
    # Script is being sourced - export the status function
    export -f component_status
fi
```

## Current Updatable Components

The following scripts follow the updatable component convention:

1. **04-claude-code-mcp-setup.sh**: Configure MCP tools for Claude Code
   - Purpose: Set up and manage Model Context Protocol tools configuration
   - Dependencies: Claude Code installation

## Using Updatable Components

### As Part of Setup Chain

These components are automatically executed in sequence by the main `setup.sh` script.

### For Independent Updates

Run any updatable component directly to update just that aspect of the environment:

```bash
# Update MCP configuration
./04-claude-code-mcp-setup.sh --update

# Get help for a component
./04-claude-code-mcp-setup.sh --help
```

## Adding New Updatable Components

When creating new updatable components, follow these guidelines:

1. Use the standardized header format
2. Implement at least `--help` and `--update` flags
3. Create a sentinel file to track configuration state
4. Provide a status function that can be sourced by other scripts
5. Handle both direct execution and being sourced
6. Be non-destructive when updating existing configurations
