variable "agent_id" {
  description = "The Coder agent ID (for Grafana app)"
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
  default     = 50
}

variable "default_enabled" {
  description = "Whether Grafana OTEL-LGTM is enabled by default"
  type        = bool
  default     = false
}

variable "grafana_port" {
  description = "HTTP port for Grafana web interface"
  type        = number
  default     = 3000
}

variable "otlp_grpc_port" {
  description = "OTLP gRPC receiver port (internal only)"
  type        = number
  default     = 4317
}

variable "otlp_http_port" {
  description = "OTLP HTTP receiver port (internal only)"
  type        = number
  default     = 4318
}

variable "app_group" {
  description = "Group name for Coder apps (used to organize apps in the UI)"
  type        = string
  default     = "Observability"
}

variable "install_mcp_grafana_default" {
  description = "Whether to install mcp-grafana by default"
  type        = bool
  default     = false
}
