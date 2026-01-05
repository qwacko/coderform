variable "agent_id" {
  description = "The Coder agent ID (for the browser app)"
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
  default     = 60
}

variable "default_enabled" {
  description = "Whether the headless browser is enabled by default"
  type        = bool
  default     = false
}

variable "browser_port" {
  description = "HTTP port for the browserless UI and API"
  type        = number
  default     = 3001 # 3000 is often used by dev servers
}

variable "app_group" {
  description = "Group name for Coder apps (used to organize apps in the UI)"
  type        = string
  default     = "AI Tools"
}
