#!/bin/bash
# Install Yarn package manager for Node.js
# Requires Node.js to be installed first

set -e

echo "📦 Installing Yarn..."

# Check if already installed
if command -v yarn &> /dev/null; then
    echo "✅ Yarn already installed ($(yarn --version))"
    return 0
fi

# Install Yarn globally using npm (modern Yarn Berry/v4 via Corepack is preferred)
# Enable Corepack (comes with Node.js 16.10+)
if command -v corepack &> /dev/null; then
    sudo corepack enable
    sudo corepack prepare yarn@stable --activate
else
    # Fallback to npm install if Corepack is not available
    sudo npm install -g yarn
fi

# Verify installation
yarn --version

echo "✅ Yarn installed successfully"
