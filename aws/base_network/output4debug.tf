output "debug" {
  value = [
    local.config_dir,
    local.env_dir,
    local.tags_cfg,
    local.networking,
    local.tags_common,
    local.vpcs_nvirginia,
    local.vpcs_london,
    local.az_letter_to_ix
  ]
}
