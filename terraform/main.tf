resource "azurerm_resource_group" "rg" {
  for_each = toset(local.regions)
  location = each.key
  name     = module.naming[each.key].resource_group.name
}

module "containerregistry" {
  source                        = "Azure/avm-res-containerregistry-registry/azurerm"
  for_each                      = toset(local.regions)
  name                          = replace("${module.naming[each.key].container_registry.name}", "-", "")
  location                      = azurerm_resource_group.rg[each.key].location
  resource_group_name           = azurerm_resource_group.rg[each.key].name
  sku                           = "Basic"
  admin_enabled                 = true
  zone_redundancy_enabled       = false # need to override this default setting because zone redundancy isn't supported on Basic SKU.
  enable_telemetry              = false
  public_network_access_enabled = true
  # enable_node_public_ip = true
}

# resource "azurerm_kubernetes_cluster" "akc" {
#   for_each            = toset(local.regions)
#   name                = module.naming[each.key].kubernetes_cluster.name
#   location            = azurerm_resource_group.rg[each.key].location
#   resource_group_name = azurerm_resource_group.rg[each.key].name
#   dns_prefix          = "ans"

#   default_node_pool {
#     name       = "default"
#     node_count = 1
#     vm_size    = "Standard_B2s_v2" #Standard_B4ls_v2
#   }

#   identity {
#     type = "SystemAssigned"
#   }
# }

# resource "azurerm_kubernetes_cluster_node_pool" "example" {
#   name                  = "internal"
#   kubernetes_cluster_id = azurerm_kubernetes_cluster.example.id
#   vm_size               = "Standard_DS2_v2"
#   node_count            = 1

#   tags = {
#     Environment = "Production"
#   }
# }


module "aks" {
  source              = "Azure/aks/azurerm"
  cluster_name        = module.naming[each.key].kubernetes_cluster.name
  for_each            = toset(local.regions)
  resource_group_name = azurerm_resource_group.rg[each.key].name
  kubernetes_version  = "1.29.2" # don't specify the patch version!
  # automatic_channel_upgrade = 
  attached_acr_id_map = {
    example = module.containerregistry[each.key].resource_id
  }
  network_plugin                  = "azure"
  network_policy                  = "azure"
  os_disk_size_gb                 = 60
  sku_tier                        = "Free"
  rbac_aad                        = false
  log_analytics_workspace_enabled = false
  prefix                          = "ans"
  # vnet_subnet_id  = azurerm_subnet.test.id


  # node_pools = {
  #   name       = "ansible"
  #   vm_size    = "Standard_B2s_v2"
  #   node_count = 1
  # }
}





# resource "azurerm_resource_group" "rg" {
#   location = "UK South"
#   name     = "${module.naming.resource_group.name}-01"
# }

# resource "azurerm_virtual_network" "hub" {
#   name                = "vnet-adv-hub-uks-01"
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = azurerm_resource_group.rg.location
#   address_space       = ["10.64.0.0/25"]

#   # subnet = {
#   #   name           = "GatewaySubnet"
#   #   address_prefix = "10.64.0.0/27"
#   #   # address_prefixes = ["10.64.0.0/27"]
#   # }
# }

# resource "azurerm_subnet" "gateway" {
#   name                 = "GatewaySubnet"
#   resource_group_name  = azurerm_resource_group.rg.name
#   virtual_network_name = azurerm_virtual_network.hub.name
#   address_prefixes     = ["10.64.0.0/29"]

#   # delegation {
#   #   name = "delegation"

#   #   service_delegation {
#   #     name    = "Microsoft.ContainerInstance/containerGroups"
#   #     actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
#   #   }
#   # }
# }

# resource "azurerm_virtual_network" "vnet" {
#   count               = 3
#   name                = "${module.naming.virtual_network.name}-0${count.index + 1}"
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = azurerm_resource_group.rg.location
#   address_space       = ["10.${count.index}.0.0/16"]
# }

# # Add a subnet to each virtual network

# resource "azurerm_subnet" "subnet_vnet" {
#   count                = 3
#   name                 = "${module.naming.subnet.name}-0${count.index + 1}"
#   virtual_network_name = azurerm_virtual_network.vnet[count.index].name
#   resource_group_name  = azurerm_resource_group.rg.name
#   address_prefixes     = ["10.${count.index}.0.0/24"]
# }

# # Create a Virtual Network Manager instance

# resource "azurerm_network_manager" "network_manager_instance" {
#   name                = "vnm-ntwk-uks-01"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   scope_accesses      = ["Connectivity"]
#   description         = "demo network manager"
#   scope {
#     subscription_ids = [data.azurerm_subscription.current.id]
#   }
# }

# # Create a network group

# resource "azurerm_network_manager_network_group" "network_group" {
#   count              = 2
#   name               = "vng-ntwk-uks-0${count.index + 1}"
#   network_manager_id = azurerm_network_manager.network_manager_instance.id
# }

# # Create a connectivity configuration

# resource "azurerm_network_manager_connectivity_configuration" "connectivity_config" {
#   name                  = "connectivity-config"
#   network_manager_id    = azurerm_network_manager.network_manager_instance.id
#   connectivity_topology = "HubAndSpoke"
#   applies_to_group {
#     group_connectivity = "DirectlyConnected"
#     network_group_id   = azurerm_network_manager_network_group.network_group[0].id
#     use_hub_gateway    = true
#   }
#   applies_to_group {
#     group_connectivity = "DirectlyConnected"
#     network_group_id   = azurerm_network_manager_network_group.network_group[1].id
#     use_hub_gateway    = true
#   }

#   hub {
#     resource_id   = azurerm_virtual_network.hub.id
#     resource_type = "Microsoft.Network/virtualNetworks"
#   }
# }

# # Commit deployment

# resource "azurerm_network_manager_deployment" "commit_deployment" {
#   network_manager_id = azurerm_network_manager.network_manager_instance.id
#   location           = azurerm_resource_group.rg.location
#   scope_access       = "Connectivity"
#   configuration_ids  = [azurerm_network_manager_connectivity_configuration.connectivity_config.id]
# }

# # output "resource_group_name" {
# #   value = azurerm_resource_group.rg.name
# # }

# # output "virtual_network_names" {
# #   value = azurerm_virtual_network.vnet[*].name
# # }
