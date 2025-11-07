variable "agent_id" {
  description = "The Coder agent ID (for pgAdmin app)"
  type        = string
}

variable "workspace_id" {
  description = "The Coder workspace ID (used for naming resources)"
  type        = string
}

variable "workspace_name" {
  description = "The Coder workspace name"
  type        = string
}

variable "username" {
  description = "The workspace owner username"
  type        = string
}

variable "owner_id" {
  description = "The workspace owner ID"
  type        = string
}

variable "repository" {
  description = "Repository URL (for labeling)"
  type        = string
}

variable "internal_network_name" {
  description = "Name of the internal Docker network to attach to"
  type        = string
}

variable "order_offset" {
  description = "Starting order number for parameters in Coder UI"
  type        = number
  default     = 10
}

variable "default_enabled" {
  description = "Whether Postgres is enabled by default"
  type        = bool
  default     = false
}

variable "default_version" {
  description = "Default Postgres version tag"
  type        = string
  default     = "18-alpine"
}

variable "default_user" {
  description = "Default Postgres user"
  type        = string
  default     = "coder"
}

variable "default_password" {
  description = "Default Postgres password"
  type        = string
  default     = "coder"
  sensitive   = true
}

variable "default_database" {
  description = "Default database name"
  type        = string
  default     = "appdb"
}

# ========== Database Management Tools ==========

variable "default_pgweb_enabled" {
  description = "Whether pgweb is enabled by default"
  type        = bool
  default     = false
}

variable "pgweb_port" {
  description = "Port for pgweb web interface"
  type        = number
  default     = 8081
}

variable "default_cloudbeaver_enabled" {
  description = "Whether CloudBeaver is enabled by default"
  type        = bool
  default     = false
}

variable "cloudbeaver_port" {
  description = "Port for CloudBeaver web interface"
  type        = number
  default     = 8978
}

variable "default_mathesar_enabled" {
  description = "Whether Mathesar is enabled by default"
  type        = bool
  default     = false
}

variable "mathesar_port" {
  description = "Port for Mathesar web interface"
  type        = number
  default     = 8000
}

variable "default_pgadmin_enabled" {
  description = "Whether pgAdmin is enabled by default"
  type        = bool
  default     = false
}

variable "pgadmin_port" {
  description = "Port for pgAdmin web interface"
  type        = number
  default     = 8082
}

variable "app_group" {
  description = "Group name for Coder apps (used to organize apps in the UI)"
  type        = string
  default     = "Tools"
}
