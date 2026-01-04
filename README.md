# coderform

Terraform modules and components for Coder workspaces, providing reusable infrastructure components for development environments.

## Usage Patterns

### Modules (Reusable Components)

Modules are reusable infrastructure components that can be imported via `source`:

```hcl
module "postgres" {
  source = "github.com/qwacko/coderform//modules/postgres"
  # ...
}
```

**Available Modules:**
- **[Postgres](./modules/postgres/)** - PostgreSQL with management tools (pgweb, CloudBeaver, Mathesar)
- **[Valkey](./modules/valkey/)** - Redis-compatible in-memory data store
- **[OTEL-LGTM](./modules/otel-lgtm/)** - Grafana LGTM stack for OpenTelemetry (Loki, Grafana, Tempo, Mimir)
- **[Ports](./modules/ports/)** - Configurable port exposures

### Examples (Complete Templates)

Examples are **complete workspace configurations** meant to be copied and customized, not imported as modules. They include Dockerfiles and build contexts that must be local.

**Available Examples:**
- **[Node.js Workspace](./examples/nodejs/)** - Complete Node.js development environment with all modules integrated

#### How to Use Examples

**Option 1: Copy the Example** (Recommended)
```bash
# Copy the example to your workspace templates directory
cp -r examples/nodejs /path/to/your/coder/templates/my-nodejs-workspace
cd /path/to/your/coder/templates/my-nodejs-workspace

# Customize as needed
vim main.tf
vim build/Dockerfile

# Push to Coder
coder templates push my-nodejs-workspace
```

**Option 2: Download as Starter**
```bash
# Download specific example
curl -L https://github.com/qwacko/coderform/archive/refs/heads/main.tar.gz | \
  tar xz --strip=2 coderform-main/examples/nodejs

# Or clone the entire repository
git clone https://github.com/qwacko/coderform.git
cd coderform/examples/nodejs
```

**Option 3: Use as Template in Coder**

In Coder, you can create a template directly from a Git repository:
1. Point to the repository: `https://github.com/qwacko/coderform`
2. Set directory: `examples/nodejs`
3. Create template

**Why Examples Can't Be Modules:**
- Examples include `build/` directories with Dockerfiles
- Docker build contexts require local files (can't reference remote paths)
- Examples are complete workspace configurations, not composable components

## Available Modules (Detailed)

### [Postgres Module](./modules/postgres/)

PostgreSQL database with optional management tools (pgweb, CloudBeaver, Mathesar).

**Quick Start:**
```hcl
module "postgres" {
  source = "github.com/qwacko/coderform//modules/postgres"

  agent_id              = coder_agent.main.id
  workspace_id          = data.coder_workspace.me.id
  workspace_name        = data.coder_workspace.me.name
  username              = data.coder_workspace_owner.me.name
  owner_id              = data.coder_workspace_owner.me.id
  repository            = local.repository
  internal_network_name = docker_network.internal_network.name
}
```

See [Postgres Module README](./modules/postgres/README.md) for full documentation.

### [Valkey Module](./modules/valkey/)

Redis-compatible in-memory data store.

### [OTEL-LGTM Module](./modules/otel-lgtm/)

Complete OpenTelemetry observability stack with Loki (logs), Grafana (visualization), Tempo (traces), and Mimir (metrics).

**Quick Start:**
```hcl
module "otel_lgtm" {
  source = "github.com/qwacko/coderform//modules/otel-lgtm"

  agent_id              = coder_agent.main.id
  workspace_id          = data.coder_workspace.me.id
  workspace_name        = data.coder_workspace.me.name
  username              = data.coder_workspace_owner.me.name
  owner_id              = data.coder_workspace_owner.me.id
  repository            = local.repository
  internal_network_name = docker_network.internal_network.name
}
```

**Features:**
- Pre-configured Grafana dashboard for visualization
- OTLP endpoints (gRPC port 4317, HTTP port 4318) for telemetry ingestion
- Automatic environment variable setup for OpenTelemetry SDKs
- Persistent storage for logs, traces, and metrics
- Internal network access for all workspace containers

See [OTEL-LGTM Module README](./modules/otel-lgtm/README.md) for full documentation.

### [Ports Module](./modules/ports/)

Configurable port exposures for workspace applications.

## Port Forwarding with proxy_specs

Several modules (like Postgres) provide a `proxy_specs` output that configures port forwarding for services running in separate Docker containers. This is required for web-based management tools to work correctly.

### How It Works

1. **Modules output `proxy_specs`**: Contains port forwarding configuration
2. **Agent startup script**: Reads `proxy_specs` and sets up socat proxies
3. **Coder apps**: Connect to `localhost` ports which forward to containers

### Required Setup

#### 1. Install Dependencies in Workspace Container

Add `jq` and `socat` to your workspace Dockerfile:

```dockerfile
ARG NODE_BASE_IMAGE=node:24-bookworm
FROM ${NODE_BASE_IMAGE}

ARG USER=coder

# Install required packages
RUN apt-get update && \
    apt-get install -y \
    sudo \
    curl \
    git \
    jq \
    socat \
    && rm -rf /var/lib/apt/lists/*

# Create user
RUN useradd -m -s /bin/bash ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${USER} && \
    chmod 0440 /etc/sudoers.d/${USER}

WORKDIR /home/${USER}
USER ${USER}
```

#### 2. Configure Agent Startup Script

Add this to your `coder_agent` startup script to enable port forwarding:

```hcl
resource "coder_agent" "main" {
  arch = data.coder_provisioner.me.arch
  os   = "linux"

  startup_script = <<-EOT
    set -e

    # Port forwarding for postgres module services
    ${jsonencode(module.postgres.proxy_specs) != "[]" ? "PROXY_SPECS='${jsonencode(module.postgres.proxy_specs)}'" : ""}
    if [ -n "$PROXY_SPECS" ] && [ "$PROXY_SPECS" != "[]" ]; then
      echo "Setting up database management tool proxies..."
      echo "$PROXY_SPECS" | jq -r '.[] | "Starting socat proxy for " + .name + ": localhost:" + (.local_port|tostring) + " -> " + .host + ":" + (.rport|tostring)'
      echo "$PROXY_SPECS" | jq -r '.[] | "nohup socat TCP4-LISTEN:" + (.local_port|tostring) + ",fork,reuseaddr TCP4:" + .host + ":" + (.rport|tostring) + " > /tmp/proxy-" + .name + ".log 2>&1 &"' | bash
    fi

    # Add other modules' proxy_specs here if needed
    # Example for multiple modules:
    # VALKEY_SPECS='${jsonencode(module.valkey.proxy_specs)}'
    # ... repeat the same pattern ...

    # Rest of your startup script
    curl -fsSL https://get.pnpm.io/install.sh | ENV="$HOME/.bashrc" SHELL="$(which bash)" bash -
  EOT
}
```

### Multiple Modules with proxy_specs

If you have multiple modules providing `proxy_specs`, combine them:

```hcl
resource "coder_agent" "main" {
  startup_script = <<-EOT
    set -e

    # Combine proxy specs from all modules
    ALL_PROXY_SPECS=$(jq -s 'add' <<EOF
${jsonencode(module.postgres.proxy_specs)}
${jsonencode(module.other_module.proxy_specs)}
EOF
)

    if [ "$ALL_PROXY_SPECS" != "[]" ] && [ -n "$ALL_PROXY_SPECS" ]; then
      echo "Setting up service proxies..."
      echo "$ALL_PROXY_SPECS" | jq -r '.[] | "Starting socat proxy for " + .name + ": localhost:" + (.local_port|tostring) + " -> " + .host + ":" + (.rport|tostring)'
      echo "$ALL_PROXY_SPECS" | jq -r '.[] | "nohup socat TCP4-LISTEN:" + (.local_port|tostring) + ",fork,reuseaddr TCP4:" + .host + ":" + (.rport|tostring) + " > /tmp/proxy-" + .name + ".log 2>&1 &"' | bash
    fi

    # Rest of startup script...
  EOT
}
```

### Troubleshooting Port Forwarding

#### Check if socat proxies are running
```bash
ps aux | grep socat
```

#### View proxy logs
```bash
cat /tmp/proxy-pgweb.log
cat /tmp/proxy-cloudbeaver.log
cat /tmp/proxy-mathesar.log
```

#### Test connectivity
```bash
# Test if the service is reachable
curl -v http://pgweb:8081

# Test if the proxy is working
curl -v http://localhost:8081
```

#### Common Issues

1. **502 Bad Gateway**:
   - Check if socat is running: `ps aux | grep socat`
   - Check proxy logs: `cat /tmp/proxy-*.log`
   - Verify service container is running: `docker ps`

2. **Connection refused**:
   - Ensure `jq` and `socat` are installed in workspace
   - Check if startup script ran successfully
   - Verify containers are on the same Docker network

3. **Port conflicts**:
   - Check if port is already in use: `netstat -tulpn | grep <port>`
   - Adjust module port variables if needed

## Project Structure

```
coderform/
├── modules/               # Reusable components (import via source)
│   ├── postgres/         # PostgreSQL + management tools
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── valkey/           # Valkey (Redis-compatible)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── otel-lgtm/        # Grafana OTEL-LGTM stack
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   └── ports/            # Port exposure management
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── examples/             # Complete templates (copy and customize)
│   └── nodejs/          # Node.js workspace example
│       ├── main.tf      # Complete configuration
│       ├── build/
│       │   └── Dockerfile
│       └── README.md
├── build/               # Build files for main_01.tf example
│   └── Dockerfile
├── main_01.tf          # Legacy example (use examples/nodejs instead)
└── README.md           # This file
```

## Legacy Example (main_01.tf)

The [main_01.tf](./main_01.tf) file is a legacy example. **Use [examples/nodejs/](./examples/nodejs/) instead** for a complete, documented template.

The nodejs example includes:

- Docker network and volume setup
- Coder agent configuration with proxy forwarding
- Module integration (Postgres, Valkey, Ports)
- Workspace container configuration

## Requirements

- **Terraform**: >= 1.0
- **Coder Provider**: >= 2.4.0
- **Docker Provider**: kreuzwerker/docker

### Workspace Requirements

For modules with `proxy_specs` output:
- `jq` - JSON processor
- `socat` - Port forwarding utility

## Contributing

When creating new modules that require port forwarding:

1. Add `ports { internal = <port> }` to docker containers
2. Add network aliases to `networks_advanced`
3. Point `coder_app` URLs to `localhost:<port>`
4. Create `proxy_specs` output with this format:

```hcl
output "proxy_specs" {
  description = "Port forwarding specifications for socat"
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

5. Document the `proxy_specs` output in the module README

## License

See repository license.

## Source

[github.com/qwacko/coderform](https://github.com/qwacko/coderform)
