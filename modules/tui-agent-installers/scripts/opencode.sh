#!/bin/bash
# Install OpenCode
# OpenCode is an AI coding assistant

set -e

echo "📦 Installing OpenCode..."

# Get npm global bin directory and add to PATH
NPM_BIN=$(npm bin -g 2>/dev/null || echo "/usr/local/bin")
export PATH="$NPM_BIN:$PATH"

# Check if already installed
if command -v opencode &> /dev/null; then
    CURRENT_VERSION=$(opencode --version 2>&1 | head -n 1 || echo "unknown")
    echo "✅ OpenCode already installed: ${CURRENT_VERSION}"
else
    # Install OpenCode using npm globally (requires sudo)
    sudo npm i -g opencode-ai@latest

    # Update PATH with npm bin directory
    NPM_BIN=$(npm bin -g 2>/dev/null || echo "/usr/local/bin")
    export PATH="$NPM_BIN:$PATH"

    # Verify installation
    if command -v opencode &> /dev/null; then
        opencode --version || echo "OpenCode installed"
        echo "✅ OpenCode installed successfully"
        echo "   Location: $(which opencode)"
    else
        echo "⚠️  OpenCode installed but not immediately available in PATH"
        echo "   npm global bin directory: $NPM_BIN"
        echo "   You may need to restart your shell"
    fi
fi
