module "log_analytics_workspace" {
  source = "../log_analytics_workspace"

  name                = "${var.name_prefix}-container-apps-log"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

module "acr_role_assignment" {
  source = "../role_assignment"

  for_each = var.container_apps

  resource_scope_id    = data.azurerm_container_registry.container_registry.id
  role_definition_name = "AcrPull"
  principal_id         = var.user_assigned_identities[each.key].principal_id
}

resource "azurerm_container_app_environment" "az_container_app_environment" {
  depends_on = [module.log_analytics_workspace]

  name                       = "${var.name_prefix}-ace"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = module.log_analytics_workspace.id

  tags = var.tags
}

resource "azurerm_container_app" "az_container_app" {

  depends_on = [
    azurerm_container_app_environment.az_container_app_environment,
    data.azurerm_container_registry.container_registry
  ]

  for_each = var.container_apps

  name                         = "${var.name_prefix}-${each.value.name}-aca"
  container_app_environment_id = azurerm_container_app_environment.az_container_app_environment.id
  resource_group_name          = var.resource_group_name
  revision_mode                = each.value.revision_mode

  identity {
    type         = "UserAssigned"
    identity_ids = [var.user_assigned_identities[each.key].id]
  }

  registry {
    server   = var.container_registry.login_server
    identity = var.user_assigned_identities[each.key].id
  }

  template {
    dynamic "container" {
      for_each = coalesce(each.value.template.containers, [])
      content {
        name   = container.value.name
        image  = "${var.container_registry.name}.azurecr.io/${container.value.image}:${container.value.tag}"
        cpu    = container.value.cpu
        memory = container.value.memory

        dynamic "env" {
          for_each = concat(container.value.env != null ? container.value.env : [], [{
            name  = "Identity__ClientId"
            value = var.user_assigned_identities[each.key].client_id
          }])
          content {
            name        = env.value.name
            secret_name = try(env.value.secret_name, null)
            value       = try(env.value.value, null)
          }
        }


        dynamic "liveness_probe" {
          for_each = coalesce(container.value.liveness_probe, [])

          content {
            failure_count_threshold = liveness_probe.value.failure_count_threshold

            dynamic "header" {
              for_each = coalesce(liveness_probe.value.header, [])
              content {
                name  = header.value.name
                value = header.value.value
              }

            }

            host             = liveness_probe.value.host
            initial_delay    = liveness_probe.value.initial_delay
            interval_seconds = liveness_probe.value.interval_seconds
            path             = liveness_probe.value.path
            port             = liveness_probe.value.port
            timeout          = liveness_probe.value.timeout
            transport        = liveness_probe.value.transport
          }
        }

        dynamic "readiness_probe" {
          for_each = coalesce(container.value.readiness_probe, [])

          content {
            failure_count_threshold = readiness_probe.value.failure_count_threshold

            dynamic "header" {
              for_each = coalesce(readiness_probe.value.header, [])
              content {
                name  = header.value.name
                value = header.value.value
              }

            }

            host                    = readiness_probe.value.host
            interval_seconds        = readiness_probe.value.interval_seconds
            path                    = readiness_probe.value.path
            port                    = readiness_probe.value.port
            success_count_threshold = readiness_probe.value.success_count_threshold
            timeout                 = readiness_probe.value.timeout
            transport               = readiness_probe.value.transport
          }
        }

        dynamic "startup_probe" {
          for_each = coalesce(container.value.startup_probe, [])

          content {
            failure_count_threshold = startup_probe.value.failure_count_threshold

            dynamic "header" {
              for_each = coalesce(startup_probe.value.header, [])
              content {
                name  = header.value.name
                value = header.value.value
              }

            }

            host             = startup_probe.value.host
            interval_seconds = startup_probe.value.interval_seconds
            path             = startup_probe.value.path
            port             = startup_probe.value.port
            timeout          = startup_probe.value.timeout
            transport        = startup_probe.value.transport
          }
        }

      }
    }

    dynamic "azure_queue_scale_rule" {
      for_each = coalesce(each.value.template.azure_queue_scale_rules, [])
      content {
        name         = azure_queue_scale_rule.value.name
        queue_name   = azure_queue_scale_rule.value.queue_name
        queue_length = azure_queue_scale_rule.value.queue_length

        dynamic "authentication" {
          for_each = azure_queue_scale_rule.value.authentication != null ? [azure_queue_scale_rule.value.authentication] : []
          content {
            secret_name       = authentication.value.secret_name
            trigger_parameter = authentication.value.trigger_parameter
          }
        }
      }
    }

    dynamic "custom_scale_rule" {
      for_each = coalesce(each.value.template.custom_scale_rules, [])
      content {
        name             = custom_scale_rule.value.name
        custom_rule_type = custom_scale_rule.value.custom_rule_type
        metadata         = custom_scale_rule.value.metadata

        dynamic "authentication" {
          for_each = custom_scale_rule.value.authentication != null ? [custom_scale_rule.value.authentication] : []
          content {
            secret_name       = authentication.value.secret_name
            trigger_parameter = authentication.value.trigger_parameter
          }
        }
      }
    }

    dynamic "tcp_scale_rule" {
      for_each = coalesce(each.value.template.tcp_scale_rules, [])
      content {
        name                = tcp_scale_rule.value.name
        concurrent_requests = tcp_scale_rule.value.concurrent_requests

        dynamic "authentication" {
          for_each = tcp_scale_rule.value.authentication != null ? [tcp_scale_rule.value.authentication] : []
          content {
            secret_name       = authentication.value.secret_name
            trigger_parameter = authentication.value.trigger_parameter
          }
        }
      }

    }

    dynamic "http_scale_rule" {
      for_each = coalesce(each.value.template.http_scale_rules, [])
      content {
        name                = http_scale_rule.value.name
        concurrent_requests = http_scale_rule.value.concurrent_requests

        dynamic "authentication" {
          for_each = http_scale_rule.value.authentication != null ? [http_scale_rule.value.authentication] : []
          content {
            secret_name       = authentication.value.secret_name
            trigger_parameter = authentication.value.trigger_parameter
          }
        }
      }
    }

    min_replicas    = try(each.value.template.min_replicas, null)
    max_replicas    = try(each.value.template.max_replicas, null)
    revision_suffix = try(each.value.template.revision_suffix, null)
  }

  dynamic "ingress" {
    for_each = each.value.ingress_enabled ? [each.value.ingress] : []
    content {
      external_enabled = try(ingress.value.external_enabled, null)
      target_port      = try(ingress.value.target_port, null)
      transport        = try(ingress.value.transport, null)

      traffic_weight {
        percentage      = try(ingress.value.traffic_weight.percentage, null)
        latest_revision = try(ingress.value.traffic_weight.latest_revision, null)
      }
    }
  }

  dynamic "secret" {
    for_each = each.value.secrets != null ? each.value.secrets : []
    content {
      name                = secret.value.name
      value               = try(secret.value.value, null)
      identity            = try(secret.value.key_vault_secret_id, null) != null ? var.user_assigned_identities[each.key].id : null
      key_vault_secret_id = try(secret.value.key_vault_secret_id, null)
    }
  }

  lifecycle {
    # CI deploys a new image tag on every merge. Terraform sets the image when the app is created and
    # then leaves it alone; otherwise every apply would roll the app back to the tag in the config.
    ignore_changes = [template[0].container[0].image]
  }

  tags = var.tags
}