# Coder Postgres Module

A Terraform module that provides PostgreSQL database functionality for Coder workspaces with optional pgAdmin web interface. This module creates user-configurable parameters and manages Postgres and pgAdmin containers with persistent storage.

## Features

- User-configurable PostgreSQL instance through Coder parameters
- Multiple PostgreSQL versions (15, 16, 17, 18)
- Optional pgAdmin 4 web interface for database management
- Persistent data storage using Docker volumes
- Automatic network configuration
- Connection strings and environment variable outputs
- Mutable parameters (can be changed without recreating workspace)
- Secure password handling

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
}
```

### With pgAdmin Enabled

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

  order_offset              = 10
  default_enabled           = true
  default_version           = "16-alpine"
  default_user              = "myuser"
  default_password          = "mypassword"
  default_database          = "myapp"
  default_pgadmin_enabled   = true
  default_pgadmin_email     = "admin@example.com"
  default_pgadmin_password  = "adminpassword"
}
```

### Using Outputs in Agent

```hcl
module "postgres" {
  source = "github.com/qwacko/coderform//modules/postgres"
  # ... required variables ...
}

resource "coder_agent" "main" {
  # ... other config ...

  env = merge(
    {
      # Your other env vars
    },
    module.postgres.env_vars
  )
}
```

## How It Works

When you use this module:

1. **Enable Postgres**: Users can enable/disable Postgres
2. **Configure Database**: If enabled, users configure:
   - PostgreSQL version
   - Database user
   - Password
   - Database name
3. **Optional pgAdmin**: Users can optionally enable pgAdmin:
   - Login email
   - Login password
4. **Resource Creation**: Module creates:
   - Postgres container with persistent volume
   - pgAdmin container (if enabled) with persistent volume
   - Coder app for pgAdmin web interface
5. **Network Attachment**: Containers join internal network

### Parameter Ordering

Parameters are ordered as follows (assuming `order_offset = 10`):

| Parameter | Order | Conditional |
|-----------|-------|-------------|
| Enable Postgres | 10 | Always shown |
| Postgres Version | 11 | Only if Postgres enabled |
| Postgres User | 12 | Only if Postgres enabled |
| Postgres Password | 13 | Only if Postgres enabled |
| Postgres Database | 14 | Only if Postgres enabled |
| Enable pgAdmin | 15 | Only if Postgres enabled |
| pgAdmin Email | 16 | Only if both Postgres and pgAdmin enabled |
| pgAdmin Password | 17 | Only if both Postgres and pgAdmin enabled |

## Variables

### Required Variables

| Name | Type | Description |
|------|------|-------------|
| `agent_id` | `string` | Coder agent ID (for pgAdmin app) |
| `workspace_id` | `string` | Coder workspace ID |
| `workspace_name` | `string` | Coder workspace name |
| `username` | `string` | Workspace owner username |
| `owner_id` | `string` | Workspace owner ID |
| `repository` | `string` | Repository URL for labeling |
| `internal_network_name` | `string` | Docker network name to attach to |

### Optional Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `order_offset` | `number` | `10` | Starting order for parameters |
| `default_enabled` | `bool` | `false` | Enable Postgres by default |
| `default_version` | `string` | `"16-alpine"` | Default Postgres version |
| `default_user` | `string` | `"coder"` | Default database user |
| `default_password` | `string` | `"coder"` | Default password |
| `default_database` | `string` | `"appdb"` | Default database name |
| `default_pgadmin_enabled` | `bool` | `false` | Enable pgAdmin by default |
| `default_pgadmin_email` | `string` | `"admin@local.host"` | Default pgAdmin email |
| `default_pgadmin_password` | `string` | `"admin"` | Default pgAdmin password |
| `pgadmin_port` | `number` | `5050` | pgAdmin web interface port |

### Available PostgreSQL Versions

- `18-alpine` - PostgreSQL 18 on Alpine Linux
- `17-alpine` - PostgreSQL 17 on Alpine Linux
- `16-alpine` - PostgreSQL 16 on Alpine Linux (default)
- `15-alpine` - PostgreSQL 15 on Alpine Linux

## Outputs

### Postgres Outputs

| Name | Type | Description |
|------|------|-------------|
| `enabled` | `bool` | Whether Postgres is enabled |
| `host` | `string` | Postgres hostname |
| `port` | `number` | Postgres port (5432) |
| `user` | `string` | Database user |
| `password` | `string` | Database password (sensitive) |
| `database` | `string` | Database name |
| `version` | `string` | Postgres version tag |
| `connection_string` | `string` | Full connection string (sensitive) |
| `connection_string_sslmode_disable` | `string` | Connection string with sslmode=disable |
| `env_vars` | `map(string)` | Environment variables map (sensitive) |

### pgAdmin Outputs

| Name | Type | Description |
|------|------|-------------|
| `pgadmin_enabled` | `bool` | Whether pgAdmin is enabled |
| `pgadmin_email` | `string` | pgAdmin login email |
| `pgadmin_password` | `string` | pgAdmin password (sensitive) |
| `pgadmin_url` | `string` | pgAdmin internal URL |
| `pgadmin_app` | `object` | Coder app resource |

### Using Outputs

```hcl
# Check if Postgres is enabled
output "db_available" {
  value = module.postgres.enabled
}

# Get connection info
output "db_url" {
  value     = module.postgres.connection_string
  sensitive = true
}

# Use environment variables in agent
resource "coder_agent" "main" {
  env = module.postgres.env_vars
}

# Check if pgAdmin is available
output "pgadmin_ready" {
  value = module.postgres.pgadmin_enabled
}
```

## Environment Variables

When using `module.postgres.env_vars`, the following environment variables are set:

| Variable | Description | Example |
|----------|-------------|---------|
| `POSTGRES_ENABLED` | Whether Postgres is enabled | `"true"` or `"false"` |
| `POSTGRES_HOST` | Hostname | `"postgres"` or `""` |
| `POSTGRES_PORT` | Port number | `"5432"` |
| `POSTGRES_USER` | Database user | `"coder"` |
| `POSTGRES_PASSWORD` | Database password | `"mypassword"` |
| `POSTGRES_DB` | Database name | `"appdb"` |

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

### Go (lib/pq)

```go
import (
    "database/sql"
    "fmt"
    "os"
    _ "github.com/lib/pq"
)

connStr := fmt.Sprintf(
    "host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
    os.Getenv("POSTGRES_HOST"),
    os.Getenv("POSTGRES_PORT"),
    os.Getenv("POSTGRES_USER"),
    os.Getenv("POSTGRES_PASSWORD"),
    os.Getenv("POSTGRES_DB"),
)

db, err := sql.Open("postgres", connStr)
```

### CLI (psql)

```bash
psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB

# Or using connection string
psql $POSTGRES_CONNECTION_STRING
```

### Connection String Format

```
postgresql://user:password@host:5432/database
postgresql://user:password@host:5432/database?sslmode=disable
```

## Using pgAdmin

When pgAdmin is enabled, users can access it through the Coder dashboard:

1. Click the "pgAdmin" app in your workspace
2. Login with the configured email and password
3. Add a new server connection:
   - **Host**: `postgres`
   - **Port**: `5432`
   - **Username**: Your Postgres user
   - **Password**: Your Postgres password
   - **Database**: Your database name

### Auto-Configure pgAdmin Connection

You can create a startup script to pre-configure the Postgres connection in pgAdmin:

```hcl
resource "coder_script" "configure_pgadmin" {
  count       = module.postgres.pgadmin_enabled ? 1 : 0
  agent_id    = coder_agent.main.id
  display_name = "Configure pgAdmin"
  run_on_start = true
  script      = <<-EOT
    #!/bin/bash
    # Wait for pgAdmin to be ready
    until curl -s http://pgadmin:${var.pgadmin_port} > /dev/null; do
      sleep 2
    done

    echo "pgAdmin is ready at: ${module.postgres.pgadmin_url}"
  EOT
}
```

## Data Persistence

The module creates Docker volumes that persist across workspace restarts:

### Postgres Volume
- Volume name: `coder-{workspace_id}-pgdata`
- Lifecycle: `ignore_changes = all`
- Mount point: `/var/lib/postgresql/data`

### pgAdmin Volume
- Volume name: `coder-{workspace_id}-pgadmindata`
- Lifecycle: `ignore_changes = all`
- Mount point: `/var/lib/pgadmin`

## Security Notes

- Passwords are marked as `sensitive` in Terraform
- Postgres runs on the internal Docker network only
- Not exposed to host machine or external networks
- pgAdmin is only accessible through Coder's authenticated proxy
- Use strong passwords in production environments

## Troubleshooting

### Can't connect to Postgres

1. Verify Postgres is enabled: Check workspace parameters
2. Check network: Ensure your app container is on the same Docker network
3. Test connection: `docker exec coder-{workspace_id}-postgres psql -U {user} -d {database} -c "SELECT 1;"`

### pgAdmin not loading

1. Verify pgAdmin is enabled: Check both Postgres and pgAdmin parameters
2. Check container is running: `docker ps | grep pgadmin`
3. Check logs: `docker logs coder-{workspace_id}-pgadmin`
4. Wait 30-60 seconds after start - pgAdmin takes time to initialize

### Can't login to pgAdmin

1. Verify credentials: Check pgAdmin email and password in parameters
2. Reset password: Update the pgAdmin password parameter and restart workspace

### Connection refused in pgAdmin

When adding server in pgAdmin:
- Use hostname `postgres` (not `localhost`)
- Use port `5432`
- Ensure you're using the correct Postgres credentials

## Complete Example

```hcl
locals {
  workspace_id   = data.coder_workspace.me.id
  workspace_name = data.coder_workspace.me.name
  username       = data.coder_workspace_owner.me.name
  owner_id       = data.coder_workspace_owner.me.id
}

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

resource "docker_network" "internal_network" {
  name     = "coder-${local.workspace_id}-network"
  driver   = "bridge"
  internal = true
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
}

module "postgres" {
  source = "./modules/postgres"

  agent_id              = coder_agent.main.id
  workspace_id          = local.workspace_id
  workspace_name        = local.workspace_name
  username              = local.username
  owner_id              = local.owner_id
  repository            = "https://github.com/example/repo"
  internal_network_name = docker_network.internal_network.name

  order_offset             = 10
  default_enabled          = true
  default_version          = "16-alpine"
  default_user             = "appuser"
  default_password         = "secure-password-123"
  default_database         = "myapp_db"
  default_pgadmin_enabled  = true
  default_pgadmin_email    = "admin@example.com"
  default_pgadmin_password = "pgadmin-password-456"
  pgadmin_port             = 5050
}

# Optional: Output connection info
output "database_url" {
  value     = module.postgres.connection_string
  sensitive = true
}

output "pgadmin_access" {
  value = module.postgres.pgadmin_enabled ? {
    email    = module.postgres.pgadmin_email
    password = module.postgres.pgadmin_password
  } : null
  sensitive = true
}
```

## Migration from Inline Configuration

Replace this:

```hcl
# OLD: Inline Postgres configuration
data "coder_parameter" "enable_postgres" { ... }
data "coder_parameter" "postgres_version" { ... }
resource "docker_volume" "postgres_data" { ... }
resource "docker_container" "postgres" { ... }
```

With this:

```hcl
# NEW: Postgres module
module "postgres" {
  source                = "./modules/postgres"
  agent_id              = coder_agent.main.id
  workspace_id          = data.coder_workspace.me.id
  workspace_name        = data.coder_workspace.me.name
  username              = data.coder_workspace_owner.me.name
  owner_id              = data.coder_workspace_owner.me.id
  repository            = local.repository
  internal_network_name = docker_network.internal_network.name
}
```

## Requirements

- Terraform >= 1.0
- Coder provider >= 2.4.0
- Docker provider (kreuzwerker/docker)

## Source

This module is part of the [coderform](https://github.com/qwacko/coderform) repository.

## License

Same as the parent repository.
