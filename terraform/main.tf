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
      address_prefixes = [cidrsubnet("${local.vnet_map[each.key]}", 0, 0)]
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

module "avm-res-compute-virtualmachine" {
  source                             = "Azure/avm-res-compute-virtualmachine/azurerm"
  for_each                           = toset(local.regions)
  admin_username                     = "localmgr"
  admin_password                     = "1QAZ2wsx3edc"
  enable_telemetry                   = var.enable_telemetry
  generate_admin_password_or_ssh_key = false
  disable_password_authentication    = false
  location                           = each.key
  name                               = module.naming[each.key].linux_virtual_machine.name
  resource_group_name                = azurerm_resource_group.rg[each.key].name
  virtualmachine_os_type             = "Linux"
  virtualmachine_sku_size            = "Standard_B2as_v2" #module.get_valid_sku_for_deployment_region.sku
  zone                               = null               #random_integer.zone_index.result

  admin_ssh_keys = [
    {
      public_key = jsondecode(jsonencode(azapi_resource_action.ssh_public_key_gen.output)).publicKey
      username   = "localmgr" #the username must match the admin_username currently.
    }
  ]

  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = [module.avm-res-managedidentity-userassignedidentity[each.key].resource_id]
  }

  network_interfaces = {
    network_interface_1 = {
      name                           = "nic-${module.naming[each.key].linux_virtual_machine.name}"
      accelerated_networking_enabled = true
      ip_configurations = {
        ip_configuration_1 = {
          name                          = "nic-${module.naming[each.key].linux_virtual_machine.name}-ipconfig"
          private_ip_subnet_resource_id = module.avm-res-network-virtualnetwork[each.key].subnets["${module.naming[each.key].subnet.name}"].id
          public_ip_address_resource_id = module.avm-res-network-publicipaddress[each.key].public_ip_id
        }
      }
    }
  }

  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    name                 = "${module.naming[each.key].linux_virtual_machine.name}-osDisk"
  }

  data_disk_managed_disks = {
    for i in range(2) : format("disk-%02d", i + 1) => {
      name                 = format("${module.naming[each.key].linux_virtual_machine.name}-dataDisk-%02d", i + 1)
      storage_account_type = "StandardSSD_LRS"
      create_option        = "Empty"
      disk_size_gb         = 64
      # on_demand_bursting_enabled = var.TF_STORAGE_ACCOUNT_TYPE == "Premium_LRS" ? true : false
      # performance_plus_enabled = true
      lun     = i
      caching = "ReadWrite"
    }
  }

  # role_assignments_system_managed_identity = {
  #   role_assignment_1 = {
  #     scope_resource_id          = module.avm-res-keyvault-vault.resource.id
  #     role_definition_id_or_name = "Key Vault Secrets Officer"
  #     description                = "Assign the Key Vault Secrets Officer role to the virtual machine's system managed identity"
  #     principal_type             = "ServicePrincipal"
  #   }
  # }

  # role_assignments = {
  #   role_assignment_2 = {
  #     principal_id               = data.azurerm_client_config.current.client_id
  #     role_definition_id_or_name = "Virtual Machine Contributor"
  #     description                = "Assign the Virtual Machine Contributor role to the deployment user on this virtual machine resource scope."
  #     principal_type             = "ServicePrincipal"
  #   }
  # }

  source_image_reference = {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  depends_on = [
    module.avm-res-keyvault-vault
  ]
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "compute" {
  for_each           = toset(local.regions)
  virtual_machine_id = module.avm-res-compute-virtualmachine[each.key].resource_id
  location           = azurerm_resource_group.rg[each.key].location
  enabled            = true

  daily_recurrence_time = "1900"
  timezone              = "GMT Standard Time"

  notification_settings {
    enabled         = false
    time_in_minutes = "15"
    webhook_url     = ""
  }
}

resource "azurerm_network_interface_security_group_association" "compute" {
  for_each                  = toset(local.regions)
  network_interface_id      = module.avm-res-compute-virtualmachine[each.key].network_interfaces["network_interface_1"].id
  network_security_group_id = module.avm-res-network-networksecuritygroup[each.key].nsg_resource.id
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
