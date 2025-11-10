#!/bin/bash
# Install OpenCode
# OpenCode is an AI coding assistant

set -e

echo "📦 Installing OpenCode..."

# Check if already installed
if command -v opencode &> /dev/null; then
    CURRENT_VERSION=$(opencode --version 2>&1 | head -n 1 || echo "unknown")
    echo "✅ OpenCode already installed: ${CURRENT_VERSION}"
else
    # Install OpenCode using their official installer
    npm i -g opencode-ai@latest

    # Verify installation
    if command -v opencode &> /dev/null; then
        opencode --version || echo "OpenCode installed"
        echo "✅ OpenCode installed successfully"
    else
        echo "⚠️  OpenCode installed but not immediately available in PATH"
        echo "   You may need to restart your shell or source your profile"
    fi
fi
