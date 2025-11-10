terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = ">=2.4.0"
    }
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}


# ============================================================================
# Runtime Installer Module
# ============================================================================

module "runtime_installer" {
  source = "github.com/qwacko/coderform//modules/runtime-installer"

  workspace_id = local.workspace_id
  order_offset = 100

  # Optional: Set default package managers for runtimes
  # nodejs_default_package_manager = "pnpm"  # Options: npm, yarn, pnpm, both
  # python_default_package_manager = "uv"    # Options: pip, poetry, pipenv, uv, both
}

# ============================================================================
# TUI Agent Installers Module
# ============================================================================

module "tui_agent_installers" {
  source = "github.com/qwacko/coderform//modules/tui-agent-installers"

  workspace_id = local.workspace_id
  order_offset = 200

  # Optional: Set default enabled state for each agent
  # claude_code_default_enabled  = true
  # opencode_default_enabled     = true
  # openai_codex_default_enabled = true
  # cursor_default_enabled       = true
}

# Write combined installation script to the build directory (always written for consistency)
resource "local_file" "install_script" {
  content = local.combined_install_script != "" ? local.combined_install_script : <<-EOT
    #!/bin/bash
    # No install script needed
    echo "No installation steps required"
  EOT
  filename        = "${path.module}/build/install.sh"
  file_permission = "0755"
}

# Write proxy specs JSON to the build directory
resource "local_file" "proxy_specs" {
  content         = jsonencode(local.all_proxy_specs)
  filename        = "${path.module}/build/proxy_specs.json"
  file_permission = "0644"
}

# Write hostnames JSON to the build directory
resource "local_file" "hostnames" {
  content         = jsonencode(local.all_hostnames)
  filename        = "${path.module}/build/hostnames.json"
  file_permission = "0644"
}

# Write combined startup script to the build directory (always written for inspection)
resource "local_file" "startup_script" {
  content = <<-EOT
#!/bin/bash
set -e

# Module startup scripts (health checks, service initialization)
${local.combined_startup_script != "" ? local.combined_startup_script : "echo 'No module startup scripts'"}

# Port forwarding for all module services
${local.proxy_setup_script != "" ? local.proxy_setup_script : "echo 'No proxy forwarding needed'"}

# IPv4 hostname resolution
${local.ipv4_setup_script != "" ? local.ipv4_setup_script : "echo 'No hostnames to resolve'"}
EOT
  filename        = "${path.module}/build/startup.sh"
  file_permission = "0755"
}


module "ports" {
  source = "github.com/qwacko/coderform//modules/ports"

  agent_id     = coder_agent.main.id
  order_offset = 300
}


module "postgres" {
  source = "github.com/qwacko/coderform//modules/postgres"

  agent_id              = coder_agent.main.id
  workspace_id          = data.coder_workspace.me.id
  workspace_name        = data.coder_workspace.me.name
  username              = data.coder_workspace_owner.me.name
  owner_id              = data.coder_workspace_owner.me.id
  repository            = local.repository
  internal_network_name = docker_network.internal_network.name

  order_offset = 90
}

module "valkey" {
  source = "github.com/qwacko/coderform//modules/valkey"

  agent_id              = coder_agent.main.id
  workspace_id          = data.coder_workspace.me.id
  workspace_name        = data.coder_workspace.me.name
  username              = data.coder_workspace_owner.me.name
  owner_id              = data.coder_workspace_owner.me.id
  repository            = local.repository
  internal_network_name = docker_network.internal_network.name
  
  order_offset = 80
}

locals {
  username       = data.coder_workspace_owner.me.name
  owner_id       = data.coder_workspace_owner.me.id
  email          = data.coder_workspace_owner.me.email
  workspace_id   = data.coder_workspace.me.id
  workspace_name = data.coder_workspace.me.name
  start_count    = data.coder_workspace.me.start_count
  ubuntu_version = data.coder_parameter.ubuntu_version.value
  additional_packages = data.coder_parameter.additional_packages.value

  # Debug flag: run install script during startup instead of Docker build
  # This makes iteration faster since you don't need to rebuild the image
  install_runs_during_startup = data.coder_parameter.install_runs_during_startup.value == "true"
}

data "coder_parameter" "ubuntu_version" {
  name         = "ubuntu_version"
  display_name = "Ubuntu Version"
  description  = "Ubuntu base image version (latest = current LTS)"
  type         = "string"
  default      = "latest"
  mutable      = true
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

data "coder_parameter" "repository" {
  name        = "Repository URL"
  description = "Git URL to clone into workspace"
  order       = 4
  type        = "string"
}

data "coder_parameter" "additional_packages" {
  name        = "Additional Packages"
  description = "Additional Packages to install"
  order       = 3
  type        = "string"
  mutable     = true
}

data "coder_parameter" "install_runs_during_startup" {
  name         = "install_runs_during_startup"
  display_name = "Debug: Run Install at Startup"
  description  = "Run install script during startup instead of Docker build (faster iteration, slower startup)"
  type         = "bool"
  default      = "false"
  mutable      = true
  order        = 6
}


# Derived locals from parameters
locals {
  repository     = data.coder_parameter.repository.value
}

# ============================================================================
# Module Output Composition
# ============================================================================

locals {
  # Combine packages from all modules
  all_packages = distinct(concat(
    module.postgres.packages,
    module.valkey.packages,
    module.runtime_installer.packages,
    module.tui_agent_installers.packages,
    module.ports.packages,
    # Split user-provided packages by space
    split(" ", local.additional_packages)
  ))

  # Combine install scripts (run during Docker build)
  combined_install_script = join("\n\n", compact([
    module.postgres.install_script,
    module.valkey.install_script,
    module.runtime_installer.install_script,
    module.tui_agent_installers.install_script,
    module.ports.install_script
  ]))

  # Combine startup scripts (run during agent startup)
  combined_startup_script = join("\n\n", compact([
    module.postgres.startup_script,
    module.valkey.startup_script,
    module.runtime_installer.startup_script,
    module.tui_agent_installers.startup_script,
    module.ports.startup_script
  ]))

  # Combine proxy specs
  all_proxy_specs = concat(
    module.postgres.proxy_specs,
    module.valkey.proxy_specs,
    module.runtime_installer.proxy_specs,
    module.tui_agent_installers.proxy_specs,
    module.ports.proxy_specs
  )

  # Combine environment variables
  all_env_vars = merge(
    module.postgres.env_vars,
    module.valkey.env_vars,
    module.runtime_installer.env_vars,
    module.tui_agent_installers.env_vars,
    module.ports.env_vars
  )

  # Combine hostnames for IPv4 resolution
  all_hostnames = distinct(concat(
    module.postgres.hostnames,
    module.valkey.hostnames,
    module.runtime_installer.hostnames,
    module.tui_agent_installers.hostnames,
    module.ports.hostnames
  ))

  # Standard proxy setup script (reusable)
  proxy_setup_script_raw = <<-EOT
    # Set up port forwarding for services
    if [ -f /tmp/proxy_specs.json ] && jq -e '. | length > 0' /tmp/proxy_specs.json >/dev/null 2>&1; then
      echo "Setting up service proxies..."
      jq -r '.[] | "Starting proxy for " + .name + ": localhost:" + (.local_port|tostring) + " -> " + .host + ":" + (.rport|tostring)' /tmp/proxy_specs.json
      jq -r '.[] | "nohup socat TCP4-LISTEN:" + (.local_port|tostring) + ",fork,reuseaddr TCP4:" + .host + ":" + (.rport|tostring) + " > /tmp/proxy-" + .name + ".log 2>&1 &"' /tmp/proxy_specs.json | bash
    fi
  EOT
  proxy_setup_script = length(local.all_proxy_specs) > 0 ? local.proxy_setup_script_raw : ""

  # IPv4 hostname resolution script (reusable)
  ipv4_setup_script_raw = <<-EOT
    # Force IPv4 resolution for Docker service containers
    if [ -f /tmp/hostnames.json ] && command -v getent >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
      for service in $(jq -r '.[]' < /tmp/hostnames.json); do
        ipv4=$(getent ahostsv4 "$${service}" 2>/dev/null | head -n 1 | cut -d ' ' -f 1)
        if [ -n "$${ipv4}" ]; then
          echo "Adding IPv4 entry for $${service}: $${ipv4}"
          echo "$${ipv4} $${service}" | sudo tee -a /etc/hosts >/dev/null
        fi
      done
    fi
  EOT
  ipv4_setup_script = length(local.all_hostnames) > 0 ? local.ipv4_setup_script_raw : ""
}

# ========== Providers and data sources ==========

data "coder_external_auth" "github" {
  id = "primary-github"
}

data "coder_provisioner" "me" {}
provider "docker" {}
data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

# ========== Modules ==========

module "vscode-web" {
  source         = "https://registry.coder.com/modules/vscode-web"
  agent_id       = coder_agent.main.id
  accept_license = true
}

module "git-clone" {
  source   = "https://registry.coder.com/modules/git-clone"
  agent_id = coder_agent.main.id
  url      = local.repository
}

# ========== Agent ==========

resource "coder_agent" "main" {
  arch           = data.coder_provisioner.me.arch
  os             = "linux"
  dir            = "~/coder"
  startup_script = <<-EOT
    set -e

    # Conditionally run install script at startup (debug mode)
    ${local.install_runs_during_startup ? "echo '🔧 Running install script at startup (debug mode)...'" : ""}
    ${local.install_runs_during_startup ? "bash /tmp/install.sh" : ""}

    # Run startup script (module health checks, port forwarding, IPv4 resolution)
    echo "🚀 Running startup script..."
    bash /tmp/startup.sh

  EOT

  env = merge(
    {
      GIT_AUTHOR_NAME     = local.username
      GIT_COMMITTER_NAME  = local.username
      GIT_AUTHOR_EMAIL    = local.email
      GIT_COMMITTER_EMAIL = local.email
    },
    local.all_env_vars
  )

  metadata {
    display_name = "CPU Usage"
    key          = "0_cpu_usage"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "RAM Usage"
    key          = "1_ram_usage"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Home Disk"
    key          = "3_home_disk"
    script       = "coder stat disk --path $${HOME}"
    interval     = 60
    timeout      = 1
  }

  metadata {
    display_name = "CPU Usage (Host)"
    key          = "4_cpu_usage_host"
    script       = "coder stat cpu --host"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Memory Usage (Host)"
    key          = "5_mem_usage_host"
    script       = "coder stat mem --host"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Load Average (Host)"
    key          = "6_load_host"
    script = <<EOT
      echo "`cat /proc/loadavg | awk '{ print $1 }'` `nproc`" | awk '{ printf "%0.2f", $1/$2 }'
    EOT
    interval = 60
    timeout  = 1
  }

  metadata {
    display_name = "Swap Usage (Host)"
    key          = "7_swap_host"
    script       = <<EOT
      free -b | awk '/^Swap/ { printf("%.1f/%.1f", $3/1024.0/1024.0/1024.0, $2/1024.0/1024.0/1024.0) }'
    EOT
    interval     = 10
    timeout      = 1
  }
}


# ========== Networking and volumes ==========

resource "docker_network" "internal_network" {
  name     = "coder-${local.workspace_id}-network"
  driver   = "bridge"
  internal = true
  ipv6 = false
}

resource "docker_volume" "home_volume" {
  name = "coder-${local.workspace_id}-home"

  lifecycle {
    ignore_changes = all
  }

  labels {
    label = "coder.owner"
    value = local.username
  }
  labels {
    label = "coder.owner_id"
    value = local.owner_id
  }
  labels {
    label = "coder.workspace_id"
    value = local.workspace_id
  }
  labels {
    label = "coder.repository"
    value = local.repository
  }
  labels {
    label = "coder.workspace_name_at_creation"
    value = local.workspace_name
  }
}

# ========== Workspace image/build ==========

resource "docker_image" "main" {
  name = "coder-${local.workspace_id}"

  build {
    context = "./build"
    build_args = {
      USER                  = local.username
      UBUNTU_VERSION        = local.ubuntu_version
      PACKAGES              = join(" ", local.all_packages)
      RUN_INSTALL_AT_BUILD  = local.install_runs_during_startup ? "false" : "true"
    }
    suppress_output = false
      # Enable BuildKit and log capture (required for build_log_file)
    #builder         = "default"  # or "docker-container", or a custom builder name
    #build_log_file  = "/tmp/docker-build-${local.workspace_id}.log"
  }


  # Trigger rebuilds when any of these change:
  # - Ubuntu version parameter changes
  # - Packages from modules or user parameters change
  # - Install/startup scripts change (detected via script content hash)
  # - Proxy specs or hostnames change (for port forwarding and IPv4 resolution)
  # - Dockerfile is modified
  # - install_runs_during_startup flag changes (affects which scripts run when)
  triggers = {
    ubuntu_version              = local.ubuntu_version
    packages                    = join(",", local.all_packages)
    install_script              = sha256(local.combined_install_script)
    startup_script              = sha256(local.combined_startup_script)
    proxy_specs                 = sha256(jsonencode(local.all_proxy_specs))
    hostnames                   = sha256(jsonencode(local.all_hostnames))
    install_runs_during_startup = tostring(local.install_runs_during_startup)
    dockerfile                  = filesha1("${path.module}/build/Dockerfile")
    force                       = timestamp()
  }

  # Ensure all scripts and JSON files are written before building
  depends_on = [
    local_file.install_script,
    local_file.startup_script,
    local_file.proxy_specs,
    local_file.hostnames
  ]

}

resource "docker_container" "workspace" {
  count = local.start_count
  image = docker_image.main.name

  name     = "coder-${local.username}-${lower(local.workspace_name)}"
  hostname = local.workspace_name

  entrypoint = [
    "sh",
    "-c",
    replace(
      coder_agent.main.init_script,
      "/localhost|127\\.0\\.0\\.1/",
      "host.docker.internal"
    )
  ]
  env = ["CODER_AGENT_TOKEN=${coder_agent.main.token}"]

  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }

  networks_advanced {
    name = docker_network.internal_network.name
  }
  networks_advanced {
    name = "bridge"
  }

  volumes {
    container_path = "/home/${local.username}"
    volume_name    = docker_volume.home_volume.name
    read_only      = false
  }

  labels {
    label = "coder.owner"
    value = local.username
  }
  labels {
    label = "coder.owner_id"
    value = local.owner_id
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

