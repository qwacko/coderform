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
# Default Settings
# ============================================================================

variable "claude_code_default_enabled" {
  description = "Default state for Claude Code installation"
  type        = bool
  default     = false
}

variable "opencode_default_enabled" {
  description = "Default state for OpenCode installation"
  type        = bool
  default     = false
}

variable "openai_codex_default_enabled" {
  description = "Default state for OpenAI Codex installation"
  type        = bool
  default     = false
}

variable "cursor_default_enabled" {
  description = "Default state for Cursor installation"
  type        = bool
  default     = false
}

variable "gemini_default_enabled" {
  description = "Default state for Gemini installation"
  type        = bool
  default     = false
}
