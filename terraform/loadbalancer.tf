resource "azurerm_network_interface" "be_nic" {
  for_each            = toset(local.regions)
  name                = module.naming[each.key].network_interface.name
  location            = each.key
  resource_group_name = azurerm_resource_group.rg[each.key].name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.avm-res-network-virtualnetwork[each.key].subnets["${module.naming[each.key].subnet.name}"].id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost("${local.vnet_map[each.key]}", 4)
  }
}

module "loadbalancer" {
  for_each            = toset(local.regions)
  source              = "Azure/avm-res-network-loadbalancer/azurerm"
  enable_telemetry    = var.enable_telemetry
  name                = module.naming[each.key].lb.name
  resource_group_name = azurerm_resource_group.rg[each.key].name
  location            = each.key

  # Frontend IP Configuration
  frontend_ip_configurations = {
    frontend_configuration_1 = {
      name                          = module.naming[each.key].public_ip.name
      create_public_ip_address      = false
      public_ip_address_resource_id = module.avm-res-network-publicipaddress[each.key].public_ip_id
      zones                         = ["None"] # Non-zonal
      # zones                           = ["1", "2", "3"] # Zone-redundant
    }
  }

  # Virtual Network for Backend Address Pool(s)
  backend_address_pool_configuration = module.avm-res-network-virtualnetwork[each.key].virtual_network_id

  # Backend Address Pool(s)
  backend_address_pools = {
    pool1 = {
      name                        = "ansible-ssh"
      virtual_network_resource_id = module.avm-res-network-virtualnetwork[each.key].virtual_network_id # set a virtual_network_resource_id if using backend_address_pool_addresses
    }
    pool2 = {
      name                        = "windows-rdp"
      virtual_network_resource_id = module.avm-res-network-virtualnetwork[each.key].virtual_network_id # set a virtual_network_resource_id if using backend_address_pool_addresses
    }
  }

  backend_address_pool_addresses = {
    address1 = {
      name                             = "ansible-ipconfig" #"${module.naming[each.key].network_interface.name}-ipconfig" # must be unique if multiple addresses are used
      backend_address_pool_object_name = "pool1"
      ip_address                       = module.avm-res-compute-virtualmachine[each.key].network_interfaces["network_interface_1"].private_ip_address #"131.128.2.5" #azurerm_network_interface.be_nic[each.key].private_ip_address
      virtual_network_resource_id      = module.avm-res-network-virtualnetwork[each.key].virtual_network_id
    }
    address2 = {
      name                             = "windows-ipconfig" #"${module.naming[each.key].network_interface.name}-ipconfig" # must be unique if multiple addresses are used
      backend_address_pool_object_name = "pool2"
      ip_address                       = module.windows[each.key].network_interfaces["network_interface_1"].private_ip_address #"131.128.2.5" #azurerm_network_interface.be_nic[each.key].private_ip_address
      virtual_network_resource_id      = module.avm-res-network-virtualnetwork[each.key].virtual_network_id
    }
  }

  # Health Probe(s)
  lb_probes = {
    ssh = {
      name                = "ansible-ssh"
      protocol            = "Tcp"
      port                = 22
      interval_in_seconds = 300
    }
    rdp = {
      name                = "windows-rdp"
      protocol            = "Tcp"
      port                = 3389
      interval_in_seconds = 300
    }
  }

  # Load Balaner rule(s)
  lb_rules = {
    ssh1 = {
      name                              = "ansible-ssh"
      frontend_ip_configuration_name    = module.naming[each.key].public_ip.name
      backend_address_pool_object_names = ["pool1"]
      protocol                          = "Tcp"
      frontend_port                     = 22
      backend_port                      = 22
      probe_object_name                 = "ssh"
      idle_timeout_in_minutes           = 15
      enable_tcp_reset                  = false
    }
    rdp = {
      name                              = "windows-rdp"
      frontend_ip_configuration_name    = module.naming[each.key].public_ip.name
      backend_address_pool_object_names = ["pool2"]
      protocol                          = "Tcp"
      frontend_port                     = 3389
      backend_port                      = 3389
      probe_object_name                 = "rdp"
      idle_timeout_in_minutes           = 15
      enable_tcp_reset                  = false
    }
  }
}
