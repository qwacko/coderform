#!/bin/bash
# Install Go
# Args: $1 = version (e.g., "1.22.0", "1.21.5")

set -e

VERSION="${1:-1.22.0}"
echo "📦 Installing Go ${VERSION}..."

# Check if already installed with correct version
if command -v go &> /dev/null; then
    CURRENT_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
    if [ "$CURRENT_VERSION" = "$VERSION" ]; then
        echo "✅ Go ${VERSION} already installed"
        return 0
    fi
fi

# Download and install Go
ARCH=$(dpkg --print-architecture)
wget -q "https://go.dev/dl/go${VERSION}.linux-${ARCH}.tar.gz" -O /tmp/go.tar.gz

# Remove old installation if exists
sudo rm -rf /usr/local/go

# Install new version
sudo tar -C /usr/local -xzf /tmp/go.tar.gz
rm /tmp/go.tar.gz

# Add to PATH if not already there
if ! grep -q '/usr/local/go/bin' ~/.bashrc; then
    echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.bashrc
fi

# Make available in current session
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

# Verify installation
go version

echo "✅ Go ${VERSION} installed successfully"
