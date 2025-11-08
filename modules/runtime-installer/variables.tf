variable "workspace_id" {
  description = "The ID of the Coder workspace"
  type        = string
}

variable "order_offset" {
  description = "Starting order number for parameters"
  type        = number
  default     = 100
}

# Runtime enablement (parameters will be created in main.tf)
# These will be populated from coder_parameter data sources
