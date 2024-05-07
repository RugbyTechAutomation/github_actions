locals {
  // Define array of region names and map for region codes
  regions = ["UK South"] #, "UK West"]

  region_map = {
    "UK South" = "uks",
    "UK West"  = "ukw"
  }

  // Define the environment map based on workspace name
  workspace_map = {
    "UKPP"  = "pp",
    "UKDV"  = "dv",
    "UKDR"  = "dr",
    "UKPR"  = "pr",
    "UKADV" = "adv"
  }

  // Define vNet address prefixes
  vnets_map = {
    "UK South" = "10.128.2.0/24",
    "UK West"  = "10.131.2.0/24"
  }

  // Get the environment code from the workspace name 
  env = lookup(local.workspace_map, terraform.workspace, "DefaultValue")
}









