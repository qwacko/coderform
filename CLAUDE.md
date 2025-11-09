# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**coderform** is a collection of Terraform modules for provisioning Coder workspaces with reusable infrastructure components like PostgreSQL, Valkey (Redis), and port management. The project is split into:

- **Modules** (`modules/`): Reusable Terraform modules that can be imported via `source`
- **Examples** (`examples/`): Complete workspace templates with Dockerfiles meant to be copied and customized

## Development Commands

### Terraform Operations

```bash
# Format Terraform files
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan changes (in examples directory)
cd examples/nodejs
terraform plan

# Apply changes (when developing/testing)
terraform apply
```

### Testing Modules Locally

When testing modules locally during development, use a local path instead of GitHub source:

```hcl
module "postgres" {
  source = "../../modules/postgres"  # Local path for testing
  # ... rest of configuration
}
```

## Architecture

### Module System

Modules are **reusable components** that:
- Accept standardized inputs (agent_id, workspace_id, etc.)
- Create Docker containers/volumes for services
- **Output 7 standard outputs for composition** (see Standard Outputs below)
- Optionally output service-specific connection details

### Standard Module Outputs

**Every module must implement these 7 outputs** to enable composition in workspace templates:

1. **enabled** (bool) - Whether the module is active
2. **env_vars** (map) - Environment variables to merge into the agent
3. **proxy_specs** (array) - Port forwarding specifications for socat
4. **startup_script** (string) - Commands to run during agent startup
5. **install_script** (string) - Script to run during Docker image build
6. **packages** (array) - System packages to install in the base image
7. **hostnames** (array) - Docker container hostnames that need IPv4 resolution

These outputs are combined in the workspace template's `locals` block and applied to:
- Docker image build args (packages)
- Dockerfile RUN commands (install_script)
- Agent startup_script (startup_script + proxy_specs + hostnames)
- Agent environment variables (env_vars)

### Port Forwarding Pattern (`proxy_specs`)

Several modules output a `proxy_specs` array that enables port forwarding from localhost to Docker containers:

```hcl
output "proxy_specs" {
  value = [
    {
      name       = "service-name"
      local_port = 8080
      host       = "container-hostname"
      rport      = 8080
    }
  ]
}
```

This output must be consumed in the agent startup script using `jq` and `socat` to set up the forwarding. See examples/nodejs/main.tf for the standard implementation pattern.

### Docker Networking

All services use an **internal Docker bridge network** for inter-container communication:
- Internal network: `coder-{workspace_id}-network` (isolated, IPv6 disabled)
- Services are accessible via hostname aliases (e.g., `postgres`, `valkey`)
- IPv6 is disabled to prevent DNS resolution issues

### Data Persistence

All modules use Docker volumes with `lifecycle { ignore_changes = all }` to ensure data persists across workspace rebuilds. Volume naming pattern: `coder-{workspace_id}-{service}data`

## Key Files

### Module Structure

Each module follows this structure:
```
modules/{name}/
├── main.tf       # Resources and data sources
├── variables.tf  # Input variables
├── outputs.tf    # Output values
└── README.md     # Module documentation
```

### Example Structure

Examples are complete templates, not modules:
```
examples/{name}/
├── main.tf           # Complete workspace configuration
├── build/
│   └── Dockerfile    # Workspace container image
└── README.md         # Usage instructions
```

## Module Development Guidelines

### Creating a New Module

1. **Parameters**: Use `coder_parameter` data sources for user-configurable options
   - Use `order` parameter to control UI display order
   - Use `mutable = true` for runtime changes
   - Group related parameters with sequential order values

2. **Docker Resources**:
   - Always attach containers to `var.internal_network_name`
   - Use network `aliases` for hostname resolution
   - Add standard labels: `coder.owner`, `coder.workspace_id`, `coder.workspace_name`

3. **Volumes**:
   - Name pattern: `coder-{workspace_id}-{purpose}`
   - Always use `lifecycle { ignore_changes = all }` for data persistence
   - Add the same standard labels as containers

4. **Standard Outputs** (REQUIRED):
   Every module MUST implement these 7 outputs for composition:

   - `enabled` (bool) - Whether the module/service is active
   - `env_vars` (map, sensitive) - Environment variables to merge into agent
   - `proxy_specs` (array) - Port forwarding specs (empty array if not needed)
   - `startup_script` (string) - Commands to run during agent startup (empty if not needed)
   - `install_script` (string) - Script to run during Docker build (empty if not needed)
   - `packages` (array of strings) - System packages required (empty array if none)
   - `hostnames` (array of strings) - Docker container hostnames for IPv4 resolution (empty array if none)

5. **Module-Specific Outputs** (optional):
   - Service connection details (host, port, password, etc.)
   - Service-specific URLs or configuration
   - Mark sensitive outputs with `sensitive = true`

### Standard Required Variables

All modules should accept:
```hcl
variable "agent_id" {}              # For coder_app resources
variable "workspace_id" {}          # For resource naming
variable "workspace_name" {}        # For labels
variable "username" {}              # For labels
variable "owner_id" {}              # For labels
variable "repository" {}            # For labels
variable "internal_network_name" {} # For Docker networking
variable "order_offset" {}          # For parameter ordering
```

### IMPORTANT: Heredoc in Ternary Limitation

**HCL cannot parse heredocs inside ternary operators.** This will cause parsing errors:

```hcl
# ❌ BROKEN - Do not use heredoc inside ternary
output "startup_script" {
  value = local.enabled ? <<-EOT
    echo "content"
  EOT : ""
}
```

**Solution:** Define the heredoc in a local variable first, then use it in the ternary:

```hcl
# ✅ CORRECT - Define heredoc separately
locals {
  startup_script_raw = <<-EOT
    echo "content"
  EOT
}

output "startup_script" {
  value = local.enabled ? local.startup_script_raw : ""
}
```

This pattern **must be used** for all standard outputs that contain heredocs (`startup_script`, `install_script`, etc.).

### Standard Outputs Examples

All modules must implement the 7 standard outputs. Here are examples:

```hcl
# In main.tf locals block - define heredoc separately
locals {
  enabled = data.coder_parameter.enable_service.value

  # Define startup script heredoc here (not in output!)
  startup_script_raw = <<-EOT
    echo "Waiting for service..."
    until curl -sf http://service:8080 >/dev/null 2>&1; do
      sleep 1
    done
    echo "✅ Service is ready"
  EOT
}

# In outputs.tf
# ========== Standard Module Outputs ==========

output "enabled" {
  description = "Whether this module is enabled"
  value       = local.enabled
}

output "env_vars" {
  description = "Environment variables for agent or containers"
  value = {
    SERVICE_ENABLED  = tostring(local.enabled)
    SERVICE_HOST     = local.enabled ? "hostname" : ""
    SERVICE_PORT     = "1234"
  }
  sensitive = true
}

output "proxy_specs" {
  description = "Port forwarding specifications"
  value = local.enabled ? [{
    name       = "service-name"
    local_port = 8080
    host       = "service-hostname"
    rport      = 8080
  }] : []
}

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
  value       = local.enabled ? ["curl", "some-client"] : []
}

output "hostnames" {
  description = "Docker container hostnames that need IPv4 resolution"
  value = local.enabled ? ["service-hostname"] : []
}
```

## Testing and Validation

### Before Committing Changes

1. Run `terraform fmt -recursive` to format all files
2. Validate each module: `cd modules/<name> && terraform validate`
3. Test with a local example workspace
4. Update module README.md if adding/changing variables or outputs

### Testing Port Forwarding

When developing modules with `proxy_specs`:

1. Ensure workspace Dockerfile has `jq` and `socat` installed
2. Verify containers are on the same network: `docker network inspect coder-{workspace_id}-network`
3. Check if socat is running: `ps aux | grep socat`
4. Check proxy logs: `cat /tmp/proxy-{service}.log`
5. Test connectivity: `curl -v http://localhost:{port}`

## Common Patterns

### Terraform Heredoc Escaping Rules

**CRITICAL:** When writing shell scripts in Terraform heredocs, understand the escaping rules:

```hcl
# In Terraform heredoc (<<-EOT)
script = <<-EOT
  # ✅ CORRECT - Command substitution does NOT need escaping
  result=$(command)
  items=$(jq -r '.[]' file.json)

  # ✅ CORRECT - Variables with braces MUST be escaped
  echo "$${variable}"
  echo "$${ipv4} $${service}"

  # ✅ CORRECT - Simple variables should be escaped for safety
  echo "$$var"
EOT
```

**The Rule:**
- `$(...)` command substitution → Use single `$` (Terraform doesn't interpret this)
- `${variable}` shell variable → Use `$${variable}` (Terraform would interpret `${...}` as interpolation)
- `$variable` simple variable → Use `$$variable` for safety

**Common Mistake:**
```hcl
# ❌ WRONG - Doubling the $ in command substitution
result=$$(command)  # This generates $(command) which is CORRECT, but unnecessary

# ❌ WRONG - Not escaping braced variables
echo "${variable}"  # Terraform tries to interpolate this as a Terraform variable!
```

### JSON Piping to jq

**BEST PRACTICE:** Write JSON data to separate files instead of embedding in shell scripts:

```hcl
# Write JSON data files that will be copied into the Docker image
resource "local_file" "proxy_specs" {
  content         = jsonencode(local.all_proxy_specs)
  filename        = "${path.module}/build/proxy_specs.json"
  file_permission = "0644"
}

resource "local_file" "hostnames" {
  content         = jsonencode(local.all_hostnames)
  filename        = "${path.module}/build/hostnames.json"
  file_permission = "0644"
}
```

Then in your Dockerfile, copy these JSON files:
```dockerfile
COPY proxy_specs.json /tmp/proxy_specs.json
COPY hostnames.json /tmp/hostnames.json
```

Now your shell scripts can simply read from these files:
```bash
# ✅ BEST - Read JSON from file with jq exit status check
if [ -f /tmp/proxy_specs.json ] && jq -e '. | length > 0' /tmp/proxy_specs.json >/dev/null 2>&1; then
  jq -r '.[] | "Starting proxy for " + .name' /tmp/proxy_specs.json
fi

# ✅ BEST - Iterate over JSON array using for loop (simpler, works reliably)
for service in $(jq -r '.[]' < /tmp/hostnames.json); do
  echo "Processing: $${service}"
done
```

**Why this is better:**
- **No escaping issues**: Avoids all shell variable assignment and heredoc-in-command-substitution problems
- **Cleaner code**: Shell scripts are simple and readable, no complex Terraform interpolation
- **Easier debugging**: You can inspect the JSON files directly in the container at `/tmp/*.json`
- **Type safety**: Terraform validates JSON structure when writing files
- **Rebuild triggers**: Easy to add file content hashes to Docker image rebuild triggers
- **Simple iteration**: `for` loops with `$(jq ...)` work reliably when following proper Terraform escaping rules

**Alternative (if embedding is required):**
```bash
# ⚠️ Use heredoc for simple piping only (not in command substitutions)
cat << 'JSON_EOF' | jq -r '.[]'
${jsonencode(local.all_proxy_specs)}
JSON_EOF
```

**Never do this:**
```bash
# ❌ WRONG - Variable assignment breaks with multi-line JSON
PROXY_SPECS='${jsonencode(local.all_proxy_specs)}'
echo "$$PROXY_SPECS" | jq -r '.[]'

# ❌ WRONG - Not escaping braced variables in Terraform heredoc
echo "${variable}"  # Terraform interprets this as interpolation!

# ❌ WRONG - Over-escaping command substitution
result=$$(command)  # Unnecessary, generates $command in output
```

**Use these patterns instead:**
```bash
# ✅ CORRECT - Command substitution with single $
result=$(command)
for item in $(jq -r '.[]' /tmp/data.json); do

# ✅ CORRECT - Braced variables with $$
echo "$${variable}"

# ✅ CORRECT - Use jq -e for test conditions (returns exit status)
if jq -e '. | length > 0' /tmp/data.json >/dev/null 2>&1; then
```

### Conditional Resources

Use `count` for optional features:
```hcl
resource "docker_container" "optional" {
  count = var.enabled ? 1 : 0
  # ... configuration
}
```

### Parameter Dependencies

Show parameters only when parent is enabled:
```hcl
data "coder_parameter" "child" {
  count = data.coder_parameter.parent.value ? 1 : 0
  # ... configuration
}
```

Access conditional parameters in locals:
```hcl
locals {
  param_value = var.parent_enabled ? data.coder_parameter.child[0].value : ""
}
```

### Module Output Composition Pattern

In your workspace template (main.tf), combine all module outputs using locals:

```hcl
# ============================================================================
# Module Output Composition
# ============================================================================

locals {
  # Combine packages from all modules
  all_packages = distinct(concat(
    module.postgres.packages,
    module.valkey.packages,
    module.runtime_installer.packages
  ))

  # Combine install scripts (run during Docker build)
  combined_install_script = join("\n\n", compact([
    module.postgres.install_script,
    module.valkey.install_script,
    module.runtime_installer.install_script
  ]))

  # Combine startup scripts (run during agent startup)
  combined_startup_script = join("\n\n", compact([
    module.postgres.startup_script,
    module.valkey.startup_script
  ]))

  # Combine proxy specs
  all_proxy_specs = concat(
    module.postgres.proxy_specs,
    module.valkey.proxy_specs
  )

  # Combine environment variables
  all_env_vars = merge(
    module.postgres.env_vars,
    module.valkey.env_vars
  )

  # Combine hostnames for IPv4 resolution
  all_hostnames = distinct(concat(
    module.postgres.hostnames,
    module.valkey.hostnames
  ))

  # Standard proxy setup script (reads from JSON file)
  proxy_setup_script_raw = <<-EOT
    # Set up port forwarding for services
    if [ -f /tmp/proxy_specs.json ] && jq -e '. | length > 0' /tmp/proxy_specs.json >/dev/null 2>&1; then
      echo "Setting up service proxies..."
      jq -r '.[] | "Starting proxy for " + .name + ": localhost:" + (.local_port|tostring) + " -> " + .host + ":" + (.rport|tostring)' /tmp/proxy_specs.json
      jq -r '.[] | "nohup socat TCP4-LISTEN:" + (.local_port|tostring) + ",fork,reuseaddr TCP4:" + .host + ":" + (.rport|tostring) + " > /tmp/proxy-" + .name + ".log 2>&1 &"' /tmp/proxy_specs.json | bash
    fi
  EOT
  proxy_setup_script = length(local.all_proxy_specs) > 0 ? local.proxy_setup_script_raw : ""

  # IPv4 hostname resolution script (reads from JSON file)
  ipv4_setup_script_raw = <<-EOT
    # Force IPv4 resolution for Docker service containers
    if [ -f /tmp/hostnames.json ] && command -v getent >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
      for service in $(jq -r '.[]' < /tmp/hostnames.json); do
        ipv4=$(getent ahostsv4 "$${service}" 2>/dev/null | head -n 1 | cut -d ' ' -f 1)
        if [ -n "$${ipv4}" ]; then
          echo "Adding IPv4 entry for $${service}: $${ipv4}"
          echo "$${ipv4} $${service}" | sudo tee -a /etc/hosts >/dev/null
        fi
      done
    fi
  EOT
  ipv4_setup_script = length(local.all_hostnames) > 0 ? local.ipv4_setup_script_raw : ""
}

# Write JSON data files for use in startup scripts
resource "local_file" "proxy_specs" {
  content         = jsonencode(local.all_proxy_specs)
  filename        = "${path.module}/build/proxy_specs.json"
  file_permission = "0644"
}

resource "local_file" "hostnames" {
  content         = jsonencode(local.all_hostnames)
  filename        = "${path.module}/build/hostnames.json"
  file_permission = "0644"
}

# Write combined install script to file
resource "local_file" "install_script" {
  count           = local.combined_install_script != "" ? 1 : 0
  content         = local.combined_install_script
  filename        = "${path.module}/build/install.sh"
  file_permission = "0755"
}

# Docker image with combined packages
resource "docker_image" "workspace" {
  build {
    context = "./build"
    build_args = {
      PACKAGES = join(" ", local.all_packages)
    }
  }

  # Trigger rebuilds when content changes
  triggers = {
    packages       = join(",", local.all_packages)
    install_script = sha256(local.combined_install_script)
    startup_script = sha256(local.combined_startup_script)
    proxy_specs    = sha256(jsonencode(local.all_proxy_specs))
    hostnames      = sha256(jsonencode(local.all_hostnames))
    dockerfile     = filesha1("${path.module}/build/Dockerfile")
  }

  # Ensure all files are written before building
  depends_on = [
    local_file.install_script,
    local_file.startup_script,
    local_file.proxy_specs,
    local_file.hostnames
  ]
}

# Agent with combined startup and env vars
resource "coder_agent" "main" {
  startup_script = <<-EOT
    set -e

    # Module startup scripts
    ${local.combined_startup_script}

    # Port forwarding
    ${local.proxy_setup_script}

    # IPv4 hostname resolution
    ${local.ipv4_setup_script}
  EOT

  env = merge(
    { GIT_AUTHOR_NAME = "..." },
    local.all_env_vars
  )
}
```

## Repository Structure

```
coderform/
├── modules/              # Reusable Terraform modules (importable)
│   ├── postgres/        # PostgreSQL with management tools
│   ├── valkey/          # Redis-compatible cache
│   └── ports/           # Port exposure management
├── examples/            # Complete workspace templates (copy and customize)
│   └── nodejs/         # Node.js workspace with all modules
├── build/              # Legacy build files for main_01.tf
├── main.tf             # Current workspace template (prefer examples/)
├── main_01.tf          # Legacy example (deprecated)
└── README.md           # User-facing documentation
```

## Requirements

- Terraform >= 1.0
- Coder provider >= 2.4.0
- Docker provider (kreuzwerker/docker)
- For workspaces using proxy_specs: `jq` and `socat` in the container

## Important Notes

- **Examples vs Modules**: Examples cannot be modules because they include Dockerfile build contexts
- **IPv6**: Disabled in internal networks to prevent DNS issues
- **Security**: Services only run on internal networks, not exposed to host
- **Persistence**: All data volumes use `ignore_changes = all` lifecycle
- **Labels**: Always include standard Coder labels for tracking and cleanup
