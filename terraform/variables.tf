variable "enable_telemetry" {
  default = false
}

variable "rules" {
  type = map(object(
    {
      # nsg_rule_name                       = string # (Required) Name of NSG rule.
      nsg_rule_priority                   = number # (Required) NSG rule priority.
      nsg_rule_direction                  = string # (Required) NSG rule direction. Possible values are `Inbound` and `Outbound`.
      nsg_rule_access                     = string # (Required) NSG rule access. Possible values are `Allow` and `Deny`.
      nsg_rule_protocol                   = string # (Required) NSG rule protocol. Possible values are `Tcp`, `Udp`, `Icmp`, `Esp`, `Asterisk`.
      nsg_rule_source_port_range          = string # (Required) NSG rule source port range.
      nsg_rule_destination_port_range     = string # (Required) NSG rule destination port range.
      nsg_rule_source_address_prefix      = string # (Required) NSG rule source address prefix.
      nsg_rule_destination_address_prefix = string # (Required) NSG rule destination address prefix.
    }
  ))
  default = {
    "AllowAnySSHInbound" = {
      nsg_rule_access                     = "Allow"
      nsg_rule_destination_address_prefix = "*"
      nsg_rule_destination_port_range     = "22"
      nsg_rule_direction                  = "Inbound"
      nsg_rule_priority                   = 100
      nsg_rule_protocol                   = "Tcp"
      nsg_rule_source_address_prefix      = "*"
      nsg_rule_source_port_range          = "*"

    }
    # "rule02" = {
    #   nsg_rule_access                     = "Allow"
    #   nsg_rule_destination_address_prefix = "*"
    #   nsg_rule_destination_port_range     = "*"
    #   nsg_rule_direction                  = "Outbound"
    #   nsg_rule_priority                   = 200
    #   nsg_rule_protocol                   = "Tcp"
    #   nsg_rule_source_address_prefix      = "*"
    #   nsg_rule_source_port_range          = "*"
    # }
  }
}
