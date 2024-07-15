module "keyvault" {
  source                          = "Azure/avm-res-keyvault-vault/azurerm"
  name                            = "kv-ans-adv-uks-02" # module.naming.key_vault.name
  enable_telemetry                = false
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  tenant_id                       = data.azurerm_subscription.current.tenant_id
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  sku_name                        = "standard"
  enabled_for_disk_encryption     = true
  purge_protection_enabled        = false

  network_acls = {
    bypass         = "AzureServices"
    default_action = "Allow"
  }

  # role_assignments = {
  #   deployment_user_kv_admin = {
  #     role_definition_id_or_name = "Key Vault Administrator"
  #     principal_id               = data.azurerm_client_config.current.client_id
  #   }
  # }

  secrets = {
    ansible-ssh-private-key = {
      name = "ansible-ssh-private-key"
    },
    ansible-ssh-public-key = {
      name = "ansible-ssh-public-key"
    }
  }
  secrets_value = {
    ansible-ssh-private-key = jsondecode(jsonencode(azapi_resource_action.ssh_public_key_gen.output)).privateKey,
    ansible-ssh-public-key  = jsondecode(jsonencode(azapi_resource_action.ssh_public_key_gen.output)).publicKey
  }

  depends_on = [resource.azapi_resource_action.ssh_public_key_gen]

  tags = local.common.tags

}
