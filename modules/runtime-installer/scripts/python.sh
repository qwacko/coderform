#!/bin/bash
# Install Python
# Args: $1 = version (e.g., "3.12", "3.11", "3.10")

set -e

VERSION="${1:-3.12}"
echo "📦 Installing Python ${VERSION}..."

# Check if already installed
if command -v python${VERSION} &> /dev/null; then
    echo "✅ Python ${VERSION} already installed"
    return 0
fi

# Add deadsnakes PPA for newer Python versions
sudo apt-get update
sudo apt-get install -y software-properties-common
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt-get update

# Install Python and common tools
sudo apt-get install -y \
    python${VERSION} \
    python${VERSION}-dev \
    python${VERSION}-venv \
    python3-pip

# Set as default python3 if requested
if [ "${2:-false}" = "true" ]; then
    sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${VERSION} 1
fi

# Verify installation
python${VERSION} --version

echo "✅ Python ${VERSION} installed successfully"
