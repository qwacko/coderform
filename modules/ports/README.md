# Coder Ports Module

A Terraform module that provides complete port exposure functionality for Coder workspaces. This module creates user-configurable parameters and corresponding Coder apps to expose up to 3 ports from your workspace.

## Features

- Complete self-contained port exposure system
- User-configurable through Coder workspace parameters
- Supports up to 3 ports with customizable settings
- Configurable parameter ordering in Coder UI
- Each port can be individually configured for:
  - Port number
  - Display title
  - Icon
  - Visibility (owner/authenticated/public)
- Conditional parameters (only show when ports are enabled)

## Quick Start

### Minimal Example

```hcl
module "ports" {
  source = "github.com/qwacko/coderform//modules/ports"

  agent_id = coder_agent.main.id
}
```

This creates:
- A parameter asking users how many ports to expose (0-3)
- Conditional parameters for each enabled port
- Coder apps for each configured port
- All parameters start at order 40 by default

### Specify Parameter Order

```hcl
module "ports" {
  source = "github.com/qwacko/coderform//modules/ports"

  agent_id     = coder_agent.main.id
  order_offset = 100  # Parameters will be ordered 100, 101, 102, etc.
}
```

### Customize Default Port Settings

```hcl
module "ports" {
  source = "github.com/qwacko/coderform//modules/ports"

  agent_id     = coder_agent.main.id
  order_offset = 40
  max_ports    = 3

  default_ports = {
    port1 = {
      number = 3000
      title  = "Next.js Dev"
      icon   = "/icon/code.svg"
    }
    port2 = {
      number = 8080
      title  = "Backend API"
      icon   = "/icon/server.svg"
    }
    port3 = {
      number = 5173
      title  = "Vite Frontend"
      icon   = "/icon/browser.svg"
    }
  }
}
```

### Limit Maximum Ports

```hcl
module "ports" {
  source = "github.com/qwacko/coderform//modules/ports"

  agent_id  = coder_agent.main.id
  max_ports = 1  # Only allow users to configure up to 1 port
}
```

### Set Default Port Count

```hcl
module "ports" {
  source = "github.com/qwacko/coderform//modules/ports"

  agent_id            = coder_agent.main.id
  default_ports_count = 0  # Default to 0 ports when creating workspace
}
```

Users will see "2" selected by default when creating their workspace, but can still change it to 0, 1, 2, or 3.

## How It Works

When you use this module:

1. **Port Count Parameter**: Users are asked "How many ports to expose?" (0-3)
2. **Conditional Parameters**: Based on the selection, users see parameters for each port:
   - Port Number
   - Display Title
   - Icon Path
   - Visibility Level
3. **Coder Apps Created**: The module automatically creates `coder_app` resources for each configured port
4. **Parameter Ordering**: All parameters are ordered sequentially starting from `order_offset`

### Parameter Ordering

Parameters are ordered as follows (assuming `order_offset = 40`):

| Parameter | Order |
|-----------|-------|
| Ports to Expose | 40 |
| Port 1 Number | 41 |
| Port 1 Title | 42 |
| Port 1 Icon | 43 |
| Port 1 Visibility | 44 |
| Port 2 Number | 45 |
| Port 2 Title | 46 |
| Port 2 Icon | 47 |
| Port 2 Visibility | 48 |
| Port 3 Number | 49 |
| Port 3 Title | 50 |
| Port 3 Icon | 51 |
| Port 3 Visibility | 52 |

## Variables

### Required Variables

| Name | Type | Description |
|------|------|-------------|
| `agent_id` | `string` | The Coder agent ID to attach apps to |

### Optional Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `order_offset` | `number` | `40` | Starting order number for parameters in Coder UI |
| `max_ports` | `number` | `3` | Maximum number of ports (0-3) |
| `default_ports_count` | `number` | `0` | Default number of ports to expose when creating workspace |
| `default_ports` | `object` | See below | Default configurations for each port |

### Default Port Configurations

By default, the module uses these settings:

```hcl
default_ports = {
  port1 = {
    number = 5000
    title  = "Dev Server"
    icon   = "/icon/widgets.svg"
  }
  port2 = {
    number = 4000
    title  = "API"
    icon   = "/icon/widgets.svg"
  }
  port3 = {
    number = 5173
    title  = "Frontend"
    icon   = "/icon/widgets.svg"
  }
}
```

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `ports_count` | `number` | Number of ports configured by the user |
| `port1` | `object` | Port 1 details (null if not configured) |
| `port2` | `object` | Port 2 details (null if not configured) |
| `port3` | `object` | Port 3 details (null if not configured) |
| `all_ports` | `list(object)` | List of all configured ports |

### Port Object Structure

Each port output contains:
```hcl
{
  number = 5000
  title  = "Dev Server"
  icon   = "/icon/widgets.svg"
  share  = "owner"
  app_id = "abc123..."
  url    = "http://localhost:5000"
}
```

### Using Outputs

```hcl
# Access specific port configuration
output "dev_server_port" {
  value = module.ports.port1.number
}

# Check how many ports are configured
output "total_ports" {
  value = module.ports.ports_count
}

# Get all configured ports
output "all_exposed_ports" {
  value = module.ports.all_ports
}
```

## Common Icon Paths

Coder provides several built-in icons:

- `/icon/widgets.svg` - Generic widget
- `/icon/server.svg` - Server
- `/icon/browser.svg` - Browser
- `/icon/terminal.svg` - Terminal
- `/icon/code.svg` - Code editor
- `/icon/database.svg` - Database

## User Experience

When users create a workspace with this module:

1. They select how many ports to expose (0-3)
2. For each port, they configure:
   - Port number (e.g., 5000, 3000, 8080)
   - Display name (e.g., "Dev Server", "API")
   - Icon path
   - Who can access it (owner/authenticated/public)
3. The configured apps appear in their Coder dashboard
4. Clicking an app opens the specified port in their browser

## Migration from Inline Configuration

If you're currently using inline port parameters like in the main coderform template, you can replace:

```hcl
# OLD: Lines 185-354 in main.tf
data "coder_parameter" "ports_count" { ... }
data "coder_parameter" "port1_number" { ... }
# ... many more parameter definitions ...
resource "coder_app" "port1" { ... }
resource "coder_app" "port2" { ... }
resource "coder_app" "port3" { ... }
```

With:

```hcl
# NEW: Single module call
module "ports" {
  source       = "./modules/ports"
  agent_id     = coder_agent.main.id
  order_offset = 40
}
```

## Advanced Usage

### Multiple Port Modules

You can use the module multiple times with different order offsets:

```hcl
module "dev_ports" {
  source       = "./modules/ports"
  agent_id     = coder_agent.main.id
  order_offset = 40
  max_ports    = 2
  default_ports = {
    port1 = { number = 3000, title = "Dev Server", icon = "/icon/code.svg" }
    port2 = { number = 3001, title = "Preview", icon = "/icon/browser.svg" }
  }
}

module "db_ports" {
  source       = "./modules/ports"
  agent_id     = coder_agent.main.id
  order_offset = 60
  max_ports    = 1
  default_ports = {
    port1 = { number = 5432, title = "PostgreSQL", icon = "/icon/database.svg" }
  }
}
```

### Conditional Module Usage

```hcl
variable "enable_port_exposure" {
  type    = bool
  default = true
}

module "ports" {
  count  = var.enable_port_exposure ? 1 : 0
  source = "./modules/ports"

  agent_id = coder_agent.main.id
}
```

## Requirements

- Terraform >= 1.0
- Coder provider >= 2.4.0

## Notes

- The module creates `coder_parameter` data sources, so users configure ports at workspace creation/update time
- Port slugs are fixed as `port1`, `port2`, `port3`
- All apps have `subdomain = true` enabled
- Visibility defaults to `owner` for all ports
- The actual services must be listening on the configured ports for the apps to work

## Source

This module is part of the [coderform](https://github.com/qwacko/coderform) repository.

Use it directly from GitHub:
```hcl
module "ports" {
  source = "github.com/qwacko/coderform//modules/ports"
  # ...
}
```

Or use a local path:
```hcl
module "ports" {
  source = "./modules/ports"
  # ...
}
```

## License

Same as the parent repository.
