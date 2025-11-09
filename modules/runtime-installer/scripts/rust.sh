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

# Install Rust via rustup (installs to $HOME/.cargo and $HOME/.rustup by default)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain ${CHANNEL}

# Symlink binaries to /usr/local/bin (already in default PATH)
if [ -d "$HOME/.cargo/bin" ]; then
    for bin in "$HOME/.cargo/bin/"*; do
        if [ -f "$bin" ]; then
            sudo ln -sf "$bin" /usr/local/bin/$(basename "$bin")
        fi
    done
fi

# Create profile.d script to set CARGO_HOME and RUSTUP_HOME for user sessions
sudo bash -c 'cat > /etc/profile.d/rust.sh << "EOF"
export RUSTUP_HOME=$HOME/.rustup
export CARGO_HOME=$HOME/.cargo
EOF'

# Verify installation
rustc --version
cargo --version

echo "✅ Rust (${CHANNEL}) installed successfully"
