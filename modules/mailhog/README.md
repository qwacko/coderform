# MailHog Module

Terraform module for provisioning MailHog, an email testing tool that captures SMTP traffic and displays it in a web interface.

## Features

- **Email Capture**: Captures all outgoing emails sent via SMTP
- **Web UI**: Browse captured emails in a user-friendly web interface
- **No External Dependencies**: Self-contained email testing solution
- **SMTP Server**: Built-in SMTP server on port 1025

## Usage

```hcl
module "mailhog" {
  source = "github.com/your-org/coderform//modules/mailhog"

  agent_id              = coder_agent.main.id
  workspace_id          = data.coder_workspace.me.id
  workspace_name        = data.coder_workspace.me.name
  username              = data.coder_workspace_owner.me.name
  owner_id              = data.coder_workspace_owner.me.id
  repository            = data.coder_workspace.me.repository
  internal_network_name = docker_network.internal.name

  order_offset    = 30
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
| order_offset | Starting order for parameters | number | 30 |
| default_enabled | Enable by default | bool | false |
| smtp_port | SMTP port | number | 1025 |
| http_port | Web UI port | number | 8025 |
| app_group | Coder app group name | string | "Tools" |

## Outputs

| Name | Description |
|------|-------------|
| enabled | Whether MailHog is enabled |
| smtp_host | SMTP hostname |
| smtp_port | SMTP port |
| http_port | Web UI port |
| web_url | Internal web URL |
| env_vars | Environment variables map |
| proxy_specs | Port forwarding configuration |

## Environment Variables

The module outputs the following environment variables:

- `MAILHOG_ENABLED`: Whether MailHog is enabled
- `MAILHOG_SMTP_HOST`: SMTP hostname (mailhog)
- `MAILHOG_SMTP_PORT`: SMTP port (1025)
- `SMTP_HOST`: Alias for MAILHOG_SMTP_HOST
- `SMTP_PORT`: Alias for MAILHOG_SMTP_PORT

## Application Configuration

Configure your application to send emails via SMTP:

**Node.js (Nodemailer):**
```javascript
const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || 'mailhog',
  port: process.env.SMTP_PORT || 1025,
  secure: false,
});
```

**Python (smtplib):**
```python
import smtplib
import os

server = smtplib.SMTP(
    os.getenv('SMTP_HOST', 'mailhog'),
    int(os.getenv('SMTP_PORT', 1025))
)
```

**PHP:**
```php
ini_set('SMTP', getenv('SMTP_HOST') ?: 'mailhog');
ini_set('smtp_port', getenv('SMTP_PORT') ?: 1025);
```

## Web Interface

Access the MailHog web UI through the Coder dashboard. The interface allows you to:

- View captured emails
- Search and filter emails
- View email content (HTML and text)
- Inspect email headers
- Delete emails

## Port Forwarding

The module provides `proxy_specs` output for port forwarding. Include it in your agent startup script:

```hcl
startup_script = <<-EOT
  ${jsonencode(module.mailhog.proxy_specs) != "[]" ? "PROXY_SPECS='${jsonencode(module.mailhog.proxy_specs)}'" : ""}
  if [ -n "$PROXY_SPECS" ] && [ "$PROXY_SPECS" != "[]" ]; then
    echo "$PROXY_SPECS" | jq -r '.[] | "nohup socat TCP4-LISTEN:" + (.local_port|tostring) + ",fork,reuseaddr TCP4:" + .host + ":" + (.rport|tostring) + " > /tmp/proxy-" + .name + ".log 2>&1 &"' | bash
  fi
EOT
```

## Notes

- MailHog does not persist emails - they are lost on container restart
- No authentication is required or supported
- Not suitable for production use - for development/testing only
