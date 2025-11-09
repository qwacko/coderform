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

# ========== Redis Management Tools Outputs ==========

output "redis_commander_enabled" {
  description = "Whether redis-commander is enabled"
  value       = local.redis_commander_enabled
}

output "redis_commander_url" {
  description = "redis-commander URL (internal)"
  value       = local.redis_commander_enabled ? "http://redis-commander:${var.redis_commander_port}" : ""
}

output "redisinsight_enabled" {
  description = "Whether RedisInsight is enabled"
  value       = local.redisinsight_enabled
}

output "redisinsight_url" {
  description = "RedisInsight URL (internal)"
  value       = local.redisinsight_enabled ? "http://redisinsight:${var.redisinsight_port}" : ""
}

# ========== Port Forwarding Configuration ==========

output "proxy_specs" {
  description = "Port forwarding specifications for socat in the agent startup script"
  value = concat(
    local.redis_commander_enabled ? [{
      name       = "redis-commander"
      local_port = var.redis_commander_port
      host       = "redis-commander"
      rport      = var.redis_commander_port
    }] : [],
    local.redisinsight_enabled ? [{
      name       = "redisinsight"
      local_port = var.redisinsight_port
      host       = "redisinsight"
      rport      = var.redisinsight_port
    }] : []
  )
}

# ========== Standard Module Outputs ==========

output "startup_script" {
  description = "Commands to run during agent startup"
  value       = local.enabled ? local.startup_script_raw : ""
}

output "install_script" {
  description = "Script to run during image build"
  value       = ""
}

output "packages" {
  description = "System packages required by this module"
  value       = local.enabled ? ["redis-tools"] : []
}

output "hostnames" {
  description = "Docker container hostnames that need IPv4 resolution"
  value = compact([
    local.enabled ? "valkey" : "",
    local.redis_commander_enabled ? "redis-commander" : "",
    local.redisinsight_enabled ? "redisinsight" : ""
  ])
}
