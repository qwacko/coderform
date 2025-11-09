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

# ========== MinIO Parameters ==========

data "coder_parameter" "enable_minio" {
  name        = "Enable MinIO"
  description = "S3-compatible object storage with web console"
  type        = "bool"
  default     = var.default_enabled
  mutable     = true
  order       = var.order_offset
}

data "coder_parameter" "minio_root_user" {
  count       = data.coder_parameter.enable_minio.value ? 1 : 0
  name        = "MinIO Root User"
  description = "MinIO access key (username)"
  type        = "string"
  default     = var.default_root_user
  mutable     = true
  order       = var.order_offset + 1
}

data "coder_parameter" "minio_root_password" {
  count       = data.coder_parameter.enable_minio.value ? 1 : 0
  name        = "MinIO Root Password"
  description = "MinIO secret key (password, min 8 characters)"
  type        = "string"
  default     = var.default_root_password
  mutable     = true
  order       = var.order_offset + 2
}

# ========== Derived Locals ==========

locals {
  enabled       = data.coder_parameter.enable_minio.value
  root_user     = local.enabled ? data.coder_parameter.minio_root_user[0].value : ""
  root_password = local.enabled ? data.coder_parameter.minio_root_password[0].value : ""
  host          = local.enabled ? "minio" : ""

  # Startup script template (defined here to avoid heredoc-in-ternary parsing issues)
  startup_script_raw = <<-EOT

  EOT
}

# ========== MinIO Volume ==========

resource "docker_volume" "minio_data" {
  count = local.enabled ? 1 : 0
  name  = "coder-${var.workspace_id}-miniodata"

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

# ========== MinIO Container ==========

resource "docker_container" "minio" {
  count   = local.enabled ? 1 : 0
  image   = "minio/minio:latest"
  name    = "coder-${var.workspace_id}-minio"
  restart = "unless-stopped"

  command = [
    "server",
    "/data",
    "--console-address",
    ":${var.console_port}"
  ]

  env = [
    "MINIO_ROOT_USER=${local.root_user}",
    "MINIO_ROOT_PASSWORD=${local.root_password}",
  ]

  networks_advanced {
    name    = var.internal_network_name
    aliases = ["minio"]
  }

  ports {
    internal = var.api_port
  }

  ports {
    internal = var.console_port
  }

  volumes {
    container_path = "/data"
    volume_name    = docker_volume.minio_data[0].name
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

resource "coder_app" "minio_console" {
  count        = local.enabled ? 1 : 0
  agent_id     = var.agent_id
  slug         = "minio-console"
  display_name = "MinIO Console"
  group        = var.app_group
  icon         = "/icon/storage.svg"
  url          = "http://localhost:${var.console_port}"
  share        = "owner"
  subdomain    = true
}

resource "coder_app" "minio_api" {
  count        = local.enabled ? 1 : 0
  agent_id     = var.agent_id
  slug         = "minio-api"
  display_name = "MinIO API"
  group        = var.app_group
  icon         = "/icon/storage.svg"
  url          = "http://localhost:${var.api_port}"
  share        = "owner"
  subdomain    = true
}
