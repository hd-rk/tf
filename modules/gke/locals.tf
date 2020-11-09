locals {
  regional = var.regional != null ? var.regional : local.preset_map[var.preset]["regional"]
  max_pods_per_node = var.max_pods_per_node != null ? var.max_pods_per_node : local.preset_map[var.preset]["max_pods_per_node"]
  pod_secondary_range_name = var.pod_secondary_range_name != null ? var.pod_secondary_range_name : local.preset_map[var.preset]["pod_secondary_range_name"]
  svc_secondary_range_name = var.svc_secondary_range_name != null ? var.svc_secondary_range_name : local.preset_map[var.preset]["svc_secondary_range_name"]
  node_pools = var.node_pools != null ? var.node_pools : local.preset_map[var.preset]["node_pools"]
  enable_monitoring = var.enable_monitoring != null ? var.enable_monitoring : local.preset_map[var.preset]["enable_monitoring"]

  location = local.regional ? var.region : var.zone
  stable_version = data.google_container_engine_versions.default.release_channel_default_version["STABLE"]
  node_pools = {for p in local.node_pools: p.name => p}
}
