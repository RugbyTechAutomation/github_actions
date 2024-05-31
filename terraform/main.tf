resource "azurerm_resource_group" "rg" {
  for_each = toset(local.regions)
  location = each.key
  name     = module.naming[each.key].resource_group.name
}

module "avm-res-managedidentity-userassignedidentity" {
  source              = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  for_each            = toset(local.regions)
  enable_telemetry    = var.enable_telemetry
  name                = module.naming[each.key].user_assigned_identity.name
  resource_group_name = azurerm_resource_group.rg[each.key].name
  location            = each.key
}

module "avm-res-network-virtualnetwork" {
  for_each            = toset(local.regions)
  source              = "Azure/avm-res-network-virtualnetwork/azurerm"
  name                = module.naming[each.key].virtual_network.name
  enable_telemetry    = var.enable_telemetry
  resource_group_name = azurerm_resource_group.rg[each.key].name
  location            = each.key
  address_space       = [local.vnet_map[each.key]]

  subnets = {
    "control" = {
      name             = "control"
      address_prefixes = [cidrsubnet("${local.vnet_map[each.key]}", 1, 0)]
    }
    "node" = {
      name             = "node"
      address_prefixes = [cidrsubnet("${local.vnet_map[each.key]}", 1, 1)]
    }
  }

  # virtual_network_dns_servers = {
  #   dns_servers = ["8.8.8.8"]
  # }

}

module "avm-res-network-publicipaddress" {
  for_each            = toset(local.regions)
  source              = "Azure/avm-res-network-publicipaddress/azurerm"
  name                = module.naming[each.key].public_ip.name
  resource_group_name = azurerm_resource_group.rg[each.key].name
  location            = each.key
  allocation_method   = "Static"
  sku                 = "Standard"
  enable_telemetry    = var.enable_telemetry
}

# module "avm-res-network-privatednszone" {
#   for_each            = toset(local.regions)
#   source              = "Azure/avm-res-network-privatednszone/azurerm"
#   domain_name         = "ansible-poc.local"
#   resource_group_name = azurerm_resource_group.rg[each.key].name

#   virtual_network_links = {
#     vnetlink1 = {
#       vnetlinkname     = "${module.naming[each.key].virtual_network.name}-pdnslink"
#       vnetid           = module.avm-res-network-virtualnetwork[each.key].virtual_network_id
#       autoregistration = true
#     }
#   }
# }

module "avm-res-network-networksecuritygroup" {
  for_each            = toset(local.regions)
  source              = "Azure/avm-res-network-networksecuritygroup/azurerm"
  name                = module.naming[each.key].network_security_group.name
  resource_group_name = azurerm_resource_group.rg[each.key].name
  location            = each.key
  security_rules      = local.nsg_rules
  enable_telemetry    = var.enable_telemetry
}

resource "azurerm_subnet_network_security_group_association" "control" {
  for_each                  = toset(local.regions)
  subnet_id                 = module.avm-res-network-virtualnetwork[each.key].subnets["control"].resource_id
  network_security_group_id = module.avm-res-network-networksecuritygroup[each.key].resource_id
}
resource "azurerm_subnet_network_security_group_association" "node" {
  for_each                  = toset(local.regions)
  subnet_id                 = module.avm-res-network-virtualnetwork[each.key].subnets["node"].resource_id
  network_security_group_id = module.avm-res-network-networksecuritygroup[each.key].resource_id
}
