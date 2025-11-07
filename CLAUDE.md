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
- Output connection details and environment variables
- Provide `proxy_specs` for port forwarding when services run in separate containers

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

4. **Port Forwarding**:
   - If service runs in a separate container, create a `proxy_specs` output
   - Add `ports { internal = <port> }` to docker_container (don't expose to host)
   - Point `coder_app` URLs to `localhost:<port>` (not container hostname)

5. **Outputs**:
   - Always output an `enabled` boolean
   - Provide `env_vars` map for easy agent integration
   - Mark sensitive outputs (passwords, connection strings) with `sensitive = true`

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

### Environment Variables Pattern

Modules should output an `env_vars` map that can be merged into the agent:

```hcl
output "env_vars" {
  value = {
    SERVICE_ENABLED  = tostring(local.enabled)
    SERVICE_HOST     = local.enabled ? "hostname" : ""
    SERVICE_PORT     = "1234"
    # ... other vars
  }
  sensitive = true
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

### Agent Startup Script Pattern

Standard startup script for proxy forwarding:
```hcl
startup_script = <<-EOT
  set -e

  # Port forwarding for module services
  ${jsonencode(module.service.proxy_specs) != "[]" ? "PROXY_SPECS='${jsonencode(module.service.proxy_specs)}'" : ""}
  if [ -n "$PROXY_SPECS" ] && [ "$PROXY_SPECS" != "[]" ]; then
    echo "Setting up service proxies..."
    echo "$PROXY_SPECS" | jq -r '.[] | "Starting socat proxy for " + .name + ": localhost:" + (.local_port|tostring) + " -> " + .host + ":" + (.rport|tostring)'
    echo "$PROXY_SPECS" | jq -r '.[] | "nohup socat TCP4-LISTEN:" + (.local_port|tostring) + ",fork,reuseaddr TCP4:" + .host + ":" + (.rport|tostring) + " > /tmp/proxy-" + .name + ".log 2>&1 &"' | bash
  fi

  # Other startup commands...
EOT
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
