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

# ========== OTEL-LGTM Parameters ==========

data "coder_parameter" "enable_otel_lgtm" {
  name        = "Enable Grafana OTEL-LGTM"
  description = "Grafana LGTM stack for OpenTelemetry (Loki, Grafana, Tempo, Mimir)"
  type        = "bool"
  default     = var.default_enabled
  mutable     = true
  order       = var.order_offset
}

data "coder_parameter" "install_mcp_grafana" {
  name        = "Install mcp-grafana"
  description = "Install mcp-grafana CLI for MCP access to Grafana"
  type        = "bool"
  default     = var.install_mcp_grafana_default
  mutable     = true
  order       = var.order_offset + 1
}

# ========== Derived Locals ==========

locals {
  enabled = data.coder_parameter.enable_otel_lgtm.value
  host    = local.enabled ? "otel-lgtm" : ""

  install_mcp_grafana = data.coder_parameter.install_mcp_grafana.value == "true"
  mcp_grafana_script  = file("${path.module}/scripts/mcp-grafana.sh")

  # Startup script template (defined here to avoid heredoc-in-ternary parsing issues)
  startup_script_raw = <<-EOT
    #!/bin/bash
    set -e
    
    ${local.install_mcp_grafana ? local.mcp_grafana_script : ""}

    ${local.install_mcp_grafana ? "install_mcp_grafana" : ""}
  EOT
}

# ========== OTEL-LGTM Volume ==========

resource "docker_volume" "otel_lgtm_data" {
  count = local.enabled ? 1 : 0
  name  = "coder-${var.workspace_id}-otel-lgtm"

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

# ========== OTEL-LGTM Container ==========

resource "docker_container" "otel_lgtm" {
  count   = local.enabled ? 1 : 0
  image   = "grafana/otel-lgtm:latest"
  name    = "coder-${var.workspace_id}-otel-lgtm"
  restart = "unless-stopped"

  networks_advanced {
    name    = var.internal_network_name
    aliases = ["otel-lgtm"]
  }

  # Grafana UI port (exposed for Coder app access)
  ports {
    internal = var.grafana_port
  }

  # Note: OTLP ports (4317 gRPC, 4318 HTTP) are automatically available
  # on the internal Docker network and don't need to be explicitly declared

  volumes {
    container_path = "/data"
    volume_name    = docker_volume.otel_lgtm_data[0].name
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

resource "coder_app" "grafana" {
  count        = local.enabled ? 1 : 0
  agent_id     = var.agent_id
  slug         = "grafana"
  display_name = "Grafana OTEL"
  group        = var.app_group
  icon         = "/icon/grafana.svg"
  url          = "http://localhost:${var.grafana_port}"
  share        = "owner"
  subdomain    = true
}
