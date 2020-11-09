locals {
  dev_preset = {
    enable_monitoring = false
    regional = false
    max_pods_per_node = 110
    pod_secondary_range_name = ""
    svc_secondary_range_name = ""
    node_pools = [
      {
        name = "mlisa-pool"
        node_count = 1
        machine_type = "n1-standard-16"
        labels = {
          application = "mlisa"
        }
        tags = []
      }
    ]
  }

  staging_preset = {
    enable_monitoring = true
    regional = false
    max_pods_per_node = 32
    pod_secondary_range_name = "${var.subnet}-gke-pod"
    svc_secondary_range_name = "${var.subnet}-gke-svc"
    node_pools = [
      {
        name = "druid-pool"
        node_count = 1
        machine_type = "n1-standard-16"
        labels = {
          application = "druid"
        }
        tags = []
      },
      {
        name = "kafka-pool"
        node_count = 1
        machine_type = "n1-standard-16"
        labels = {
          application = "kafka"
        }
        tags = []
      },
      {
        name = "etl-pool"
        node_count = 1
        machine_type = "n1-standard-16"
        labels = {
          application = "etl"
        }
        tags = []
      },
      {
        name = "core-pool"
        node_count = 1
        machine_type = "n1-standard-16"
        labels = {
          application = "core"
        }
        tags = []
      }
    ]
  }

  preset_map = {
    development = local.dev_preset
    staging = local.staging_preset
  }
}
