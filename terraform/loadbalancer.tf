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
  backend_address_pool_configuration = module.avm-res-network-virtualnetwork[each.key].resource_id

  # Backend Address Pool(s)
  backend_address_pools = {
    pool1 = {
      name                        = "control-ssh"
      virtual_network_resource_id = module.avm-res-network-virtualnetwork[each.key].resource_id # set a virtual_network_resource_id if using backend_address_pool_addresses
    }
    pool2 = {
      name                        = "node-ssh"
      virtual_network_resource_id = module.avm-res-network-virtualnetwork[each.key].resource_id # set a virtual_network_resource_id if using backend_address_pool_addresses
    }
    pool3 = {
      name                        = "dc-rdp"
      virtual_network_resource_id = module.avm-res-network-virtualnetwork[each.key].resource_id # set a virtual_network_resource_id if using backend_address_pool_addresses
    }

  }

  backend_address_pool_addresses = {
    address1 = {
      name                             = "nic-control-ipconfig" #azurerm_network_interface.be_nic.ip_configuration[each.key].name
      backend_address_pool_object_name = "pool1"
      ip_address                       = module.control[each.key].network_interfaces["network_interface_1"].private_ip_address
      virtual_network_resource_id      = module.avm-res-network-virtualnetwork[each.key].resource_id
    }
    address2 = {
      name                             = "nic-node-ipconfig" #azurerm_network_interface.be_nic.ip_configuration[each.key].name
      backend_address_pool_object_name = "pool2"
      ip_address                       = module.node[each.key].network_interfaces["network_interface_1"].private_ip_address
      virtual_network_resource_id      = module.avm-res-network-virtualnetwork[each.key].resource_id
    }
    address3 = {
      name                             = "nic-vmansadvuks01-ipconfig" #azurerm_network_interface.be_nic.ip_configuration[each.key].name
      backend_address_pool_object_name = "pool3"
      ip_address                       = module.dc01[each.key].network_interfaces["network_interface_1"].private_ip_address
      virtual_network_resource_id      = module.avm-res-network-virtualnetwork[each.key].resource_id
    }
  }

  # Health Probe(s)
  lb_probes = {
    ssh = {
      name                = "ssh"
      protocol            = "Tcp"
      port                = 22
      interval_in_seconds = 300
    }
    rdp = {
      name                = "rdp"
      protocol            = "Tcp"
      port                = 3389
      interval_in_seconds = 300
    }
  }

  # Load Balaner rule(s)
  lb_rules = {
    control_ssh = {
      name                              = "control-ssh"
      frontend_ip_configuration_name    = module.naming[each.key].public_ip.name
      backend_address_pool_object_names = ["pool1"]
      protocol                          = "Tcp"
      frontend_port                     = 22
      backend_port                      = 22
      probe_object_name                 = "ssh"
      idle_timeout_in_minutes           = 15
      enable_tcp_reset                  = false
      # disable_outbound_snat             = true
    }
    node_ssh = {
      name                              = "node-ssh"
      frontend_ip_configuration_name    = module.naming[each.key].public_ip.name
      backend_address_pool_object_names = ["pool2"]
      protocol                          = "Tcp"
      frontend_port                     = 122
      backend_port                      = 22
      probe_object_name                 = "ssh"
      idle_timeout_in_minutes           = 15
      enable_tcp_reset                  = false
      # disable_outbound_snat             = true
    }
    dc01_rdp = {
      name                              = "dc01-rdp"
      frontend_ip_configuration_name    = module.naming[each.key].public_ip.name
      backend_address_pool_object_names = ["pool3"]
      protocol                          = "Tcp"
      frontend_port                     = 3389
      backend_port                      = 3389
      probe_object_name                 = "rdp"
      idle_timeout_in_minutes           = 15
      enable_tcp_reset                  = false
      # disable_outbound_snat             = true
    }
  }

  depends_on = [
    module.control,
    module.node,
    module.dc01
  ]

}
