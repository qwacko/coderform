output "enabled" {
  description = "Whether Hoppscotch is enabled"
  value       = local.enabled
}

output "host" {
  description = "Hoppscotch hostname (empty if disabled)"
  value       = local.host
}

output "http_port" {
  description = "Web UI port"
  value       = var.http_port
}

output "web_url" {
  description = "Hoppscotch web UI URL (internal)"
  value       = local.enabled ? "http://hoppscotch:${var.http_port}" : ""
}

output "env_vars" {
  description = "Environment variables for agent or containers"
  value = {
    HOPPSCOTCH_ENABLED = tostring(local.enabled)
    HOPPSCOTCH_URL     = local.enabled ? "http://hoppscotch:${var.http_port}" : ""
  }
}

# ========== Port Forwarding Configuration ==========

output "proxy_specs" {
  description = "Port forwarding specifications for socat in the agent startup script"
  value = local.enabled ? [{
    name       = "hoppscotch"
    local_port = var.http_port
    host       = "hoppscotch"
    rport      = var.http_port
  }] : []
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
  value       = local.enabled ? ["hoppscotch"] : []
}
