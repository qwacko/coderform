# API Testing Module

Terraform module for provisioning Hoppscotch, an open-source API development and testing tool (alternative to Postman).

## Features

- **REST API Testing**: Test HTTP/REST APIs with various methods
- **GraphQL Support**: Test GraphQL queries and mutations
- **WebSocket Testing**: Test real-time WebSocket connections
- **Collections**: Organize requests into collections
- **Environments**: Manage different environment variables
- **Request History**: Track and replay previous requests
- **Code Generation**: Generate code snippets in multiple languages
- **Persistent Storage**: Data persists across workspace rebuilds

## Usage

```hcl
module "apitesting" {
  source = "github.com/your-org/coderform//modules/apitesting"

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
| http_port | Web UI port | number | 3000 |
| app_group | Coder app group name | string | "Tools" |

## Outputs

| Name | Description |
|------|-------------|
| enabled | Whether Hoppscotch is enabled |
| host | Hoppscotch hostname |
| http_port | Web UI port |
| web_url | Internal web URL |
| env_vars | Environment variables map |
| proxy_specs | Port forwarding configuration |

## Environment Variables

The module outputs the following environment variables:

- `HOPPSCOTCH_ENABLED`: Whether Hoppscotch is enabled
- `HOPPSCOTCH_URL`: Hoppscotch web UI URL

## Features Overview

### REST API Testing
- Support for all HTTP methods (GET, POST, PUT, DELETE, PATCH, etc.)
- Custom headers and authentication
- Request body with multiple content types
- Response viewing with syntax highlighting

### GraphQL
- GraphQL query and mutation testing
- Schema introspection
- Query variables and headers

### WebSocket
- Real-time WebSocket connection testing
- Message sending and receiving
- Connection state management

### Collections & Environments
- Organize related requests into collections
- Create environment variables for different stages (dev, staging, prod)
- Share collections across team members (when using file exports)

### Code Generation
- Generate code snippets for your requests
- Support for multiple languages: JavaScript, Python, Go, PHP, etc.
- Copy-paste ready code for your application

## Testing Internal Services

Hoppscotch runs on the internal Docker network, making it perfect for testing other services in your workspace:

```
http://postgres:5432     - PostgreSQL database
http://valkey:6379       - Valkey/Redis cache
http://minio:9000        - MinIO S3 API
http://mailhog:1025      - MailHog SMTP
http://localhost:8080    - Your application
```

## Data Persistence

All collections, environments, and settings are stored in a persistent Docker volume and will survive workspace rebuilds.

## Port Forwarding

The module provides `proxy_specs` output for port forwarding. Include it in your agent startup script:

```hcl
startup_script = <<-EOT
  ${jsonencode(module.apitesting.proxy_specs) != "[]" ? "PROXY_SPECS='${jsonencode(module.apitesting.proxy_specs)}'" : ""}
  if [ -n "$PROXY_SPECS" ] && [ "$PROXY_SPECS" != "[]" ]; then
    echo "$PROXY_SPECS" | jq -r '.[] | "nohup socat TCP4-LISTEN:" + (.local_port|tostring) + ",fork,reuseaddr TCP4:" + .host + ":" + (.rport|tostring) + " > /tmp/proxy-" + .name + ".log 2>&1 &"' | bash
  fi
EOT
```

## Comparison to Alternatives

| Feature | Hoppscotch | Postman | Insomnia |
|---------|------------|---------|----------|
| Open Source | ✅ | ❌ | ✅ |
| Self-Hosted | ✅ | ❌ | Partial |
| Lightweight | ✅ | ❌ | ✅ |
| GraphQL | ✅ | ✅ | ✅ |
| WebSocket | ✅ | ✅ | ✅ |
| No Account Required | ✅ | ❌ | ✅ |

## Best Practices

1. **Use Environment Variables**: Define base URLs and credentials as environment variables
2. **Organize Collections**: Group related endpoints into collections
3. **Test Incrementally**: Test APIs as you develop them
4. **Export Collections**: Export collections to share with team members or backup
5. **Use Pre-request Scripts**: Automate authentication and data setup (if supported)

## Use Cases

- **API Development**: Test APIs as you build them
- **Integration Testing**: Verify API integrations with other services
- **Debugging**: Troubleshoot API issues with detailed request/response inspection
- **Documentation**: Use collections as living API documentation
- **Client Development**: Test backend APIs while building frontend applications
