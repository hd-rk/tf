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


variable "name" {}

variable "internal_ip" {
  type = bool
  default = true
}

variable "image_version" {}

variable "properties" {
  type = map(string)
  default = {}
}


variable "init_actions" {
  type = set(string)
  default = []
}


variable "master_config" {
  type = object({
    ha = bool
    machine_type = string
    disk_config = object({
      boot_disk_type = string
      boot_disk_size_gb = number
      num_local_ssds = number
    })
  })
}

variable "worker_config" {
  type = object({
    num_instances = number
    machine_type = string
    disk_config = object({
      boot_disk_type = string
      boot_disk_size_gb = number
      num_local_ssds = number
    })
  })
}

variable "num_preemptible_workers" {
  type = number
  default = 0
}

variable "labels" {
  type = map(string)
  default = {}
}

variable "product_labels" {
  type = map(string)
  default = {
    "product" = "mlisa"
  }
}
