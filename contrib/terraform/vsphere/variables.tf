## Global ##

# Required variables

variable "machines" {
  description = "Cluster machines"
  type = map(object({
    node_type = string
    ip        = string
    netmask   = string
  }))
}

variable "network" {}

variable "gateway" {}

variable "vsphere_datacenter" {}

variable "vsphere_compute_cluster" {}

variable "vsphere_datastore" {}

variable "vsphere_user" {}

variable "vsphere_password" {
  sensitive = true
}

variable "vsphere_server" {}

variable "ssh_public_keys" {
  description = "List of public SSH keys which are injected into the VMs."
  type        = list(string)
}

variable "template_name" {}

# Optional variables (ones where reasonable defaults exist)
variable "vapp" {
  default = false
}

variable "interface_name" {
  default = "ens192"
}

variable "folder" {
  default = ""
}

variable "prefix" {
  default = "k8s"
}

variable "inventory_file" {
  default = "inventory.ini"
}

variable "dns_primary" {
  default = "8.8.4.4"
}

variable "dns_secondary" {
  default = "8.8.8.8"
}

variable "firmware" {
  default = "bios"
}

variable "hardware_version" {
  default = "15"
}

## Master ##

variable "master_cores" {
  default = 4
}

variable "master_memory" {
  default = 4096
}

variable "master_disk_size" {
  default = "40"
}

## Worker ##

variable "worker_cores" {
  default = 16
}

variable "worker_memory" {
  default = 8192
}
variable "worker_disk_size" {
  default = "80"
}
##############################
#### Vars added by rodney ####
##############################
variable "vsphere_resource_pool" {
  description = "vSphere resource pool"
}

variable "vm_haproxy_vip" {
  description = "IP used for the HAProxy floating VIP"
}

variable "vm_haproxy_ips" {
  type        = map(string)
  description = "IP used for two HAProxy virtual machine"
}

variable "vm_haproxy_cpu" {
  description = "Number of vCPU for the HAProxy virtual machine"
}

variable "vm_haproxy_ram" {
  description = "Amount of RAM for the HAProxy virtual machine (example: 1024)"
}

variable "vm_user" {
  description = "vm user name"
}

variable "vm_password" {
  description = "password"
}

variable "vm_privilege_password" {
  description = "priv passwoord"
}

variable "vm_domain" {
  description = "domain"
}

variable "vm_netmask" {
  description = "netmask"
}

variable "action" {
  description = "Which action have to be done on the cluster (create, add_worker, remove_worker, or upgrade)"
  default     = "create"
}

variable "vm_distro" {
  description = "Linux distribution of the vSphere virtual machines (ubuntu/centos/debian/rhel)"
  default     = "ubuntu"
}