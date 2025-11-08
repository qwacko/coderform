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

# Install Bun
curl -fsSL https://bun.sh/install | bash

# Add to PATH if not already there
if ! grep -q 'bun/bin' ~/.bashrc; then
    echo 'export PATH="$HOME/.bun/bin:$PATH"' >> ~/.bashrc
fi

# Make available in current session
export PATH="$HOME/.bun/bin:$PATH"

# Verify installation
bun --version

echo "✅ Bun installed successfully"
