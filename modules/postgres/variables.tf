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

variable "default_pgadmin_enabled" {
  description = "Whether pgAdmin is enabled by default"
  type        = bool
  default     = false
}

variable "default_pgadmin_email" {
  description = "Default pgAdmin login email"
  type        = string
  default     = "admin@local.host"
}

variable "default_pgadmin_password" {
  description = "Default pgAdmin login password"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "pgadmin_port" {
  description = "Port for pgAdmin web interface"
  type        = number
  default     = 5050
}

variable "pgadmin_proxy_count" {
  description = "Number of reverse proxies in front of pgAdmin (Caddy + Coder = 2+)"
  type        = number
  default     = 3
}
