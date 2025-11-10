# TUI Agent Installers Module

Terraform module for installing popular TUI (Terminal User Interface) agents and AI coding assistants in Coder workspaces.

## Features

- **Claude Code**: Anthropic's official CLI for interacting with Claude
- **OpenCode**: AI coding assistant with advanced capabilities
- **OpenAI Codex**: OpenAI's AI coding assistant
- **Cursor CLI**: Command-line tools for the Cursor AI-first code editor

## Usage

```hcl
module "tui_agent_installers" {
  source = "github.com/qwacko/coderform//modules/tui-agent-installers"

  workspace_id = data.coder_workspace.me.id
  order_offset = 200

  # Optional: Set default enabled state for each agent
  claude_code_default_enabled = false
  opencode_default_enabled    = false
  openai_codex_default_enabled = false
  cursor_default_enabled      = false
}
```

## Requirements

- **All TUI agents**: Automatically ensures Node.js is available before installation
  - Checks if any version of Node.js is installed
  - If not found, installs Node.js 24.x LTS from NodeSource
  - Installation happens before any TUI agents are installed
  - Includes both Node.js and npm system packages as fallback
- **Claude Code**: Standalone installation via official installer script
- **OpenCode**: Standalone installation via official installer script
- **OpenAI Codex**: Uses npm for installation
- **Cursor CLI**: Standalone installation (downloads AppImage), requires fuse and libfuse2

## Standard Module Outputs

This module implements the 7 standard outputs required for composition:

1. **enabled** (bool) - Whether any TUI agents are enabled
2. **env_vars** (map) - Environment variables indicating which agents are installed
3. **proxy_specs** (array) - Port forwarding specifications (empty for this module)
4. **startup_script** (string) - Commands to run during agent startup (empty for this module)
5. **install_script** (string) - Script to run during Docker image build
6. **packages** (array) - System packages required by enabled agents
7. **hostnames** (array) - Docker container hostnames (empty for this module)

## Module-Specific Outputs

- **agents** - List of enabled TUI agent names
- **agents_summary** - Human-readable summary of installed agents

## Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| workspace_id | The ID of the Coder workspace | string | (required) |
| order_offset | Starting order number for parameters | number | 100 |
| claude_code_default_enabled | Default state for Claude Code | bool | false |
| opencode_default_enabled | Default state for OpenCode | bool | false |
| openai_codex_default_enabled | Default state for OpenAI Codex | bool | false |
| cursor_default_enabled | Default state for Cursor CLI | bool | false |

## Integration Example

```hcl
# In your workspace template main.tf

module "runtime_installer" {
  source = "github.com/qwacko/coderform//modules/runtime-installer"

  workspace_id = local.workspace_id
  order_offset = 100
}

module "tui_agent_installers" {
  source = "github.com/qwacko/coderform//modules/tui-agent-installers"

  workspace_id = local.workspace_id
  order_offset = 200
}

# Combine all module outputs
locals {
  all_packages = distinct(concat(
    module.runtime_installer.packages,
    module.tui_agent_installers.packages
  ))

  combined_install_script = join("\n\n", compact([
    module.runtime_installer.install_script,
    module.tui_agent_installers.install_script
  ]))
}
```

## Notes

- All agents are installed during the Docker image build phase (via `install_script`)
- **Node.js installation flow**:
  1. Node.js and npm packages are included via apt for base installation
  2. Before TUI agent installation, the script checks if Node.js is available
  3. If no Node.js version is found, installs Node.js 24.x LTS from NodeSource
  4. TUI agents only install if Node.js is successfully available
- Claude Code, OpenCode, and Cursor use standalone installer scripts
- OpenAI Codex requires npm for installation
- Cursor CLI requires fuse and libfuse2 system packages
- Installation scripts check for existing installations to avoid reinstalling
- All scripts follow a consistent pattern with version checking and installation verification
- The `ensure-nodejs.sh` script accepts any existing Node.js version and only installs if missing
