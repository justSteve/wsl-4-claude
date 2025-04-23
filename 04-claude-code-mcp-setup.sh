#!/bin/bash
# 04-claude-code-mcp-setup.sh
#
# WSL4CLAUDE - Model Context Protocol (MCP) Configuration Script
# ============================================================
# MODIFIABLE: YES - This script can be run independently to update MCP configuration
# COMPONENT: Claude Code MCP Tools Setup
# DEPENDS: claude-code installation
#
# This script sets up MCP tools configuration for Claude Code based on the desktop version approach.
# Instead of using the CLI wizard (claude mcp add), this script directly creates and configures
# the MCP settings file for better control and flexibility.
#
# For more details: https://scottspence.com/posts/configuring-mcp-tools-in-claude-code
#
# USAGE:
#   As standalone:  ./04-claude-code-mcp-setup.sh [--help] [--update]
#   In setup chain: Called by setup.sh in sequence
#
# OPTIONS:
#   --help    Show this help message
#   --update  Update existing configuration instead of creating new

# Process command-line arguments
if [[ "$1" == "--help" ]]; then
    echo "WSL4CLAUDE - Model Context Protocol (MCP) Configuration Script"
    echo "Usage: ./04-claude-code-mcp-setup.sh [--help] [--update]"
    echo ""
    echo "Options:"
    echo "  --help    Show this help message"
    echo "  --update  Update existing configuration instead of creating new"
    echo ""
    echo "This script can be run independently to configure MCP tools for Claude Code,"
    echo "or as part of the overall WSL environment setup chain."
    exit 0
fi

UPDATE_MODE=false
if [[ "$1" == "--update" ]]; then
    UPDATE_MODE=true
fi

set -e  # Exit on any error

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Setting up MCP configuration for Claude Code...${NC}"

# First, determine the config file location
# For Claude Code, the config is stored in the Linux filesystem since it runs in Node environment
# We need to find the Claude Code config directory
if [ -d "$HOME/.config/claude-code" ]; then
    CLAUDE_CONFIG_DIR="$HOME/.config/claude-code"
elif [ -d "$HOME/.claude-code" ]; then
    CLAUDE_CONFIG_DIR="$HOME/.claude-code"
else
    # Create the directory if it doesn't exist
    CLAUDE_CONFIG_DIR="$HOME/.config/claude-code"
    mkdir -p "$CLAUDE_CONFIG_DIR"
    echo -e "${YELLOW}Created config directory at $CLAUDE_CONFIG_DIR${NC}"
fi

MCP_CONFIG_FILE="$CLAUDE_CONFIG_DIR/mcp-config.json"
echo -e "${GREEN}MCP configuration will be written to: $MCP_CONFIG_FILE${NC}"

# Handle existing configuration if in update mode
if [[ "$UPDATE_MODE" == true ]] && [[ -f "$MCP_CONFIG_FILE" ]]; then
    echo -e "${YELLOW}Update mode: Backing up existing configuration...${NC}"
    cp "$MCP_CONFIG_FILE" "${MCP_CONFIG_FILE}.bak"
    echo -e "${GREEN}Backup created at ${MCP_CONFIG_FILE}.bak${NC}"
    
    # We won't overwrite completely, just proceed to the helper script
    echo -e "${BLUE}Existing configuration preserved. Use the helper script to modify it.${NC}"
else
    # Create a template MCP config
    # This is based on the Claude Desktop config format but adapted for Claude Code
    cat > "$MCP_CONFIG_FILE" << EOF
{
  "mcpServers": {
    "mcp-omnisearch": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "mcp-omnisearch"],
      "env": {
        "TAVILY_API_KEY": "",
        "BRAVE_API_KEY": "",
        "KAGI_API_KEY": "",
        "PERPLEXITY_API_KEY": "",
        "JINA_AI_API_KEY": ""
      }
    },
    "filesystem": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "$HOME/projects"]
    }
  }
}
EOF
    echo -e "${GREEN}Created base MCP configuration with omnisearch and filesystem tools.${NC}"
fi

echo -e "${YELLOW}Please edit $MCP_CONFIG_FILE to add your API keys.${NC}"

# Check if Claude Code is installed and inform about restart
if command -v claude &> /dev/null; then
    echo -e "${BLUE}Claude Code appears to be installed.${NC}"
    echo -e "${YELLOW}Please restart Claude Code for the MCP configuration to take effect.${NC}"
    echo -e "${YELLOW}After restarting, check MCP tools by running '/mcp' in Claude Code.${NC}"
else
    echo -e "${RED}Claude Code doesn't appear to be installed or is not in your PATH.${NC}"
    echo -e "${YELLOW}After installing Claude Code, restart it for the MCP configuration to take effect.${NC}"
fi

# Adding a helper function to add additional MCP tools
cat > "$CLAUDE_CONFIG_DIR/add-mcp-tool.sh" << EOF
#!/bin/bash
# Helper script to add an MCP tool to the configuration

if [ \$# -lt 3 ]; then
    echo "Usage: \$0 <tool-name> <command> <args>"
    echo "Example: \$0 brave-search npx \"-y mcp-brave-search\""
    exit 1
fi

TOOL_NAME="\$1"
COMMAND="\$2"
ARGS="\$3"
CONFIG_FILE="$MCP_CONFIG_FILE"

# Convert string args to JSON array
ARGS_JSON="[\$(echo "\$ARGS" | sed 's/,/","/g' | sed 's/^/"/;s/$/"/')]"

# Use jq if available, otherwise use a more manual approach
if command -v jq &> /dev/null; then
    # Create a temporary file with the updated JSON
    jq ".mcpServers[\\"\$TOOL_NAME\\"] = {\\\"type\\\": \\\"stdio\\\", \\\"command\\\": \\"\$COMMAND\\", \\\"args\\\": \$ARGS_JSON}" "\$CONFIG_FILE" > "\${CONFIG_FILE}.tmp"
    mv "\${CONFIG_FILE}.tmp" "\$CONFIG_FILE"
    echo "Added \$TOOL_NAME to MCP configuration using jq."
else
    echo "The jq tool is not installed. Please install it for better JSON handling or edit \$CONFIG_FILE manually."
    echo ""
    echo "You need to add the following to the mcpServers section of your config file:"
    echo "{\"type\": \"stdio\", \"command\": \"\$COMMAND\", \"args\": \$ARGS_JSON}"
fi

echo "Remember to restart Claude Code for changes to take effect."
EOF

chmod +x "$CLAUDE_CONFIG_DIR/add-mcp-tool.sh"
echo -e "${GREEN}Created helper script at $CLAUDE_CONFIG_DIR/add-mcp-tool.sh to easily add more MCP tools.${NC}"
echo -e "${BLUE}Usage example: $CLAUDE_CONFIG_DIR/add-mcp-tool.sh brave-search npx \"-y,mcp-brave-search\"${NC}"

# Provide additional information about MCP tools
echo -e "\n${BLUE}Additional MCP Tools Information:${NC}"
echo -e "${YELLOW}Available MCP Tools:${NC}"
echo -e "  - mcp-omnisearch: Combined search using multiple providers"
echo -e "  - server-filesystem: Access to files in specified directory"
echo -e "  - mcp-brave-search: Web search using Brave"
echo -e "  - mcp-tavily-search: AI-powered search"
echo -e "  - mcp-perplexity-search: AI-powered search"
echo -e "  - mcp-jinaai-search: Web search"
echo -e "  - mcp-jinaai-grounding: Website content retrieval"
echo -e "\n${YELLOW}To install these tools:${NC}"
echo -e "  npm install -g mcp-omnisearch @modelcontextprotocol/server-filesystem mcp-brave-search"
echo -e "  # Add more tools as needed"

# Create a sentinel file indicating this component has been configured
touch "$CLAUDE_CONFIG_DIR/.mcp_configured"

echo -e "\n${GREEN}MCP configuration setup complete!${NC}"

# Function to be used when script is sourced by the main setup
mcp_setup_status() {
    if [[ -f "$CLAUDE_CONFIG_DIR/.mcp_configured" ]]; then
        echo "MCP Tools: Configured"
        return 0
    else
        echo "MCP Tools: Not configured"
        return 1
    fi
}

# This ensures the script can both run standalone and be sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being run directly
    :
else
    # Script is being sourced - export the status function
    export -f mcp_setup_status
fi
