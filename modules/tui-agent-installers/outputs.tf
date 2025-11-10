# ========== Standard Module Outputs ==========

output "enabled" {
  description = "Whether any TUI agents are enabled"
  value       = length(local.active_install_commands) > 0
}

output "env_vars" {
  description = "Environment variables indicating which TUI agents are enabled"
  value       = local.env_vars
}

output "proxy_specs" {
  description = "Port forwarding specifications (not used by this module)"
  value       = []
}

output "startup_script" {
  description = "Commands to run during agent startup to install TUI agents"
  value       = local.startup_script
}

output "install_script" {
  description = "Script to run during image build to install Node.js and npm (agent installation happens at startup)"
  value       = local.install_script
}

output "packages" {
  description = "System packages required by this module"
  value = distinct(concat(
    ["curl", "ca-certificates"],
    length(local.active_install_commands) > 0 ? ["nodejs", "npm"] : [],
    local.cursor_enabled ? ["fuse", "libfuse2"] : []
  ))
}

output "hostnames" {
  description = "Docker container hostnames that need IPv4 resolution"
  value       = []
}

# ========== Module-Specific Outputs ==========

output "agents" {
  description = "List of enabled TUI agents"
  value = compact([
    local.claude_code_enabled ? "claude-code" : "",
    local.opencode_enabled ? "opencode" : "",
    local.openai_codex_enabled ? "openai-codex" : "",
    local.cursor_enabled ? "cursor" : "",
  ])
}

output "agents_summary" {
  description = "Human-readable summary of installed TUI agents"
  value = length(local.active_install_commands) > 0 ? join(", ", compact([
    local.claude_code_enabled ? "Claude Code" : "",
    local.opencode_enabled ? "OpenCode" : "",
    local.openai_codex_enabled ? "OpenAI Codex" : "",
    local.cursor_enabled ? "Cursor CLI" : "",
  ])) : "None"
}
