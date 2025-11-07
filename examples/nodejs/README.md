# Node.js Workspace Example

A complete Coder workspace template for Node.js development with PostgreSQL, Valkey (Redis), MinIO, MailHog, API testing, and configurable ports.

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
  - pgAdmin (full-featured administration)
  - Mathesar (spreadsheet-like interface)
- **Valkey (Redis)**: Optional Redis-compatible cache with web UIs:
  - redis-commander (lightweight browser)
  - RedisInsight (full-featured GUI)
- **MailHog**: Email testing tool with SMTP capture and web UI
- **MinIO**: S3-compatible object storage with web console
- **Hoppscotch**: API development and testing tool (Postman alternative)
- **Configurable Ports**: Expose custom ports for your applications
- **Git Integration**: Automatic repository cloning
- **VS Code Web**: Browser-based VS Code editor
- **Persistent Storage**: Home directory and all service data persists across workspace restarts

## Quick Start

1. **Create a new workspace** in Coder using this template
2. **Configure parameters**:
   - Select Node.js version
   - Enter your Git repository URL
   - Enable PostgreSQL if needed (with optional web UIs)
   - Enable Valkey if needed (with optional web UIs)
   - Enable MailHog for email testing
   - Enable MinIO for S3-compatible storage
   - Enable Hoppscotch for API testing
   - Configure exposed ports for your application
3. **Start the workspace** and wait for initialization
4. **Access services** through the Coder dashboard apps menu

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
- **Enable pgweb**: Lightweight web-based database browser (port 8081)
- **Enable pgAdmin**: Full-featured database administration tool (port 8082)
- **Enable Mathesar**: Spreadsheet-like interface for PostgreSQL (port 8000)

### Cache Services (Order: 80)

- **Enable Valkey**: Redis-compatible in-memory data store
- **Valkey Version**: Select version tag (7-9)
- **Valkey Password**: Optional authentication password
- **Enable redis-commander**: Lightweight Redis web browser (port 8083)
- **Enable RedisInsight**: Full-featured Redis GUI from Redis Ltd (port 5540)

### Email Testing (Order: 70)

- **Enable MailHog**: Email testing tool with SMTP capture
  - SMTP server on port 1025
  - Web UI on port 8025

### Object Storage (Order: 60)

When MinIO is enabled:
- **MinIO Root User**: Access key for S3 API
- **MinIO Root Password**: Secret key for S3 API (min 8 chars)
  - API endpoint on port 9000
  - Web console on port 9001

### API Testing (Order: 50)

- **Enable Hoppscotch**: Open-source API development tool (port 3000)
  - REST, GraphQL, and WebSocket support
  - Collections and environments

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

All web-based management tools run in separate containers and use socat proxies to forward ports from localhost to the containers:

**PostgreSQL Tools:**
- **pgweb**: `localhost:8081` → `pgweb:8081`
- **pgAdmin**: `localhost:8082` → `pgadmin:80`
- **Mathesar**: `localhost:8000` → `mathesar:8000`

**Valkey Tools:**
- **redis-commander**: `localhost:8083` → `redis-commander:8083`
- **RedisInsight**: `localhost:5540` → `redisinsight:5540`

**Other Services:**
- **MailHog**: `localhost:8025` → `mailhog:8025`
- **MinIO API**: `localhost:9000` → `minio:9000`
- **MinIO Console**: `localhost:9001` → `minio:9001`
- **Hoppscotch**: `localhost:3000` → `hoppscotch:3000`

This forwarding happens automatically in the agent startup script.

### Persistent Volumes

- **Home Directory**: `/home/<username>` - Persists code, config, and data
- **PostgreSQL Data**: Database files persist across restarts
- **pgAdmin Config**: Connection settings and preferences persist
- **Mathesar Config**: Schema and settings persist
- **Valkey Data**: Cache data persists (with AOF enabled)
- **RedisInsight Config**: Connection settings persist
- **MinIO Data**: Object storage data persists
- **Hoppscotch Data**: Collections and environments persist

## Environment Variables

All enabled services automatically set environment variables in your workspace:

### PostgreSQL

```bash
POSTGRES_ENABLED="true"
POSTGRES_HOST="postgres"
POSTGRES_PORT="5432"
POSTGRES_USER="<your-user>"
POSTGRES_PASSWORD="<your-password>"
POSTGRES_DB="<your-database>"
```

### Valkey (Redis)

```bash
VALKEY_ENABLED="true"
VALKEY_HOST="valkey"
VALKEY_PORT="6379"
VALKEY_PASSWORD="<your-password>"
```

### MailHog

```bash
MAILHOG_ENABLED="true"
MAILHOG_SMTP_HOST="mailhog"
MAILHOG_SMTP_PORT="1025"
SMTP_HOST="mailhog"
SMTP_PORT="1025"
```

### MinIO

```bash
MINIO_ENABLED="true"
MINIO_ENDPOINT="http://minio:9000"
MINIO_ROOT_USER="<access-key>"
MINIO_ROOT_PASSWORD="<secret-key>"
MINIO_ACCESS_KEY="<access-key>"
MINIO_SECRET_KEY="<secret-key>"
S3_ENDPOINT="http://minio:9000"
S3_ACCESS_KEY_ID="<access-key>"
S3_SECRET_ACCESS_KEY="<secret-key>"
```

### Hoppscotch

```bash
HOPPSCOTCH_ENABLED="true"
HOPPSCOTCH_URL="http://hoppscotch:3000"
```

## Connecting to Services

### PostgreSQL

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

### Valkey (Redis)

#### From Node.js (using ioredis)

```javascript
const Redis = require('ioredis');

const redis = new Redis({
  host: process.env.VALKEY_HOST,
  port: parseInt(process.env.VALKEY_PORT),
  password: process.env.VALKEY_PASSWORD || undefined,
});
```

#### From Command Line

```bash
redis-cli -h $VALKEY_HOST -p $VALKEY_PORT -a $VALKEY_PASSWORD
```

### MailHog (SMTP)

#### From Node.js (using nodemailer)

```javascript
const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: parseInt(process.env.SMTP_PORT),
  secure: false,
});

await transporter.sendMail({
  from: 'test@example.com',
  to: 'recipient@example.com',
  subject: 'Test Email',
  text: 'This email is captured by MailHog!',
});
```

### MinIO (S3)

#### From Node.js (using AWS SDK)

```javascript
const AWS = require('aws-sdk');

const s3 = new AWS.S3({
  endpoint: process.env.S3_ENDPOINT,
  accessKeyId: process.env.S3_ACCESS_KEY_ID,
  secretAccessKey: process.env.S3_SECRET_ACCESS_KEY,
  s3ForcePathStyle: true,
  signatureVersion: 'v4',
});

// Upload a file
await s3.upload({
  Bucket: 'mybucket',
  Key: 'myfile.txt',
  Body: 'Hello World!',
}).promise();
```

#### Using MinIO Client (mc)

```bash
mc alias set local http://minio:9000 $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD
mc mb local/mybucket
mc cp myfile.txt local/mybucket/
```

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

### Web UI tools show 502 Bad Gateway

1. Check if socat proxies are running:
   ```bash
   ps aux | grep socat
   ```

2. Check proxy logs for specific services:
   ```bash
   cat /tmp/proxy-pgweb.log
   cat /tmp/proxy-pgadmin.log
   cat /tmp/proxy-mathesar.log
   cat /tmp/proxy-redis-commander.log
   cat /tmp/proxy-redisinsight.log
   cat /tmp/proxy-mailhog.log
   cat /tmp/proxy-minio-api.log
   cat /tmp/proxy-minio-console.log
   cat /tmp/proxy-hoppscotch.log
   ```

3. Verify containers are running:
   ```bash
   docker ps | grep -E "postgres|valkey|pgweb|pgadmin|mathesar|redis-commander|redisinsight|mailhog|minio|hoppscotch"
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

### Can't connect to Valkey

1. Verify Valkey is enabled in workspace parameters
2. Check if container is running:
   ```bash
   docker ps | grep valkey
   ```
3. Test connection:
   ```bash
   redis-cli -h valkey -p 6379 -a "$VALKEY_PASSWORD" PING
   ```

### Email not being captured by MailHog

1. Verify MailHog is enabled and running
2. Check if your application is using the correct SMTP settings:
   - Host: `mailhog` or `$SMTP_HOST`
   - Port: `1025` or `$SMTP_PORT`
3. View MailHog web UI at `localhost:8025` to see captured emails

### MinIO connection issues

1. Verify MinIO is enabled and running
2. Check environment variables are set correctly
3. Ensure your S3 client is using `s3ForcePathStyle: true`
4. Test connection:
   ```bash
   mc alias set test http://minio:9000 $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD
   mc ls test
   ```

### IPv6 DNS issues

The startup script automatically adds IPv4 entries to `/etc/hosts`. Verify:

```bash
cat /etc/hosts | grep -E "postgres|valkey|pgweb|pgadmin|mathesar|redis-commander|redisinsight|mailhog|minio|hoppscotch"
```

### Workspace won't start

Check the agent logs in Coder UI for errors. Common issues:
- Dockerfile build failures
- Missing required parameters
- Docker network conflicts
- Port conflicts between services

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
3. **Service Containers**: All enabled services start (postgres, valkey, mailhog, minio, hoppscotch)
4. **IPv4 Resolution**: Adds service hosts to `/etc/hosts`
5. **Port Forwarding**: Sets up socat proxies for all web-based management tools
6. **Package Installation**: Installs pnpm via startup script
7. **Git Clone**: Clones repository (via git-clone module)
8. **VS Code Web**: Starts browser-based editor
9. **Web UIs Available**: All enabled management tools are accessible via Coder dashboard

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

- [Postgres Module](../../modules/postgres/) - PostgreSQL database with web management tools
- [Valkey Module](../../modules/valkey/) - Redis-compatible cache with web UIs
- [MailHog Module](../../modules/mailhog/) - Email testing tool
- [MinIO Module](../../modules/minio/) - S3-compatible object storage
- [API Testing Module](../../modules/apitesting/) - Hoppscotch API development tool
- [Ports Module](../../modules/ports/) - Dynamic port exposure

## License

Same as parent repository.
