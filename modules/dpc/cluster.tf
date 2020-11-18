locals {
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
  name = "${var.deployment_name}-dpc-${random_string.mlisa_dpc_id.result}-${var.name}"
  project = var.project
  region = var.region
  labels = merge(var.product_labels, var.labels)

  cluster_config {
    gce_cluster_config {
      zone = var.zone
      subnetwork = var.subnet
      internal_ip_only = var.internal_ip
      metadata = local.metadata
    }

    software_config {
      image_version = var.image_version
      override_properties = var.properties
    }

    master_config {
      num_instances = var.master_config.ha ? 2 : 1
      machine_type = var.master_config.machine_type
      dynamic "disk_config" {
        for_each = [var.master_config.disk_config]
        content {
          boot_disk_type = disk_config.value.boot_disk_type
          boot_disk_size_gb = disk_config.value.boot_disk_size_gb
          num_local_ssds = disk_config.value.num_local_ssds
        }
      }
    }

    worker_config {
      num_instances = var.worker_config.num_instances
      machine_type = var.worker_config.machine_type
      dynamic "disk_config" {
        for_each = [var.worker_config.disk_config]
        content {
          boot_disk_type = disk_config.value.boot_disk_type
          boot_disk_size_gb = disk_config.value.boot_disk_size_gb
          num_local_ssds = disk_config.value.num_local_ssds
        }
      }
    }

    preemptible_worker_config {
      num_instances = var.num_preemptible_workers
      dynamic "disk_config" {
        for_each = [var.worker_config.disk_config]
        content {
          boot_disk_type = disk_config.value.boot_disk_type
          boot_disk_size_gb = disk_config.value.boot_disk_size_gb
          num_local_ssds = disk_config.value.num_local_ssds
        }
      }
    }

    dynamic "initialization_action" {
      for_each = var.init_actions
      content {
        script = initialization_action.value
      }
    }
  }
}

resource "google_runtimeconfig_variable" "mlisa_dpc_cluster_name" {
  name = "DPC_CLUSTER_NAME_${upper(var.name)}"
  parent = var.deployment_config_name
  text = google_dataproc_cluster.mlisa.name
}

resource "google_runtimeconfig_variable" "mlisa_dpc_master_hostname" {
  name = "DPC_MASTER_HOST_${upper(var.name)}"
  parent = var.deployment_config_name
  text = google_dataproc_cluster.mlisa.cluster_config[0].master_config[0].instance_names[0]
}
