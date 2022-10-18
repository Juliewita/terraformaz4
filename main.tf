terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.27.0"
    }
  }
}

provider "azurerm" {
  features {}
}

#Create Resource Group
resource "azurerm_resource_group" "terrarg" {
  name     = "terraform-rg"
  location = "West Europe"
}

#Create virtual Network
resource "azurerm_virtual_network" "terravnet" {
  name                = "terraform-vn"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.terrarg.location
  resource_group_name = azurerm_resource_group.terrarg.name
}

#Create Subnet to hold the VM
resource "azurerm_subnet" "terrasn" {
  name                 = "terraform-sn"
  resource_group_name  = azurerm_resource_group.terrarg.name
  virtual_network_name = azurerm_virtual_network.terravnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

#Create vNIC for the VM and assign to the VM
resource "azurerm_network_interface" "terranic" {
  name                = "terraform-nic-01"
  location            = azurerm_resource_group.terrarg.location
  resource_group_name = azurerm_resource_group.terrarg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.terrasn.id
    private_ip_address_allocation = "Dynamic"
  }
}

#Create the Virtual Machine 
resource "azurerm_windows_virtual_machine" "terraformvm" {
  name                = "terraform-vm-01"
  resource_group_name = azurerm_resource_group.terrarg.name
  location            = azurerm_resource_group.terrarg.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.terranic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}