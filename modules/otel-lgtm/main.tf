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

# ========== Derived Locals ==========

locals {
  enabled = data.coder_parameter.enable_otel_lgtm.value
  host    = local.enabled ? "otel-lgtm" : ""

  # Startup script template (defined here to avoid heredoc-in-ternary parsing issues)
  startup_script_raw = <<-EOT

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

  # Grafana UI port
  ports {
    internal = var.grafana_port
  }

  # OTLP gRPC port (internal only, not exposed)
  expose = [var.otlp_grpc_port]

  # OTLP HTTP port (internal only, not exposed)
  expose = [var.otlp_http_port]

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
