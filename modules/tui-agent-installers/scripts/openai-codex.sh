#!/bin/bash
# Install OpenAI Codex
# OpenAI Codex is an AI coding assistant from OpenAI

set -e

echo "📦 Installing OpenAI Codex..."

# Check if already installed
if command -v codex &> /dev/null; then
    CURRENT_VERSION=$(codex --version 2>&1 | head -n 1 || echo "unknown")
    echo "✅ OpenAI Codex already installed: ${CURRENT_VERSION}"
    return 0
fi

# Install OpenAI Codex using npm globally
sudo npm install -g @openai/codex

# Verify installation
if command -v codex &> /dev/null; then
    codex --version || echo "OpenAI Codex installed"
    echo "✅ OpenAI Codex installed successfully"
else
    echo "⚠️  OpenAI Codex installed but not immediately available in PATH"
    echo "   You may need to restart your shell or source your profile"
fi
