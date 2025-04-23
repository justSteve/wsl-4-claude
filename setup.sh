#!/bin/bash
#
# WSL4CLAUDE - Main Setup Script
# ===============================
# This script orchestrates the overall setup process by running all component scripts
# in sequence and handling their results. It now supports the updatable components convention,
# which allows individual components to be run independently.
#
# Usage: ./setup.sh [--help] [--update-all]
#
# Options:
#   --help         Show this help message
#   --update-all   Update all components instead of fresh installation

# Process command-line arguments
HELP=false
UPDATE_MODE=false

for arg in "$@"; do
  case $arg in
    --help)
      HELP=true
      ;;
    --update-all)
      UPDATE_MODE=true
      ;;
  esac
done

if [ "$HELP" = true ]; then
    echo "WSL4CLAUDE - Main Setup Script"
    echo "Usage: ./setup.sh [--help] [--update-all]"
    echo ""
    echo "Options:"
    echo "  --help         Show this help message"
    echo "  --update-all   Update all components instead of fresh installation"
    echo ""
    echo "This script orchestrates the overall setup process by running all component"
    echo "scripts in sequence. Individual components can also be run independently."
    echo ""
    echo "Individual component scripts can be found in the scripts/ directory:"
    echo "  - 01-wsl-setup.sh: Base WSL configuration"
    echo "  - 02-dev-tools.sh: Development tools installation"
    echo "  - 03-git-config.sh: Git and GitHub configuration"
    echo "  - 04-claude-setup.sh: Claude Code installation and setup"
    echo "  - 04-claude-code-mcp-setup.sh: Model Context Protocol configuration"
    echo "  - 05-win-credentials.ps1: Windows credential setup (run in PowerShell)"
    echo "  - 06-lx-credentials.sh: Linux credential setup"
    echo "  - 99-validation.sh: Environment validation"
    echo ""
    echo "Each component script supports --help and --update flags for independent use."
    exit 0
fi

# Create logs directory if it doesn't exist
mkdir -p logs

# Define log files
MAIN_LOG="logs/00-full-setup.log"
SUMMARY_LOG="logs/00-full-setup-summary.log"

# Clear existing logs
> "$MAIN_LOG"
> "$SUMMARY_LOG"

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Log the start of setup
echo -e "${BLUE}WSL Environment Setup for Claude Code - Started at $(date)${NC}" | tee -a "$MAIN_LOG" "$SUMMARY_LOG"
echo "==========================================" | tee -a "$MAIN_LOG" "$SUMMARY_LOG"

# Function to run a script with logging
run_script() {
    SCRIPT="$1"
    UPDATE_FLAG="$2"
    SCRIPT_NAME=$(basename "$SCRIPT" .sh)
    STEP_NUM=$(echo "$SCRIPT_NAME" | cut -d'-' -f1)
    STEP_DESC=$(echo "$SCRIPT_NAME" | cut -d'-' -f2-)
    STEP_LOG="logs/${SCRIPT_NAME}.log"
    STEP_SUMMARY="logs/${SCRIPT_NAME}-summary.log"
    
    # Clear individual log files
    > "$STEP_LOG"
    > "$STEP_SUMMARY"
    
    echo -e "${BLUE}=========================================="
    echo "Running $SCRIPT (Step ${STEP_NUM})"
    echo "==========================================${NC}" 
    echo "=========================================" | tee -a "$STEP_LOG" "$MAIN_LOG"
    echo "Running $SCRIPT (Step ${STEP_NUM})" | tee -a "$STEP_LOG" "$MAIN_LOG"
    echo "=========================================" | tee -a "$STEP_LOG" "$MAIN_LOG"
    
    # Add header to summary
    echo "=========================================" > "$STEP_SUMMARY"
    echo "Summary for Step ${STEP_NUM}: ${STEP_DESC}" >> "$STEP_SUMMARY"
    echo "=========================================" >> "$STEP_SUMMARY"
    
    # Execute the script with update flag if provided and capture the exit code
    if [ -n "$UPDATE_FLAG" ]; then
        bash "$SCRIPT" "$UPDATE_FLAG" 2>&1 | tee -a "$STEP_LOG" "$MAIN_LOG"
    else
        bash "$SCRIPT" 2>&1 | tee -a "$STEP_LOG" "$MAIN_LOG"
    fi
    EXIT_CODE=${PIPESTATUS[0]}
    
    if [ $EXIT_CODE -eq 0 ]; then
        RESULT="✓ SUCCESS"
        echo -e "${GREEN}$RESULT: Step ${STEP_NUM} - ${STEP_DESC}${NC}"
    else
        RESULT="✗ FAILED"
        echo -e "${RED}$RESULT: Step ${STEP_NUM} - ${STEP_DESC}${NC}"
    fi
    
    # Generate summary based on log content
    {
        echo "$RESULT: Step ${STEP_NUM} - ${STEP_DESC}"
        echo ""
        echo "Key actions performed:"
        grep -E "Installing|Configuring|Setting up|Created|Added" "$STEP_LOG" | head -n 10 || echo "No key actions found in logs."
        
        echo ""
        echo "Notes and warnings:"
        grep -E "WARNING|NOTE|ATTENTION|NOTICE|warning|note" "$STEP_LOG" || echo "No notes or warnings found."
        
        echo ""
        echo "Errors (if any):"
        grep -E "ERROR|Error|Failed|failed|error" "$STEP_LOG" || echo "No errors found."
        
        echo ""
        echo "Completed at: $(date)"
        echo "========================================="
    } >> "$STEP_SUMMARY"
    
    # Add summary to main summary log
    cat "$STEP_SUMMARY" >> "$SUMMARY_LOG"
    
    # Return the exit code from the script
    return $EXIT_CODE
}

# Set update flag if in update mode
UPDATE_FLAG=""
if [ "$UPDATE_MODE" = true ]; then
    UPDATE_FLAG="--update"
fi

# Run each script
echo -e "${BLUE}Running initialization script...${NC}"
if [ -f "scripts/00-init-repo.sh" ]; then
    run_script "scripts/00-init-repo.sh" "$UPDATE_FLAG" || { echo -e "${RED}Initialization failed. Exiting.${NC}"; exit 1; }
else
    echo -e "${YELLOW}WARNING: Initialization script not found. Continuing...${NC}" | tee -a "$MAIN_LOG" "$SUMMARY_LOG"
fi

echo -e "${BLUE}Setting up WSL environment...${NC}"
if [ -f "scripts/01-wsl-setup.sh" ]; then
    run_script "scripts/01-wsl-setup.sh" "$UPDATE_FLAG" || { echo -e "${RED}WSL setup failed. Exiting.${NC}"; exit 1; }
else
    echo -e "${YELLOW}WARNING: WSL setup script not found. Continuing...${NC}" | tee -a "$MAIN_LOG" "$SUMMARY_LOG"
fi

echo -e "${BLUE}Installing developer tools...${NC}"
if [ -f "scripts/02-dev-tools.sh" ]; then
    run_script "scripts/02-dev-tools.sh" "$UPDATE_FLAG" || { echo -e "${RED}Developer tools installation failed. Exiting.${NC}"; exit 1; }
else
    echo -e "${YELLOW}WARNING: Developer tools script not found. Continuing...${NC}" | tee -a "$MAIN_LOG" "$SUMMARY_LOG"
fi

echo -e "${BLUE}Configuring Git...${NC}"
if [ -f "scripts/03-git-config.sh" ]; then
    run_script "scripts/03-git-config.sh" "$UPDATE_FLAG" || { echo -e "${RED}Git configuration failed. Exiting.${NC}"; exit 1; }
else
    echo -e "${YELLOW}WARNING: Git configuration script not found. Continuing...${NC}" | tee -a "$MAIN_LOG" "$SUMMARY_LOG"
fi

echo -e "${BLUE}Setting up Claude Code...${NC}"
if [ -f "scripts/04-claude-setup.sh" ]; then
    run_script "scripts/04-claude-setup.sh" "$UPDATE_FLAG" || { echo -e "${RED}Claude Code setup failed. Exiting.${NC}"; exit 1; }
else
    echo -e "${YELLOW}WARNING: Claude Code setup script not found. Continuing...${NC}" | tee -a "$MAIN_LOG" "$SUMMARY_LOG"
fi

echo -e "${BLUE}Setting up Claude Code MCP...${NC}"
if [ -f "04-claude-code-mcp-setup.sh" ]; then
    run_script "04-claude-code-mcp-setup.sh" "$UPDATE_FLAG" || { echo -e "${YELLOW}MCP setup failed but continuing...${NC}"; }
elif [ -f "scripts/04-claude-code-mcp-setup.sh" ]; then
    run_script "scripts/04-claude-code-mcp-setup.sh" "$UPDATE_FLAG" || { echo -e "${YELLOW}MCP setup failed but continuing...${NC}"; }
else
    echo -e "${YELLOW}WARNING: Claude Code MCP setup script not found. Continuing...${NC}" | tee -a "$MAIN_LOG" "$SUMMARY_LOG"
fi

echo -e "${BLUE}Setting up Linux credentials...${NC}"
if [ -f "scripts/06-lx-credentials.sh" ]; then
    run_script "scripts/06-lx-credentials.sh" "$UPDATE_FLAG" || { echo -e "${RED}Linux credentials setup failed. Exiting.${NC}"; exit 1; }
else
    echo -e "${YELLOW}WARNING: Linux credentials script not found. Continuing...${NC}" | tee -a "$MAIN_LOG" "$SUMMARY_LOG"
fi

echo -e "${BLUE}Running validation...${NC}"
if [ -f "scripts/99-validation.sh" ]; then
    run_script "scripts/99-validation.sh" || { echo -e "${RED}Validation failed. Exiting.${NC}"; exit 1; }
else
    echo -e "${YELLOW}WARNING: Validation script not found. Continuing...${NC}" | tee -a "$MAIN_LOG" "$SUMMARY_LOG"
fi

# Note about Windows credentials script
if [ -f "scripts/05-win-credentials.ps1" ]; then
    echo -e "${YELLOW}NOTE: Windows credentials script exists but needs to be run separately in PowerShell.${NC}" | tee -a "$MAIN_LOG" "$SUMMARY_LOG"
    echo -e "${YELLOW}Run it with: powershell.exe -ExecutionPolicy Bypass -File scripts/05-win-credentials.ps1${NC}" | tee -a "$MAIN_LOG" "$SUMMARY_LOG"
fi

# Display summary of component status
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}Component Status Summary${NC}"
echo -e "${BLUE}============================================${NC}"

# Source each component script to get status functions
for script in scripts/[0-9][0-9]-*.sh 04-claude-code-mcp-setup.sh; do
    if [ -f "$script" ]; then
        # Source the script to get the status function
        source "$script" &>/dev/null || true
    fi
done

# Call status functions if they exist
[ -n "$(type -t wsl_setup_status)" ] && wsl_setup_status
[ -n "$(type -t dev_tools_status)" ] && dev_tools_status
[ -n "$(type -t git_config_status)" ] && git_config_status
[ -n "$(type -t claude_setup_status)" ] && claude_setup_status
[ -n "$(type -t mcp_setup_status)" ] && mcp_setup_status

echo -e "${GREEN}Setup completed successfully!${NC}" | tee -a "$MAIN_LOG" "$SUMMARY_LOG"
echo -e "${BLUE}See logs directory for detailed information.${NC}" | tee -a "$MAIN_LOG"
echo -e "${BLUE}Summary log available at: $SUMMARY_LOG${NC}" | tee -a "$MAIN_LOG"

exit 0
