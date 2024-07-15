module "control" {
  source                             = "Azure/avm-res-compute-virtualmachine/azurerm"
  admin_username                     = "localmgr"
  admin_password                     = "Lloyds0fLondon"
  enable_telemetry                   = var.enable_telemetry
  generate_admin_password_or_ssh_key = false
  disable_password_authentication    = false
  location                           = azurerm_resource_group.rg.location
  name                               = "control"

  resource_group_name     = azurerm_resource_group.rg.name
  virtualmachine_os_type  = "Linux"
  virtualmachine_sku_size = "Standard_B2as_v2"
  zone                    = null

  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = [azurerm_user_assigned_identity.uai.id]
  }

  network_interfaces = {
    network_interface_1 = {
      name = "nic-control"

      accelerated_networking_enabled = true
      ip_configurations = {
        ip_configuration_1 = {
          name = "nic-control-ipconfig"

          private_ip_subnet_resource_id = azurerm_subnet.ansible_subnet.id
          private_ip_address_allocation = "Static"
          private_ip_address            = cidrhost(azurerm_subnet.ansible_subnet.address_prefixes[0], 4)
        }
      }
    }
  }

  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    name                 = "dsk-control-osDisk"

  }

  data_disk_managed_disks = {
    for i in range(0) : format("disk-%02d", i + 1) => {
      name = format("dsk-control-dataDisk-%02d", i + 1)

      storage_account_type = "StandardSSD_LRS"
      create_option        = "Empty"
      disk_size_gb         = 64
      # on_demand_bursting_enabled = var.TF_STORAGE_ACCOUNT_TYPE == "Premium_LRS" ? true : false
      # performance_plus_enabled = true
      lun     = i
      caching = "ReadWrite"
    }
  }

  shutdown_schedules = {
    standard_schedule = {
      daily_recurrence_time = "1900"
      timezone              = "GMT Standard Time"
      enabled               = true
      notification_settings = {
        enabled = false
      }
    }
  }

  allow_extension_operations = true

  extensions = {
  }

  source_image_reference = {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts" #"0001-com-ubuntu-server-mantic"
    sku       = "server"           #"23_10-gen2"
    version   = "latest"
  }

  tags = local.common.tags

}
