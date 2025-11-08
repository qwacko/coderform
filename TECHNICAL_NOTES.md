# Technical Notes

## How Module Script Loading Works from GitHub

### The Question
When using `source = "github.com/qwacko/coderform//modules/runtime-installer"`, how does `file("${path.module}/scripts/nodejs.sh")` work?

### The Answer

**TL;DR: It works perfectly!** ✅

### The Process

1. **Module Download** (`terraform init`)
   ```bash
   terraform init
   # Downloads module to: .terraform/modules/runtime_installer/
   ```

2. **File Reading** (during `terraform plan`)
   ```hcl
   # This reads from the downloaded module directory
   file("${path.module}/scripts/nodejs.sh")
   # Expands to: .terraform/modules/runtime_installer/scripts/nodejs.sh
   ```

3. **Content Embedding**
   - The `file()` function reads the script content at **plan time**
   - Content is embedded into the Terraform state
   - The script becomes part of the `install_script` output

4. **Script Injection** (during `terraform apply`)
   ```hcl
   startup_script = <<-EOT
     ${module.runtime_installer.install_script}
   EOT
   ```
   - The embedded script content is injected into the workspace configuration
   - Workspace container runs this script on startup

### Update Flow

```bash
# 1. Update module version in main.tf
source = "github.com/.../runtime-installer?ref=v1.1.0"

# 2. Download new version
terraform init -upgrade

# 3. Plan will show changes to startup_script (if scripts changed)
terraform plan

# 4. Apply to update workspace template
terraform apply

# 5. Workspace uses new scripts on next start
coder stop my-workspace && coder start my-workspace
```

### Key Insight

The scripts are **not** fetched during workspace startup. They're:
- Fetched during `terraform init`
- Read during `terraform plan`
- Embedded in the workspace template
- Executed from the embedded copy during startup

This means:
- ✅ No internet access needed during workspace startup
- ✅ Scripts are versioned with your workspace template
- ✅ Updates require `terraform init -upgrade`
- ✅ Consistent behavior across workspace rebuilds

## Why `rm -rf /var/lib/apt/lists/*` is Safe

### The Question
If we delete `/var/lib/apt/lists/*` in the Dockerfile, can the runtime installers still install packages?

### The Answer

**Yes, it's completely safe!** ✅

### Explanation

**What `/var/lib/apt/lists/*` contains:**
- Package index files (lists of available packages)
- Downloaded by `apt-get update`
- Used by `apt-get install` to find packages

**Why deleting is OK:**

1. **In Dockerfile** (build time):
   ```dockerfile
   RUN apt-get update && \
       apt-get install -y curl git ... && \
       rm -rf /var/lib/apt/lists/*  # ← Reduces image size
   ```
   - We install packages, then delete the lists
   - Reduces final image size by ~20-50MB
   - Standard Docker best practice

2. **In Runtime Installer** (container startup):
   ```bash
   # The script does this first:
   sudo apt-get update -qq  # ← Re-downloads the lists

   # Then installs packages:
   sudo apt-get install -y nodejs
   ```
   - `apt-get update` re-downloads package lists
   - Fresh lists, no stale cache issues
   - Works perfectly!

### Best Practices

**DO**: Clean up after each RUN command in Dockerfile
```dockerfile
RUN apt-get update && \
    apt-get install -y foo bar && \
    rm -rf /var/lib/apt/lists/*
```

**DON'T**: Run update in a separate RUN command
```dockerfile
# BAD - creates larger layers
RUN apt-get update
RUN apt-get install -y foo bar
RUN rm -rf /var/lib/apt/lists/*
```

## Additional Packages Pattern

### Implementation

**1. Coder Parameter** (user choice)
```hcl
data "coder_parameter" "additional_packages" {
  name    = "additional_packages"
  type    = "string"
  default = ""
}
```

**2. Dockerfile Build Arg**
```dockerfile
ARG ADDITIONAL_PACKAGES=""

RUN apt-get update && \
    apt-get install -y \
        curl \
        git \
        ${ADDITIONAL_PACKAGES} \
        && rm -rf /var/lib/apt/lists/*
```

**3. Docker Build**
```hcl
resource "docker_image" "workspace" {
  build {
    build_args = {
      ADDITIONAL_PACKAGES = data.coder_parameter.additional_packages.value
    }
  }
}
```

### Why This Works

- Users can specify: `"htop tmux vim"`
- Docker interpolates: `apt-get install -y curl git htop tmux vim`
- Empty string works fine: `apt-get install -y curl git `

### Alternatives Considered

**Option A: Install in startup script**
```bash
# In startup_script
sudo apt-get update
sudo apt-get install -y ${ADDITIONAL_PACKAGES}
```
❌ Slower (runs every start, not just rebuild)
❌ Requires internet access during startup

**Option B: Build arg** (chosen) ✅
✅ Fast (packages in base image)
✅ No runtime dependency on apt repos
✅ Users choose via parameter

## Module vs Example

### Why Examples Can't Be Modules

**Problem:**
```
examples/polyglot/
├── main.tf
└── build/Dockerfile  # ← This breaks it!
```

**Reason:**
- Modules are meant to be referenced remotely
- Docker build context requires local files
- Can't have both in the same directory

**Solution:**
- **Modules** = Infrastructure components (postgres, valkey, runtime-installer)
- **Examples** = Complete templates that *use* modules
- Examples are copied and customized, not imported

### The Runtime Installer Workaround

Instead of making the workspace a module, we:
1. Make a module that **generates scripts**
2. Examples import the module
3. Scripts run during startup

This gives us:
- ✅ Module-style updates
- ✅ Dockerfile in example
- ✅ User customization
- ✅ Version control

Clever, right? 😎
