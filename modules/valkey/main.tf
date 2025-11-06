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

# ========== Derived Locals ==========

locals {
  enabled  = data.coder_parameter.enable_valkey.value
  version  = local.enabled ? data.coder_parameter.valkey_version[0].value : ""
  password = local.enabled ? data.coder_parameter.valkey_password[0].value : ""
  host     = local.enabled ? "valkey" : ""
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
