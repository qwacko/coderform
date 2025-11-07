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

# ========== Database Management Tools Parameters ==========

data "coder_parameter" "enable_pgweb" {
  count       = data.coder_parameter.enable_postgres.value ? 1 : 0
  name        = "Enable pgweb"
  description = "Lightweight PostgreSQL web browser (Go-based)"
  type        = "bool"
  default     = var.default_pgweb_enabled
  mutable     = true
  order       = var.order_offset + 5
}

data "coder_parameter" "enable_cloudbeaver" {
  count       = data.coder_parameter.enable_postgres.value ? 1 : 0
  name        = "Enable CloudBeaver"
  description = "Web-based database manager (supports multiple DBs)"
  type        = "bool"
  default     = var.default_cloudbeaver_enabled
  mutable     = true
  order       = var.order_offset + 6
}

data "coder_parameter" "enable_mathesar" {
  count       = data.coder_parameter.enable_postgres.value ? 1 : 0
  name        = "Enable Mathesar"
  description = "Modern spreadsheet-like interface for PostgreSQL"
  type        = "bool"
  default     = var.default_mathesar_enabled
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

  # Database management tools
  pgweb_enabled       = local.enabled && try(data.coder_parameter.enable_pgweb[0].value, false)
  cloudbeaver_enabled = local.enabled && try(data.coder_parameter.enable_cloudbeaver[0].value, false)
  mathesar_enabled    = local.enabled && try(data.coder_parameter.enable_mathesar[0].value, false)
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

# ========== pgweb Container ==========

resource "docker_container" "pgweb" {
  count   = local.pgweb_enabled ? 1 : 0
  image   = "sosedoff/pgweb:latest"
  name    = "coder-${var.workspace_id}-pgweb"
  restart = "unless-stopped"

  command = [
    "pgweb",
    "--bind=0.0.0.0",
    "--listen=${var.pgweb_port}",
    "--host=postgres",
    "--user=${local.user}",
    "--pass=${local.password}",
    "--db=${local.database}",
  ]

  ports {
    internal = var.pgweb_port
  }

  networks_advanced {
    name = var.internal_network_name
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

resource "coder_app" "pgweb" {
  count        = local.pgweb_enabled ? 1 : 0
  agent_id     = var.agent_id
  slug         = "pgweb"
  display_name = "pgweb"
  icon         = "/icon/database.svg"
  url          = "http://host.docker.internal:${var.pgweb_port}"
  share        = "owner"
  subdomain    = true
}

# ========== CloudBeaver Container ==========

resource "docker_volume" "cloudbeaver_data" {
  count = local.cloudbeaver_enabled ? 1 : 0
  name  = "coder-${var.workspace_id}-cloudbeaver"

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

resource "docker_container" "cloudbeaver" {
  count   = local.cloudbeaver_enabled ? 1 : 0
  image   = "dbeaver/cloudbeaver:latest"
  name    = "coder-${var.workspace_id}-cloudbeaver"
  restart = "unless-stopped"

  networks_advanced {
    name = var.internal_network_name
  }

  volumes {
    container_path = "/opt/cloudbeaver/workspace"
    volume_name    = docker_volume.cloudbeaver_data[0].name
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

resource "coder_app" "cloudbeaver" {
  count        = local.cloudbeaver_enabled ? 1 : 0
  agent_id     = var.agent_id
  slug         = "cloudbeaver"
  display_name = "CloudBeaver"
  icon         = "/icon/database.svg"
  url          = "http://cloudbeaver:${var.cloudbeaver_port}"
  share        = "owner"
  subdomain    = true
}

# ========== Mathesar Container ==========

resource "docker_volume" "mathesar_data" {
  count = local.mathesar_enabled ? 1 : 0
  name  = "coder-${var.workspace_id}-mathesar"

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

resource "docker_container" "mathesar" {
  count   = local.mathesar_enabled ? 1 : 0
  image   = "mathesar/mathesar:latest"
  name    = "coder-${var.workspace_id}-mathesar"
  restart = "unless-stopped"

  env = [
    "MATHESAR_DATABASES=(postgresql://${local.user}:${local.password}@postgres:5432/${local.database})",
    "SECRET_KEY=change_this_to_a_random_string",
    "DJANGO_SUPERUSER_PASSWORD=admin",
    "ALLOWED_HOSTS=*",
  ]

  networks_advanced {
    name = var.internal_network_name
  }

  volumes {
    container_path = "/mathesar"
    volume_name    = docker_volume.mathesar_data[0].name
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

resource "coder_app" "mathesar" {
  count        = local.mathesar_enabled ? 1 : 0
  agent_id     = var.agent_id
  slug         = "mathesar"
  display_name = "Mathesar"
  icon         = "/icon/database.svg"
  url          = "http://mathesar:${var.mathesar_port}"
  share        = "owner"
  subdomain    = true
}