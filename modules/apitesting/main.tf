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

# ========== API Testing Parameters ==========

data "coder_parameter" "enable_apitesting" {
  name        = "Enable Hoppscotch"
  description = "Open-source API development and testing tool"
  type        = "bool"
  default     = var.default_enabled
  mutable     = true
  order       = var.order_offset
}

# ========== Derived Locals ==========

locals {
  enabled = data.coder_parameter.enable_apitesting.value
  host    = local.enabled ? "hoppscotch" : ""

  # Startup script template (defined here to avoid heredoc-in-ternary parsing issues)
  startup_script_raw = <<-EOT

  EOT
}

# ========== Hoppscotch Volume ==========

resource "docker_volume" "hoppscotch_data" {
  count = local.enabled ? 1 : 0
  name  = "coder-${var.workspace_id}-hoppscotch"

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

# ========== Hoppscotch Container ==========

resource "docker_container" "hoppscotch" {
  count   = local.enabled ? 1 : 0
  image   = "hoppscotch/hoppscotch:latest"
  name    = "coder-${var.workspace_id}-hoppscotch"
  restart = "unless-stopped"

  networks_advanced {
    name    = var.internal_network_name
    aliases = ["hoppscotch"]
  }

  ports {
    internal = var.http_port
  }

  volumes {
    container_path = "/app/data"
    volume_name    = docker_volume.hoppscotch_data[0].name
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

resource "coder_app" "hoppscotch" {
  count        = local.enabled ? 1 : 0
  agent_id     = var.agent_id
  slug         = "hoppscotch"
  display_name = "Hoppscotch"
  group        = var.app_group
  icon         = "/icon/code.svg"
  url          = "http://localhost:${var.http_port}"
  share        = "owner"
  subdomain    = true
}
