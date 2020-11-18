variable "deployment_name" {}
variable "project" {}
variable "region" {}
variable "zone" {}

variable "network" {}
variable "subnet" {}

variable "deployment_config_name" {}

variable "enable_monitoring" {
  type = bool
  default = true
}

variable "logstash" {
  type = object({
    host = string
    port = string
  })
  default = {
    host = ""
    port = ""
  }
}

variable "clusters" {
  type = list(object({
    name = string
    internal_ip = bool
    image_version = string
    properties = map(string)
    init_actions = set(string)
    master_config = object({
      ha = bool
      machine_type = string
      disk_config = object({
        boot_disk_type = string
        boot_disk_size_gb = number
        num_local_ssds = number
      })
    })
    worker_config = object({
      num_instances = number
      machine_type = string
      disk_config = object({
        boot_disk_type = string
        boot_disk_size_gb = number
        num_local_ssds = number
      })
    })
    num_preemptible_workers = number
    labels = map(string)
  }))
}

variable "product_labels" {
  type = map(string)
  default = {
    "product" = "mlisa"
  }
}
