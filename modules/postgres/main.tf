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

# ========== Postgres Parameters ==========

data "coder_parameter" "enable_postgres" {
  name        = "Enable Postgres"
  description = "Start a Postgres database"
  type        = "bool"
  default     = var.default_enabled
  mutable     = true
  order       = var.order_offset
}

data "coder_parameter" "postgres_version" {
  count       = data.coder_parameter.enable_postgres.value ? 1 : 0
  name        = "Postgres Version"
  description = "Docker image tag for Postgres"
  type        = "string"
  default     = var.default_version
  mutable     = true
  option {
    name  = "18-alpine"
    value = "18-alpine"
  }
  option {
    name  = "17-alpine"
    value = "17-alpine"
  }
  option {
    name  = "16-alpine"
    value = "16-alpine"
  }
  option {
    name  = "15-alpine"
    value = "15-alpine"
  }
  order = var.order_offset + 1
}

data "coder_parameter" "postgres_user" {
  count       = data.coder_parameter.enable_postgres.value ? 1 : 0
  name        = "Postgres User"
  description = "Database user"
  type        = "string"
  default     = var.default_user
  mutable     = true
  order       = var.order_offset + 2
}

data "coder_parameter" "postgres_password" {
  count       = data.coder_parameter.enable_postgres.value ? 1 : 0
  name        = "Postgres Password"
  description = "Database user password"
  type        = "string"
  default     = var.default_password
  mutable     = true
  order       = var.order_offset + 3
}

data "coder_parameter" "postgres_db" {
  count       = data.coder_parameter.enable_postgres.value ? 1 : 0
  name        = "Postgres Database"
  description = "Default database name"
  type        = "string"
  default     = var.default_database
  mutable     = true
  order       = var.order_offset + 4
}

# ========== Derived Locals ==========

locals {
  enabled          = data.coder_parameter.enable_postgres.value
  version          = local.enabled ? data.coder_parameter.postgres_version[0].value : ""
  user             = local.enabled ? data.coder_parameter.postgres_user[0].value : ""
  password         = local.enabled ? data.coder_parameter.postgres_password[0].value : ""
  database         = local.enabled ? data.coder_parameter.postgres_db[0].value : ""
  host             = local.enabled ? "postgres" : ""
}

# ========== Postgres Volume ==========

resource "docker_volume" "postgres_data" {
  count = local.enabled ? 1 : 0
  name  = "coder-${var.workspace_id}-pgdata"

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

# ========== Postgres Container ==========

resource "docker_container" "postgres" {
  count   = local.enabled ? 1 : 0
  image   = "postgres:${local.version}"
  name    = "coder-${var.workspace_id}-postgres"
  restart = "unless-stopped"

  env = [
    "POSTGRES_USER=${local.user}",
    "POSTGRES_PASSWORD=${local.password}",
    "POSTGRES_DB=${local.database}",
  ]

  networks_advanced {
    name    = var.internal_network_name
    aliases = ["postgres"]
  }

  volumes {
    container_path = "/var/lib/postgresql/data"
    volume_name    = docker_volume.postgres_data[0].name
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
