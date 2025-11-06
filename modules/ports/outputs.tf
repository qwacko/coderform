output "ports_count" {
  description = "Number of ports configured by the user"
  value       = local.ports_count
}

output "port1" {
  description = "Port 1 configuration and app details"
  value = local.ports_count >= 1 && var.max_ports >= 1 ? {
    number       = local.port1_num
    title        = local.port1_title
    icon         = local.port1_icon
    share        = local.port1_share
    app_id       = coder_app.port1[0].id
    url          = coder_app.port1[0].url
  } : null
}

output "port2" {
  description = "Port 2 configuration and app details"
  value = local.ports_count >= 2 && var.max_ports >= 2 ? {
    number       = local.port2_num
    title        = local.port2_title
    icon         = local.port2_icon
    share        = local.port2_share
    app_id       = coder_app.port2[0].id
    url          = coder_app.port2[0].url
  } : null
}

output "port3" {
  description = "Port 3 configuration and app details"
  value = local.ports_count >= 3 && var.max_ports >= 3 ? {
    number       = local.port3_num
    title        = local.port3_title
    icon         = local.port3_icon
    share        = local.port3_share
    app_id       = coder_app.port3[0].id
    url          = coder_app.port3[0].url
  } : null
}

output "all_ports" {
  description = "List of all configured port details"
  value = compact([
    local.ports_count >= 1 && var.max_ports >= 1 ? {
      slot         = 1
      number       = local.port1_num
      title        = local.port1_title
      icon         = local.port1_icon
      share        = local.port1_share
      app_id       = coder_app.port1[0].id
      url          = coder_app.port1[0].url
    } : null,
    local.ports_count >= 2 && var.max_ports >= 2 ? {
      slot         = 2
      number       = local.port2_num
      title        = local.port2_title
      icon         = local.port2_icon
      share        = local.port2_share
      app_id       = coder_app.port2[0].id
      url          = coder_app.port2[0].url
    } : null,
    local.ports_count >= 3 && var.max_ports >= 3 ? {
      slot         = 3
      number       = local.port3_num
      title        = local.port3_title
      icon         = local.port3_icon
      share        = local.port3_share
      app_id       = coder_app.port3[0].id
      url          = coder_app.port3[0].url
    } : null,
  ])
}
