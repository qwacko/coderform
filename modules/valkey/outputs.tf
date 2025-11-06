output "enabled" {
  description = "Whether Valkey is enabled"
  value       = local.enabled
}

output "host" {
  description = "Valkey hostname (empty if disabled)"
  value       = local.host
}

output "password" {
  description = "Valkey password (empty if no auth)"
  value       = local.password
  sensitive   = true
}

output "version" {
  description = "Valkey version tag"
  value       = local.version
}

output "port" {
  description = "Valkey port (always 6379)"
  value       = 6379
}

output "connection_string" {
  description = "Connection string for Valkey"
  value       = local.enabled ? (length(local.password) > 0 ? "redis://:${local.password}@${local.host}:6379" : "redis://${local.host}:6379") : ""
  sensitive   = true
}

output "env_vars" {
  description = "Environment variables for agent or containers"
  value = {
    VALKEY_ENABLED  = tostring(local.enabled)
    VALKEY_HOST     = local.host
    VALKEY_PASSWORD = local.password
    VALKEY_PORT     = "6379"
  }
  sensitive = true
}
