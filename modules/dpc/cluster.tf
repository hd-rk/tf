locals {
  clusters = {for c in var.clusters: c.name => c}
  dns_metadata = {"VmDnsSetting" = "ZonalPreferred"}
  logstash_metadata = var.enable_monitoring ? {
    "mspLogstashHosts" =  var.logstash.host
    "mspLogstashPort" = var.logstash.port
    "mlisaLogFields" = "\"mlisa_deployment_name\" \"${var.deployment_name}\""
    "mlisaDeploymentName" = var.deployment_name
  } : {}
  metadata = merge(local.dns_metadata, local.logstash_metadata)
}

resource "random_string" "mlisa_dpc_id" {
  length = 6
  upper = false
  special = false
}

resource "google_dataproc_cluster" "mlisa" {
  for_each = local.clusters

  name = "${var.deployment_name}-dpc-${random_string.mlisa_dpc_id.result}-${each.key}"
  project = var.project
  region = var.region
  labels = merge(var.product_labels, each.value.labels)

  cluster_config {
    gce_cluster_config {
      zone = var.zone
      subnetwork = var.subnet
      internal_ip_only = each.value.internal_ip
      metadata = local.metadata
    }

    software_config {
      image_version = each.value.image_version
      override_properties = each.value.properties
    }

    master_config {
      num_instances = each.value.master_config.ha ? 2 : 1
      machine_type = each.value.master_config.machine_type
      dynamic "disk_config" {
        for_each = [each.value.master_config.disk_config]
        content {
          boot_disk_type = disk_config.value.boot_disk_type
          boot_disk_size_gb = disk_config.value.boot_disk_size_gb
          num_local_ssds = disk_config.value.num_local_ssds
        }
      }
    }

    worker_config {
      num_instances = each.value.worker_config.num_instances
      machine_type = each.value.worker_config.machine_type
      dynamic "disk_config" {
        for_each = [each.value.worker_config.disk_config]
        content {
          boot_disk_type = disk_config.value.boot_disk_type
          boot_disk_size_gb = disk_config.value.boot_disk_size_gb
          num_local_ssds = disk_config.value.num_local_ssds
        }
      }
    }

    preemptible_worker_config {
      num_instances = each.value.num_preemptible_workers
      dynamic "disk_config" {
        for_each = [each.value.worker_config.disk_config]
        content {
          boot_disk_type = disk_config.value.boot_disk_type
          boot_disk_size_gb = disk_config.value.boot_disk_size_gb
          num_local_ssds = disk_config.value.num_local_ssds
        }
      }
    }

    dynamic "initialization_action" {
      for_each = each.value.init_actions
      content {
        script = initialization_action.value
      }
    }
  }
}

resource "google_runtimeconfig_variable" "mlisa_dpc_cluster_name" {
  for_each = local.clusters

  name = "DPC_CLUSTER_NAME_${upper(each.key)}"
  parent = var.deployment_config_name
  text = google_dataproc_cluster.mlisa[each.key].name
}

resource "google_runtimeconfig_variable" "mlisa_dpc_master_hostname" {
  for_each = local.clusters

  name = "DPC_MASTER_HOST_${upper(each.key)}"
  parent = var.deployment_config_name
  text = google_dataproc_cluster.mlisa[each.key].cluster_config[0].master_config[0].instance_names[0]
}
