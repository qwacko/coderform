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

# Symlink binaries to /usr/local/bin (already in default PATH)
sudo ln -sf /usr/local/go/bin/go /usr/local/bin/go
sudo ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt

# Create profile.d script for GOPATH and additional tools
sudo bash -c 'cat > /etc/profile.d/go.sh << "EOF"
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
EOF'

# Verify installation
go version

echo "✅ Go ${VERSION} installed successfully"
