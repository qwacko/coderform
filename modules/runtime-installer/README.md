# Runtime Installer Module

A Terraform module that generates dynamic installation scripts for development runtimes (Node.js, Python, Go, Bun, Rust) in Coder workspaces. Runtimes are installed during workspace startup, not baked into Docker images.

## Why This Approach?

**Problem**: Examples can't be modules (they need Dockerfile build context), but you want module-style updateability for runtime installations.

**Solution**: This module generates installation scripts that run during agent startup. Updates are pulled automatically from the module repository on each workspace rebuild.

## Features

- **Module-based Updates**: Update runtime installers by changing the module version
- **User Selection**: Users choose which runtimes to install via Coder parameters
- **Smart Caching**: Checks if runtime already installed to avoid reinstallation
- **Version Pinning**: Select specific versions (Node 20, Python 3.12, etc.)
- **Mutable Parameters**: Change runtime versions without recreating workspace
- **Lightweight Images**: Base Docker image stays small

## Supported Runtimes

| Runtime | Versions | Package Managers | Notes |
|---------|----------|------------------|-------|
| Node.js | 18, 20, 22 | npm, yarn, pnpm, both | Installed via NodeSource |
| Python  | 3.10, 3.11, 3.12 | pip, poetry, pipenv, uv, both | Installed via deadsnakes PPA |
| Go      | 1.21.6, 1.22.0 | - | Official binaries |
| Bun     | latest | - | Installed via official installer |
| Rust    | stable, nightly, beta | - | Installed via rustup |

### Package Managers

**Node.js:**
- **npm** - Included by default with Node.js
- **yarn** - Installed via Corepack (modern Yarn Berry)
- **pnpm** - Fast, disk space efficient package manager
- **both** - Installs both yarn and pnpm

**Python:**
- **pip** - Included by default with Python
- **poetry** - Modern dependency management and packaging
- **pipenv** - Virtual environment and package management
- **uv** - Extremely fast pip alternative from Astral (creators of Ruff)
- **both** - Installs both poetry and uv

## Usage

### Basic Example

```hcl
module "runtime_installer" {
  source = "github.com/yourusername/coderform//modules/runtime-installer?ref=v1.0.0"

  workspace_id = data.coder_workspace.me.id
  order_offset = 100

  # Optional: Set default package managers
  nodejs_default_package_manager = "pnpm"
  python_default_package_manager = "uv"
}

resource "coder_agent" "main" {
  # ... other config ...

  startup_script = <<-EOT
    #!/bin/bash
    set -e

    # Install selected runtimes
    ${module.runtime_installer.install_script}

    # Rest of your startup script...
    echo "Workspace ready!"
  EOT
}
```

### With Environment Variables

```hcl
resource "docker_container" "workspace" {
  # ... other config ...

  env = concat(
    ["CODER_AGENT_TOKEN=${coder_agent.main.token}"],
    [for k, v in module.runtime_installer.env_vars : "${k}=${v}"]
  )
}
```

### Conditional Logic Based on Runtimes

```hcl
resource "coder_app" "jupyter" {
  count = module.runtime_installer.env_vars["RUNTIME_PYTHON_ENABLED"] == "true" ? 1 : 0

  agent_id     = coder_agent.main.id
  display_name = "Jupyter Lab"
  # ... other config ...
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| workspace_id | The ID of the Coder workspace | string | - | yes |
| order_offset | Starting order number for parameters | number | 100 | no |
| nodejs_default_package_manager | Default Node.js package manager | string | "npm" | no |
| python_default_package_manager | Default Python package manager | string | "pip" | no |

## Outputs

| Name | Description |
|------|-------------|
| install_script | Shell script to install selected runtimes and package managers (inject into agent startup_script) |
| env_vars | Map of environment variables indicating enabled runtimes, versions, and package managers |
| enabled | Boolean indicating if any runtimes are enabled |
| runtimes | List of enabled runtime strings with package managers (e.g., "nodejs-20 (pnpm)", "python-3.12 (uv)") |
| package_managers | Map of package managers installed for each runtime (nodejs, python) |

## How It Works

### 1. Parameter Generation

The module creates Coder parameters for runtime selection:

- `nodejs_enabled` (bool)
- `nodejs_version` (string, conditional on nodejs_enabled)
- `nodejs_package_manager` (string, conditional on nodejs_enabled)
- `python_enabled` (bool)
- `python_version` (string, conditional on python_enabled)
- `python_package_manager` (string, conditional on python_enabled)
- ... etc for each runtime

### 2. Script Compilation

Based on selected parameters, the module:

1. Reads installation scripts from `scripts/` directory
2. Generates function definitions for each runtime
3. Creates execution commands for enabled runtimes
4. Combines into a single bash script

### 3. Startup Execution

The generated script is injected into the agent's `startup_script`, where it:

1. Updates apt package lists
2. Defines installation functions
3. Executes each enabled runtime's installer
4. Each installer checks if already present (for speed on rebuilds)

### 4. Caching Behavior

Each installation script includes smart caching:

```bash
# Example from nodejs.sh
if command -v node &> /dev/null; then
    CURRENT_VERSION=$(node --version | sed 's/v//' | cut -d. -f1)
    if [ "$CURRENT_VERSION" = "$VERSION" ]; then
        echo "✅ Node.js ${VERSION} already installed"
        return 0
    fi
fi
```

This means rebuilding a workspace with the same runtimes is fast!

## Installation Scripts

Individual scripts are located in `scripts/`:

**Runtimes:**
- `nodejs.sh` - Node.js via NodeSource
- `python.sh` - Python via deadsnakes PPA
- `go.sh` - Go official binaries
- `bun.sh` - Bun official installer
- `rust.sh` - Rust via rustup

**Package Managers:**
- `yarn.sh` - Yarn via Corepack or npm
- `pnpm.sh` - pnpm via npm
- `poetry.sh` - Poetry via official installer
- `pipenv.sh` - Pipenv via pip
- `uv.sh` - uv via official installer

Each script:
- Accepts version/channel as first argument (where applicable)
- Checks if already installed
- Installs via official/recommended method
- Adds to PATH (in ~/.bashrc if needed)
- Verifies successful installation

## Docker Image Requirements

Your base Dockerfile must include:

```dockerfile
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    ca-certificates \
    software-properties-common \
    sudo \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash coder && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/coder

USER coder
```

**Why these dependencies?**
- `curl`, `wget`: Download installers
- `build-essential`: Compiling native modules
- `software-properties-common`: Adding PPAs (for Python)
- `sudo`: Runtime installers need sudo access
- `ca-certificates`: HTTPS downloads

## Environment Variables

The module outputs these environment variables:

```bash
RUNTIME_NODEJS_ENABLED=true|false
RUNTIME_NODEJS_VERSION=20                  # (if enabled)
RUNTIME_NODEJS_PACKAGE_MANAGER=pnpm        # (if enabled)
RUNTIME_PYTHON_ENABLED=true|false
RUNTIME_PYTHON_VERSION=3.12                # (if enabled)
RUNTIME_PYTHON_PACKAGE_MANAGER=uv          # (if enabled)
RUNTIME_GO_ENABLED=true|false
RUNTIME_GO_VERSION=1.22.0                  # (if enabled)
RUNTIME_BUN_ENABLED=true|false
RUNTIME_RUST_ENABLED=true|false
RUNTIME_RUST_CHANNEL=stable                # (if enabled)
```

Use these in scripts or to conditionally create Coder apps.

## Performance

**Startup Time Impact**:

| Runtime | First Install | Cached (already installed) |
|---------|---------------|----------------------------|
| Node.js | ~30 seconds | <1 second |
| Python  | ~1-2 minutes | <1 second |
| Go      | ~30 seconds | <1 second |
| Bun     | ~10 seconds | <1 second |
| Rust    | ~2-3 minutes | <1 second |

**Tips**:
- Use `startup_script_behavior = "blocking"` to ensure runtimes install before user connects
- Consider pre-building images with runtimes if startup time is critical
- Caching makes rebuilds fast - only first start is slow

## Updating the Module

### For Module Maintainers

To add a new runtime:

1. Create `scripts/newruntime.sh`:
   ```bash
   #!/bin/bash
   VERSION="${1:-default}"
   # ... installation logic
   ```

2. Add parameters in `main.tf`:
   ```hcl
   data "coder_parameter" "newruntime_enabled" {
     # ... config
   }
   ```

3. Add to `locals` in `main.tf`:
   ```hcl
   locals {
     newruntime_enabled = data.coder_parameter.newruntime_enabled.value == "true"
     install_commands = [
       # ... existing commands
       local.newruntime_enabled ? "install_newruntime ${local.newruntime_version}" : "",
     ]
   }
   ```

4. Bump module version and push

### For Workspace Users

Update your workspace template:

```hcl
module "runtime_installer" {
  source = "github.com/yourusername/coderform//modules/runtime-installer?ref=v1.1.0"  # Updated version
  # ... same config
}
```

Rebuild workspace to pull new runtime options.

## Examples

See the complete example in `/examples/polyglot/`

## Alternatives Considered

### Approach 1: Pre-built Images
**Rejected**: Requires image registry, slow to update, large images

### Approach 2: Dockerfile Generator Module
**Considered**: Generates Dockerfile content, but still requires rebuilding image for updates

### Approach 3: Features Directory
**Considered**: Not versionable independently

### Approach 4: Startup Script (this module) ✅
**Selected**: Module-versionable, transparent, flexible, cached

## Troubleshooting

### Runtime not in PATH

Some runtimes modify `~/.bashrc`. Start a new shell:

```bash
exec bash -l
```

Or source it:

```bash
source ~/.bashrc
```

### Installation fails

Check agent startup logs:

```bash
# In Coder workspace
cat /tmp/coder-startup-script.log
```

### Sudo password required

Ensure your Dockerfile includes:

```dockerfile
RUN echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/coder
```

## License

MIT
