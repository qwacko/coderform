#!/bin/bash
# Install Rust
# Args: $1 = channel (e.g., "stable", "nightly", "beta")

set -e

CHANNEL="${1:-stable}"
echo "📦 Installing Rust (${CHANNEL})..."

# Check if already installed
if command -v rustc &> /dev/null; then
    echo "✅ Rust already installed: $(rustc --version)"
    return 0
fi

# Install Rust via rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain ${CHANNEL}

# Add to PATH if not already there
if ! grep -q 'cargo/env' ~/.bashrc; then
    echo 'source "$HOME/.cargo/env"' >> ~/.bashrc
fi

# Make available in current session
source "$HOME/.cargo/env"

# Verify installation
rustc --version
cargo --version

echo "✅ Rust (${CHANNEL}) installed successfully"
