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

# ========== Headless Browser Parameters ==========

data "coder_parameter" "enable_headless_browser" {
  name        = "Enable Headless Browser"
  description = "A headless browser for AI coding agents and automation."
  type        = "bool"
  default     = var.default_enabled
  mutable     = true
  order       = var.order_offset
}

# ========== Derived Locals ==========

locals {
  enabled = data.coder_parameter.enable_headless_browser.value
  host    = local.enabled ? "headless-browser" : ""
}

# ========== Headless Browser Container ==========

resource "docker_container" "headless_browser" {
  count   = local.enabled ? 1 : 0
  image   = "ghcr.io/browserless/chromium:latest"
  name    = "coder-${var.workspace_id}-headless-browser"
  restart = "unless-stopped"

  networks_advanced {
    name    = var.internal_network_name
    aliases = ["headless-browser"]
  }

  ports {
    internal = 3000
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

resource "coder_app" "headless_browser" {
  count        = local.enabled ? 1 : 0
  agent_id     = var.agent_id
  slug         = "headless-browser"
  display_name = "Headless Browser"
  group        = var.app_group
  icon         = "/icon/chrome.svg"
  url          = "http://localhost:${var.browser_port}"
  share        = "owner"
  subdomain    = true
}
