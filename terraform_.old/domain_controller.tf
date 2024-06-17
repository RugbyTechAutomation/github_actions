module "dc01" {
  source = "Azure/avm-res-compute-virtualmachine/azurerm"
  # for_each                           = toset(local.regions)
  admin_username                     = "localmgr"
  admin_password                     = "1QAZ2wsx3edc"
  enable_telemetry                   = var.enable_telemetry
  generate_admin_password_or_ssh_key = false
  location                           = azurerm_resource_group.rg.location # each.key
  name                               = "vmansadvuks01"                    #replace("${module.naming[each.key].virtual_machine.name}-01", "/-/", "")
  resource_group_name                = azurerm_resource_group.rg.name
  virtualmachine_os_type             = "Windows"
  virtualmachine_sku_size            = "Standard_B2as_v2" #module.get_valid_sku_for_deployment_region.sku #
  zone                               = null

  # admin_ssh_keys = [
  #   {
  #     public_key = jsondecode(jsonencode(azapi_resource_action.ssh_public_key_gen.output)).publicKey
  #     username   = "localmgr" #the username must match the admin_username currently.
  #   }
  # ]

  managed_identities = {
    system_assigned = true
    # user_assigned_resource_ids = [module.avm-res-managedidentity-userassignedidentity[each.key].resource_id]
  }

  network_interfaces = {
    network_interface_1 = {
      name                           = "nic-vmansadvuks01"
      accelerated_networking_enabled = true
      ip_configurations = {
        ip_configuration_1 = {
          name                          = "nic-vmansadvuks01-ipconfig"
          private_ip_subnet_resource_id = azurerm_subnet.SN-Workload.id #"/subscriptions/19067dda-d761-44a6-b79d-29a8e342f633/resourceGroups/rg-ans-adv-uks-01/providers/Microsoft.Network/virtualNetworks/vnet-ans-adv-adds-01/subnets/snet-ans-adv-adds-01"
          private_ip_address_allocation = "Dynamic"                     # "Static"
          # private_ip_address            = cidrhost("${local.vnet_map[each.key]}", 4)
        }
      }
    }
  }

  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    name                 = "dsk-vmansadvuks01-osDisk"
  }

  data_disk_managed_disks = {
    for i in range(2) : format("dsk-%02d", i + 1) => {
      name                 = format("dsk-vmansadvuks01-dataDisk-%02d", i + 1)
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
    # publisher = "MicrosoftWindowsServer"
    # offer     = "WindowsServer"
    # sku       = "2022-datacenter-smalldisk-g2"
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-11"
    sku       = "win11-23h2-ent"
    version   = "latest"
  }
}

# resource "azurerm_network_interface_security_group_association" "windows" {
#   for_each                  = toset(local.regions)
#   network_interface_id      = module.avm-res-compute-virtualmachine[each.key].network_interfaces["network_interface_1"].id
#   network_security_group_id = module.avm-res-network-networksecuritygroup[each.key].nsg_resource.id
# }

# resource "azurerm_network_interface_backend_address_pool_association" "example" {
#   for_each                = toset(local.regions)
#   network_interface_id    = module.avm-res-compute-virtualmachine[each.key].network_interfaces["network_interface_1"].id
#   ip_configuration_name   = "internal"
#   backend_address_pool_id = "/subscriptions/19067dda-d761-44a6-b79d-29a8e342f633/resourceGroups/rg-sql-adv-uks-01/providers/Microsoft.Network/loadBalancers/lb-sql-adv-uks-01/backendAddressPools/windows-rdp"
# }
