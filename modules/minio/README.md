# MinIO Module

Terraform module for provisioning MinIO, an S3-compatible object storage service with a built-in web console.

## Features

- **S3-Compatible API**: Drop-in replacement for Amazon S3
- **Web Console**: Modern web interface for managing buckets and objects
- **Persistent Storage**: Data persists across workspace rebuilds
- **Dual Endpoints**: Separate API and console access

## Usage

```hcl
module "minio" {
  source = "github.com/your-org/coderform//modules/minio"

  agent_id              = coder_agent.main.id
  workspace_id          = data.coder_workspace.me.id
  workspace_name        = data.coder_workspace.me.name
  username              = data.coder_workspace_owner.me.name
  owner_id              = data.coder_workspace_owner.me.id
  repository            = data.coder_workspace.me.repository
  internal_network_name = docker_network.internal.name

  order_offset          = 40
  default_enabled       = false
  default_root_user     = "minioadmin"
  default_root_password = "minioadmin"
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
| order_offset | Starting order for parameters | number | 40 |
| default_enabled | Enable by default | bool | false |
| default_root_user | Default access key | string | "minioadmin" |
| default_root_password | Default secret key | string | "minioadmin" |
| api_port | API port | number | 9000 |
| console_port | Console port | number | 9001 |
| app_group | Coder app group name | string | "Tools" |

## Outputs

| Name | Description |
|------|-------------|
| enabled | Whether MinIO is enabled |
| host | MinIO hostname |
| api_port | API port |
| console_port | Console port |
| root_user | Access key |
| root_password | Secret key (sensitive) |
| endpoint | S3 API endpoint |
| console_url | Internal console URL |
| env_vars | Environment variables map |
| proxy_specs | Port forwarding configuration |

## Environment Variables

The module outputs the following environment variables:

- `MINIO_ENABLED`: Whether MinIO is enabled
- `MINIO_ENDPOINT`: MinIO API endpoint
- `MINIO_ROOT_USER`: Access key
- `MINIO_ROOT_PASSWORD`: Secret key
- `MINIO_ACCESS_KEY`: Alias for root user
- `MINIO_SECRET_KEY`: Alias for root password
- `S3_ENDPOINT`: Alias for endpoint
- `S3_ACCESS_KEY_ID`: Alias for access key
- `S3_SECRET_ACCESS_KEY`: Alias for secret key

## Application Configuration

### AWS SDK (Node.js)

```javascript
const AWS = require('aws-sdk');

const s3 = new AWS.S3({
  endpoint: process.env.S3_ENDPOINT || 'http://minio:9000',
  accessKeyId: process.env.S3_ACCESS_KEY_ID || 'minioadmin',
  secretAccessKey: process.env.S3_SECRET_ACCESS_KEY || 'minioadmin',
  s3ForcePathStyle: true,
  signatureVersion: 'v4',
});
```

### boto3 (Python)

```python
import boto3
import os

s3_client = boto3.client(
    's3',
    endpoint_url=os.getenv('S3_ENDPOINT', 'http://minio:9000'),
    aws_access_key_id=os.getenv('S3_ACCESS_KEY_ID', 'minioadmin'),
    aws_secret_access_key=os.getenv('S3_SECRET_ACCESS_KEY', 'minioadmin'),
)
```

### Go

```go
package main

import (
    "os"
    "github.com/minio/minio-go/v7"
    "github.com/minio/minio-go/v7/pkg/credentials"
)

func main() {
    endpoint := os.Getenv("S3_ENDPOINT")
    accessKeyID := os.Getenv("S3_ACCESS_KEY_ID")
    secretAccessKey := os.Getenv("S3_SECRET_ACCESS_KEY")

    minioClient, err := minio.New(endpoint, &minio.Options{
        Creds:  credentials.NewStaticV4(accessKeyID, secretAccessKey, ""),
        Secure: false,
    })
}
```

### MinIO Client (mc)

```bash
mc alias set local http://minio:9000 $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD
mc mb local/mybucket
mc cp file.txt local/mybucket/
```

## Web Console

Access the MinIO Console through the Coder dashboard. The console allows you to:

- Create and manage buckets
- Upload and download files
- Set bucket policies and access controls
- Monitor storage usage and metrics
- Manage users and access keys

## Port Forwarding

The module provides `proxy_specs` output for port forwarding. Include it in your agent startup script:

```hcl
startup_script = <<-EOT
  ${jsonencode(module.minio.proxy_specs) != "[]" ? "PROXY_SPECS='${jsonencode(module.minio.proxy_specs)}'" : ""}
  if [ -n "$PROXY_SPECS" ] && [ "$PROXY_SPECS" != "[]" ]; then
    echo "$PROXY_SPECS" | jq -r '.[] | "nohup socat TCP4-LISTEN:" + (.local_port|tostring) + ",fork,reuseaddr TCP4:" + .host + ":" + (.rport|tostring) + " > /tmp/proxy-" + .name + ".log 2>&1 &"' | bash
  fi
EOT
```

## Security Notes

- **Change Default Credentials**: Always use strong, unique credentials in production
- **Minimum Password Length**: MinIO requires passwords to be at least 8 characters
- **Internal Network Only**: MinIO runs on the internal Docker network and is not exposed to the host
- **Data Persistence**: All data is stored in a persistent Docker volume

## Use Cases

- **Development**: Test S3 integrations locally without AWS
- **CI/CD**: Store build artifacts and test files
- **File Storage**: General-purpose object storage for applications
- **Backups**: Store database backups and snapshots
- **Static Assets**: Serve static files for web applications
