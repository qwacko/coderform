#!/bin/bash
# Install Claude Code CLI
# Claude Code is Anthropic's official CLI for interacting with Claude

set -e

echo "📦 Installing Claude Code..."

# Check if already installed
if command -v claude &> /dev/null; then
    CURRENT_VERSION=$(claude --version 2>&1 | head -n 1 || echo "unknown")
    echo "✅ Claude Code already installed: ${CURRENT_VERSION}"
    return 0
fi

# Install Claude Code using their official installer
curl -fsSL https://claude.ai/install.sh | bash

# Verify installation
if command -v claude &> /dev/null; then
    claude --version || echo "Claude Code installed"
    echo "✅ Claude Code installed successfully"
else
    echo "⚠️  Claude Code installed but not immediately available in PATH"
    echo "   You may need to restart your shell or source your profile"
fi
