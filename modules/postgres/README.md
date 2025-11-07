# Postgres Module

A Terraform module that provides PostgreSQL database functionality for Coder workspaces with optional database management tools. This module creates user-configurable parameters and manages Postgres containers with persistent storage.

## Features

- **PostgreSQL Database**: Configurable version, credentials, and database name
- **Persistent Storage**: Database data persisted across workspace rebuilds
- **Database Management Tools**: Optional web-based tools for database management
  - **pgweb**: Lightweight PostgreSQL browser (Go-based)
  - **CloudBeaver**: Full-featured database manager (supports multiple DBs)
  - **Mathesar**: Modern spreadsheet-like interface for PostgreSQL
- **Port Forwarding**: Automatic socat proxy configuration via `proxy_specs` output
- **Environment Variables**: Easy integration with agent configuration

## Quick Start

### Minimal Example

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

  order_offset = 90
}
```

### With Management Tools Enabled

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

  order_offset              = 90
  default_enabled           = true
  default_version           = "17-alpine"
  default_pgweb_enabled     = true  # Enable pgweb by default
}
```

## Port Forwarding Configuration

The module outputs `proxy_specs` which contains the port forwarding configuration for database management tools. This output **must** be used in your agent startup script to set up socat port forwarding.

### Why Port Forwarding?

Database management tools run in separate Docker containers. The Coder agent needs to access them via localhost for the web apps to work correctly. We use socat to forward localhost ports to the container ports.

### proxy_specs Output Format

```terraform
output "proxy_specs" {
  value = [
    {
      name       = "pgweb"
      local_port = 8081
      host       = "pgweb"
      rport      = 8081
    },
    {
      name       = "cloudbeaver"
      local_port = 8978
      host       = "cloudbeaver"
      rport      = 8978
    },
    {
      name       = "mathesar"
      local_port = 8000
      host       = "mathesar"
      rport      = 8000
    }
  ]
}
```

### Integration with Agent Startup Script

Add this to your `coder_agent` startup script to enable port forwarding:

```hcl
resource "coder_agent" "main" {
  # ... other configuration ...

  startup_script = <<-EOT
    set -e

    # Port forwarding for postgres module services
    ${jsonencode(module.postgres.proxy_specs) != "[]" ? "PROXY_SPECS='${jsonencode(module.postgres.proxy_specs)}'" : ""}
    if [ -n "$PROXY_SPECS" ] && [ "$PROXY_SPECS" != "[]" ]; then
      echo "Setting up database management tool proxies..."
      echo "$PROXY_SPECS" | jq -r '.[] | "Starting socat proxy for " + .name + ": localhost:" + (.local_port|tostring) + " -> " + .host + ":" + (.rport|tostring)'
      echo "$PROXY_SPECS" | jq -r '.[] | "nohup socat TCP4-LISTEN:" + (.local_port|tostring) + ",fork,reuseaddr TCP4:" + .host + ":" + (.rport|tostring) + " > /tmp/proxy-" + .name + ".log 2>&1 &"' | bash
    fi

    # Rest of your startup script...
  EOT
}
```

**Note**: This requires `jq` and `socat` to be installed in your workspace container. Add them to your Dockerfile:

```dockerfile
RUN apt-get update && \
    apt-get install -y socat jq && \
    rm -rf /var/lib/apt/lists/*
```

## Variables

### Required Variables

| Name | Type | Description |
|------|------|-------------|
| `agent_id` | `string` | Coder agent ID (for management tool apps) |
| `workspace_id` | `string` | Coder workspace ID |
| `workspace_name` | `string` | Coder workspace name |
| `username` | `string` | Workspace owner username |
| `owner_id` | `string` | Workspace owner ID |
| `repository` | `string` | Repository URL for labeling |
| `internal_network_name` | `string` | Docker network name to attach to |

### Optional Variables

#### PostgreSQL Configuration

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `order_offset` | `number` | `10` | Starting order for parameters |
| `default_enabled` | `bool` | `false` | Enable Postgres by default |
| `default_version` | `string` | `"18-alpine"` | Default Postgres version |
| `default_user` | `string` | `"coder"` | Default database user |
| `default_password` | `string` | `"coder"` | Default password (sensitive) |
| `default_database` | `string` | `"appdb"` | Default database name |

#### Management Tools

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `default_pgweb_enabled` | `bool` | `false` | Enable pgweb by default |
| `pgweb_port` | `number` | `8081` | Port for pgweb |
| `default_cloudbeaver_enabled` | `bool` | `false` | Enable CloudBeaver by default |
| `cloudbeaver_port` | `number` | `8978` | Port for CloudBeaver |
| `default_mathesar_enabled` | `bool` | `false` | Enable Mathesar by default |
| `mathesar_port` | `number` | `8000` | Port for Mathesar |

### Available PostgreSQL Versions

- `18-alpine` - PostgreSQL 18 on Alpine Linux (default)
- `17-alpine` - PostgreSQL 17 on Alpine Linux
- `16-alpine` - PostgreSQL 16 on Alpine Linux
- `15-alpine` - PostgreSQL 15 on Alpine Linux

## Outputs

### Database Connection

| Name | Type | Description |
|------|------|-------------|
| `enabled` | `bool` | Whether Postgres is enabled |
| `host` | `string` | Postgres hostname (`"postgres"` or `""`) |
| `port` | `number` | Postgres port (`5432`) |
| `user` | `string` | Database user |
| `password` | `string` | Database password (sensitive) |
| `database` | `string` | Database name |
| `version` | `string` | Postgres version tag |
| `connection_string` | `string` | Full connection string (sensitive) |
| `connection_string_sslmode_disable` | `string` | Connection string with sslmode=disable (sensitive) |
| `env_vars` | `map(string)` | Environment variables map (sensitive) |

### Management Tools

| Name | Type | Description |
|------|------|-------------|
| `pgweb_enabled` | `bool` | Whether pgweb is enabled |
| `pgweb_url` | `string` | pgweb internal URL |
| `cloudbeaver_enabled` | `bool` | Whether CloudBeaver is enabled |
| `cloudbeaver_url` | `string` | CloudBeaver internal URL |
| `mathesar_enabled` | `bool` | Whether Mathesar is enabled |
| `mathesar_url` | `string` | Mathesar internal URL |

### Port Forwarding

| Name | Type | Description |
|------|------|-------------|
| `proxy_specs` | `list(object)` | Port forwarding specifications for socat |

## Management Tool Details

### pgweb

- **Auto-connects** to PostgreSQL on startup (no configuration needed)
- **Lightweight** Go-based web interface
- **Fast** and responsive
- Perfect for quick database browsing and SQL queries
- **Port**: 8081 (default)

**Access**: Click "pgweb" in your Coder workspace apps

### CloudBeaver

- **Full-featured** database manager (similar to DBeaver Desktop)
- Supports **multiple database types**
- **ER diagrams** and schema visualization
- Advanced SQL editor with autocomplete
- **Port**: 8978 (default)
- **Requires first-time setup** through web UI

**Access**: Click "CloudBeaver" in your Coder workspace apps

**Note**: On first launch, you'll need to create an admin user and add a connection to your PostgreSQL database manually.

### Mathesar

- **Spreadsheet-like interface** for non-technical users
- Visual data exploration and editing
- Table creation and schema management
- **Port**: 8000 (default)
- **Default credentials**: username `admin`, password `admin`
- **Requires initial migration** on first launch (may take 1-2 minutes)

**Access**: Click "Mathesar" in your Coder workspace apps

**Note**: Mathesar auto-connects to your PostgreSQL database on startup.

## Environment Variables

When using `module.postgres.env_vars`, the following environment variables are set in your agent:

| Variable | Description | Example |
|----------|-------------|---------|
| `POSTGRES_ENABLED` | Whether Postgres is enabled | `"true"` or `"false"` |
| `POSTGRES_HOST` | Hostname | `"postgres"` or `""` |
| `POSTGRES_PORT` | Port number | `"5432"` |
| `POSTGRES_USER` | Database user | `"coder"` |
| `POSTGRES_PASSWORD` | Database password | `"mypassword"` |
| `POSTGRES_DB` | Database name | `"appdb"` |

### Using Environment Variables

```hcl
resource "coder_agent" "main" {
  # ... other config ...

  env = merge(
    {
      MY_APP_VAR = "value"
    },
    module.postgres.env_vars
  )
}
```

## Connection Examples

### Node.js (pg)

```javascript
const { Client } = require('pg');

const client = new Client({
  host: process.env.POSTGRES_HOST,
  port: parseInt(process.env.POSTGRES_PORT),
  user: process.env.POSTGRES_USER,
  password: process.env.POSTGRES_PASSWORD,
  database: process.env.POSTGRES_DB,
});

await client.connect();
```

### Python (psycopg2)

```python
import psycopg2
import os

conn = psycopg2.connect(
    host=os.getenv('POSTGRES_HOST'),
    port=os.getenv('POSTGRES_PORT'),
    user=os.getenv('POSTGRES_USER'),
    password=os.getenv('POSTGRES_PASSWORD'),
    database=os.getenv('POSTGRES_DB')
)
```

### CLI (psql)

```bash
psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB

# Or using connection string
psql "$POSTGRES_CONNECTION_STRING"
```

## Complete Example

```hcl
locals {
  workspace_id   = data.coder_workspace.me.id
  workspace_name = data.coder_workspace.me.name
  username       = data.coder_workspace_owner.me.name
  owner_id       = data.coder_workspace_owner.me.id
  repository     = "https://github.com/example/repo"
}

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

resource "docker_network" "internal_network" {
  name     = "coder-${local.workspace_id}-network"
  driver   = "bridge"
  internal = true
}

module "postgres" {
  source = "github.com/qwacko/coderform//modules/postgres"

  agent_id              = coder_agent.main.id
  workspace_id          = local.workspace_id
  workspace_name        = local.workspace_name
  username              = local.username
  owner_id              = local.owner_id
  repository            = local.repository
  internal_network_name = docker_network.internal_network.name

  order_offset              = 90
  default_enabled           = true
  default_version           = "17-alpine"
  default_user              = "appuser"
  default_password          = "secure-password-123"
  default_database          = "myapp_db"
  default_pgweb_enabled     = true
}

resource "coder_agent" "main" {
  arch = "amd64"
  os   = "linux"

  env = merge(
    {
      MY_APP_VAR = "value"
    },
    module.postgres.env_vars
  )

  startup_script = <<-EOT
    set -e

    # Port forwarding for postgres module services
    ${jsonencode(module.postgres.proxy_specs) != "[]" ? "PROXY_SPECS='${jsonencode(module.postgres.proxy_specs)}'" : ""}
    if [ -n "$PROXY_SPECS" ] && [ "$PROXY_SPECS" != "[]" ]; then
      echo "Setting up database management tool proxies..."
      echo "$PROXY_SPECS" | jq -r '.[] | "Starting socat proxy for " + .name + ": localhost:" + (.local_port|tostring) + " -> " + .host + ":" + (.rport|tostring)'
      echo "$PROXY_SPECS" | jq -r '.[] | "nohup socat TCP4-LISTEN:" + (.local_port|tostring) + ",fork,reuseaddr TCP4:" + .host + ":" + (.rport|tostring) + " > /tmp/proxy-" + .name + ".log 2>&1 &"' | bash
    fi

    # Your other startup commands...
  EOT
}
```

## Data Persistence

The module creates Docker volumes that persist across workspace restarts:

### Postgres Volume
- Volume name: `coder-{workspace_id}-pgdata`
- Lifecycle: `ignore_changes = all`
- Mount point: `/var/lib/postgresql/data`

### CloudBeaver Volume
- Volume name: `coder-{workspace_id}-cloudbeaver`
- Lifecycle: `ignore_changes = all`
- Mount point: `/opt/cloudbeaver/workspace`

### Mathesar Volume
- Volume name: `coder-{workspace_id}-mathesar`
- Lifecycle: `ignore_changes = all`
- Mount point: `/mathesar`

## Network Configuration

All containers are connected to the internal network specified by `internal_network_name`. The containers are accessible by their aliases:

- `postgres` - PostgreSQL database
- `pgweb` - pgweb (if enabled)
- `cloudbeaver` - CloudBeaver (if enabled)
- `mathesar` - Mathesar (if enabled)

## Security Notes

- Passwords are marked as `sensitive` in Terraform
- Postgres runs on the internal Docker network only
- Not exposed to host machine or external networks
- Management tools are only accessible through Coder's authenticated proxy
- Use strong passwords in production environments

## Troubleshooting

### Can't connect to Postgres

1. Verify Postgres is enabled in workspace parameters
2. Check network: Ensure your app container is on the same Docker network
3. Test connection: `docker exec coder-{workspace_id}-postgres psql -U {user} -d {database} -c "SELECT 1;"`

### Management tool not loading (502 Bad Gateway)

1. Check if socat proxies are running: `ps aux | grep socat`
2. Check proxy logs: `cat /tmp/proxy-{tool-name}.log`
3. Verify container is running: `docker ps | grep {tool-name}`
4. Check container logs: `docker logs coder-{workspace_id}-{tool-name}`
5. Ensure `jq` and `socat` are installed in your workspace container

### CloudBeaver requires setup

CloudBeaver requires first-time configuration:
1. Access CloudBeaver through Coder apps
2. Create an admin user
3. Add connection:
   - Host: `postgres`
   - Port: `5432`
   - Database: Your database name
   - Username: Your Postgres user
   - Password: Your Postgres password

### Mathesar is slow to start

Mathesar runs Django migrations on first start, which can take 1-2 minutes. Check logs:
```bash
docker logs coder-{workspace_id}-mathesar
```

## Requirements

- Terraform >= 1.0
- Coder provider >= 2.4.0
- Docker provider (kreuzwerker/docker)
- Workspace container must have `jq` and `socat` installed

## Source

This module is part of the [coderform](https://github.com/qwacko/coderform) repository.
