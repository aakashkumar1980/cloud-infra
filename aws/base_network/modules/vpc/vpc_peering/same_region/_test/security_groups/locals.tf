locals {
  # Load firewall configurations
  common_firewall = yamldecode(file(var.common_firewall_path))
  custom_firewall = yamldecode(file("${path.module}/firewall.yaml"))
}