# Coder Valkey Module

A Terraform module that provides Valkey (Redis-compatible) cache functionality for Coder workspaces. This module creates user-configurable parameters and manages a Valkey container with persistent storage.

## Features

- User-configurable Valkey instance through Coder parameters
- Optional authentication with password
- Multiple version options (7, 8, 9 with alpine/trixie variants)
- Persistent data storage using Docker volumes
- Automatic network configuration
- Connection string and environment variable outputs
- Mutable parameters (can be changed without recreating workspace)

## Quick Start

### Minimal Example

```hcl
module "valkey" {
  source = "github.com/qwacko/coderform//modules/valkey"

  workspace_id          = data.coder_workspace.me.id
  workspace_name        = data.coder_workspace.me.name
  username              = data.coder_workspace_owner.me.name
  owner_id              = data.coder_workspace_owner.me.id
  repository            = local.repository
  internal_network_name = docker_network.internal_network.name
}
```

### With Custom Defaults

```hcl
module "valkey" {
  source = "github.com/qwacko/coderform//modules/valkey"

  workspace_id          = data.coder_workspace.me.id
  workspace_name        = data.coder_workspace.me.name
  username              = data.coder_workspace_owner.me.name
  owner_id              = data.coder_workspace_owner.me.id
  repository            = local.repository
  internal_network_name = docker_network.internal_network.name

  order_offset     = 20
  default_enabled  = true
  default_version  = "9-alpine"
  default_password = "secure-password-123"
}
```

### Using Outputs in Agent

```hcl
module "valkey" {
  source = "github.com/qwacko/coderform//modules/valkey"
  # ... required variables ...
}

resource "coder_agent" "main" {
  # ... other config ...

  env = merge(
    {
      # Your other env vars
    },
    module.valkey.env_vars
  )
}
```

## How It Works

When you use this module:

1. **Enable Parameter**: Users can enable/disable Valkey
2. **Version Selection**: If enabled, users select Valkey version
3. **Password Configuration**: Users can optionally set a password
4. **Container Creation**: Module creates Docker container with persistent volume
5. **Network Attachment**: Container joins the internal network with "valkey" hostname

### Parameter Ordering

Parameters are ordered as follows (assuming `order_offset = 20`):

| Parameter | Order | Conditional |
|-----------|-------|-------------|
| Enable Valkey | 20 | Always shown |
| Valkey Version | 21 | Only if enabled |
| Valkey Password | 22 | Only if enabled |

## Variables

### Required Variables

| Name | Type | Description |
|------|------|-------------|
| `workspace_id` | `string` | Coder workspace ID |
| `workspace_name` | `string` | Coder workspace name |
| `username` | `string` | Workspace owner username |
| `owner_id` | `string` | Workspace owner ID |
| `repository` | `string` | Repository URL for labeling |
| `internal_network_name` | `string` | Docker network name to attach to |

### Optional Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `order_offset` | `number` | `20` | Starting order for parameters |
| `default_enabled` | `bool` | `false` | Enable Valkey by default |
| `default_version` | `string` | `"9-alpine"` | Default Valkey version |
| `default_password` | `string` | `""` | Default password (empty = no auth) |

### Available Versions

- `9-alpine` - Valkey 9 on Alpine Linux (smallest)
- `9-trixie` - Valkey 9 on Debian Trixie
- `8-alpine` - Valkey 8 on Alpine Linux
- `8-trixie` - Valkey 8 on Debian Trixie
- `7-alpine` - Valkey 7 on Alpine Linux
- `7-trixie` - Valkey 7 on Debian Trixie
- `latest` - Latest version (not recommended for production)

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `enabled` | `bool` | Whether Valkey is enabled |
| `host` | `string` | Valkey hostname (empty if disabled) |
| `password` | `string` | Valkey password (sensitive) |
| `version` | `string` | Valkey version tag |
| `port` | `number` | Valkey port (always 6379) |
| `connection_string` | `string` | Full connection string (sensitive) |
| `env_vars` | `map(string)` | Environment variables map (sensitive) |

### Using Outputs

```hcl
# Check if Valkey is enabled
output "valkey_available" {
  value = module.valkey.enabled
}

# Get connection info
output "valkey_host" {
  value = module.valkey.host
}

# Use environment variables in agent
resource "coder_agent" "main" {
  env = module.valkey.env_vars
}

# Access connection string in scripts
resource "coder_script" "connect_valkey" {
  count       = module.valkey.enabled ? 1 : 0
  agent_id    = coder_agent.main.id
  display_name = "Test Valkey"
  script      = "redis-cli -u ${module.valkey.connection_string} PING"
}
```

## Environment Variables

When using `module.valkey.env_vars`, the following environment variables are set:

| Variable | Description | Example |
|----------|-------------|---------|
| `VALKEY_ENABLED` | Whether Valkey is enabled | `"true"` or `"false"` |
| `VALKEY_HOST` | Hostname | `"valkey"` or `""` |
| `VALKEY_PASSWORD` | Password | `"mypassword"` or `""` |
| `VALKEY_PORT` | Port number | `"6379"` |

## Connection Examples

### Node.js (ioredis)

```javascript
const Redis = require('ioredis');

const redis = new Redis({
  host: process.env.VALKEY_HOST,
  port: parseInt(process.env.VALKEY_PORT),
  password: process.env.VALKEY_PASSWORD || undefined,
});
```

### Python (redis-py)

```python
import redis
import os

r = redis.Redis(
    host=os.getenv('VALKEY_HOST'),
    port=int(os.getenv('VALKEY_PORT')),
    password=os.getenv('VALKEY_PASSWORD') or None,
)
```

### Go (go-redis)

```go
import (
    "github.com/redis/go-redis/v9"
    "os"
)

rdb := redis.NewClient(&redis.Options{
    Addr:     os.Getenv("VALKEY_HOST") + ":" + os.Getenv("VALKEY_PORT"),
    Password: os.Getenv("VALKEY_PASSWORD"),
})
```

### CLI

```bash
# With password
redis-cli -h $VALKEY_HOST -p $VALKEY_PORT -a $VALKEY_PASSWORD

# Without password
redis-cli -h $VALKEY_HOST -p $VALKEY_PORT
```

## Data Persistence

The module creates a Docker volume for Valkey data that persists across workspace restarts:
- Volume name: `coder-{workspace_id}-valkeydata`
- Lifecycle: `ignore_changes = all` (won't be deleted on workspace updates)
- Mount point: `/data` in container
- AOF (Append-Only File) persistence enabled

## Security Notes

- Passwords are marked as `sensitive` in Terraform
- Empty password means no authentication (use only in trusted environments)
- Valkey runs on the internal Docker network only
- Not exposed to host machine or external networks

## Troubleshooting

### Can't connect to Valkey

1. Verify Valkey is enabled: Check workspace parameters
2. Check network: Ensure your app container is on the same Docker network
3. Test connection: `docker exec coder-{workspace_id}-valkey valkey-cli PING`

### Authentication errors

1. Verify password is set correctly in parameters
2. Check environment variables: `echo $VALKEY_PASSWORD`
3. Try without password: Set password to empty string

### Data not persisting

The volume uses `lifecycle { ignore_changes = all }`, so data should persist. If not:
1. Check volume exists: `docker volume ls | grep valkey`
2. Check volume labels match workspace ID

## Complete Example

```hcl
locals {
  workspace_id = data.coder_workspace.me.id
}

resource "docker_network" "internal_network" {
  name     = "coder-${local.workspace_id}-network"
  driver   = "bridge"
  internal = true
}

module "valkey" {
  source = "./modules/valkey"

  workspace_id          = data.coder_workspace.me.id
  workspace_name        = data.coder_workspace.me.name
  username              = data.coder_workspace_owner.me.name
  owner_id              = data.coder_workspace_owner.me.id
  repository            = "https://github.com/example/repo"
  internal_network_name = docker_network.internal_network.name

  order_offset     = 20
  default_enabled  = false
  default_version  = "9-alpine"
  default_password = ""
}

resource "coder_agent" "main" {
  # ... other config ...

  env = merge(
    {
      MY_OTHER_VAR = "value"
    },
    module.valkey.env_vars
  )
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
