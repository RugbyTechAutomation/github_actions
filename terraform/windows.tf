module "windows" {
  # source                             = "Azure/avm-res-compute-virtualmachine/azurerm"
  source                             = "./.terraform/modules/avm-res-compute-virtualmachine"
  for_each                           = toset(local.regions)
  admin_username                     = "localmgr"
  admin_password                     = "1QAZ2wsx3edc"
  enable_telemetry                   = var.enable_telemetry
  generate_admin_password_or_ssh_key = false
  location                           = each.key
  name                               = "dc01"
  resource_group_name                = azurerm_resource_group.rg[each.key].name
  virtualmachine_os_type             = "Windows"
  virtualmachine_sku_size            = "Standard_B2as_v2" #module.get_valid_sku_for_deployment_region.sku
  zone                               = null

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
      name                           = "nic-dc01"
      accelerated_networking_enabled = true
      ip_configurations = {
        ip_configuration_1 = {
          name                          = "nic-dc01-ipconfig"
          private_ip_subnet_resource_id = module.avm-res-network-virtualnetwork[each.key].subnets["${module.naming[each.key].subnet.name}"].id
          private_ip_address_allocation = "Static"
          private_ip_address            = cidrhost("${local.vnet_map[each.key]}", 6)
        }
      }
    }
  }

  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    name                 = "dc01-osDisk"
  }

  data_disk_managed_disks = {
    for i in range(0) : format("disk-%02d", i + 1) => {
      name                 = format("dc01-dataDisk-%02d", i + 1)
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
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    # sku       = "2022-datacenter-smalldisk-g2"
    sku     = "2019-datacenter-smalldisk-g2"
    version = "latest"
  }

  depends_on = [
    module.avm-res-keyvault-vault
  ]
}

resource "azurerm_network_interface_security_group_association" "windows" {
  for_each                  = toset(local.regions)
  network_interface_id      = module.windows[each.key].network_interfaces["network_interface_1"].id
  network_security_group_id = module.avm-res-network-networksecuritygroup[each.key].nsg_resource.id
}
