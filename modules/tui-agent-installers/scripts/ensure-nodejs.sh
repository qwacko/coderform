#!/bin/bash
# Ensure Node.js is installed for TUI agents
# If no version is installed, installs Node.js 24.x (LTS)

set -e

echo "🔍 Checking for Node.js installation..."

# Check if Node.js and npm are both already installed
if command -v node &> /dev/null && command -v npm &> /dev/null; then
    CURRENT_VERSION=$(node --version)
    NPM_VERSION=$(npm --version)
    echo "✅ Node.js already installed: ${CURRENT_VERSION}"
    echo "   npm version: ${NPM_VERSION}"
else
    # Install Node.js 24.x from NodeSource
    echo "📦 Installing Node.js 24.x LTS..."

    # Download and run NodeSource setup script
    curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -

    # Install Node.js (includes npm)
    sudo apt-get install -y nodejs

    # Verify installation
    if command -v node &> /dev/null && command -v npm &> /dev/null; then
        NODE_VERSION=$(node --version)
        NPM_VERSION=$(npm --version)
        echo "✅ Node.js installed successfully!"
        echo "   Node.js version: ${NODE_VERSION}"
        echo "   npm version: ${NPM_VERSION}"
    else
        echo "❌ Failed to install Node.js"
        exit 1
    fi
fi
