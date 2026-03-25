locals {
  policy = yamldecode(templatefile("${path.module}/vnet_flow_log_policy.yaml.tftpl", {}))
  config = yamldecode(templatefile("${path.module}/subscription_policy.yaml.tftpl", {
    subscription_id = data.azurerm_subscription.current.subscription_id
  }))
  assignments = { for a in local.config.assignments : a.name => a }
}

data "azurerm_subscription" "current" {}

resource "azurerm_policy_definition" "vnet_flow_logs" {
  name         = "custom-vnet-flowlogs-dine"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Custom: Configure virtual network to enable Flow Log and Traffic Analytics"

  metadata    = jsonencode(local.policy.policy_definition.metadata)
  policy_rule = jsonencode(local.policy.policy_definition.policy_rule)
  parameters  = jsonencode(local.policy.policy_definition.parameters)
}

resource "azurerm_subscription_policy_assignment" "vnet_flow_logs" {
  for_each             = local.assignments
  display_name         = "Configure virtual network to enable Flow Log and Traffic Analytics - ${each.key}"
  name                 = "configure-vnet-flowlogs-${each.key}"
  policy_definition_id = azurerm_policy_definition.vnet_flow_logs.id
  subscription_id      = data.azurerm_subscription.current.id
  location             = each.value.region

  identity {
    type = "SystemAssigned"
  }

  parameters = jsonencode({
    effect = {
      value = "DeployIfNotExists"
    }
    vnetRegion = {
      value = each.value.region
    }
    storageId = {
      value = each.value.storage_account_id
    }
    workspaceResourceId = {
      value = each.value.workspace_resource_id
    }
    workspaceRegion = {
      value = each.value.workspace_region
    }
    timeInterval = {
      value = each.value.time_interval
    }
    retentionDays = {
      value = tostring(each.value.retention_days)
    }
  })
}

# The policy managed identity requires Contributor (not just Network Contributor) because
# the remediation deployment creates Microsoft.Resources/deployments in the NetworkWatcherRG.
resource "azurerm_role_assignment" "policy_contributor" {
  for_each             = local.assignments
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_subscription_policy_assignment.vnet_flow_logs[each.key].identity[0].principal_id
}

# Triggers remediation for existing non-compliant VNets. New VNets are handled
# automatically by the DeployIfNotExists effect on resource creation/update.
resource "azurerm_subscription_policy_remediation" "vnet_flow_logs" {
  for_each             = local.assignments
  name                 = "vnet-flowlog-rem-${each.key}"
  subscription_id      = data.azurerm_subscription.current.id
  policy_assignment_id = azurerm_subscription_policy_assignment.vnet_flow_logs[each.key].id

  depends_on = [azurerm_role_assignment.policy_contributor]
}
