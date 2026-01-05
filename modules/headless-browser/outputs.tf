output "enabled" {
  description = "Whether the headless browser is enabled"
  value       = local.enabled
}

output "host" {
  description = "Headless browser hostname (empty if disabled)"
  value       = local.host
}

output "browser_port" {
  description = "HTTP port for the browserless UI and API"
  value       = var.browser_port
}

output "browser_url" {
  description = "Browserless UI and API URL (internal)"
  value       = local.enabled ? "http://headless-browser:3000" : ""
}

output "websocket_url" {
  description = "Websocket URL for browser automation (internal)"
  value       = local.enabled ? "ws://headless-browser:3000" : ""
}

output "env_vars" {
  description = "Environment variables for agent or containers"
  value = {
    HEADLESS_BROWSER_ENABLED     = tostring(local.enabled)
    HEADLESS_BROWSER_URL         = local.enabled ? "http://headless-browser:3000" : ""
    HEADLESS_BROWSER_WS_URL      = local.enabled ? "ws://headless-browser:3000" : ""
    BROWSER_WS_ENDPOINT          = local.enabled ? "ws://headless-browser:3000" : "" # For compatibility with some tools
  }
}

# ========== Port Forwarding Configuration ==========

output "proxy_specs" {
  description = "Port forwarding specifications for socat in the agent startup script"
  value = local.enabled ? [{
    name       = "headless-browser"
    local_port = var.browser_port
    host       = "headless-browser"
    rport      = 3000
  }] : []
}

# ========== Standard Module Outputs ==========

output "startup_script" {
  description = "Commands to run during agent startup"
  value       = ""
}

output "install_script" {
  description = "Script to run during image build"
  value       = ""
}

output "packages" {
  description = "System packages required by this module"
  value       = []
}

output "hostnames" {
  description = "Docker container hostnames that need IPv4 resolution"
  value       = local.enabled ? ["headless-browser"] : []
}
