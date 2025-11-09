# ========== Standard Module Outputs ==========

output "enabled" {
  description = "Whether any runtimes are enabled"
  value       = length(local.active_install_commands) > 0
}

output "env_vars" {
  description = "Environment variables indicating which runtimes are enabled"
  value       = local.env_vars
}

output "proxy_specs" {
  description = "Port forwarding specifications (not used by this module)"
  value       = []
}

output "startup_script" {
  description = "Commands to run during agent startup (not used by this module)"
  value       = ""
}

output "install_script" {
  description = "Script to run during image build to install selected runtimes"
  value       = local.install_script
}

output "packages" {
  description = "System packages required by this module"
  value       = ["curl", "ca-certificates", "gnupg", "build-essential", "git"]
}

output "hostnames" {
  description = "Docker container hostnames that need IPv4 resolution"
  value       = []
}

# ========== Module-Specific Outputs ==========

output "runtimes" {
  description = "List of enabled runtimes"
  value = compact([
    local.nodejs_enabled ? "nodejs-${local.nodejs_version}" : "",
    local.python_enabled ? "python-${local.python_version}" : "",
    local.go_enabled ? "go-${local.go_version}" : "",
    local.bun_enabled ? "bun" : "",
    local.rust_enabled ? "rust-${local.rust_channel}" : "",
  ])
}
