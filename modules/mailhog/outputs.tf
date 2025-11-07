output "enabled" {
  description = "Whether MailHog is enabled"
  value       = local.enabled
}

output "smtp_host" {
  description = "SMTP hostname (empty if disabled)"
  value       = local.host
}

output "smtp_port" {
  description = "SMTP port"
  value       = var.smtp_port
}

output "http_port" {
  description = "Web UI port"
  value       = var.http_port
}

output "web_url" {
  description = "MailHog web UI URL (internal)"
  value       = local.enabled ? "http://mailhog:${var.http_port}" : ""
}

output "env_vars" {
  description = "Environment variables for agent or containers"
  value = {
    MAILHOG_ENABLED   = tostring(local.enabled)
    MAILHOG_SMTP_HOST = local.host
    MAILHOG_SMTP_PORT = tostring(var.smtp_port)
    SMTP_HOST         = local.host
    SMTP_PORT         = tostring(var.smtp_port)
  }
}

# ========== Port Forwarding Configuration ==========

output "proxy_specs" {
  description = "Port forwarding specifications for socat in the agent startup script"
  value = local.enabled ? [{
    name       = "mailhog"
    local_port = var.http_port
    host       = "mailhog"
    rport      = var.http_port
  }] : []
}
