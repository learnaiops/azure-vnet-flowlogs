# Azure VNet Flow Logs

Terraform configuration to automatically enable **VNet Flow Logs** and **Traffic Analytics** across an Azure subscription using Azure Policy (DeployIfNotExists).

## Overview

This repo has two independent Terraform root modules:

| Module | Purpose |
|--------|---------|
| [`infra/`](infra/) | Demo infrastructure — VNets, storage accounts, Log Analytics workspace, test VMs |
| [`vnet-flow-logs/`](vnet-flow-logs/) | Azure Policy definition + subscription-level assignments to auto-enable flow logs on all VNets |

The policy uses a **DeployIfNotExists** effect, so any VNet created or updated in a covered region automatically gets flow logs and Traffic Analytics enabled. A remediation task handles existing non-compliant VNets.

## Prerequisites

- Azure CLI authenticated (`az login`)
- Terraform >= 1.5
- An Azure storage account for Terraform remote state

## Usage

### 1. Configure Terraform backend

In both `infra/providers.tf` and `vnet-flow-logs/providers.tf`, replace the placeholders with your actual values:

```hcl
backend "azurerm" {
  resource_group_name  = "<YOUR_TERRAFORM_STATE_RG>"
  storage_account_name = "<YOUR_TERRAFORM_STATE_SA>"
  container_name       = "tfstate"
  ...
}
```

### 2. Deploy demo infrastructure

```bash
cd infra
terraform init
terraform apply -var="vm_admin_password=<PASSWORD>" -var="allowed_ip_address=<YOUR_IP>"
```

Or create a `terraform.tfvars` (excluded from git):

```hcl
vm_admin_password  = "..."
allowed_ip_address = "1.2.3.4"
```

### 3. Deploy the flow log policy

Edit [`vnet-flow-logs/subscription_policy.yaml.tftpl`](vnet-flow-logs/subscription_policy.yaml.tftpl) to set the storage account and Log Analytics workspace resource IDs for each region, then:

```bash
cd vnet-flow-logs
terraform init
terraform apply
```

## Variables (`infra/`)

| Name | Description |
|------|-------------|
| `vm_admin_password` | Admin password for the test Windows VMs |
| `allowed_ip_address` | Your public IP — used for storage network rules and RDP access |

## How the policy works

1. **Policy definition** (`vnet_flow_log_policy.yaml.tftpl`) — a custom DINE policy that targets `Microsoft.Network/virtualNetworks` in a specified region and deploys a `Microsoft.Network/networkWatchers/flowLogs` resource if one is not already enabled with Traffic Analytics.
2. **Policy assignments** (`subscription_policy.yaml.tftpl`) — one assignment per region, each pointing to a region-local storage account and a Log Analytics workspace.
3. **Managed identity** — each assignment gets a system-assigned identity with `Contributor` scope so it can create `Microsoft.Resources/deployments` in `NetworkWatcherRG`.
4. **Remediation** — a remediation task is created for each assignment to bring existing VNets into compliance.
