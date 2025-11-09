#!/bin/bash
# Install OpenCode
# OpenCode is an AI coding assistant

set -e

echo "📦 Installing OpenCode..."

# Check if already installed
if command -v opencode &> /dev/null; then
    CURRENT_VERSION=$(opencode --version 2>&1 | head -n 1 || echo "unknown")
    echo "✅ OpenCode already installed: ${CURRENT_VERSION}"
    return 0
fi

# Install OpenCode using their official installer
curl -fsSL https://opencode.ai/install | bash

# Verify installation
if command -v opencode &> /dev/null; then
    opencode --version || echo "OpenCode installed"
    echo "✅ OpenCode installed successfully"
else
    echo "⚠️  OpenCode installed but not immediately available in PATH"
    echo "   You may need to restart your shell or source your profile"
fi
