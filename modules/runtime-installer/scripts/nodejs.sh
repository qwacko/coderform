#!/bin/bash
# Install Node.js
# Args: $1 = version (e.g., "20", "18", "latest")

set -e

VERSION="${1:-20}"
echo "📦 Installing Node.js ${VERSION}..."

# Check if already installed with correct version
if command -v node &> /dev/null; then
    CURRENT_VERSION=$(node --version | sed 's/v//' | cut -d. -f1)
    if [ "$CURRENT_VERSION" = "$VERSION" ]; then
        echo "✅ Node.js ${VERSION} already installed"
        return 0
    fi
fi

# Install Node.js from NodeSource
curl -fsSL https://deb.nodesource.com/setup_${VERSION}.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify installation
node --version
npm --version

echo "✅ Node.js ${VERSION} installed successfully"
