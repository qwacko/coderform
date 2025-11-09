output "enabled" {
  description = "Whether MinIO is enabled"
  value       = local.enabled
}

output "host" {
  description = "MinIO hostname (empty if disabled)"
  value       = local.host
}

output "api_port" {
  description = "MinIO API port"
  value       = var.api_port
}

output "console_port" {
  description = "MinIO Console port"
  value       = var.console_port
}

output "root_user" {
  description = "MinIO root user (access key)"
  value       = local.root_user
}

output "root_password" {
  description = "MinIO root password (secret key)"
  value       = local.root_password
  sensitive   = true
}

output "endpoint" {
  description = "MinIO S3 API endpoint"
  value       = local.enabled ? "http://${local.host}:${var.api_port}" : ""
}

output "console_url" {
  description = "MinIO Console URL (internal)"
  value       = local.enabled ? "http://minio:${var.console_port}" : ""
}

output "env_vars" {
  description = "Environment variables for agent or containers"
  value = {
    MINIO_ENABLED        = tostring(local.enabled)
    MINIO_ENDPOINT       = local.enabled ? "http://${local.host}:${var.api_port}" : ""
    MINIO_ROOT_USER      = local.root_user
    MINIO_ROOT_PASSWORD  = local.root_password
    MINIO_ACCESS_KEY     = local.root_user
    MINIO_SECRET_KEY     = local.root_password
    S3_ENDPOINT          = local.enabled ? "http://${local.host}:${var.api_port}" : ""
    S3_ACCESS_KEY_ID     = local.root_user
    S3_SECRET_ACCESS_KEY = local.root_password
  }
  sensitive = true
}

# ========== Port Forwarding Configuration ==========

output "proxy_specs" {
  description = "Port forwarding specifications for socat in the agent startup script"
  value = local.enabled ? [
    {
      name       = "minio-api"
      local_port = var.api_port
      host       = "minio"
      rport      = var.api_port
    },
    {
      name       = "minio-console"
      local_port = var.console_port
      host       = "minio"
      rport      = var.console_port
    }
  ] : []
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
  value       = local.enabled ? ["curl"] : []
}

output "hostnames" {
  description = "Docker container hostnames that need IPv4 resolution"
  value       = local.enabled ? ["minio"] : []
}
