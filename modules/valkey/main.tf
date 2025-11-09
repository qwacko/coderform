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

# ========== Valkey Parameters ==========

data "coder_parameter" "enable_valkey" {
  name        = "Enable Valkey"
  description = "Start a Valkey (Redis-compatible) cache"
  type        = "bool"
  default     = var.default_enabled
  mutable     = true
  order       = var.order_offset
}

data "coder_parameter" "valkey_version" {
  count       = data.coder_parameter.enable_valkey.value ? 1 : 0
  name        = "Valkey Version"
  description = "Image tag for Valkey"
  type        = "string"
  default     = var.default_version
  mutable     = true
  option {
    name  = "9-alpine"
    value = "9-alpine"
  }
  option {
    name  = "9-trixie"
    value = "9-trixie"
  }
  option {
    name  = "8-alpine"
    value = "8-alpine"
  }
  option {
    name  = "8-trixie"
    value = "8-trixie"
  }
  option {
    name  = "7-alpine"
    value = "7-alpine"
  }
  option {
    name  = "7-trixie"
    value = "7-trixie"
  }
  option {
    name  = "latest"
    value = "latest"
  }
  order = var.order_offset + 1
}

data "coder_parameter" "valkey_password" {
  count       = data.coder_parameter.enable_valkey.value ? 1 : 0
  name        = "Valkey Password"
  description = "Leave empty to disable authentication"
  type        = "string"
  default     = var.default_password
  mutable     = true
  order       = var.order_offset + 2
}

# ========== Redis Management Tools Parameters ==========

data "coder_parameter" "enable_redis_commander" {
  count       = data.coder_parameter.enable_valkey.value ? 1 : 0
  name        = "Enable redis-commander"
  description = "Lightweight Redis web management tool"
  type        = "bool"
  default     = var.default_redis_commander_enabled
  mutable     = true
  order       = var.order_offset + 3
}

data "coder_parameter" "enable_redisinsight" {
  count       = data.coder_parameter.enable_valkey.value ? 1 : 0
  name        = "Enable RedisInsight"
  description = "Full-featured Redis GUI from Redis Ltd"
  type        = "bool"
  default     = var.default_redisinsight_enabled
  mutable     = true
  order       = var.order_offset + 4
}

# ========== Derived Locals ==========

locals {
  enabled  = data.coder_parameter.enable_valkey.value
  version  = local.enabled ? data.coder_parameter.valkey_version[0].value : ""
  password = local.enabled ? data.coder_parameter.valkey_password[0].value : ""
  host     = local.enabled ? "valkey" : ""

  # Redis management tools
  redis_commander_enabled = local.enabled && try(data.coder_parameter.enable_redis_commander[0].value, false)
  redisinsight_enabled    = local.enabled && try(data.coder_parameter.enable_redisinsight[0].value, false)

  # Startup script template (defined here to avoid heredoc-in-ternary parsing issues)
  startup_script_raw = <<-EOT

  EOT
}

# ========== Valkey Volume ==========

resource "docker_volume" "valkey_data" {
  count = local.enabled ? 1 : 0
  name  = "coder-${var.workspace_id}-valkeydata"

  lifecycle {
    ignore_changes = all
  }

  labels {
    label = "coder.owner"
    value = var.username
  }
  labels {
    label = "coder.owner_id"
    value = var.owner_id
  }
  labels {
    label = "coder.workspace_id"
    value = var.workspace_id
  }
  labels {
    label = "coder.repository"
    value = var.repository
  }
  labels {
    label = "coder.workspace_name_at_creation"
    value = var.workspace_name
  }
}

# ========== Valkey Container ==========

resource "docker_container" "valkey" {
  count   = local.enabled ? 1 : 0
  image   = "valkey/valkey:${local.version}"
  name    = "coder-${var.workspace_id}-valkey"
  restart = "unless-stopped"

  command = length(local.password) > 0 ? [
    "valkey-server", "--appendonly", "yes", "--requirepass", local.password
  ] : [
    "valkey-server", "--appendonly", "yes"
  ]

  networks_advanced {
    name    = var.internal_network_name
    aliases = ["valkey"]
  }

  volumes {
    container_path = "/data"
    volume_name    = docker_volume.valkey_data[0].name
  }

  labels {
    label = "coder.owner"
    value = var.username
  }
  labels {
    label = "coder.owner_id"
    value = var.owner_id
  }
  labels {
    label = "coder.workspace_id"
    value = var.workspace_id
  }
  labels {
    label = "coder.workspace_name"
    value = var.workspace_name
  }
}

# ========== redis-commander Container ==========

resource "docker_container" "redis_commander" {
  count   = local.redis_commander_enabled ? 1 : 0
  image   = "rediscommander/redis-commander:latest"
  name    = "coder-${var.workspace_id}-redis-commander"
  restart = "unless-stopped"

  env = concat(
    [
      "REDIS_HOST=valkey",
      "REDIS_PORT=6379",
    ],
    length(local.password) > 0 ? ["REDIS_PASSWORD=${local.password}"] : []
  )

  ports {
    internal = var.redis_commander_port
  }

  networks_advanced {
    name    = var.internal_network_name
    aliases = ["redis-commander"]
  }

  labels {
    label = "coder.owner"
    value = var.username
  }
  labels {
    label = "coder.owner_id"
    value = var.owner_id
  }
  labels {
    label = "coder.workspace_id"
    value = var.workspace_id
  }
  labels {
    label = "coder.workspace_name"
    value = var.workspace_name
  }
}

resource "coder_app" "redis_commander" {
  count        = local.redis_commander_enabled ? 1 : 0
  agent_id     = var.agent_id
  slug         = "redis-commander"
  display_name = "redis-commander"
  group        = var.app_group
  icon         = "/icon/memory.svg"
  url          = "http://localhost:${var.redis_commander_port}"
  share        = "owner"
  subdomain    = true
}

# ========== RedisInsight Container ==========

resource "docker_volume" "redisinsight_data" {
  count = local.redisinsight_enabled ? 1 : 0
  name  = "coder-${var.workspace_id}-redisinsight"

  lifecycle {
    ignore_changes = all
  }

  labels {
    label = "coder.owner"
    value = var.username
  }
  labels {
    label = "coder.owner_id"
    value = var.owner_id
  }
  labels {
    label = "coder.workspace_id"
    value = var.workspace_id
  }
  labels {
    label = "coder.repository"
    value = var.repository
  }
  labels {
    label = "coder.workspace_name_at_creation"
    value = var.workspace_name
  }
}

resource "docker_container" "redisinsight" {
  count   = local.redisinsight_enabled ? 1 : 0
  image   = "redis/redisinsight:latest"
  name    = "coder-${var.workspace_id}-redisinsight"
  restart = "unless-stopped"

  env = [
    "REDIS_HOSTS=local:valkey:6379${length(local.password) > 0 ? ":${local.password}" : ""}",
  ]

  ports {
    internal = var.redisinsight_port
  }

  networks_advanced {
    name    = var.internal_network_name
    aliases = ["redisinsight"]
  }

  volumes {
    container_path = "/data"
    volume_name    = docker_volume.redisinsight_data[0].name
  }

  labels {
    label = "coder.owner"
    value = var.username
  }
  labels {
    label = "coder.owner_id"
    value = var.owner_id
  }
  labels {
    label = "coder.workspace_id"
    value = var.workspace_id
  }
  labels {
    label = "coder.workspace_name"
    value = var.workspace_name
  }
}

resource "coder_app" "redisinsight" {
  count        = local.redisinsight_enabled ? 1 : 0
  agent_id     = var.agent_id
  slug         = "redisinsight"
  display_name = "RedisInsight"
  group        = var.app_group
  icon         = "/icon/memory.svg"
  url          = "http://localhost:${var.redisinsight_port}"
  share        = "owner"
  subdomain    = true
}
