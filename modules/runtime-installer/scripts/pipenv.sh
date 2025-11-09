#!/bin/bash
# Install Pipenv package manager for Python
# Requires Python to be installed first

set -e

echo "📦 Installing Pipenv..."

# Check if already installed
if command -v pipenv &> /dev/null; then
    echo "✅ Pipenv already installed ($(pipenv --version))"
    return 0
fi

# Install Pipenv using pip
python3 -m pip install --user pipenv

# Add user site-packages to PATH
export PATH="$HOME/.local/bin:$PATH"

# Verify installation
pipenv --version

echo "✅ Pipenv installed successfully"
