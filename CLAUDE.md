# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

- **Run scripts**: Use bash or sh to run individual scripts (e.g., `bash scripts/01-wsl-setup.sh`)
- **Test scripts**: Add `--help` or `--update` flag to test scripts (e.g., `bash setup.sh --help`)
- **Python scripts**: Run with `python scripts/python/generate_config.py`
- **Basic validation**: `bash scripts/99-validation.sh`

## Code Style Guidelines

- **Shell scripts**: Use 4-space indentation, `set -e` for error handling
- **Functions**: Use snake_case for shell functions, descriptive names
- **Variables**: UPPERCASE for constants, snake_case for local variables
- **Comments**: Include script purpose, usage, and dependencies as header comments
- **Heredocs**: Use EOL, EOJSON, or EOMD for multiline strings
- **Error handling**: Check command return codes, provide useful error messages
- **Output**: Use color coding with GREEN/YELLOW/RED for status messages
- **Python**: Follow PEP 8 with 4-space indentation
- **Git practices**: Work on feature branches, use descriptive commit messages

When making changes, maintain consistent formatting with existing files and ensure all scripts remain executable with proper shebang lines (`#!/bin/bash`).