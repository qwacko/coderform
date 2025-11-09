terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
  }
}

# ============================================================================
# Parameters for TUI Agent Selection
# ============================================================================

data "coder_parameter" "claude_code_enabled" {
  name         = "claude_code_enabled"
  display_name = "Install Claude Code"
  description  = "Install Anthropic's Claude Code CLI"
  type         = "bool"
  default      = tostring(var.claude_code_default_enabled)
  mutable      = true
  order        = var.order_offset
}

data "coder_parameter" "opencode_enabled" {
  name         = "opencode_enabled"
  display_name = "Install OpenCode"
  description  = "Install OpenCode AI coding assistant"
  type         = "bool"
  default      = tostring(var.opencode_default_enabled)
  mutable      = true
  order        = var.order_offset + 1
}

data "coder_parameter" "openai_codex_enabled" {
  name         = "openai_codex_enabled"
  display_name = "Install OpenAI Codex"
  description  = "Install OpenAI Codex AI coding assistant"
  type         = "bool"
  default      = tostring(var.openai_codex_default_enabled)
  mutable      = true
  order        = var.order_offset + 2
}

data "coder_parameter" "cursor_enabled" {
  name         = "cursor_enabled"
  display_name = "Install Cursor CLI"
  description  = "Install Cursor AI-first code editor CLI"
  type         = "bool"
  default      = tostring(var.cursor_default_enabled)
  mutable      = true
  order        = var.order_offset + 3
}

# ============================================================================
# Script Generation Logic
# ============================================================================

locals {
  # Read installation scripts
  claude_code_script = file("${path.module}/scripts/claude-code.sh")
  opencode_script    = file("${path.module}/scripts/opencode.sh")
  openai_codex_script = file("${path.module}/scripts/openai-codex.sh")
  cursor_script      = file("${path.module}/scripts/cursor.sh")

  # Get parameter values
  claude_code_enabled = data.coder_parameter.claude_code_enabled.value == "true"
  opencode_enabled    = data.coder_parameter.opencode_enabled.value == "true"
  openai_codex_enabled = data.coder_parameter.openai_codex_enabled.value == "true"
  cursor_enabled      = data.coder_parameter.cursor_enabled.value == "true"

  # Generate installation commands for each enabled TUI agent
  install_commands = [
    local.claude_code_enabled ? "install_claude_code" : "",
    local.opencode_enabled ? "install_opencode" : "",
    local.openai_codex_enabled ? "install_openai_codex" : "",
    local.cursor_enabled ? "install_cursor" : "",
  ]

  # Filter out empty commands
  active_install_commands = [for cmd in local.install_commands : cmd if cmd != ""]

  # Build the complete installation script (when agents are enabled)
  full_install_script = <<-EOT
    #!/bin/bash
    set -e

    echo "🚀 Starting TUI agent installation..."
    echo "Workspace: ${var.workspace_id}"

    # Define TUI agent installation functions
    install_claude_code() {
      ${indent(2, local.claude_code_script)}
    }

    install_opencode() {
      ${indent(2, local.opencode_script)}
    }

    install_openai_codex() {
      ${indent(2, local.openai_codex_script)}
    }

    install_cursor() {
      ${indent(2, local.cursor_script)}
    }

    # Execute installations
    ${join("\n    ", local.active_install_commands)}

    echo "✅ All TUI agents installed successfully!"
  EOT

  # Choose between full script or empty comment
  install_script = length(local.active_install_commands) > 0 ? local.full_install_script : "# No TUI agents selected for installation"

  # Environment variables for TUI agent info
  env_vars = {
    TUI_CLAUDE_CODE_ENABLED = tostring(local.claude_code_enabled)
    TUI_OPENCODE_ENABLED    = tostring(local.opencode_enabled)
    TUI_OPENAI_CODEX_ENABLED = tostring(local.openai_codex_enabled)
    TUI_CURSOR_ENABLED      = tostring(local.cursor_enabled)
  }
}
