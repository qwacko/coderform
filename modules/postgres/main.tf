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

data "coder_parameter" "enable_pgadmin" {
  count       = data.coder_parameter.enable_postgres.value ? 1 : 0
  name        = "Enable pgAdmin"
  description = "Start pgAdmin web interface for database management"
  type        = "bool"
  default     = var.default_pgadmin_enabled
  mutable     = true
  order       = var.order_offset + 5
}

data "coder_parameter" "pgadmin_email" {
  count       = data.coder_parameter.enable_postgres.value && try(data.coder_parameter.enable_pgadmin[0].value, false) ? 1 : 0
  name        = "pgAdmin Email"
  description = "Email for pgAdmin login"
  type        = "string"
  default     = var.default_pgadmin_email
  mutable     = true
  order       = var.order_offset + 6
}

data "coder_parameter" "pgadmin_password" {
  count       = data.coder_parameter.enable_postgres.value && try(data.coder_parameter.enable_pgadmin[0].value, false) ? 1 : 0
  name        = "pgAdmin Password"
  description = "Password for pgAdmin login"
  type        = "string"
  default     = var.default_pgadmin_password
  mutable     = true
  order       = var.order_offset + 7
}

# ========== Derived Locals ==========

locals {
  enabled          = data.coder_parameter.enable_postgres.value
  version          = local.enabled ? data.coder_parameter.postgres_version[0].value : ""
  user             = local.enabled ? data.coder_parameter.postgres_user[0].value : ""
  password         = local.enabled ? data.coder_parameter.postgres_password[0].value : ""
  database         = local.enabled ? data.coder_parameter.postgres_db[0].value : ""
  host             = local.enabled ? "postgres" : ""

  pgadmin_enabled  = local.enabled && try(data.coder_parameter.enable_pgadmin[0].value, false)
  pgadmin_email    = local.pgadmin_enabled ? data.coder_parameter.pgadmin_email[0].value : ""
  pgadmin_password = local.pgadmin_enabled ? data.coder_parameter.pgadmin_password[0].value : ""
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

# ========== pgAdmin Volume ==========

resource "docker_volume" "pgadmin_data" {
  count = local.pgadmin_enabled ? 1 : 0
  name  = "coder-${var.workspace_id}-pgadmindata"

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

# ========== pgAdmin Container ==========

resource "docker_container" "pgadmin" {
  count   = local.pgadmin_enabled ? 1 : 0
  image   = "dpage/pgadmin4:latest"
  name    = "coder-${var.workspace_id}-pgadmin"
  restart = "unless-stopped"

  env = [
    "PGADMIN_DEFAULT_EMAIL=${local.pgadmin_email}",
    "PGADMIN_DEFAULT_PASSWORD=${local.pgadmin_password}",
    "PGADMIN_LISTEN_PORT=${var.pgadmin_port}",
    "PGADMIN_CONFIG_PROXY_X_FOR_COUNT=1",
    "PGADMIN_CONFIG_PROXY_X_PROTO_COUNT=1",
  ]

  networks_advanced {
    name    = var.internal_network_name
    aliases = ["pgadmin"]
  }

  # Also connect to bridge network so workspace can reach via host.docker.internal
  networks_advanced {
    name = "bridge"
  }

  volumes {
    container_path = "/var/lib/pgadmin"
    volume_name    = docker_volume.pgadmin_data[0].name
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

# ========== pgAdmin Coder App ==========

resource "coder_app" "pgadmin" {
  count        = local.pgadmin_enabled ? 1 : 0
  agent_id     = var.agent_id
  slug         = "pgadmin"
  display_name = "pgAdmin"
  icon         = "/icon/database.svg"
  url          = "http://pgadmin:${var.pgadmin_port}"
  share        = "owner"
  subdomain    = true
}
