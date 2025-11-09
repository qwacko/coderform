#!/bin/bash
# Install pnpm package manager for Node.js
# Requires Node.js to be installed first

set -e

echo "📦 Installing pnpm..."

# Check if already installed
if command -v pnpm &> /dev/null; then
    echo "✅ pnpm already installed ($(pnpm --version))"
    return 0
fi

# Install pnpm globally using npm
sudo npm install -g pnpm

# Verify installation
pnpm --version

echo "✅ pnpm installed successfully"
