resource "azurerm_resource_group" "gbtest_rg" {
  name     = "gbtest_rg"
  location = var.location
  tags = {
    InstanceType = "test"
  }
}

resource "azurerm_public_ip" "public_ip" {
  name                = "acceptanceTestPublicIp1"
  resource_group_name = azurerm_resource_group.gbtest_rg.name
  location            = azurerm_resource_group.gbtest_rg.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_security_group" "ssh" {
  name                = "acceptanceTestSecurityGroup1"
  location            = azurerm_resource_group.gbtest_rg.location
  resource_group_name = azurerm_resource_group.gbtest_rg.name

  security_rule {
    name                       = "openssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.gbtest_rg.location
  resource_group_name = azurerm_resource_group.gbtest_rg.name
}

resource "azurerm_subnet" "example" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.gbtest_rg.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  location            = azurerm_resource_group.gbtest_rg.location
  resource_group_name = azurerm_resource_group.gbtest_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "gbtest" {
  name                = var.name
  admin_username      = "gburucua"
  resource_group_name = azurerm_resource_group.gbtest_rg.name
  location            = var.location
  size                = "Standard_B1s"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_ssh_key {
    username   = "gburucua"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}