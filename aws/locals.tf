/**
* Load and shape the network config from JSON.
* We then pass that data into region-scoped modules using provider aliases.
*/
locals {
  network_raw = jsondecode(file(var.network_config_path))

  common_tags = {
    Project   = var.project
    Env       = var.env
    Owner     = var.owner
    ManagedBy = "terraform"
  }

  region_nvirginia_vpcs = try(local.network_raw.region_nvirginia.vpc, {})
  region_london_vpcs    = try(local.network_raw.region_london.vpc, {})
}