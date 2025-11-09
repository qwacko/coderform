#!/bin/bash
# Install Poetry package manager for Python
# Requires Python to be installed first

set -e

echo "📦 Installing Poetry..."

# Check if already installed
if command -v poetry &> /dev/null; then
    echo "✅ Poetry already installed ($(poetry --version))"
    return 0
fi

# Install Poetry using the official installer
curl -sSL https://install.python-poetry.org | python3 -

# Add Poetry to PATH (for current session and future sessions)
export PATH="$HOME/.local/bin:$PATH"

# Verify installation
poetry --version

echo "✅ Poetry installed successfully"
echo "ℹ️  Poetry is installed at: $HOME/.local/bin/poetry"
