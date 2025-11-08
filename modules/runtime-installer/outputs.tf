output "install_script" {
  description = "Shell script to install selected runtimes (run during agent startup)"
  value       = local.install_script
}

output "env_vars" {
  description = "Environment variables indicating which runtimes are enabled"
  value       = local.env_vars
}

output "enabled" {
  description = "Whether any runtimes are enabled"
  value       = length(local.active_install_commands) > 0
}

output "runtimes" {
  description = "List of enabled runtimes"
  value = [
    local.nodejs_enabled ? "nodejs-${local.nodejs_version}" : "",
    local.python_enabled ? "python-${local.python_version}" : "",
    local.go_enabled ? "go-${local.go_version}" : "",
    local.bun_enabled ? "bun" : "",
    local.rust_enabled ? "rust-${local.rust_channel}" : "",
  ]
}
