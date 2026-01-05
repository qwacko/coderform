# Headless Browser Module

Terraform module for provisioning a headless browser container, based on the `browserless/chromium` image. This is primarily intended for use by AI coding agents that require a browser for automation, testing, or content rendering.

## Features

- **Headless Chrome**: Runs the latest `ghcr.io/browserless/chromium` image.
- **Automation Ready**: Exposes a WebSocket endpoint for Puppeteer, Playwright, and other automation libraries.
- **Debugger UI**: Includes a web-based UI for debugging and inspecting browser sessions.
- **Easy Integration**: Provides environment variables for connecting from the Coder agent or other containers.

## Usage

```hcl
module "headless_browser" {
  source = "github.com/your-org/coderform//modules/headless-browser"

  agent_id              = coder_agent.main.id
  workspace_id          = data.coder_workspace.me.id
  workspace_name        = data.coder_workspace.me.name
  username              = data.coder_workspace_owner.me.name
  owner_id              = data.coder_workspace_owner.me.id
  repository            = data.coder_workspace.me.repository
  internal_network_name = docker_network.internal.name

  order_offset    = 60
  default_enabled = false
}
```

## Inputs

| Name                  | Description                   | Type   | Default         |
| --------------------- | ----------------------------- | ------ | --------------- |
| agent_id              | The Coder agent ID            | string | required        |
| workspace_id          | The Coder workspace ID        | string | required        |
| workspace_name        | The Coder workspace name      | string | required        |
| username              | The workspace owner username  | string | required        |
| owner_id              | The workspace owner ID        | string | required        |
| repository            | Repository URL                | string | required        |
| internal_network_name | Docker network name           | string | required        |
| order_offset          | Starting order for parameters | number | 60              |
| default_enabled       | Enable by default             | bool   | false           |
| browser_port          | Port for the UI and API       | number | 3001            |
| app_group             | Coder app group name          | string | "AI Tools"      |

## Outputs

| Name            | Description                            |
| --------------- | -------------------------------------- |
| enabled         | Whether the browser is enabled         |
| host            | Headless browser hostname              |
| browser_port    | Port for the UI and API                |
| browser_url     | Internal URL for the UI and API        |
| websocket_url   | Internal WebSocket URL for automation  |
| env_vars        | Environment variables map              |
| proxy_specs     | Port forwarding configuration          |

## Connecting for Automation

To use the headless browser with a library like Puppeteer or Playwright, you can use the environment variables provided by the module.

### Puppeteer Example (Node.js)

```javascript
const puppeteer = require('puppeteer');

(async () => {
  // The BROWSER_WS_ENDPOINT environment variable is set by the module
  const browser = await puppeteer.connect({
    browserWSEndpoint: process.env.BROWSER_WS_ENDPOINT,
  });

  const page = await browser.newPage();
  await page.goto('https://example.com');
  // ... your automation script ...
  await browser.close();
})();
```

The module sets the following environment variables:

- `HEADLESS_BROWSER_ENABLED`: "true" or "false"
- `HEADLESS_BROWSER_URL`: e.g., `http://headless-browser:3000`
- `HEADLESS_BROWSER_WS_URL`: e.g., `ws://headless-browser:3000`
- `BROWSER_WS_ENDPOINT`: Alias for `HEADLESS_BROWSER_WS_URL`

## Accessing the UI

When enabled, a Coder app named "Headless Browser" will be available. This UI allows you to see live sessions, debug, and inspect the browser.

## Resources

- [Browserless Website](https://www.browserless.io/)
- [Browserless GitHub](https://github.com/browserless/browserless)
