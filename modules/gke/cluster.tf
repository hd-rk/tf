resource "google_container_cluster" "mlisa" {
  lifecycle {
    ignore_changes = [
      node_version,
      min_master_version,
      name
    ]
  }

  name    = "${var.deployment_name}-gke"
  project = var.project

  network    = var.network
  subnetwork = var.subnet

  location = local.location

  initial_node_count = 0
  remove_default_node_pool = true

  default_max_pods_per_node = local.max_pods_per_node

  node_version = local.stable_version
  min_master_version = local.stable_version

  resource_labels = {
    product = "mlisa"
    name = var.deployment_name
  }

  ip_allocation_policy {
    cluster_secondary_range_name = local.pod_secondary_range_name
    services_secondary_range_name = local.svc_secondary_range_name
  }

  master_auth {
    username = ""
    password = ""
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = split(",", trimspace(var.master_auth_networks))

      content {
        display_name = split(":", cidr_blocks.value)[0]
        cidr_block = split(":", cidr_blocks.value)[1]
      }
    }
  }

  private_cluster_config {
    enable_private_nodes = var.private.enabled
    enable_private_endpoint = var.private.enabled && var.private.master_private_endpoint
    master_ipv4_cidr_block = var.private.master_range_cidr
  }

  monitoring_service = local.enable_monitoring ? "none" : "monitoring.googleapis.com/kubernetes"
  logging_service = local.enable_monitoring ? "none" : "logging.googleapis.com/kubernetes"

  addons_config {
    horizontal_pod_autoscaling {
      disabled = false
    }
    http_load_balancing {
      disabled = false
    }
    network_policy_config {
      disabled = true
    }
  }

  enable_shielded_nodes = true

  cluster_autoscaling {
    enabled = false
  }

  vertical_pod_autoscaling {
    enabled = false
  }

  database_encryption {
    state = "DECRYPTED"
  }

}

resource "google_container_node_pool" "mlisa" {
  for_each = local.node_pools
  lifecycle {
    ignore_changes = [
      version
    ]
  }

  name = each.key
  project = var.project
  cluster = google_container_cluster.mlisa.name
  version = local.stable_version
  location = local.location

  node_count = each.value.node_count

  node_config {
    disk_size_gb = 100
    disk_type = "pd-standard"
    image_type = "COS"
    labels = each.value.labels
    tags = each.value.tags
    local_ssd_count = 0
    machine_type = each.value.machine_type
    oauth_scopes = var.oauth_scopes
    service_account = "default"
    preemptible = false
    shielded_instance_config {
      enable_secure_boot = false
      enable_integrity_monitoring = true
    }
    workload_metadata_config {
      node_metadata = "EXPOSE"
    }
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  dynamic "management" {
    for_each = [var.node_management]
    content = {
      auto_repair = management.value["auto_repair"]
      auto_upgrade = management.value["auto_upgrade"]
    }
  }

  upgrade_settings {
    max_surge = each.value.node_count
    max_unavailable = 0
  }
}
