output "enabled" {
  description = "Whether Grafana OTEL-LGTM is enabled"
  value       = local.enabled
}

output "host" {
  description = "OTEL-LGTM hostname (empty if disabled)"
  value       = local.host
}

output "grafana_port" {
  description = "Grafana web UI port"
  value       = var.grafana_port
}

output "otlp_grpc_port" {
  description = "OTLP gRPC receiver port"
  value       = var.otlp_grpc_port
}

output "otlp_http_port" {
  description = "OTLP HTTP receiver port"
  value       = var.otlp_http_port
}

output "grafana_url" {
  description = "Grafana web UI URL (internal)"
  value       = local.enabled ? "http://otel-lgtm:${var.grafana_port}" : ""
}

output "otlp_grpc_endpoint" {
  description = "OTLP gRPC endpoint (internal)"
  value       = local.enabled ? "otel-lgtm:${var.otlp_grpc_port}" : ""
}

output "otlp_http_endpoint" {
  description = "OTLP HTTP endpoint (internal)"
  value       = local.enabled ? "http://otel-lgtm:${var.otlp_http_port}" : ""
}

output "env_vars" {
  description = "Environment variables for agent or containers"
  value = {
    OTEL_LGTM_ENABLED           = tostring(local.enabled)
    GRAFANA_URL                 = local.enabled ? "http://otel-lgtm:${var.grafana_port}" : ""
    OTEL_EXPORTER_OTLP_ENDPOINT = local.enabled ? "http://otel-lgtm:${var.otlp_http_port}" : ""
    OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = local.enabled ? "http://otel-lgtm:${var.otlp_http_port}/v1/traces" : ""
    OTEL_EXPORTER_OTLP_METRICS_ENDPOINT = local.enabled ? "http://otel-lgtm:${var.otlp_http_port}/v1/metrics" : ""
    OTEL_EXPORTER_OTLP_LOGS_ENDPOINT = local.enabled ? "http://otel-lgtm:${var.otlp_http_port}/v1/logs" : ""
  }
}

# ========== Port Forwarding Configuration ==========

output "proxy_specs" {
  description = "Port forwarding specifications for socat in the agent startup script"
  value = local.enabled ? [{
    name       = "grafana"
    local_port = var.grafana_port
    host       = "otel-lgtm"
    rport      = var.grafana_port
  }] : []
}

# ========== Standard Module Outputs ==========

output "startup_script" {
  description = "Commands to run during agent startup"
  value       = local.enabled ? local.startup_script_raw : ""
}

output "install_script" {
  description = "Script to run during image build"
  value       = ""
}
