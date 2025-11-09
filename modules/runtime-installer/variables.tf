variable "workspace_id" {
  description = "The ID of the Coder workspace"
  type        = string
}

variable "order_offset" {
  description = "Starting order number for parameters"
  type        = number
  default     = 100
}

# ============================================================================
# Package Manager Defaults
# ============================================================================

variable "nodejs_default_package_manager" {
  description = "Default Node.js package manager (npm, yarn, pnpm, both)"
  type        = string
  default     = "npm"

  validation {
    condition     = contains(["npm", "yarn", "pnpm", "both"], var.nodejs_default_package_manager)
    error_message = "nodejs_default_package_manager must be one of: npm, yarn, pnpm, both"
  }
}

variable "python_default_package_manager" {
  description = "Default Python package manager (pip, poetry, pipenv, uv, both)"
  type        = string
  default     = "pip"

  validation {
    condition     = contains(["pip", "poetry", "pipenv", "uv", "both"], var.python_default_package_manager)
    error_message = "python_default_package_manager must be one of: pip, poetry, pipenv, uv, both"
  }
}

# Runtime enablement (parameters will be created in main.tf)
# These will be populated from coder_parameter data sources
