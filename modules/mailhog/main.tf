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

# ========== MailHog Parameters ==========

data "coder_parameter" "enable_mailhog" {
  name        = "Enable MailHog"
  description = "Email testing tool with web UI"
  type        = "bool"
  default     = var.default_enabled
  mutable     = true
  order       = var.order_offset
}

# ========== Derived Locals ==========

locals {
  enabled = data.coder_parameter.enable_mailhog.value
  host    = local.enabled ? "mailhog" : ""

  # Startup script template (defined here to avoid heredoc-in-ternary parsing issues)
  startup_script_raw = <<-EOT

  EOT
}

# ========== MailHog Container ==========

resource "docker_container" "mailhog" {
  count   = local.enabled ? 1 : 0
  image   = "mailhog/mailhog:latest"
  name    = "coder-${var.workspace_id}-mailhog"
  restart = "unless-stopped"

  networks_advanced {
    name    = var.internal_network_name
    aliases = ["mailhog"]
  }

  ports {
    internal = var.smtp_port
  }

  ports {
    internal = var.http_port
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

resource "coder_app" "mailhog" {
  count        = local.enabled ? 1 : 0
  agent_id     = var.agent_id
  slug         = "mailhog"
  display_name = "MailHog"
  group        = var.app_group
  icon         = "/icon/email.svg"
  url          = "http://localhost:${var.http_port}"
  share        = "owner"
  subdomain    = true
}
