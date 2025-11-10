#!/bin/bash
# Install Cursor CLI
# Cursor is an AI-first code editor (this installs the CLI tools)

set -e

echo "📦 Installing Cursor CLI..."

# Check if already installed
if command -v cursor &> /dev/null; then
    echo "✅ Cursor CLI already installed"
else
    # Install Cursor using their official installer
    curl -fsSL https://cursor.com/install | bash

    # Verify installation
    if command -v cursor &> /dev/null; then
        cursor --version || echo "Cursor CLI installed"
        echo "✅ Cursor CLI installed successfully"
        echo "   Note: The full Cursor editor UI requires a graphical environment"
    else
        echo "⚠️  Cursor CLI installed but not immediately available in PATH"
        echo "   You may need to restart your shell or source your profile"
    fi
fi
