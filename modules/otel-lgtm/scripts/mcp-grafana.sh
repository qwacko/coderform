#!/bin/bash
set -e

# Function to install mcp-grafana
install_mcp_grafana() {
  echo "🚀 Installing mcp-grafana..."
  local version="0.7.10"
  local arch
  case "$(dpkg --print-architecture)" in
    amd64)
      arch="amd64"
      ;;
    arm64)
      arch="arm64"
      ;;
    *)
      echo "Unsupported architecture: $(dpkg --print-architecture)"
      exit 1
      ;;
  esac

  local url="https://github.com/grafana/mcp-grafana/releases/download/v${version}/mcp-grafana_${version}_linux_${arch}.tar.gz"

  echo "Downloading mcp-grafana from ${url}"
  curl -L -o /tmp/mcp-grafana.tar.gz "${url}"

  echo "Extracting mcp-grafana"
  tar -xzf /tmp/mcp-grafana.tar.gz -C /tmp

  echo "Installing mcp-grafana to /usr/local/bin"
  sudo mv /tmp/mcp-grafana /usr/local/bin/mcp-grafana
  sudo chmod +x /usr/local/bin/mcp-grafana

  echo "Cleaning up..."
  rm /tmp/mcp-grafana.tar.gz

  echo "✅ mcp-grafana installation complete."
}
