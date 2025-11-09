#!/bin/bash
# Install uv - fast Python package installer and resolver (pip alternative)
# Requires Python to be installed first
# uv is developed by Astral (creators of Ruff)

set -e

echo "📦 Installing uv..."

# Check if already installed
if command -v uv &> /dev/null; then
    echo "✅ uv already installed ($(uv --version))"
    return 0
fi

# Install uv using the official installer
curl -LsSf https://astral.sh/uv/install.sh | sh

# Add uv to PATH (for current session)
export PATH="$HOME/.cargo/bin:$PATH"

# Verify installation
uv --version

echo "✅ uv installed successfully"
echo "ℹ️  uv is installed at: $HOME/.cargo/bin/uv"
