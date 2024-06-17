resource "azurerm_resource_group" "rg" {
  name     = module.naming.resource_group.name
  location = "UK West"
}

resource "azurerm_virtual_network" "azfw_vnet" {
  name                = "${module.naming.virtual_network.name}-hub"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "firewall_subnet" {
  name                 = "AzureFirewallSubnet"
  address_prefixes     = ["10.0.1.0/26"]
  virtual_network_name = azurerm_virtual_network.azfw_vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
}

resource "azurerm_virtual_network" "VN-Spoke" {
  name                = "${module.naming.virtual_network.name}-spoke"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["192.168.0.0/16"]
}

resource "azurerm_subnet" "SN-Workload" {
  name                 = module.naming.subnet.name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.VN-Spoke.name
  address_prefixes     = ["192.168.1.0/24"]
}

resource "azurerm_subnet" "ansible_subnet" {
  name                 = "${module.naming.subnet.name}-ansible"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.VN-Spoke.name
  address_prefixes     = ["192.168.2.0/24"]
}

resource "azurerm_virtual_network_peering" "hub-to-spoke" {
  name                      = "${azurerm_virtual_network.azfw_vnet.name}-to-${azurerm_virtual_network.VN-Spoke.name}"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.azfw_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.VN-Spoke.id

  # allow_virtual_network_access = true
  # allow_forwarded_traffic      = true
  # allow_gateway_transit        = false
  # use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "spoke-to-hub" {
  name                      = "${azurerm_virtual_network.VN-Spoke.name}-to-${azurerm_virtual_network.azfw_vnet.name}"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.VN-Spoke.name
  remote_virtual_network_id = azurerm_virtual_network.azfw_vnet.id

  # allow_virtual_network_access = true
  # allow_forwarded_traffic      = true
  # allow_gateway_transit        = false
  # use_remote_gateways          = false
}


resource "azurerm_public_ip" "pip_azfw" {
  name                = module.naming.public_ip.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "azfw" {
  name                = module.naming.firewall.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  ip_configuration {
    name                 = module.naming.firewall_ip_configuration.name
    subnet_id            = azurerm_subnet.firewall_subnet.id
    public_ip_address_id = azurerm_public_ip.pip_azfw.id
  }
}

resource "azurerm_firewall_policy" "azfw" {
  name                = module.naming.firewall_policy.name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_route_table" "rt" {
  name                          = module.naming.route_table.name
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  disable_bgp_route_propagation = false
  route {
    name                   = module.naming.route.name
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.azfw.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "subnet_rt_association" {
  subnet_id      = azurerm_subnet.SN-Workload.id
  route_table_id = azurerm_route_table.rt.id
}

resource "azurerm_subnet_route_table_association" "ansible_subnet_rt_association" {
  subnet_id      = azurerm_subnet.ansible_subnet.id
  route_table_id = azurerm_route_table.rt.id
}

resource "azurerm_firewall_nat_rule_collection" "nat_rule_collection" {
  name                = module.naming.firewall_nat_rule_collection.name
  azure_firewall_name = azurerm_firewall.azfw.name
  resource_group_name = azurerm_resource_group.rg.name
  priority            = 200
  action              = "Dnat"

  rule {
    name = "rdp-nat"
    source_addresses = [
      "*"
    ]

    destination_ports = [
      "3389"
    ]

    destination_addresses = [
      # azurerm_firewall.azfw.ip_configuration[0].private_ip_address
      azurerm_public_ip.pip_azfw.ip_address
    ]

    translated_port    = 3389
    translated_address = module.dc01.network_interfaces.network_interface_1.private_ip_address
    protocols = [
      "TCP"
    ]
  }
  rule {
    name = "ssh-nat"
    source_addresses = [
      "*"
    ]

    destination_ports = [
      "22"
    ]

    destination_addresses = [
      azurerm_public_ip.pip_azfw.ip_address
    ]

    translated_port    = 22
    translated_address = module.control.network_interfaces.network_interface_1.private_ip_address
    protocols = [
      "TCP"
    ]
  }

  depends_on = [
    module.dc01,
    module.control
  ]
}

# resource "azurerm_storage_account" "sa" {
#   name                     = random_string.storage_account_name.result
#   resource_group_name      = azurerm_resource_group.rg.name
#   location                 = azurerm_resource_group.rg.location
#   account_tier             = "Standard"
#   account_replication_type = "LRS"
#   account_kind             = "StorageV2"
# }

# resource "azurerm_firewall_policy" "azfw_policy" {
#   name                     = module.naming.firewall_policy.name
#   resource_group_name      = azurerm_resource_group.rg.name
#   location                 = azurerm_resource_group.rg.location
#   sku                      = var.firewall_sku_tier
#   threat_intelligence_mode = "Alert"
# }

# resource "azurerm_firewall_policy_rule_collection_group" "prcg" {
#   name               = module.naming.firewall_policy_rule_collection_group.name
#   firewall_policy_id = azurerm_firewall_policy.azfw_policy.id
#   priority           = 300
#   application_rule_collection {
#     name     = module.naming.firewall_application_rule_collection.name
#     priority = 101
#     action   = "Allow"
#     rule {
#       name = "someAppRule"
#       protocols {
#         type = "Https"
#         port = 443
#       }
#       destination_fqdns = ["*bing.com"]
#       source_ip_groups  = [azurerm_ip_group.ip_group_1.id]
#     }
#   }
#   network_rule_collection {
#     name     = module.naming.firewall_network_rule_collection.name
#     priority = 200
#     action   = "Allow"
#     rule {
#       name                  = "InboundRDP"
#       protocols             = ["TCP", "UDP", "ICMP"]
#       source_ip_groups      = [azurerm_ip_group.ip_group_1.id]
#       destination_ip_groups = [azurerm_ip_group.ip_group_2.id]
#       destination_ports     = ["3389"]
#     }
#   }
# }

# resource "azurerm_ip_group" "ip_group_1" {
#   name                = "ipg-ans-adv-uks-01"
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = azurerm_resource_group.rg.location
#   cidrs               = ["13.73.64.64/26", "13.73.208.128/25", "52.126.194.0/23"]
# }
# resource "azurerm_ip_group" "ip_group_2" {
#   name                = "ipg-ans-adv-uks-02"
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = azurerm_resource_group.rg.location
#   cidrs               = ["12.0.0.0/24", "13.9.0.0/24"]
# }



# resource "azurerm_subnet" "jump_subnet" {
#   name                 = "subnet-jump"
#   resource_group_name  = azurerm_resource_group.rg.name
#   virtual_network_name = azurerm_virtual_network.azfw_vnet.name
#   address_prefixes     = ["10.10.2.0/24"]
# }

# resource "azurerm_public_ip" "vm_jump_pip" {
#   name                = "pip-jump"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }

# resource "azurerm_network_interface" "vm_server_nic" {
#   name                = "nic-server"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name

#   ip_configuration {
#     name                          = "ipconfig-workload"
#     subnet_id                     = azurerm_subnet.server_subnet.id
#     private_ip_address_allocation = "Dynamic"
#   }
# }

# resource "azurerm_network_interface" "vm_jump_nic" {
#   name                = "nic-jump"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name

#   ip_configuration {
#     name                          = "ipconfig-jump"
#     subnet_id                     = azurerm_subnet.jump_subnet.id
#     private_ip_address_allocation = "Dynamic"
#     public_ip_address_id          = azurerm_public_ip.vm_jump_pip.id
#   }
# }

# resource "azurerm_network_security_group" "vm_server_nsg" {
#   name                = "nsg-server"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
# }

# resource "azurerm_network_security_group" "vm_jump_nsg" {
#   name                = "nsg-jump"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   security_rule {
#     name                       = "Allow-SSH"
#     priority                   = 1000
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "22"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
# }

# resource "azurerm_network_interface_security_group_association" "vm_server_nsg_association" {
#   network_interface_id      = azurerm_network_interface.vm_server_nic.id
#   network_security_group_id = azurerm_network_security_group.vm_server_nsg.id
# }

# resource "azurerm_network_interface_security_group_association" "vm_jump_nsg_association" {
#   network_interface_id      = azurerm_network_interface.vm_jump_nic.id
#   network_security_group_id = azurerm_network_security_group.vm_jump_nsg.id
# }

# resource "azurerm_linux_virtual_machine" "vm_server" {
#   name                = "server-vm"
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = azurerm_resource_group.rg.location
#   size                = var.virtual_machine_size
#   admin_username      = var.admin_username
#   admin_ssh_key {
#     username   = "localmgr"
#     public_key = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
#   }
#   network_interface_ids = [azurerm_network_interface.vm_server_nic.id]
#   os_disk {
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }
#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "UbuntuServer"
#     sku       = "18.04-LTS"
#     version   = "latest"
#   }
#   boot_diagnostics {
#     storage_account_uri = azurerm_storage_account.sa.primary_blob_endpoint
#   }
# }

# resource "azurerm_linux_virtual_machine" "vm_jump" {
#   name                  = "jump-vm"
#   resource_group_name   = azurerm_resource_group.rg.name
#   location              = azurerm_resource_group.rg.location
#   size                  = var.virtual_machine_size
#   network_interface_ids = [azurerm_network_interface.vm_jump_nic.id]
#   admin_username        = "localmgr"
#   os_disk {
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }
#   admin_ssh_key {
#     username   = var.admin_username
#     public_key = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
#   }
#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "UbuntuServer"
#     sku       = "18.04-LTS"
#     version   = "latest"
#   }
#   boot_diagnostics {
#     storage_account_uri = azurerm_storage_account.sa.primary_blob_endpoint
#   }
#   computer_name = "JumpBox"

# }




