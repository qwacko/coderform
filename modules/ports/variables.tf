variable "agent_id" {
  description = "The Coder agent ID to attach apps to"
  type        = string
}

variable "order_offset" {
  description = "Starting order number for parameters in Coder UI"
  type        = number
  default     = 40
}

variable "max_ports" {
  description = "Maximum number of ports that can be configured (0-3)"
  type        = number
  default     = 3

  validation {
    condition     = var.max_ports >= 0 && var.max_ports <= 3
    error_message = "max_ports must be between 0 and 3"
  }
}

variable "default_ports_count" {
  description = "Default number of ports to expose (0-3)"
  type        = number
  default     = 0

  validation {
    condition     = var.default_ports_count >= 0 && var.default_ports_count <= 3
    error_message = "default_ports_count must be between 0 and 3"
  }
}

variable "default_ports" {
  description = "Default port configurations for each port slot"
  type = object({
    port1 = optional(object({
      number = number
      title  = string
      icon   = string
    }), {
      number = 5000
      title  = "Dev Server"
      icon   = "/icon/widgets.svg"
    })
    port2 = optional(object({
      number = number
      title  = string
      icon   = string
    }), {
      number = 4000
      title  = "API"
      icon   = "/icon/widgets.svg"
    })
    port3 = optional(object({
      number = number
      title  = string
      icon   = string
    }), {
      number = 5173
      title  = "Frontend"
      icon   = "/icon/widgets.svg"
    })
  })
  default = {
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
}
