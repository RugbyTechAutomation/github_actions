resource "azurerm_resource_group" "rg" {
  for_each = toset(local.regions)
  location = each.key
  name     = module.naming[each.key].resource_group.name
}

# module "containerregistry" {
#   source                        = "Azure/avm-res-containerregistry-registry/azurerm"
#   for_each                      = toset(local.regions)
#   name                          = replace("${module.naming[each.key].container_registry.name}", "-", "")
#   location                      = azurerm_resource_group.rg[each.key].location
#   resource_group_name           = azurerm_resource_group.rg[each.key].name
#   sku                           = "Basic"
#   admin_enabled                 = true
#   zone_redundancy_enabled       = false # need to override this default setting because zone redundancy isn't supported on Basic SKU.
#   enable_telemetry              = false
#   public_network_access_enabled = true
#   # enable_node_public_ip = true
# }

# # resource "azurerm_kubernetes_cluster" "akc" {
# #   for_each            = toset(local.regions)
# #   name                = module.naming[each.key].kubernetes_cluster.name
# #   location            = azurerm_resource_group.rg[each.key].location
# #   resource_group_name = azurerm_resource_group.rg[each.key].name
# #   dns_prefix          = "ans"

# #   default_node_pool {
# #     name       = "default"
# #     node_count = 1
# #     vm_size    = "Standard_B2s_v2" #Standard_B4ls_v2
# #   }

# #   identity {
# #     type = "SystemAssigned"
# #   }
# # }

# # resource "azurerm_kubernetes_cluster_node_pool" "example" {
# #   name                  = "internal"
# #   kubernetes_cluster_id = azurerm_kubernetes_cluster.example.id
# #   vm_size               = "Standard_DS2_v2"
# #   node_count            = 1

# #   tags = {
# #     Environment = "Production"
# #   }
# # }


# module "aks" {
#   source              = "Azure/aks/azurerm"
#   cluster_name        = module.naming[each.key].kubernetes_cluster.name
#   for_each            = toset(local.regions)
#   resource_group_name = azurerm_resource_group.rg[each.key].name
#   kubernetes_version  = "1.29.2" # don't specify the patch version!
#   # automatic_channel_upgrade = 
#   attached_acr_id_map = {
#     example = module.containerregistry[each.key].resource_id
#   }
#   network_plugin                  = "azure"
#   network_policy                  = "azure"
#   os_disk_size_gb                 = 60
#   sku_tier                        = "Free"
#   rbac_aad                        = false
#   log_analytics_workspace_enabled = false
#   prefix                          = "ans"
#   # vnet_subnet_id  = azurerm_subnet.test.id


#   # node_pools = {
#   #   name       = "ansible"
#   #   vm_size    = "Standard_B2s_v2"
#   #   node_count = 1
#   # }
# }





# # resource "azurerm_resource_group" "rg" {
# #   location = "UK South"
# #   name     = "${module.naming.resource_group.name}-01"
# # }

# # resource "azurerm_virtual_network" "hub" {
# #   name                = "vnet-adv-hub-uks-01"
# #   resource_group_name = azurerm_resource_group.rg.name
# #   location            = azurerm_resource_group.rg.location
# #   address_space       = ["10.64.0.0/25"]

# #   # subnet = {
# #   #   name           = "GatewaySubnet"
# #   #   address_prefix = "10.64.0.0/27"
# #   #   # address_prefixes = ["10.64.0.0/27"]
# #   # }
# # }

# # resource "azurerm_subnet" "gateway" {
# #   name                 = "GatewaySubnet"
# #   resource_group_name  = azurerm_resource_group.rg.name
# #   virtual_network_name = azurerm_virtual_network.hub.name
# #   address_prefixes     = ["10.64.0.0/29"]

# #   # delegation {
# #   #   name = "delegation"

# #   #   service_delegation {
# #   #     name    = "Microsoft.ContainerInstance/containerGroups"
# #   #     actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
# #   #   }
# #   # }
# # }

# # resource "azurerm_virtual_network" "vnet" {
# #   count               = 3
# #   name                = "${module.naming.virtual_network.name}-0${count.index + 1}"
# #   resource_group_name = azurerm_resource_group.rg.name
# #   location            = azurerm_resource_group.rg.location
# #   address_space       = ["10.${count.index}.0.0/16"]
# # }

# # # Add a subnet to each virtual network

# # resource "azurerm_subnet" "subnet_vnet" {
# #   count                = 3
# #   name                 = "${module.naming.subnet.name}-0${count.index + 1}"
# #   virtual_network_name = azurerm_virtual_network.vnet[count.index].name
# #   resource_group_name  = azurerm_resource_group.rg.name
# #   address_prefixes     = ["10.${count.index}.0.0/24"]
# # }

# # # Create a Virtual Network Manager instance

# # resource "azurerm_network_manager" "network_manager_instance" {
# #   name                = "vnm-ntwk-uks-01"
# #   location            = azurerm_resource_group.rg.location
# #   resource_group_name = azurerm_resource_group.rg.name
# #   scope_accesses      = ["Connectivity"]
# #   description         = "demo network manager"
# #   scope {
# #     subscription_ids = [data.azurerm_subscription.current.id]
# #   }
# # }

# # # Create a network group

# # resource "azurerm_network_manager_network_group" "network_group" {
# #   count              = 2
# #   name               = "vng-ntwk-uks-0${count.index + 1}"
# #   network_manager_id = azurerm_network_manager.network_manager_instance.id
# # }

# # # Create a connectivity configuration

# # resource "azurerm_network_manager_connectivity_configuration" "connectivity_config" {
# #   name                  = "connectivity-config"
# #   network_manager_id    = azurerm_network_manager.network_manager_instance.id
# #   connectivity_topology = "HubAndSpoke"
# #   applies_to_group {
# #     group_connectivity = "DirectlyConnected"
# #     network_group_id   = azurerm_network_manager_network_group.network_group[0].id
# #     use_hub_gateway    = true
# #   }
# #   applies_to_group {
# #     group_connectivity = "DirectlyConnected"
# #     network_group_id   = azurerm_network_manager_network_group.network_group[1].id
# #     use_hub_gateway    = true
# #   }

# #   hub {
# #     resource_id   = azurerm_virtual_network.hub.id
# #     resource_type = "Microsoft.Network/virtualNetworks"
# #   }
# # }

# # # Commit deployment

# # resource "azurerm_network_manager_deployment" "commit_deployment" {
# #   network_manager_id = azurerm_network_manager.network_manager_instance.id
# #   location           = azurerm_resource_group.rg.location
# #   scope_access       = "Connectivity"
# #   configuration_ids  = [azurerm_network_manager_connectivity_configuration.connectivity_config.id]
# # }

# # # output "resource_group_name" {
# # #   value = azurerm_resource_group.rg.name
# # # }

# # # output "virtual_network_names" {
# # #   value = azurerm_virtual_network.vnet[*].name
# # # }

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

# resource "azurerm_resource_group" "aap" {
#   name     = lower("${module.naming.resource_group.name}")
#   location = "UK South"
# }

# # resource "azurerm_key_vault" "aap" {
# #   for_each                 = toset(var.regions)
# #   name                     = lower("${module.naming.key_vault.name}")
# #   location                 = azurerm_resource_group.aap.location
# #   resource_group_name      = azurerm_resource_group.aap.name
# #   sku_name                 = "standard"
# #   purge_protection_enabled = false
# #   enabled_for_deployment   = true
# #   tenant_id                = data.azurerm_client_config.current.tenant_id

# #   access_policy {
# #     tenant_id = data.azurerm_client_config.current.tenant_id
# #     object_id = data.azurerm_client_config.current.object_id

# #     certificate_permissions = ["Backup",
# #       "Create",
# #       "Delete",
# #       "DeleteIssuers",
# #       "Get",
# #       "GetIssuers",
# #       "Import",
# #       "List",
# #       "ListIssuers",
# #       "ManageContacts",
# #       "ManageIssuers",
# #       "Purge",
# #       "Recover",
# #       "Restore",
# #       "SetIssuers",
# #       "Update"
# #     ]

# #     key_permissions = [
# #       "Backup",
# #       "Create",
# #       "Decrypt",
# #       "Delete",
# #       "Encrypt",
# #       "Get",
# #       "Import",
# #       "List",
# #       "Purge",
# #       "Recover",
# #       "Restore",
# #       "Sign",
# #       "UnwrapKey",
# #       "Update",
# #       "Verify",
# #       "WrapKey",
# #       "Release",
# #       "Rotate",
# #       "GetRotationPolicy",
# #       "SetRotationPolicy"
# #     ]

# #     secret_permissions = [
# #       "Backup",
# #       "Delete",
# #       "Get",
# #       "List",
# #       "Purge",
# #       "Recover",
# #       "Restore",
# #       "Set"
# #     ]

# #     storage_permissions = [
# #       "Get",
# #     ]
# #   }
# # }

# # resource "azurerm_key_vault_key" "aap" {
# #   for_each     = toset(var.regions)
# #   name         = "${var.short_loc}-posit-admin"
# #   key_vault_id = azurerm_key_vault.aap.id
# #   key_type     = "RSA"
# #   key_size     = 4096

# #   key_opts = [
# #     "decrypt",
# #     "encrypt",
# #     "sign",
# #     "unwrapKey",
# #     "verify",
# #     "wrapKey",
# #   ]

# #   # rotation_policy {
# #   #   automatic {
# #   #     time_before_expiry = "P30D"
# #   #   }

# #   #   expire_after         = "P90D"
# #   #   notify_before_expiry = "P29D"
# #   # }
# # }

# # resource "local_file" "ssh_key" {
# #   # content  = tls_private_key.aap.private_key_pem
# #   content  = jsondecode(azapi_resource_action.ssh_public_key_gen.output).privateKey
# #   filename = "C:\\Users\\david\\.ssh\\aap-pk"
# # }

# resource "azurerm_public_ip" "aap" {
#   allocation_method   = "Static"
#   location            = azurerm_resource_group.aap.location
#   resource_group_name = azurerm_resource_group.aap.name
#   name                = lower("${module.naming.public_ip.name}")
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

# module "vnet" {
#   source              = "Azure/vnet/azurerm"
#   vnet_name           = lower("${module.naming.virtual_network.name}")
#   resource_group_name = azurerm_resource_group.aap.name
#   use_for_each        = true
#   address_space       = [var.addr_space]
#   subnet_prefixes     = ["${cidrsubnet(var.addr_space, 5, 0)}", "${cidrsubnet(var.addr_space, 5, 1)}"]
#   subnet_names        = ["${module.naming.subnet.name}", "adds"]
#   vnet_location       = azurerm_resource_group.aap.location
# }

# module "aap" {
#   source                     = "Azure/virtual-machine/azurerm"
#   name                       = "vm-aap-dyeo-poc-01"
#   computer_name              = "vmansdyeopoc01"
#   resource_group_name        = azurerm_resource_group.aap.name
#   location                   = azurerm_resource_group.aap.location
#   admin_username             = "azadmin"
#   admin_password             = "1QAZ2wsx3edc"
#   allow_extension_operations = true
#   vtpm_enabled               = false
#   encryption_at_host_enabled = false
#   secure_boot_enabled        = false

#   subnet_id = module.vnet.vnet_subnets[0]

#   admin_ssh_keys = [{
#     public_key = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
#     username   = "azadmin"
#   }]

#   image_os                        = "linux"
#   size                            = "Standard_B4ls_v2"
#   disable_password_authentication = false

#   # custom_data = base64encode(file("bootstrap.sh"))

#   source_image_reference = {
#     publisher = "Canonical"
#     offer     = "0001-com-ubuntu-server-mantic"
#     sku       = "23_10-gen2"
#     version   = "latest"
#   }

#   os_disk = {
#     caching              = "ReadWrite"
#     disk_size_gb         = 256
#     name                 = "dsk-aap-dyeo-poc-01-osDisk"
#     storage_account_type = "StandardSSD_LRS"
#   }

#   new_network_interface = {
#     name                           = "nic-aap-dyeo-poc-01"
#     accelerated_networking_enabled = false
#     ip_configurations = [{
#       name                          = "nic-aap-dyeo-poc-01-ipconfig"
#       primary                       = true
#       private_ip_address_allocation = "Dynamic"
#       # private_ip_address            = cidrhost(module.vnet.vnet_address_space[0], 4)
#       public_ip_address_id = azurerm_public_ip.aap.id
#     }]
#   }
# }

# resource "azurerm_dev_test_global_vm_shutdown_schedule" "compute" {
#   virtual_machine_id = module.aap.vm_id
#   location           = azurerm_resource_group.aap.location
#   enabled            = true

#   daily_recurrence_time = "1900"
#   timezone              = "GMT Standard Time"

#   notification_settings {
#     enabled         = false
#     time_in_minutes = "15"
#     webhook_url     = ""
#   }
# }

# # resource "azurerm_private_dns_zone" "pdns" {
# #   for_each            = toset(var.regions)
# #   name                = lower("${module.naming.dns_zone.name}.postgres.database.azure.com")
# #   resource_group_name = azurerm_resource_group.aap.name
# # }

# # resource "azurerm_private_dns_zone_virtual_network_link" "pdns" {
# #   for_each              = toset(var.regions)
# #   name                  = lower("${module.naming.dns_zone.name}-to-${module.vnet.vnet_name}")
# #   resource_group_name   = azurerm_resource_group.aap.name
# #   private_dns_zone_name = azurerm_private_dns_zone.pdns.name
# #   virtual_network_id    = module.vnet.vnet_id
# #   registration_enabled  = true
# # }

# # resource "azurerm_lb" "posit" {
# #   for_each            = toset(var.regions)
# #   name                = lower("${module.naming.lb.name}")
# #   resource_group_name = azurerm_resource_group.aap.name
# #   location            = azurerm_resource_group.aap.location

# #   frontend_ip_configuration {
# #     name                 = "PublicIPAddress"
# #     public_ip_address_id = azurerm_public_ip.aap.id
# #   }
# # }

# # resource "azurerm_lb_backend_address_pool" "compute" {
# #   for_each        = toset(var.regions)
# #   loadbalancer_id = azurerm_lb.posit.id
# #   name            = "compute"
# # }

# # resource "azurerm_lb_backend_address_pool" "postgresql" {
# #   for_each        = toset(var.regions)
# #   loadbalancer_id = azurerm_lb.posit.id
# #   name            = "postgresql"
# # }

# # resource "azurerm_lb_rule" "ssh" {
# #   for_each                       = toset(var.regions)
# #   loadbalancer_id                = azurerm_lb.posit.id
# #   name                           = "ssh"
# #   protocol                       = "Tcp"
# #   frontend_port                  = 22
# #   backend_port                   = 22
# #   frontend_ip_configuration_name = azurerm_lb.posit.frontend_ip_configuration.name
# #   backend_address_pool_ids       = [azurerm_lb_backend_address_pool.compute.id]
# # }

# # module "storage_account" {
# #   source                                   = "Azure/storage-account/azure"
# #   storage_account_name                     = lower(replace(module.naming.storage_account.name, "/-/", ""))
# #   storage_account_location                 = azurerm_resource_group.aap.location
# #   storage_account_account_replication_type = "LRS"
# #   storage_account_account_tier             = "Standard"
# #   storage_account_resource_group_name      = azurerm_resource_group.aap.name
# #   # storage_container = {
# #   #   blob_container = {
# #   #     name                  = lower("${module.naming.storage_blob.name}") #"blob-container-${random_pet.this.id}"
# #   #     container_access_type = "private"
# #   #   }
# #   # }
# #   # storage_account_network_rules = {
# #   #   bypass         = ["AzureServices"]
# #   #   default_action = "Allow"
# #   #   # virtual_network_subnet_ids = module.vnet.vnet_subnets[0]
# #   #   # ip_rules       = [local.public_ip]

# #   # }
# # }
