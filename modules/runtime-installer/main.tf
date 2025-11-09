terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
  }
}

# ============================================================================
# Parameters for Runtime Selection
# ============================================================================

data "coder_parameter" "nodejs_enabled" {
  name         = "nodejs_enabled"
  display_name = "Install Node.js"
  description  = "Install Node.js runtime"
  type         = "bool"
  default      = "false"
  mutable      = true
  order        = var.order_offset
}

data "coder_parameter" "nodejs_version" {
  count        = data.coder_parameter.nodejs_enabled.value == "true" ? 1 : 0
  name         = "nodejs_version"
  display_name = "Node.js Version"
  description  = "Node.js major version to install"
  type         = "string"
  default      = "20"
  mutable      = true
  order        = var.order_offset + 1

  option {
    name  = "Node.js 20 (LTS)"
    value = "20"
  }
  option {
    name  = "Node.js 18 (LTS)"
    value = "18"
  }
  option {
    name  = "Node.js 22 (Current)"
    value = "22"
  }
}

data "coder_parameter" "nodejs_package_manager" {
  count        = data.coder_parameter.nodejs_enabled.value == "true" ? 1 : 0
  name         = "nodejs_package_manager"
  display_name = "Node.js Package Manager"
  description  = "Package manager to install for Node.js (npm is included by default)"
  type         = "string"
  default      = var.nodejs_default_package_manager
  mutable      = true
  order        = var.order_offset + 2

  option {
    name  = "npm (default)"
    value = "npm"
  }
  option {
    name  = "Yarn"
    value = "yarn"
  }
  option {
    name  = "pnpm"
    value = "pnpm"
  }
  option {
    name  = "Yarn + pnpm"
    value = "both"
  }
}

data "coder_parameter" "python_enabled" {
  name         = "python_enabled"
  display_name = "Install Python"
  description  = "Install Python runtime"
  type         = "bool"
  default      = "false"
  mutable      = true
  order        = var.order_offset + 3
}

data "coder_parameter" "python_version" {
  count        = data.coder_parameter.python_enabled.value == "true" ? 1 : 0
  name         = "python_version"
  display_name = "Python Version"
  description  = "Python version to install"
  type         = "string"
  default      = "3.12"
  mutable      = true
  order        = var.order_offset + 4

  option {
    name  = "Python 3.12"
    value = "3.12"
  }
  option {
    name  = "Python 3.11"
    value = "3.11"
  }
  option {
    name  = "Python 3.10"
    value = "3.10"
  }
}

data "coder_parameter" "python_package_manager" {
  count        = data.coder_parameter.python_enabled.value == "true" ? 1 : 0
  name         = "python_package_manager"
  display_name = "Python Package Manager"
  description  = "Package manager to install for Python (pip is included by default)"
  type         = "string"
  default      = var.python_default_package_manager
  mutable      = true
  order        = var.order_offset + 5

  option {
    name  = "pip (default)"
    value = "pip"
  }
  option {
    name  = "Poetry"
    value = "poetry"
  }
  option {
    name  = "Pipenv"
    value = "pipenv"
  }
  option {
    name  = "uv (fast pip alternative)"
    value = "uv"
  }
  option {
    name  = "Poetry + uv"
    value = "both"
  }
}

data "coder_parameter" "go_enabled" {
  name         = "go_enabled"
  display_name = "Install Go"
  description  = "Install Go runtime"
  type         = "bool"
  default      = "false"
  mutable      = true
  order        = var.order_offset + 6
}

data "coder_parameter" "go_version" {
  count        = data.coder_parameter.go_enabled.value == "true" ? 1 : 0
  name         = "go_version"
  display_name = "Go Version"
  description  = "Go version to install"
  type         = "string"
  default      = "1.22.0"
  mutable      = true
  order        = var.order_offset + 7

  option {
    name  = "Go 1.22"
    value = "1.22.0"
  }
  option {
    name  = "Go 1.21"
    value = "1.21.6"
  }
}

data "coder_parameter" "bun_enabled" {
  name         = "bun_enabled"
  display_name = "Install Bun"
  description  = "Install Bun runtime"
  type         = "bool"
  default      = "false"
  mutable      = true
  order        = var.order_offset + 8
}

data "coder_parameter" "rust_enabled" {
  name         = "rust_enabled"
  display_name = "Install Rust"
  description  = "Install Rust toolchain"
  type         = "bool"
  default      = "false"
  mutable      = true
  order        = var.order_offset + 9
}

data "coder_parameter" "rust_channel" {
  count        = data.coder_parameter.rust_enabled.value == "true" ? 1 : 0
  name         = "rust_channel"
  display_name = "Rust Channel"
  description  = "Rust release channel"
  type         = "string"
  default      = "stable"
  mutable      = true
  order        = var.order_offset + 10

  option {
    name  = "Stable"
    value = "stable"
  }
  option {
    name  = "Nightly"
    value = "nightly"
  }
  option {
    name  = "Beta"
    value = "beta"
  }
}

# ============================================================================
# Script Generation Logic
# ============================================================================

locals {
  # Read installation scripts
  nodejs_script = file("${path.module}/scripts/nodejs.sh")
  python_script = file("${path.module}/scripts/python.sh")
  go_script     = file("${path.module}/scripts/go.sh")
  bun_script    = file("${path.module}/scripts/bun.sh")
  rust_script   = file("${path.module}/scripts/rust.sh")

  # Package manager scripts
  yarn_script   = file("${path.module}/scripts/yarn.sh")
  pnpm_script   = file("${path.module}/scripts/pnpm.sh")
  poetry_script = file("${path.module}/scripts/poetry.sh")
  pipenv_script = file("${path.module}/scripts/pipenv.sh")
  uv_script     = file("${path.module}/scripts/uv.sh")

  # Get parameter values (with defaults for conditional parameters)
  nodejs_enabled         = data.coder_parameter.nodejs_enabled.value == "true"
  nodejs_version         = local.nodejs_enabled ? data.coder_parameter.nodejs_version[0].value : ""
  nodejs_package_manager = local.nodejs_enabled ? data.coder_parameter.nodejs_package_manager[0].value : ""

  python_enabled         = data.coder_parameter.python_enabled.value == "true"
  python_version         = local.python_enabled ? data.coder_parameter.python_version[0].value : ""
  python_package_manager = local.python_enabled ? data.coder_parameter.python_package_manager[0].value : ""

  go_enabled = data.coder_parameter.go_enabled.value == "true"
  go_version = local.go_enabled ? data.coder_parameter.go_version[0].value : ""

  bun_enabled = data.coder_parameter.bun_enabled.value == "true"

  rust_enabled = data.coder_parameter.rust_enabled.value == "true"
  rust_channel = local.rust_enabled ? data.coder_parameter.rust_channel[0].value : ""

  # Generate installation commands for each enabled runtime and package manager
  install_commands = concat(
    # Runtime installations
    [
      local.nodejs_enabled ? "install_nodejs ${local.nodejs_version}" : "",
      local.python_enabled ? "install_python ${local.python_version}" : "",
      local.go_enabled ? "install_go ${local.go_version}" : "",
      local.bun_enabled ? "install_bun latest" : "",
      local.rust_enabled ? "install_rust ${local.rust_channel}" : "",
    ],
    # Node.js package manager installations
    [
      local.nodejs_enabled && contains(["yarn", "both"], local.nodejs_package_manager) ? "install_yarn" : "",
      local.nodejs_enabled && contains(["pnpm", "both"], local.nodejs_package_manager) ? "install_pnpm" : "",
    ],
    # Python package manager installations
    [
      local.python_enabled && contains(["poetry", "both"], local.python_package_manager) ? "install_poetry" : "",
      local.python_enabled && local.python_package_manager == "pipenv" ? "install_pipenv" : "",
      local.python_enabled && contains(["uv", "both"], local.python_package_manager) ? "install_uv" : "",
    ]
  )

  # Filter out empty commands
  active_install_commands = [for cmd in local.install_commands : cmd if cmd != ""]

  # Build the complete installation script (when runtimes are enabled)
  full_install_script = <<-EOT
    #!/bin/bash
    set -e

    echo "🚀 Starting runtime installation..."
    echo "Workspace: ${var.workspace_id}"

    # Update package lists once
    sudo apt-get update -qq

    # Define runtime installation functions
    install_nodejs() {
      ${indent(2, local.nodejs_script)}
    }

    install_python() {
      ${indent(2, local.python_script)}
    }

    install_go() {
      ${indent(2, local.go_script)}
    }

    install_bun() {
      ${indent(2, local.bun_script)}
    }

    install_rust() {
      ${indent(2, local.rust_script)}
    }

    # Define package manager installation functions
    install_yarn() {
      ${indent(2, local.yarn_script)}
    }

    install_pnpm() {
      ${indent(2, local.pnpm_script)}
    }

    install_poetry() {
      ${indent(2, local.poetry_script)}
    }

    install_pipenv() {
      ${indent(2, local.pipenv_script)}
    }

    install_uv() {
      ${indent(2, local.uv_script)}
    }

    # Execute installations
    ${join("\n    ", local.active_install_commands)}

    echo "✅ All runtimes and package managers installed successfully!"
  EOT

  # Choose between full script or empty comment
  install_script = length(local.active_install_commands) > 0 ? local.full_install_script : "# No runtimes selected for installation"

  # Environment variables for runtime info
  env_vars = {
    RUNTIME_NODEJS_ENABLED         = tostring(local.nodejs_enabled)
    RUNTIME_NODEJS_VERSION         = local.nodejs_version
    RUNTIME_NODEJS_PACKAGE_MANAGER = local.nodejs_package_manager
    RUNTIME_PYTHON_ENABLED         = tostring(local.python_enabled)
    RUNTIME_PYTHON_VERSION         = local.python_version
    RUNTIME_PYTHON_PACKAGE_MANAGER = local.python_package_manager
    RUNTIME_GO_ENABLED             = tostring(local.go_enabled)
    RUNTIME_GO_VERSION             = local.go_version
    RUNTIME_BUN_ENABLED            = tostring(local.bun_enabled)
    RUNTIME_RUST_ENABLED           = tostring(local.rust_enabled)
    RUNTIME_RUST_CHANNEL           = local.rust_channel
  }
}
