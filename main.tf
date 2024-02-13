terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}


provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "demo" {
  name     = "demo-resources"
  location = "West Europe"
}

resource "azurerm_virtual_network" "demo-vm" {
  name                = "demo-vm-network"
  resource_group_name = azurerm_resource_group.demo.name
  location            = azurerm_resource_group.demo.location
  address_space       = ["10.0.0.0/16"]
}
resource "azurerm_subnet" "demo-net" {
  name                 = "demo-net-subnet"
  resource_group_name  = azurerm_resource_group.demo.name
  virtual_network_name = azurerm_virtual_network.demo-vm.name
  address_prefixes     = ["10.0.1.0/24"]
}
resource "azurerm_storage_account" "demo-sa" {
  name                     = "storageaccount1"
  resource_group_name      = azurerm_resource_group.demo.name
  location                 = azurerm_resource_group.demo.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "prod"
  }
}
variable "prefix" {
  default = "tf"
}



resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.demo.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-vm"
  location              = azurerm_resource_group.demo.location
  resource_group_name   = azurerm_resource_group.demo.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS1_v2"

  
  delete_os_disk_on_termination = true

  
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "dev"
  }
}
resource "azurerm_redis_cache" "demo-cache" {
  name                = "rcache123"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
  capacity            = 2
  family              = "C"
  sku_name            = "Standard"
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"

  redis_configuration {
  }
}
resource "azurerm_sql_server" "demo-sql" {
  name                         = "mssqlserver123"
  resource_group_name          = azurerm_resource_group.demo.name
  location                     = azurerm_resource_group.demo.location
  version                      = "12.0"
  administrator_login          = "mradministrator"
  administrator_login_password = "admin123"

  tags = {
    environment = "dev"
  }
}
resource "azurerm_sql_database" "example" {
  name                = "myexamplesqldatabase"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  server_name         = azurerm_sql_server.example.name

  tags = {
    environment = "production"
  }
}
resource "azurerm_eventhub_namespace" "example" {
  name                = "acceptanceTestEventHubNamespace"
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
  sku                 = "Standard"
  capacity            = 1

  tags = {
    environment = "Production"
  }
}

resource "azurerm_eventhub" "example" {
  name                = "acceptanceTestEventHub"
  namespace_name      = azurerm_eventhub_namespace.demo.name
  resource_group_name = azurerm_resource_group.demo.name
  partition_count     = 2
  message_retention   = 1
}
resource "azurerm_stream_analytics_job" "example" {
  name                                     = "example-job"
  resource_group_name                      = azurerm_resource_group.demo.name
  location                                 = azurerm_resource_group.demo.location
  compatibility_level                      = "1.2"
  data_locale                              = "en-GB"
  events_late_arrival_max_delay_in_seconds = 60
  events_out_of_order_max_delay_in_seconds = 50
  events_out_of_order_policy               = "Adjust"
  output_error_policy                      = "Drop"
  streaming_units                          = 3
  transformation_query = <<QUERY
    SELECT *
    INTO [YourOutputAlias]
    FROM [YourInputAlias]
QUERY
}
