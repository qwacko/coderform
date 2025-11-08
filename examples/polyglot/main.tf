terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = ">= 2.4.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

# ============================================================================
# Workspace Data
# ============================================================================

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

locals {
  workspace_name    = data.coder_workspace.me.name
  workspace_id      = data.coder_workspace.me.id
  owner_id          = data.coder_workspace_owner.me.id
  username          = data.coder_workspace_owner.me.name
  repository        = "coderform/polyglot"
  network_name      = "coder-${local.workspace_id}-network"
}

# ============================================================================
# Base Image Configuration
# ============================================================================

data "coder_parameter" "ubuntu_version" {
  name         = "ubuntu_version"
  display_name = "Ubuntu Version"
  description  = "Ubuntu base image version (latest = current LTS)"
  type         = "string"
  default      = "latest"
  mutable      = false
  order        = 5

  option {
    name  = "Latest LTS (recommended)"
    value = "latest"
  }
  option {
    name  = "Ubuntu 24.04 LTS (Noble)"
    value = "24.04"
  }
  option {
    name  = "Ubuntu 22.04 LTS (Jammy)"
    value = "22.04"
  }
  option {
    name  = "Ubuntu 20.04 LTS (Focal)"
    value = "20.04"
  }
}

data "coder_parameter" "additional_packages" {
  name         = "additional_packages"
  display_name = "Additional apt packages"
  description  = "Space-separated list of additional apt packages to install in the base image (e.g., 'htop tmux vim')"
  type         = "string"
  default      = ""
  mutable      = false
  order        = 10
}

# ============================================================================
# Runtime Installer Module
# ============================================================================

module "runtime_installer" {
  source = "github.com/qwacko/coderform//modules/runtime-installer"

  workspace_id = local.workspace_id
  order_offset = 100
}

# Write the runtime installation script to the build directory
resource "local_file" "install_runtimes_script" {
  content  = module.runtime_installer.install_script
  filename = "${path.module}/build/install-runtimes.sh"

  # Make the file executable
  file_permission = "0755"
}

# ============================================================================
# Optional Services
# ============================================================================

module "postgres" {
  source = "github.com/qwacko/coderform//modules/postgres"

  agent_id             = coder_agent.main.id
  workspace_id         = local.workspace_id
  workspace_name       = local.workspace_name
  username             = local.username
  owner_id             = local.owner_id
  repository           = local.repository
  internal_network_name = local.network_name
  order_offset         = 200
}

module "valkey" {
  source = "github.com/qwacko/coderform//modules/valkey"

  agent_id             = coder_agent.main.id
  workspace_id         = local.workspace_id
  workspace_name       = local.workspace_name
  username             = local.username
  owner_id             = local.owner_id
  repository           = local.repository
  internal_network_name = local.network_name
  order_offset         = 300
}

# ============================================================================
# Docker Network
# ============================================================================

resource "docker_network" "internal_network" {
  name = local.network_name
  labels {
    label = "coder.owner"
    value = local.username
  }
  labels {
    label = "coder.workspace_id"
    value = local.workspace_id
  }
  labels {
    label = "coder.workspace_name"
    value = local.workspace_name
  }
  ipv6    = false
  internal = true
}

# ============================================================================
# Workspace Container
# ============================================================================

resource "docker_image" "workspace" {
  name = "coder-${local.workspace_id}:latest"
  build {
    context    = "${path.module}/build"
    dockerfile = "Dockerfile"
    build_args = {
      UBUNTU_VERSION      = data.coder_parameter.ubuntu_version.value
      ADDITIONAL_PACKAGES = data.coder_parameter.additional_packages.value
    }
  }

  # Rebuild when base image, packages, or runtime selections change
  triggers = {
    ubuntu_version    = data.coder_parameter.ubuntu_version.value
    packages          = data.coder_parameter.additional_packages.value
    runtime_script    = sha256(module.runtime_installer.install_script)
  }

  # Ensure the install script is written before building
  depends_on = [local_file.install_runtimes_script]
}

resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = docker_image.workspace.name
  name  = "coder-${local.username}-${local.workspace_name}"

  command = ["sleep", "infinity"]

  env = concat(
    [
      "CODER_AGENT_TOKEN=${coder_agent.main.token}",
    ],
    [for k, v in module.runtime_installer.env_vars : "${k}=${v}"],
    module.postgres.enabled ? [for k, v in module.postgres.env_vars : "${k}=${v}"] : [],
    module.valkey.enabled ? [for k, v in module.valkey.env_vars : "${k}=${v}"] : []
  )

  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }

  networks_advanced {
    name = docker_network.internal_network.name
  }

  labels {
    label = "coder.owner"
    value = local.username
  }
  labels {
    label = "coder.workspace_id"
    value = local.workspace_id
  }
  labels {
    label = "coder.workspace_name"
    value = local.workspace_name
  }
}

# ============================================================================
# Coder Agent
# ============================================================================

resource "coder_agent" "main" {
  arch = "amd64"
  os   = "linux"
  dir  = "/home/coder"

  startup_script_behavior = "blocking"

  startup_script = <<-EOT
    #!/bin/bash
    set -e

    echo "🚀 Starting workspace initialization..."

    # =========================================================================
    # Port Forwarding for External Services
    # =========================================================================
    ${module.postgres.enabled && jsonencode(module.postgres.proxy_specs) != "[]" ? "POSTGRES_PROXY_SPECS='${jsonencode(module.postgres.proxy_specs)}'" : ""}
    if [ -n "$POSTGRES_PROXY_SPECS" ] && [ "$POSTGRES_PROXY_SPECS" != "[]" ]; then
      echo "Setting up PostgreSQL proxies..."
      echo "$POSTGRES_PROXY_SPECS" | jq -r '.[] | "Starting proxy for " + .name + ": localhost:" + (.local_port|tostring) + " -> " + .host + ":" + (.rport|tostring)'
      echo "$POSTGRES_PROXY_SPECS" | jq -r '.[] | "nohup socat TCP4-LISTEN:" + (.local_port|tostring) + ",fork,reuseaddr TCP4:" + .host + ":" + (.rport|tostring) + " > /tmp/proxy-" + .name + ".log 2>&1 &"' | bash
    fi

    ${module.valkey.enabled && jsonencode(module.valkey.proxy_specs) != "[]" ? "VALKEY_PROXY_SPECS='${jsonencode(module.valkey.proxy_specs)}'" : ""}
    if [ -n "$VALKEY_PROXY_SPECS" ] && [ "$VALKEY_PROXY_SPECS" != "[]" ]; then
      echo "Setting up Valkey proxies..."
      echo "$VALKEY_PROXY_SPECS" | jq -r '.[] | "Starting proxy for " + .name + ": localhost:" + (.local_port|tostring) + " -> " + .host + ":" + (.rport|tostring)'
      echo "$VALKEY_PROXY_SPECS" | jq -r '.[] | "nohup socat TCP4-LISTEN:" + (.local_port|tostring) + ",fork,reuseaddr TCP4:" + .host + ":" + (.rport|tostring) + " > /tmp/proxy-" + .name + ".log 2>&1 &"' | bash
    fi

    echo "✅ Workspace ready!"
  EOT
}

# ============================================================================
# Coder Apps
# ============================================================================

resource "coder_app" "code_server" {
  agent_id     = coder_agent.main.id
  slug         = "code-server"
  display_name = "VS Code Web"
  url          = "http://localhost:13337/?folder=/home/coder"
  icon         = "/icon/code.svg"
  subdomain    = false
  share        = "owner"

  healthcheck {
    url       = "http://localhost:13337/healthz"
    interval  = 3
    threshold = 10
  }
}
