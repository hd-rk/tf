data "google_container_engine_versions" "default" {
  location = var.regional ? var.region : var.zone
}

locals {
  gke_stable_version = data.google_container_engine_versions.default.release_channel_default_version["STABLE"]
  gke_location = var.regional ? var.region : var.zone
  gke_node_pools = {for p in var.node_pools: p.name => p}
}

resource "random_string" "mlisa_gke_id" {
  length = 6
  upper = false
  special = false
}

resource "google_container_cluster" "mlisa" {
  lifecycle {
    ignore_changes = [
      node_version,
      min_master_version,
      name
    ]
  }

  name    = "${var.deployment_name}-gke-${random_string.mlisa_gke_id.result}"
  project = var.project

  network    = var.network
  subnetwork = var.subnet

  location = local.gke_location

  initial_node_count = 1
  remove_default_node_pool = true

  default_max_pods_per_node = var.max_pods_per_node

  node_version = local.gke_stable_version
  min_master_version = local.gke_stable_version

  resource_labels = {
    product = "mlisa"
    name = var.deployment_name
  }

  ip_allocation_policy {
    cluster_secondary_range_name = var.pod_secondary_range_name
    services_secondary_range_name = var.svc_secondary_range_name
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

  monitoring_service = var.enable_monitoring ? "none" : "monitoring.googleapis.com/kubernetes"
  logging_service = var.enable_monitoring ? "none" : "logging.googleapis.com/kubernetes"

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
  for_each = local.gke_node_pools
  lifecycle {
    ignore_changes = [
      version
    ]
  }

  name = each.key
  project = var.project
  cluster = google_container_cluster.mlisa.name
  version = local.gke_stable_version
  location = local.gke_location

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

  management {
    auto_repair = false
    auto_upgrade = false
  }

  upgrade_settings {
    max_surge = each.value.node_count
    max_unavailable = 0
  }
}

resource "google_runtimeconfig_variable" "mlisa_gke_cluster_name" {
  name = "GKE_CLUSTER_NAME"
  parent = var.deployment_config_name
  text = google_container_cluster.mlisa.name
}
