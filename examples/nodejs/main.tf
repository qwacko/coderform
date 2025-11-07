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

module "ports" {
  source = "github.com/qwacko/coderform//modules/ports"

  agent_id     = coder_agent.main.id
  order_offset = 100
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

module "mailhog" {
  source = "github.com/qwacko/coderform//modules/mailhog"

  agent_id              = coder_agent.main.id
  workspace_id          = data.coder_workspace.me.id
  workspace_name        = data.coder_workspace.me.name
  username              = data.coder_workspace_owner.me.name
  owner_id              = data.coder_workspace_owner.me.id
  repository            = local.repository
  internal_network_name = docker_network.internal_network.name

  order_offset = 70
}

module "minio" {
  source = "github.com/qwacko/coderform//modules/minio"

  agent_id              = coder_agent.main.id
  workspace_id          = data.coder_workspace.me.id
  workspace_name        = data.coder_workspace.me.name
  username              = data.coder_workspace_owner.me.name
  owner_id              = data.coder_workspace_owner.me.id
  repository            = local.repository
  internal_network_name = docker_network.internal_network.name

  order_offset = 60
}

module "apitesting" {
  source = "github.com/qwacko/coderform//modules/apitesting"

  agent_id              = coder_agent.main.id
  workspace_id          = data.coder_workspace.me.id
  workspace_name        = data.coder_workspace.me.name
  username              = data.coder_workspace_owner.me.name
  owner_id              = data.coder_workspace_owner.me.id
  repository            = local.repository
  internal_network_name = docker_network.internal_network.name

  order_offset = 50
}

locals {
  username       = data.coder_workspace_owner.me.name
  owner_id       = data.coder_workspace_owner.me.id
  email          = data.coder_workspace_owner.me.email
  workspace_id   = data.coder_workspace.me.id
  workspace_name = data.coder_workspace.me.name
  start_count    = data.coder_workspace.me.start_count
}

data "coder_parameter" "node_base_image" {
  name        = "Node.js Base Image"
  description = "Select the base Node.js image for the workspace"
  order = 1
  type        = "string"
  default     = "node:24-bookworm"
  option {
    name  = "Node 25 (bookworm)"
    value = "node:25-bookworm"
  }
  option {
    name  = "Node 24 (bookworm)"
    value = "node:24-bookworm"
  }
  option {
    name  = "Node 22 (bookworm)"
    value = "node:22-bookworm"
  }
  option {
    name  = "Node 20 (bookworm)"
    value = "node:20-bookworm"
  }
}

data "coder_parameter" "repository" {
  name        = "Repository URL"
  description = "Git URL to clone into workspace"
  order = 3
  type        = "string"
}


# Derived locals from parameters
locals {
  repository     = data.coder_parameter.repository.value
  node_base_image = data.coder_parameter.node_base_image.value
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

    # Force IPv4 resolution for Docker service containers
    # Get IPv4 addresses and add to /etc/hosts to override IPv6 DNS
    if command -v getent >/dev/null 2>&1; then
      for service in postgres valkey pgweb pgadmin mathesar redis-commander redisinsight mailhog minio hoppscotch; do
        ipv4=$(getent ahostsv4 "$service" 2>/dev/null | awk 'NR==1 {print $1}')
        if [ -n "$ipv4" ]; then
          echo "Adding IPv4 entry for $service: $ipv4"
          echo "$ipv4 $service" | sudo tee -a /etc/hosts
        fi
      done
    fi

    # Port forwarding for module services
    PROXY_SPECS='${jsonencode(concat(
      module.postgres.proxy_specs,
      module.valkey.proxy_specs,
      module.mailhog.proxy_specs,
      module.minio.proxy_specs,
      module.apitesting.proxy_specs
    ))}'
    if [ "$PROXY_SPECS" != "[]" ] && [ "$PROXY_SPECS" != "" ]; then
      echo "Setting up service proxies..."
      echo "$PROXY_SPECS" | jq -r '.[] | "Starting socat proxy for " + .name + ": localhost:" + (.local_port|tostring) + " -> " + .host + ":" + (.rport|tostring)'
      echo "$PROXY_SPECS" | jq -r '.[] | "nohup socat TCP4-LISTEN:" + (.local_port|tostring) + ",fork,reuseaddr TCP4:" + .host + ":" + (.rport|tostring) + " > /tmp/proxy-" + .name + ".log 2>&1 &"' | bash
    fi

    # Install pnpm for the user shell
    curl -fsSL https://get.pnpm.io/install.sh | ENV="$HOME/.bashrc" SHELL="$(which bash)" bash -
  EOT

  env = merge(
    {
      GIT_AUTHOR_NAME     = local.username
      GIT_COMMITTER_NAME  = local.username
      GIT_AUTHOR_EMAIL    = local.email
      GIT_COMMITTER_EMAIL = local.email
      NODE_BASE_IMAGE     = local.node_base_image
    },
    module.postgres.env_vars,
    module.valkey.env_vars,
    module.mailhog.env_vars,
    module.minio.env_vars,
    module.apitesting.env_vars
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
      USER            = local.username
      NODE_BASE_IMAGE = local.node_base_image
    }
  }

  triggers = {
    dir_sha1        = sha1(join("", [for f in fileset(path.module, "build/*") : filesha1(f)]))
    node_base_image = local.node_base_image
  }
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

# ========== Debug Outputs ==========

output "all_proxy_specs" {
  description = "Debug: Shows all configured proxy specs from all modules"
  value = concat(
    module.postgres.proxy_specs,
    module.valkey.proxy_specs,
    module.mailhog.proxy_specs,
    module.minio.proxy_specs,
    module.apitesting.proxy_specs
  )
}

output "modules_enabled" {
  description = "Debug: Shows which modules are enabled"
  value = {
    postgres   = module.postgres.enabled
    valkey     = module.valkey.enabled
    mailhog    = module.mailhog.enabled
    minio      = module.minio.enabled
    apitesting = module.apitesting.enabled
  }
}

output "postgres_management_tools" {
  description = "Debug: Shows which postgres management tools are enabled"
  value = {
    pgweb    = module.postgres.pgweb_enabled
    pgadmin  = module.postgres.pgadmin_enabled
    mathesar = module.postgres.mathesar_enabled
  }
}

output "valkey_management_tools" {
  description = "Debug: Shows which valkey management tools are enabled"
  value = {
    redis_commander = module.valkey.redis_commander_enabled
    redisinsight    = module.valkey.redisinsight_enabled
  }
}
