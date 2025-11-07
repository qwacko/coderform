variable "agent_id" {
  description = "The Coder agent ID (for MailHog app)"
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
  default     = 30
}

variable "default_enabled" {
  description = "Whether MailHog is enabled by default"
  type        = bool
  default     = false
}

variable "smtp_port" {
  description = "SMTP port for MailHog"
  type        = number
  default     = 1025
}

variable "http_port" {
  description = "HTTP port for MailHog web UI"
  type        = number
  default     = 8025
}

variable "app_group" {
  description = "Group name for Coder apps (used to organize apps in the UI)"
  type        = string
  default     = "Tools"
}
