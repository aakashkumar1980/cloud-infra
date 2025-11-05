/**
* Load and shape the network config from JSON.
* We then pass that data into region-scoped modules using provider aliases.
*/
locals {
  // common tags for all resources
  tags = {
    project   = var.project
    env       = var.env
    owner     = var.owner
    managed_by = "terraform"
  }

  // load raw network config from JSON file
  network_raw = jsondecode(file(var.network_config_path))
  // extract region-specific data
  region_nvirginia = try(local.network_raw.region_nvirginia.region, {})
  region_nvirginia_vpcs = try(local.network_raw.region_nvirginia.vpc, {})
  region_london      = try(local.network_raw.region_london.region, {})
  region_london_vpcs    = try(local.network_raw.region_london.vpc, {})
}