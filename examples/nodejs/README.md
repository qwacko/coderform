# Node.js Workspace Example

A complete Coder workspace template for Node.js development with PostgreSQL, Valkey (Redis), and configurable ports.

> **⚠️ This is a complete template, not a module**
> This example includes a Dockerfile and build context, so it **cannot be imported as a module**. Instead, you should:
> - **Copy** the entire directory to your Coder templates location
> - **Clone** the repository and use this directory
> - **Point Coder** directly at this directory in the Git repository
>
> See the [main README](../../README.md#how-to-use-examples) for detailed usage instructions.

## Features

- **Node.js Environment**: Configurable Node.js versions (20, 22, 24, 25)
- **PostgreSQL Database**: Optional PostgreSQL with management tools:
  - pgweb (lightweight browser)
  - CloudBeaver (full-featured manager)
  - Mathesar (spreadsheet-like interface)
- **Valkey (Redis)**: Optional Redis-compatible cache
- **Configurable Ports**: Expose custom ports for your applications
- **Git Integration**: Automatic repository cloning
- **VS Code Web**: Browser-based VS Code editor
- **Persistent Storage**: Home directory persists across workspace restarts

## Quick Start

1. **Create a new workspace** in Coder using this template
2. **Configure parameters**:
   - Select Node.js version
   - Enter your Git repository URL
   - Enable PostgreSQL if needed
   - Enable Valkey if needed
   - Configure exposed ports
3. **Start the workspace** and wait for initialization

## Workspace Parameters

### Base Configuration

- **Node.js Base Image**: Choose Node.js version (20, 22, 24, or 25)
- **Repository URL**: Git repository to clone

### Database Services (Order: 90)

When PostgreSQL is enabled:
- **Postgres Version**: 15, 16, 17, or 18 (Alpine Linux)
- **Database User**: Username for PostgreSQL
- **Database Password**: Password for PostgreSQL
- **Database Name**: Name of the default database
- **Enable pgweb**: Lightweight web-based database browser
- **Enable CloudBeaver**: Full-featured database management tool
- **Enable Mathesar**: Spreadsheet-like interface for PostgreSQL

### Cache Services (Order: 80)

- **Enable Valkey**: Redis-compatible in-memory data store
- **Valkey Version**: Select version tag
- **Valkey Password**: Optional authentication password

### Port Exposure (Order: 100)

- **Ports to Expose**: Number of ports (0-3)
- For each port:
  - Port number
  - Display title
  - Icon
  - Visibility (owner/authenticated/public)

## Architecture

### Docker Networks

- **Internal Network**: Isolated bridge network for inter-service communication
  - Postgres, Valkey, and workspace container communicate here
  - IPv6 disabled to avoid DNS resolution issues
- **Bridge Network**: Default Docker network for external connectivity

### Port Forwarding

Database management tools run in separate containers and use socat proxies to forward ports from localhost to the containers:

- **pgweb**: `localhost:8081` → `pgweb:8081`
- **CloudBeaver**: `localhost:8978` → `cloudbeaver:8978`
- **Mathesar**: `localhost:8000` → `mathesar:8000`

This forwarding happens automatically in the agent startup script.

### Persistent Volumes

- **Home Directory**: `/home/<username>` - Persists code, config, and data
- **PostgreSQL Data**: Database files persist across restarts
- **CloudBeaver Config**: Connection settings persist
- **Mathesar Config**: Schema and settings persist

## Environment Variables

When PostgreSQL is enabled, these environment variables are automatically set:

```bash
POSTGRES_ENABLED="true"
POSTGRES_HOST="postgres"
POSTGRES_PORT="5432"
POSTGRES_USER="<your-user>"
POSTGRES_PASSWORD="<your-password>"
POSTGRES_DB="<your-database>"
```

### Connecting to PostgreSQL

#### From Node.js (using pg)

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

#### From Command Line

```bash
psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB
```

### Connecting to Valkey

Valkey is accessible at `valkey:6379` from within the workspace container.

## Customization

### Modifying the Dockerfile

Edit `build/Dockerfile` to:
- Add additional system packages
- Install global npm packages
- Configure environment settings

The Dockerfile rebuilds when:
- Any file in `build/` changes
- Node.js base image parameter changes

### Changing Module Versions

Update the module sources in `main.tf`:

```hcl
module "postgres" {
  source = "github.com/qwacko/coderform//modules/postgres?ref=v1.0.0"
  # ...
}
```

## Troubleshooting

### Database management tools show 502 Bad Gateway

1. Check if socat proxies are running:
   ```bash
   ps aux | grep socat
   ```

2. Check proxy logs:
   ```bash
   cat /tmp/proxy-pgweb.log
   cat /tmp/proxy-cloudbeaver.log
   cat /tmp/proxy-mathesar.log
   ```

3. Verify containers are running:
   ```bash
   docker ps | grep postgres
   docker ps | grep pgweb
   ```

### Can't connect to PostgreSQL

1. Verify Postgres is enabled in workspace parameters
2. Check if container is running:
   ```bash
   docker ps | grep postgres
   ```
3. Test connection:
   ```bash
   psql -h postgres -U $POSTGRES_USER -d $POSTGRES_DB -c "SELECT 1;"
   ```

### IPv6 DNS issues

The startup script automatically adds IPv4 entries to `/etc/hosts`. Verify:

```bash
cat /etc/hosts | grep -E "postgres|valkey|pgweb|cloudbeaver|mathesar"
```

### Workspace won't start

Check the agent logs in Coder UI for errors. Common issues:
- Dockerfile build failures
- Missing required parameters
- Docker network conflicts

## File Structure

```
examples/nodejs/
├── main.tf              # Workspace infrastructure definition
├── build/
│   └── Dockerfile       # Workspace container image
└── README.md           # This file
```

## What Happens During Startup

1. **Container Start**: Workspace container starts with Coder agent
2. **Network Setup**: Container joins internal and bridge networks
3. **IPv4 Resolution**: Adds service hosts to `/etc/hosts`
4. **Port Forwarding**: Sets up socat proxies for management tools
5. **Package Installation**: Installs pnpm via startup script
6. **Git Clone**: Clones repository (via git-clone module)
7. **VS Code Web**: Starts browser-based editor

## Package Management

This workspace uses **pnpm** as the Node.js package manager:

```bash
pnpm install         # Install dependencies
pnpm add <package>   # Add a package
pnpm dev            # Run dev script
```

npm and yarn are also available if needed.

## Requirements

- Coder >= 2.4.0
- Docker provider
- Access to Docker daemon

## Based On

This example uses modules from the [coderform](https://github.com/qwacko/coderform) repository:

- [Postgres Module](../../modules/postgres/)
- [Valkey Module](../../modules/valkey/)
- [Ports Module](../../modules/ports/)

## License

Same as parent repository.
