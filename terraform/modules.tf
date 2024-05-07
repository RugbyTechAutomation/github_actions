module "naming" {
  for_each = toset(local.regions)
  source   = "Azure/naming/azurerm"
  suffix   = ["ans-${local.env}-${local.region_map[each.key]}-01"]
}

# module "regions" {
#   source          = "Azure/regions/azurerm"
#   use_cached_data = false
# }


