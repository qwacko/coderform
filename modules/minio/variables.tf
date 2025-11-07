variable "agent_id" {
  description = "The Coder agent ID (for MinIO app)"
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
  default     = 40
}

variable "default_enabled" {
  description = "Whether MinIO is enabled by default"
  type        = bool
  default     = false
}

variable "default_root_user" {
  description = "Default MinIO root user (access key)"
  type        = string
  default     = "minioadmin"
}

variable "default_root_password" {
  description = "Default MinIO root password (secret key)"
  type        = string
  default     = "minioadmin"
  sensitive   = true
}

variable "api_port" {
  description = "MinIO API port"
  type        = number
  default     = 9000
}

variable "console_port" {
  description = "MinIO Console port"
  type        = number
  default     = 9001
}

variable "app_group" {
  description = "Group name for Coder apps (used to organize apps in the UI)"
  type        = string
  default     = "Tools"
}
