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
