output "enabled" {
  description = "Whether Postgres is enabled"
  value       = local.enabled
}

output "host" {
  description = "Postgres hostname (empty if disabled)"
  value       = local.host
}

output "port" {
  description = "Postgres port (always 5432)"
  value       = 5432
}

output "user" {
  description = "Postgres user"
  value       = local.user
}

output "password" {
  description = "Postgres password"
  value       = local.password
  sensitive   = true
}

output "database" {
  description = "Postgres database name"
  value       = local.database
}

output "version" {
  description = "Postgres version tag"
  value       = local.version
}

output "connection_string" {
  description = "PostgreSQL connection string"
  value       = local.enabled ? "postgresql://${local.user}:${local.password}@${local.host}:5432/${local.database}" : ""
  sensitive   = true
}

output "connection_string_sslmode_disable" {
  description = "PostgreSQL connection string with sslmode=disable"
  value       = local.enabled ? "postgresql://${local.user}:${local.password}@${local.host}:5432/${local.database}?sslmode=disable" : ""
  sensitive   = true
}

output "env_vars" {
  description = "Environment variables for agent or containers"
  value = {
    POSTGRES_ENABLED  = tostring(local.enabled)
    POSTGRES_HOST     = local.host
    POSTGRES_PORT     = "5432"
    POSTGRES_USER     = local.user
    POSTGRES_PASSWORD = local.password
    POSTGRES_DB       = local.database
  }
  sensitive = true
}

# ========== Database Management Tools Outputs ==========

output "pgweb_enabled" {
  description = "Whether pgweb is enabled"
  value       = local.pgweb_enabled
}

output "pgweb_url" {
  description = "pgweb URL (internal)"
  value       = local.pgweb_enabled ? "http://pgweb:${var.pgweb_port}" : ""
}

output "cloudbeaver_enabled" {
  description = "Whether CloudBeaver is enabled"
  value       = local.cloudbeaver_enabled
}

output "cloudbeaver_url" {
  description = "CloudBeaver URL (internal)"
  value       = local.cloudbeaver_enabled ? "http://cloudbeaver:${var.cloudbeaver_port}" : ""
}

output "mathesar_enabled" {
  description = "Whether Mathesar is enabled"
  value       = local.mathesar_enabled
}

output "mathesar_url" {
  description = "Mathesar URL (internal)"
  value       = local.mathesar_enabled ? "http://mathesar:${var.mathesar_port}" : ""
}

output "pgadmin_enabled" {
  description = "Whether pgAdmin is enabled"
  value       = local.pgadmin_enabled
}

output "pgadmin_url" {
  description = "pgAdmin URL (internal)"
  value       = local.pgadmin_enabled ? "http://pgadmin:80" : ""
}

# ========== Port Forwarding Configuration ==========

output "proxy_specs" {
  description = "Port forwarding specifications for socat in the agent startup script"
  value = concat(
    local.pgweb_enabled ? [{
      name       = "pgweb"
      local_port = var.pgweb_port
      host       = "pgweb"
      rport      = var.pgweb_port
    }] : [],
    local.cloudbeaver_enabled ? [{
      name       = "cloudbeaver"
      local_port = var.cloudbeaver_port
      host       = "cloudbeaver"
      rport      = var.cloudbeaver_port
    }] : [],
    local.mathesar_enabled ? [{
      name       = "mathesar"
      local_port = var.mathesar_port
      host       = "mathesar"
      rport      = var.mathesar_port
    }] : [],
    local.pgadmin_enabled ? [{
      name       = "pgadmin"
      local_port = var.pgadmin_port
      host       = "pgadmin"
      rport      = 80
    }] : []
  )
}
