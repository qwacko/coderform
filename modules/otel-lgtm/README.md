# OTEL-LGTM Module

Terraform module for provisioning Grafana OTEL-LGTM, an all-in-one OpenTelemetry backend stack that includes Loki (logs), Grafana (visualization), Tempo (traces), and Mimir (metrics).

## Features

- **Complete Observability Stack**: Logs, traces, and metrics in one container
- **OpenTelemetry Native**: OTLP protocol support via gRPC and HTTP
- **Grafana Dashboard**: Pre-configured Grafana UI for visualization
- **Easy Integration**: Standard OTLP endpoints for instrumentation
- **Persistent Storage**: Data persists across workspace rebuilds
- **Internal Network**: OTLP endpoints available to all workspace containers

## Usage

```hcl
module "otel_lgtm" {
  source = "github.com/your-org/coderform//modules/otel-lgtm"

  agent_id              = coder_agent.main.id
  workspace_id          = data.coder_workspace.me.id
  workspace_name        = data.coder_workspace.me.name
  username              = data.coder_workspace_owner.me.name
  owner_id              = data.coder_workspace_owner.me.id
  repository            = data.coder_workspace.me.repository
  internal_network_name = docker_network.internal.name

  order_offset    = 50
  default_enabled = false
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| agent_id | The Coder agent ID | string | required |
| workspace_id | The Coder workspace ID | string | required |
| workspace_name | The Coder workspace name | string | required |
| username | The workspace owner username | string | required |
| owner_id | The workspace owner ID | string | required |
| repository | Repository URL | string | required |
| internal_network_name | Docker network name | string | required |
| order_offset | Starting order for parameters | number | 50 |
| default_enabled | Enable by default | bool | false |
| grafana_port | Grafana web UI port | number | 3000 |
| otlp_grpc_port | OTLP gRPC receiver port | number | 4317 |
| otlp_http_port | OTLP HTTP receiver port | number | 4318 |
| app_group | Coder app group name | string | "Observability" |

## Outputs

| Name | Description |
|------|-------------|
| enabled | Whether OTEL-LGTM is enabled |
| host | OTEL-LGTM hostname |
| grafana_port | Grafana web UI port |
| otlp_grpc_port | OTLP gRPC receiver port |
| otlp_http_port | OTLP HTTP receiver port |
| grafana_url | Internal Grafana URL |
| otlp_grpc_endpoint | OTLP gRPC endpoint |
| otlp_http_endpoint | OTLP HTTP endpoint |
| env_vars | Environment variables map |
| proxy_specs | Port forwarding configuration |

## Environment Variables

The module outputs the following environment variables for easy OpenTelemetry integration:

- `OTEL_LGTM_ENABLED`: Whether OTEL-LGTM is enabled
- `GRAFANA_URL`: Grafana web UI URL
- `OTEL_EXPORTER_OTLP_ENDPOINT`: Base OTLP endpoint (HTTP)
- `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT`: Traces endpoint
- `OTEL_EXPORTER_OTLP_METRICS_ENDPOINT`: Metrics endpoint
- `OTEL_EXPORTER_OTLP_LOGS_ENDPOINT`: Logs endpoint

## What is LGTM?

LGTM stands for:
- **L**oki: Log aggregation system
- **G**rafana: Metrics visualization and dashboards
- **T**empo: Distributed tracing backend
- **M**imir: Long-term metrics storage

This all-in-one stack provides a complete observability solution for OpenTelemetry data.

## Accessing Grafana

Once enabled, access Grafana through the Coder app interface. The default credentials are typically:
- Username: `admin`
- Password: `admin` (you'll be prompted to change this on first login)

The Grafana instance comes pre-configured with data sources for Loki, Tempo, and Mimir.

## Sending Telemetry Data

### Using Environment Variables

The module sets standard OpenTelemetry environment variables that many SDKs will automatically use:

```bash
# These are automatically set in your workspace
echo $OTEL_EXPORTER_OTLP_ENDPOINT
# Output: http://otel-lgtm:4318
```

### Language-Specific Examples

#### Python (using opentelemetry-sdk)

```python
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

# The OTEL_EXPORTER_OTLP_ENDPOINT environment variable is automatically used
provider = TracerProvider()
processor = BatchSpanProcessor(OTLPSpanExporter())
provider.add_span_processor(processor)
trace.set_tracer_provider(provider)

tracer = trace.get_tracer(__name__)
```

#### Node.js (using @opentelemetry/sdk-node)

```javascript
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');

// The OTEL_EXPORTER_OTLP_ENDPOINT environment variable is automatically used
const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter(),
});

sdk.start();
```

#### Go (using go.opentelemetry.io/otel)

```go
import (
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
    "go.opentelemetry.io/otel/sdk/trace"
)

// The OTEL_EXPORTER_OTLP_ENDPOINT environment variable is automatically used
exporter, _ := otlptracehttp.New(context.Background())
tp := trace.NewTracerProvider(trace.WithBatcher(exporter))
otel.SetTracerProvider(tp)
```

### Manual Configuration

If you need to manually specify endpoints:

```bash
# HTTP endpoint (most common)
curl -X POST http://otel-lgtm:4318/v1/traces \
  -H "Content-Type: application/json" \
  -d '...'

# gRPC endpoint
# Use otel-lgtm:4317 in your OTLP gRPC exporter configuration
```

## Data Persistence

All telemetry data (logs, traces, metrics) is stored in the `/data` volume mount point. This data persists across workspace rebuilds but is specific to each workspace.

## Internal Network Access

The OTLP receiver ports (4317 and 4318) are only accessible within the internal Docker network. This means:
- ✅ Other containers in your workspace can send telemetry data
- ✅ Applications running in the Coder agent can send telemetry data
- ❌ External services cannot send data directly

Only the Grafana UI (port 3000) is exposed through the Coder app interface.

## Example Integration

Here's a complete example showing how to use the module with environment variables:

```hcl
module "otel_lgtm" {
  source = "github.com/your-org/coderform//modules/otel-lgtm"

  agent_id              = coder_agent.main.id
  workspace_id          = data.coder_workspace.me.id
  workspace_name        = data.coder_workspace.me.name
  username              = data.coder_workspace_owner.me.name
  owner_id              = data.coder_workspace_owner.me.id
  repository            = data.coder_workspace.me.repository
  internal_network_name = docker_network.internal.name

  default_enabled = true
  app_group       = "Observability"
}

# Pass environment variables to your agent
resource "coder_agent" "main" {
  # ... other configuration ...
  
  env = merge(
    module.otel_lgtm.env_vars,
    # ... other env vars ...
  )
}
```

## Troubleshooting

### Grafana not loading
- Ensure the module is enabled in the workspace parameters
- Check that port 3000 is not being used by another service

### No telemetry data appearing
- Verify your application is using the correct endpoint: `http://otel-lgtm:4318` or `otel-lgtm:4317`
- Check that your application is on the same Docker network
- Ensure the OTEL SDK is properly initialized in your application
- Check application logs for OTLP export errors

### Container not starting
- Check Docker logs: `docker logs coder-<workspace-id>-otel-lgtm`
- Verify sufficient resources are available

## Resources

- [Grafana OTEL-LGTM Docker Image](https://hub.docker.com/r/grafana/otel-lgtm)
- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Loki Documentation](https://grafana.com/docs/loki/)
- [Tempo Documentation](https://grafana.com/docs/tempo/)
- [Mimir Documentation](https://grafana.com/docs/mimir/)
