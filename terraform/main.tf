resource "azurerm_resource_group" "rg" {
  for_each = toset(local.regions)
  location = each.key
  name     = module.naming[each.key].resource_group.name
}

module "avm-res-network-virtualnetwork" {
  for_each            = toset(local.regions)
  source              = "Azure/avm-res-network-virtualnetwork/azurerm"
  name                = module.naming[each.key].virtual_network.name
  enable_telemetry    = var.enable_telemetry
  resource_group_name = azurerm_resource_group.rg[each.key].name
  location            = each.key

  subnets = {
    "${module.naming[each.key].subnet.name}" = {
      address_prefixes = [cidrsubnet("${local.vnet_map[each.key]}", 1, 0)]
    }
  }

  virtual_network_dns_servers = {
    dns_servers = ["8.8.8.8"]
  }

  virtual_network_address_space = [local.vnet_map[each.key]]
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

module "avm-res-network-privatednszone" {
  for_each            = toset(local.regions)
  source              = "Azure/avm-res-network-privatednszone/azurerm"
  domain_name         = "ansible-poc.local"
  resource_group_name = azurerm_resource_group.rg[each.key].name

  virtual_network_links = {
    vnetlink1 = {
      vnetlinkname     = "${module.naming[each.key].virtual_network.name}-pdnslink"
      vnetid           = module.avm-res-network-virtualnetwork[each.key].virtual_network_id
      autoregistration = true
    }
  }
}

module "avm-res-network-networksecuritygroup" {
  for_each            = toset(local.regions)
  source              = "Azure/avm-res-network-networksecuritygroup/azurerm"
  name                = module.naming[each.key].network_security_group.name
  resource_group_name = azurerm_resource_group.rg[each.key].name
  location            = each.key
  nsgrules            = var.rules
  enable_telemetry    = var.enable_telemetry
}

module "avm-res-managedidentity-userassignedidentity" {
  for_each            = toset(local.regions)
  source              = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  name                = module.naming[each.key].user_assigned_identity.name
  resource_group_name = azurerm_resource_group.rg[each.key].name
  location            = each.key
  enable_telemetry    = var.enable_telemetry
}

module "avm-res-keyvault-vault" {
  for_each            = toset(local.regions)
  source              = "Azure/avm-res-keyvault-vault/azurerm"
  name                = module.naming[each.key].key_vault.name
  resource_group_name = azurerm_resource_group.rg[each.key].name
  location            = each.key
  tenant_id           = data.azurerm_client_config.current.tenant_id
}

resource "azapi_resource" "ssh_public_key" {
  type      = "Microsoft.Compute/sshPublicKeys@2023-09-01"
  name      = "pub-ans-adv-uks-01"
  location  = azurerm_resource_group.rg["UK South"].location
  parent_id = azurerm_resource_group.rg["UK South"].id
}

resource "azapi_resource_action" "ssh_public_key_gen" {
  type                   = "Microsoft.Compute/sshPublicKeys@2023-09-01"
  resource_id            = azapi_resource.ssh_public_key.id
  action                 = "generateKeyPair"
  method                 = "POST"
  response_export_values = ["publicKey", "privateKey"]
}

resource "local_file" "private_key" {
  content  = jsondecode(jsonencode(azapi_resource_action.ssh_public_key_gen.output)).privateKey
  filename = "../.ssh/rsa"
}


# resource "tls-private-key" "private_key" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }

# resource "azurerm_key_vault_secret" "admin_ssh_key" {
#   for_each     = toset(local.regions)
#   key_vault_id = module.avm-res-keyvault-vault[each.key].resource.id
#   name         = "azureuser-ssh-private-key"
#   value        = tls_private_key.private_key.private_key_pem

#   depends_on = [
#     module.avm-res-keyvault-vault
#   ]
# }

# resource "azapi_resource_action" "ssh_public_key_gen" {
#   type                   = "Microsoft.Compute/sshPublicKeys@2022-11-01"
#   resource_id            = azapi_resource.ssh_public_key.id
#   action                 = "generateKeyPair"
#   method                 = "POST"
#   response_export_values = ["publicKey", "privateKey"]
# }

# resource "azapi_resource" "ssh_public_key" {
#   type      = "Microsoft.Compute/sshPublicKeys@2023-07-01"
#   name      = "aap_ssh_public_key"
#   location  = azurerm_resource_group.aap.location
#   parent_id = azurerm_resource_group.aap.id
# }

# resource "local_file" "ssh_key" {
#   content  = jsondecode(azapi_resource_action.ssh_public_key_gen.output).privateKey
#   filename = "C:\\Users\\david\\.ssh\\aap-pk"
# }

# module "nsg" {
#   source                = "Azure/network-security-group/azurerm"
#   resource_group_name   = azurerm_resource_group.aap.name
#   security_group_name   = lower("${module.naming.network_security_group.name}")
#   source_address_prefix = module.vnet.vnet_address_space

#   custom_rules = [
#     {
#       name                       = "sshInbound"
#       priority                   = "1000"
#       direction                  = "Inbound"
#       access                     = "Allow"
#       protocol                   = "Tcp"
#       source_port_range          = "22"
#       destination_port_range     = "22"
#       source_address_prefix      = "*"
#       destination_address_prefix = "*"
#     },
#     {
#       name                       = "httpInbound"
#       priority                   = "1020"
#       direction                  = "Inbound"
#       access                     = "Allow"
#       protocol                   = "Tcp"
#       source_port_range          = "80"
#       destination_port_range     = "80"
#       source_address_prefix      = "*"
#       destination_address_prefix = "*"
#     },
#     {
#       name                       = "httpsInbound"
#       priority                   = "1030"
#       direction                  = "Inbound"
#       access                     = "Allow"
#       protocol                   = "Tcp"
#       source_port_range          = "443"
#       destination_port_range     = "443"
#       source_address_prefix      = "*"
#       destination_address_prefix = "*"
#     },
#     {
#       name                       = "semaphoreInbound"
#       priority                   = "1040"
#       direction                  = "Inbound"
#       access                     = "Allow"
#       protocol                   = "Tcp"
#       source_port_range          = "3000"
#       destination_port_range     = "3000"
#       source_address_prefix      = "*"
#       destination_address_prefix = "*"
#     },
#     {
#       name                       = "pgsqlInbound"
#       priority                   = "1050"
#       direction                  = "Inbound"
#       access                     = "Allow"
#       protocol                   = "Tcp"
#       source_port_range          = "5432"
#       destination_port_range     = "5432"
#       source_address_prefix      = "*"
#       destination_address_prefix = "*"
#     },
#     {
#       name                       = "receptorInbound"
#       priority                   = "1060"
#       direction                  = "Inbound"
#       access                     = "Allow"
#       protocol                   = "Tcp"
#       source_port_range          = "27199"
#       destination_port_range     = "27199"
#       source_address_prefix      = "*"
#       destination_address_prefix = "*"
#     }
#   ]

#   depends_on = [azurerm_resource_group.aap]

# }
