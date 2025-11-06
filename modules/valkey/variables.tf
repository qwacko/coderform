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
  default     = 20
}

variable "default_enabled" {
  description = "Whether Valkey is enabled by default"
  type        = bool
  default     = false
}

variable "default_version" {
  description = "Default Valkey version tag"
  type        = string
  default     = "9-alpine"
}

variable "default_password" {
  description = "Default Valkey password (empty = no auth)"
  type        = string
  default     = ""
  sensitive   = true
}
