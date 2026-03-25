resource "azurerm_resource_group" "rg" {
  name     = "rg-infra-example"
  location = "East US"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-infra-example"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "snet-infra-example"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_virtual_network" "vnet2" {
  name                = "vnet-infra-example-2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "subnet2" {
  name                 = "snet-infra-example-2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet2.name
  address_prefixes     = ["10.1.0.0/24"]
}

resource "azurerm_resource_group" "rg_uksouth" {
  name     = "rg-infra-example-uksouth"
  location = "UK South"
}

resource "azurerm_virtual_network" "vnet_uksouth" {
  name                = "vnet-infra-example-uksouth"
  location            = azurerm_resource_group.rg_uksouth.location
  resource_group_name = azurerm_resource_group.rg_uksouth.name
  address_space       = ["10.2.0.0/16"]
}

resource "azurerm_subnet" "subnet_uksouth" {
  name                 = "snet-infra-example-uksouth"
  resource_group_name  = azurerm_resource_group.rg_uksouth.name
  virtual_network_name = azurerm_virtual_network.vnet_uksouth.name
  address_prefixes     = ["10.2.0.0/24"]
}

resource "azurerm_storage_account" "sa" {
  name                          = "savnetflowlogsdemo24"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  https_traffic_only_enabled = true

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices", "Logging", "Metrics"]
    ip_rules       = [var.allowed_ip_address]
  }
}

resource "azurerm_storage_account" "sa_uksouth" {
  name                       = "savnetflowlogsdemo24uk"
  resource_group_name        = azurerm_resource_group.rg_uksouth.name
  location                   = azurerm_resource_group.rg_uksouth.location
  account_tier               = "Standard"
  account_replication_type   = "LRS"
  https_traffic_only_enabled = true

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices", "Logging", "Metrics"]
    ip_rules       = [var.allowed_ip_address]
  }
}

resource "azurerm_network_security_group" "test_vms" {
  name                = "nsg-test-vms"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-rdp"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.allowed_ip_address
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "vm1" {
  name                = "pip-test-vm1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "vm1" {
  name                = "nic-test-vm1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm1.id
  }
}

resource "azurerm_network_interface_security_group_association" "vm1" {
  network_interface_id      = azurerm_network_interface.vm1.id
  network_security_group_id = azurerm_network_security_group.test_vms.id
}

resource "azurerm_windows_virtual_machine" "vm1" {
  name                = "vm-test-vnet1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2ms"
  admin_username      = "azureuser"
  admin_password      = var.vm_admin_password

  network_interface_ids = [azurerm_network_interface.vm1.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-smalldisk-g2"
    version   = "latest"
  }
}

resource "azurerm_public_ip" "vm2" {
  name                = "pip-test-vm2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "vm2" {
  name                = "nic-test-vm2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm2.id
  }
}

resource "azurerm_network_interface_security_group_association" "vm2" {
  network_interface_id      = azurerm_network_interface.vm2.id
  network_security_group_id = azurerm_network_security_group.test_vms.id
}

resource "azurerm_windows_virtual_machine" "vm2" {
  name                = "vm-test-vnet2"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2ms"
  admin_username      = "azureuser"
  admin_password      = var.vm_admin_password

  network_interface_ids = [azurerm_network_interface.vm2.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-smalldisk-g2"
    version   = "latest"
  }
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-vnetflowlogs-demo-24"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
}
