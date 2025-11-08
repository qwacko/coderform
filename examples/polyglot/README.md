# Polyglot Development Workspace

A flexible Coder workspace template that allows you to install **multiple language runtimes on-demand** using the `runtime-installer` module.

## Features

- **Dynamic Runtime Installation**: Choose which runtimes to install at workspace creation
- **Module-based Updates**: Runtime installation scripts are pulled from the module, making updates seamless
- **Smart Caching**: Runtimes check if already installed to avoid reinstallation
- **Mutable Parameters**: Change runtime versions without recreating the workspace
- **Lightweight Base Image**: Base Ubuntu image stays small; runtimes installed during startup

## Supported Runtimes

- **Node.js** (18, 20, 22)
- **Python** (3.10, 3.11, 3.12)
- **Go** (1.21, 1.22)
- **Bun** (latest)
- **Rust** (stable, nightly, beta)

## Optional Services

- **PostgreSQL** with pgAdmin and Adminer
- **Valkey** (Redis-compatible) with RedisInsight

## Usage

### 1. Copy this example to your project

```bash
cp -r examples/polyglot my-workspace
cd my-workspace
```

### 2. Update module sources

If using from a git repository:

```hcl
module "runtime_installer" {
  source = "github.com/yourusername/coderform//modules/runtime-installer?ref=v1.0.0"

  workspace_id = local.workspace_id
  order_offset = 100
}
```

### 3. Add additional packages (optional)

You can add extra apt packages in two ways:

**Option A: Via Coder Parameter** (recommended for user choice)

When creating the workspace, users can specify packages in the "Additional apt packages" field:
```
htop tmux neovim net-tools
```

**Option B: Edit the Dockerfile** (for team-wide defaults)

```dockerfile
ARG ADDITIONAL_PACKAGES="htop tmux"  # Set default here
```

### 4. Deploy to Coder

```bash
terraform init
coder templates push polyglot
```

## How It Works

### Startup Flow

1. **Docker Build**: Base Ubuntu image built with system packages + additional packages
2. **Container Starts**: Workspace container starts
3. **Agent Initializes**: Coder agent starts
4. **Runtime Installation**: Module-generated script runs, installing selected runtimes
5. **Service Proxies**: Port forwarding set up for PostgreSQL/Valkey (if enabled)
6. **Ready**: Workspace ready for development

### Module Updates and Script Loading

**How runtime scripts are loaded from GitHub:**

1. When you run `terraform init`, Terraform downloads the module from GitHub to `.terraform/modules/`
2. The `file("${path.module}/scripts/nodejs.sh")` function reads these scripts from the local copy
3. Script contents are embedded into the Terraform plan
4. Scripts are injected into the workspace's `startup_script`

**To get updated runtime installers:**

1. Update the module version in `main.tf`:
   ```hcl
   source = "github.com/yourusername/coderform//modules/runtime-installer?ref=v1.1.0"
   ```

2. Re-initialize and push:
   ```bash
   terraform init -upgrade  # Downloads new module version
   coder templates push polyglot
   ```

3. Rebuild workspace:
   ```bash
   coder stop my-workspace
   coder start my-workspace
   ```

The new installation scripts will be pulled automatically!

### Why `rm -rf /var/lib/apt/lists/*` is OK

The Dockerfile removes apt package lists to reduce image size. This is safe because:
- The runtime installer script runs `sudo apt-get update -qq` first
- This re-downloads the package lists fresh before installing runtimes
- Best practice for production Docker images

## Performance Considerations

**Startup Time**: Installing runtimes adds 1-5 minutes to first startup depending on selections:
- Node.js: ~30 seconds
- Python: ~1-2 minutes (includes PPA setup)
- Go: ~30 seconds
- Bun: ~10 seconds
- Rust: ~2-3 minutes

**Optimization**: Runtimes check if already installed, so rebuilds are fast if you don't change versions.

**Alternative**: For faster startups, consider pre-building Docker images with runtimes included.

## Environment Variables

The module sets these environment variables automatically:

```bash
RUNTIME_NODEJS_ENABLED=true
RUNTIME_NODEJS_VERSION=20
RUNTIME_PYTHON_ENABLED=true
RUNTIME_PYTHON_VERSION=3.12
# ... etc
```

Use these in your scripts to detect available runtimes.

## Troubleshooting

### Check runtime installation logs

```bash
# View agent startup logs in Coder UI
# Or connect to workspace and check:
cat /tmp/coder-startup-script.log
```

### Manually reinstall a runtime

```bash
# Connect to workspace
coder ssh my-workspace

# Source the installation functions
source /tmp/coder-startup-script.log

# Reinstall specific runtime
install_nodejs 20
```

### Runtime not in PATH

Some runtimes add to `~/.bashrc`. Start a new shell:

```bash
exec bash -l
```

## Customization

### Add a new runtime

1. Create installation script in `modules/runtime-installer/scripts/mynewruntime.sh`
2. Add parameter in `modules/runtime-installer/main.tf`
3. Add to `install_commands` in locals
4. Update module version and push

### Change default versions

Edit the `default` values in `modules/runtime-installer/main.tf` parameters.

## License

MIT
