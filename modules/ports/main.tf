terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = ">=2.4.0"
    }
  }
}

# ========== Port Count Parameter ==========

data "coder_parameter" "ports_count" {
  name        = "Ports to Expose"
  description = "Number of ports to expose as Apps"
  type        = "number"
  default     = var.default_ports_count
  mutable     = true
  option {
    name  = "0"
    value = 0
  }
  option {
    name  = "1"
    value = 1
  }
  option {
    name  = "2"
    value = 2
  }
  option {
    name  = "3"
    value = 3
  }
  order = var.order_offset
}

# ========== Port 1 Parameters ==========

data "coder_parameter" "port1_number" {
  count       = data.coder_parameter.ports_count.value >= 1 && var.max_ports >= 1 ? 1 : 0
  name        = "Port 1 Number"
  description = "Port number for App #1"
  type        = "number"
  default     = var.default_ports.port1.number
  mutable     = true
  order       = var.order_offset + 1
}

data "coder_parameter" "port1_title" {
  count       = data.coder_parameter.ports_count.value >= 1 && var.max_ports >= 1 ? 1 : 0
  name        = "Port 1 Title"
  description = "Display name for App #1"
  type        = "string"
  default     = var.default_ports.port1.title
  mutable     = true
  order       = var.order_offset + 2
}

data "coder_parameter" "port1_icon" {
  count       = data.coder_parameter.ports_count.value >= 1 && var.max_ports >= 1 ? 1 : 0
  name        = "Port 1 Icon"
  description = "Icon path for App #1"
  type        = "string"
  default     = var.default_ports.port1.icon
  mutable     = true
  order       = var.order_offset + 3
}

data "coder_parameter" "port1_share" {
  count       = data.coder_parameter.ports_count.value >= 1 && var.max_ports >= 1 ? 1 : 0
  name        = "Port 1 Visibility"
  description = "Who can access App #1"
  type        = "string"
  default     = "owner"
  mutable     = true
  option {
    name  = "Owner"
    value = "owner"
  }
  option {
    name  = "Authenticated"
    value = "authenticated"
  }
  option {
    name  = "Public"
    value = "public"
  }
  order = var.order_offset + 4
}

# ========== Port 2 Parameters ==========

data "coder_parameter" "port2_number" {
  count       = data.coder_parameter.ports_count.value >= 2 && var.max_ports >= 2 ? 1 : 0
  name        = "Port 2 Number"
  description = "Port number for App #2"
  type        = "number"
  default     = var.default_ports.port2.number
  mutable     = true
  order       = var.order_offset + 5
}

data "coder_parameter" "port2_title" {
  count       = data.coder_parameter.ports_count.value >= 2 && var.max_ports >= 2 ? 1 : 0
  name        = "Port 2 Title"
  description = "Display name for App #2"
  type        = "string"
  default     = var.default_ports.port2.title
  mutable     = true
  order       = var.order_offset + 6
}

data "coder_parameter" "port2_icon" {
  count       = data.coder_parameter.ports_count.value >= 2 && var.max_ports >= 2 ? 1 : 0
  name        = "Port 2 Icon"
  description = "Icon path for App #2"
  type        = "string"
  default     = var.default_ports.port2.icon
  mutable     = true
  order       = var.order_offset + 7
}

data "coder_parameter" "port2_share" {
  count       = data.coder_parameter.ports_count.value >= 2 && var.max_ports >= 2 ? 1 : 0
  name        = "Port 2 Visibility"
  description = "Who can access App #2"
  type        = "string"
  default     = "owner"
  mutable     = true
  option {
    name  = "Owner"
    value = "owner"
  }
  option {
    name  = "Authenticated"
    value = "authenticated"
  }
  option {
    name  = "Public"
    value = "public"
  }
  order = var.order_offset + 8
}

# ========== Port 3 Parameters ==========

data "coder_parameter" "port3_number" {
  count       = data.coder_parameter.ports_count.value >= 3 && var.max_ports >= 3 ? 1 : 0
  name        = "Port 3 Number"
  description = "Port number for App #3"
  type        = "number"
  default     = var.default_ports.port3.number
  mutable     = true
  order       = var.order_offset + 9
}

data "coder_parameter" "port3_title" {
  count       = data.coder_parameter.ports_count.value >= 3 && var.max_ports >= 3 ? 1 : 0
  name        = "Port 3 Title"
  description = "Display name for App #3"
  type        = "string"
  default     = var.default_ports.port3.title
  mutable     = true
  order       = var.order_offset + 10
}

data "coder_parameter" "port3_icon" {
  count       = data.coder_parameter.ports_count.value >= 3 && var.max_ports >= 3 ? 1 : 0
  name        = "Port 3 Icon"
  description = "Icon path for App #3"
  type        = "string"
  default     = var.default_ports.port3.icon
  mutable     = true
  order       = var.order_offset + 11
}

data "coder_parameter" "port3_share" {
  count       = data.coder_parameter.ports_count.value >= 3 && var.max_ports >= 3 ? 1 : 0
  name        = "Port 3 Visibility"
  description = "Who can access App #3"
  type        = "string"
  default     = "owner"
  mutable     = true
  option {
    name  = "Owner"
    value = "owner"
  }
  option {
    name  = "Authenticated"
    value = "authenticated"
  }
  option {
    name  = "Public"
    value = "public"
  }
  order = var.order_offset + 12
}

# ========== Derived Locals ==========

locals {
  ports_count = data.coder_parameter.ports_count.value

  port1_num   = local.ports_count >= 1 && var.max_ports >= 1 ? data.coder_parameter.port1_number[0].value : 0
  port1_title = local.ports_count >= 1 && var.max_ports >= 1 ? data.coder_parameter.port1_title[0].value : ""
  port1_icon  = local.ports_count >= 1 && var.max_ports >= 1 ? data.coder_parameter.port1_icon[0].value : "/icon/server.svg"
  port1_share = local.ports_count >= 1 && var.max_ports >= 1 ? data.coder_parameter.port1_share[0].value : "owner"

  port2_num   = local.ports_count >= 2 && var.max_ports >= 2 ? data.coder_parameter.port2_number[0].value : 0
  port2_title = local.ports_count >= 2 && var.max_ports >= 2 ? data.coder_parameter.port2_title[0].value : ""
  port2_icon  = local.ports_count >= 2 && var.max_ports >= 2 ? data.coder_parameter.port2_icon[0].value : "/icon/terminal.svg"
  port2_share = local.ports_count >= 2 && var.max_ports >= 2 ? data.coder_parameter.port2_share[0].value : "owner"

  port3_num   = local.ports_count >= 3 && var.max_ports >= 3 ? data.coder_parameter.port3_number[0].value : 0
  port3_title = local.ports_count >= 3 && var.max_ports >= 3 ? data.coder_parameter.port3_title[0].value : ""
  port3_icon  = local.ports_count >= 3 && var.max_ports >= 3 ? data.coder_parameter.port3_icon[0].value : "/icon/browser.svg"
  port3_share = local.ports_count >= 3 && var.max_ports >= 3 ? data.coder_parameter.port3_share[0].value : "owner"
}

# ========== Coder Apps ==========

resource "coder_app" "port1" {
  count        = local.ports_count >= 1 && var.max_ports >= 1 ? 1 : 0
  agent_id     = var.agent_id
  slug         = "port1"
  display_name = local.port1_title
  icon         = local.port1_icon
  url          = "http://localhost:${local.port1_num}"
  share        = local.port1_share
  subdomain    = true
}

resource "coder_app" "port2" {
  count        = local.ports_count >= 2 && var.max_ports >= 2 ? 1 : 0
  agent_id     = var.agent_id
  slug         = "port2"
  display_name = local.port2_title
  icon         = local.port2_icon
  url          = "http://localhost:${local.port2_num}"
  share        = local.port2_share
  subdomain    = true
}

resource "coder_app" "port3" {
  count        = local.ports_count >= 3 && var.max_ports >= 3 ? 1 : 0
  agent_id     = var.agent_id
  slug         = "port3"
  display_name = local.port3_title
  icon         = local.port3_icon
  url          = "http://localhost:${local.port3_num}"
  share        = local.port3_share
  subdomain    = true
}
