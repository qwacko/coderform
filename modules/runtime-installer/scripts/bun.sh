#!/bin/bash
# Install Bun
# Args: $1 = version (e.g., "1.0.0", "latest")

set -e

VERSION="${1:-latest}"
echo "📦 Installing Bun ${VERSION}..."

# Check if already installed
if command -v bun &> /dev/null; then
    echo "✅ Bun already installed: $(bun --version)"
    return 0
fi

# Install Bun (installs to $HOME/.bun by default)
curl -fsSL https://bun.sh/install | bash

# Symlink to /usr/local/bin (already in default PATH)
if [ -f "$HOME/.bun/bin/bun" ]; then
    sudo ln -sf "$HOME/.bun/bin/bun" /usr/local/bin/bun
fi

# Create profile.d script to set BUN_INSTALL for user sessions
sudo bash -c 'cat > /etc/profile.d/bun.sh << "EOF"
export BUN_INSTALL=$HOME/.bun
EOF'

# Verify installation
bun --version

echo "✅ Bun installed successfully"
