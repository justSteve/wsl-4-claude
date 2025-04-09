#!/bin/bash

# Setup script for WSL Environment optimized for Claude Code
# Version with enhanced logging capabilities

# Create logs directory if it doesn't exist
mkdir -p logs

# Define log files
MAIN_LOG="logs/00-full-setup.log"
SUMMARY_LOG="logs/00-full-setup-summary.log"

# Clear existing logs
> "$MAIN_LOG"
> "$SUMMARY_LOG"

# Log the start of setup
echo "WSL Environment Setup for Claude Code - Started at $(date)" | tee -a "$MAIN_LOG" "$SUMMARY_LOG"
echo "==========================================" | tee -a "$MAIN_LOG" "$SUMMARY_LOG"

# Function to run a script with logging
run_script() {
    SCRIPT="$1"
    SCRIPT_NAME=$(basename "$SCRIPT" .sh)
    STEP_NUM=$(echo "$SCRIPT_NAME" | cut -d'-' -f1)
    STEP_DESC=$(echo "$SCRIPT_NAME" | cut -d'-' -f2-)
    STEP_LOG="logs/${SCRIPT_NAME}.log"
    STEP_SUMMARY="logs/${SCRIPT_NAME}-summary.log"
    
    # Clear individual log files
    > "$STEP_LOG"
    > "$STEP_SUMMARY"
    
    echo "=========================================="
    echo "Running $SCRIPT (Step ${STEP_NUM})"
    echo "==========================================" 
    echo "=========================================" | tee -a "$STEP_LOG" "$MAIN_LOG"
    echo "Running $SCRIPT (Step ${STEP_NUM})" | tee -a "$STEP_LOG" "$MAIN_LOG"
    echo "=========================================" | tee -a "$STEP_LOG" "$MAIN_LOG"
    
    # Add header to summary
    echo "=========================================" > "$STEP_SUMMARY"
    echo "Summary for Step ${STEP_NUM}: ${STEP_DESC}" >> "$STEP_SUMMARY"
    echo "=========================================" >> "$STEP_SUMMARY"
    
    # Execute the script and capture the exit code
    bash "$SCRIPT" 2>&1 | tee -a "$STEP_LOG" "$MAIN_LOG"
    EXIT_CODE=${PIPESTATUS[0]}
    
    if [ $EXIT_CODE -eq 0 ]; then
        RESULT="✓ SUCCESS"
    else
        RESULT="✗ FAILED"
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

# Run each script
echo "Running initialization script..."
if [ -f "scripts/00-init-repo.sh" ]; then
    run_script "scripts/00-init-repo.sh" || { echo "Initialization failed. Exiting."; exit 1; }
else
    echo "WARNING: Initialization script not found. Continuing..." | tee -a "$MAIN_LOG" "$SUMMARY_LOG"
fi

echo "Setting up WSL environment..."
if [ -f "scripts/01-wsl-setup.sh" ]; then
    run_script "scripts/01-wsl-setup.sh" || { echo "WSL setup failed. Exiting."; exit 1; }
else
    echo "WARNING: WSL setup script not found. Continuing..." | tee -a "$MAIN_LOG" "$SUMMARY_LOG"
fi

echo "Installing developer tools..."
if [ -f "scripts/02-dev-tools.sh" ]; then
    run_script "scripts/02-dev-tools.sh" || { echo "Developer tools installation failed. Exiting."; exit 1; }
else
    echo "WARNING: Developer tools script not found. Continuing..." | tee -a "$MAIN_LOG" "$SUMMARY_LOG"
fi

echo "Configuring Git..."
if [ -f "scripts/03-git-config.sh" ]; then
    run_script "scripts/03-git-config.sh" || { echo "Git configuration failed. Exiting."; exit 1; }
else
    echo "WARNING: Git configuration script not found. Continuing..." | tee -a "$MAIN_LOG" "$SUMMARY_LOG"
fi

echo "Setting up Claude Code..."
if [ -f "scripts/04-claude-setup.sh" ]; then
    run_script "scripts/04-claude-setup.sh" || { echo "Claude Code setup failed. Exiting."; exit 1; }
else
    echo "WARNING: Claude Code setup script not found. Continuing..." | tee -a "$MAIN_LOG" "$SUMMARY_LOG"
fi

echo "Setting up Linux credentials..."
if [ -f "scripts/06-lx-credentials.sh" ]; then
    run_script "scripts/06-lx-credentials.sh" || { echo "Linux credentials setup failed. Exiting."; exit 1; }
else
    echo "WARNING: Linux credentials script not found. Continuing..." | tee -a "$MAIN_LOG" "$SUMMARY_LOG"
fi

echo "Running validation..."
if [ -f "scripts/99-validation.sh" ]; then
    run_script "scripts/99-validation.sh" || { echo "Validation failed. Exiting."; exit 1; }
else
    echo "WARNING: Validation script not found. Continuing..." | tee -a "$MAIN_LOG" "$SUMMARY_LOG"
fi

# Note about Windows credentials script
if [ -f "scripts/05-win-credentials.ps1" ]; then
    echo "NOTE: Windows credentials script exists but needs to be run separately in PowerShell." | tee -a "$MAIN_LOG" "$SUMMARY_LOG"
fi

echo "Setup completed successfully!" | tee -a "$MAIN_LOG" "$SUMMARY_LOG"
echo "See logs directory for detailed information." | tee -a "$MAIN_LOG"
echo "Summary log available at: $SUMMARY_LOG" | tee -a "$MAIN_LOG"