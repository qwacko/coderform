# Polyglot Development Workspace

A flexible Coder workspace template that allows you to install **multiple language runtimes on-demand** using the `runtime-installer` module.

## Features

- **Configurable Ubuntu Version**: Choose from Ubuntu 20.04, 22.04, or 24.04 LTS
- **Dynamic Runtime Installation**: Choose which runtimes to install at workspace creation
- **Module-based Updates**: Runtime installation scripts are pulled from the module, making updates seamless
- **Smart Caching**: Runtimes check if already installed to avoid reinstallation
- **Mutable Parameters**: Change runtime versions without recreating the workspace
- **Custom Packages**: Add additional apt packages via parameter
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

### 3. Configure workspace (optional)

When creating a workspace, you can customize:

**Ubuntu Version:**
- Latest LTS (recommended) - default, automatically uses current Ubuntu LTS
- Ubuntu 24.04 LTS (Noble)
- Ubuntu 22.04 LTS (Jammy)
- Ubuntu 20.04 LTS (Focal)

**Additional apt packages:**
Specify extra packages to install in the base image:
```
htop tmux neovim net-tools
```

**Development Runtimes:**
Choose which language runtimes to install (Node.js, Python, Go, Bun, Rust) and their versions.

### 4. Deploy to Coder

```bash
terraform init
coder templates push polyglot
```

## How It Works

### Build & Startup Flow

**During Docker Build (happens once per configuration):**
1. Base Ubuntu image selected (latest/24.04/22.04/20.04)
2. System packages + additional packages installed
3. Coder user created with sudo privileges
4. Runtime installation script copied to `/tmp/install-runtimes.sh`
5. Image tagged and cached

**During Workspace Startup (happens on each start):**
1. Container starts from built image
2. Coder agent initializes
3. **Selected runtimes installed** (Node.js, Python, Go, Bun, Rust as selected)
   - Output visible in agent startup logs
   - Cached on subsequent starts if already installed
4. Port forwarding set up for PostgreSQL/Valkey (if enabled)
5. Workspace ready for development

**Key Benefit:** Runtimes install during startup, so:
- **Installation output is visible** in agent startup logs
- Smart caching prevents reinstallation if already present
- Changing runtime selections triggers automatic rebuild
- First startup: 1-5 minutes (installing runtimes)
- Subsequent startups: <10 seconds (runtimes cached)

### Module Updates and Script Loading

**How runtime scripts are loaded from GitHub:**

1. When you run `terraform init`, Terraform downloads the module from GitHub to `.terraform/modules/`
2. The `file("${path.module}/scripts/nodejs.sh")` function reads these scripts from the local copy
3. Script contents are embedded into the Terraform plan
4. Script is base64-encoded and passed as `RUNTIME_INSTALL_SCRIPT` build arg
5. Dockerfile decodes and executes the script during image build

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

### Ubuntu Version Compatibility

All supported Ubuntu LTS versions work with the runtime installers:

- **latest** (recommended): Always uses the current Ubuntu LTS release maintained by Docker. Currently points to 24.04, will automatically update when newer LTS versions are released.
- **24.04 (Noble)**: Latest LTS, newest packages, may have compatibility issues with some older tools
- **22.04 (Jammy)**: Previous LTS, stable and well-tested, good balance
- **20.04 (Focal)**: Older LTS, mature and stable, wider package availability

**Recommendation:** Use "latest" unless you need a specific version for compatibility. This ensures you get security updates and the newest Ubuntu features automatically.

**Note:** The runtime installer scripts are designed to work across all LTS versions. If you encounter issues with a specific Ubuntu version, please report them.

## Performance Considerations

**Build Time vs Startup Time:**

**Docker Build** (happens when creating workspace or changing parameters):
- Ubuntu base + packages: ~1 minute
- Copying runtime installation script
- **Total build time**: ~1 minute

**First Workspace Startup** (happens when workspace created):
- Container start: ~5 seconds
- Runtime installation (if runtimes selected):
  - Node.js: +30 seconds
  - Python: +1-2 minutes (includes PPA setup)
  - Go: +30 seconds
  - Bun: +10 seconds
  - Rust: +2-3 minutes
- Port forwarding setup: ~1 second
- **Total first startup**: 1-7 minutes depending on runtime selections

**Subsequent Startups** (runtimes already installed):
- **<10 seconds** - Runtimes detected and skipped!

**Rebuild Behavior:**
- Changing Ubuntu version → full rebuild
- Changing additional packages → full rebuild
- Changing runtime selections → script regenerated (triggers rebuild)
- Modifying the Dockerfile → full rebuild
- No changes → uses cached image (instant)

**Trade-off:** Longer first startup (installing runtimes) for visibility into installation process!

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

### Inspect the generated installation script

The runtime installation script is saved in your workspace at `/tmp/install-runtimes.sh` for debugging:

```bash
# View the script that was executed during build
cat /tmp/install-runtimes.sh

# View the installation logs
cat /tmp/install-runtimes.log

# Re-run it manually if needed (careful - may reinstall things!)
bash /tmp/install-runtimes.sh
```

### Runtime installation failed during startup

If runtime installation fails during workspace startup:

1. **Check agent startup logs** in Coder UI - the full installation output will be displayed
2. **After workspace starts** (even if installation failed), inspect the script and logs:
   ```bash
   cat /tmp/install-runtimes.sh      # The script that ran
   cat /tmp/install-runtimes.log     # Full output and errors
   ```
3. **Debug locally** (if you have Docker and Terraform):
   ```bash
   cd examples/polyglot
   terraform init
   terraform apply  # This generates the script
   # Extract and view the script that would be built:
   terraform show -json | jq -r '.values.root_module.resources[] | select(.address=="docker_image.main") | .values.build.build_args.RUNTIME_INSTALL_SCRIPT' | base64 -d
   ```

Common issues:
- **Network errors**: Runtime installers need internet access during build
- **PPA issues**: Ubuntu 24.04 may have Python PPA compatibility issues
- **Version conflicts**: Try a different Ubuntu base version

### Runtime not in PATH

If a runtime is installed but not found:

```bash
# Check if runtime is actually installed
which node   # or python3, go, bun, rustc

# If installed but not in PATH, reload shell
exec bash -l

# Or source bashrc
source ~/.bashrc
```

### Verify installed runtimes

```bash
# Check what's installed
node --version
python3 --version
go version
bun --version
rustc --version
```

### Force rebuild

To force a complete rebuild (useful for testing):

```bash
# Change any parameter (like additional packages), then change it back
# Or manually trigger via Coder CLI:
coder stop my-workspace
# Delete and recreate workspace
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
