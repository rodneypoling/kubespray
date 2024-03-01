provider "vsphere" {
  # Username and password set through env vars VSPHERE_USER and VSPHERE_PASSWORD
  user     = var.vsphere_user
  password = var.vsphere_password

  vsphere_server = var.vsphere_server

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.template_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "compute_cluster" {
  name          = var.vsphere_compute_cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_resource_pool" "pool" {
  name                    = "${var.prefix}-cluster-pool"
  parent_resource_pool_id = data.vsphere_compute_cluster.compute_cluster.resource_pool_id
}

module "kubernetes" {
  source = "./modules/kubernetes-cluster"

  prefix = var.prefix

  machines = var.machines

  ## Master ##
  master_cores     = var.master_cores
  master_memory    = var.master_memory
  master_disk_size = var.master_disk_size

  ## Worker ##
  worker_cores     = var.worker_cores
  worker_memory    = var.worker_memory
  worker_disk_size = var.worker_disk_size

  ## Global ##

  gateway       = var.gateway
  dns_primary   = var.dns_primary
  dns_secondary = var.dns_secondary

  pool_id      = vsphere_resource_pool.pool.id
  datastore_id = data.vsphere_datastore.datastore.id

  folder                = var.folder
  guest_id              = data.vsphere_virtual_machine.template.guest_id
  scsi_type             = data.vsphere_virtual_machine.template.scsi_type
  network_id            = data.vsphere_network.network.id
  adapter_type          = data.vsphere_virtual_machine.template.network_interface_types[0]
  interface_name        = var.interface_name
  firmware              = var.firmware
  hardware_version      = var.hardware_version
  disk_thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned

  template_id = data.vsphere_virtual_machine.template.id
  vapp        = var.vapp

  ssh_public_keys = var.ssh_public_keys
}

#
# Generate ansible inventory
#

resource "local_file" "inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    connection_strings_master = join("\n", formatlist("%s ansible_user=ubuntu ansible_host=%s etcd_member_name=etcd%d",
      keys(module.kubernetes.master_ip),
      values(module.kubernetes.master_ip),
    range(1, length(module.kubernetes.master_ip) + 1))),
    connection_strings_worker = join("\n", formatlist("%s ansible_user=ubuntu ansible_host=%s",
      keys(module.kubernetes.worker_ip),
    values(module.kubernetes.worker_ip))),
    list_master = join("\n", formatlist("%s", keys(module.kubernetes.master_ip))),
    list_worker = join("\n", formatlist("%s", keys(module.kubernetes.worker_ip)))
  })
  filename = var.inventory_file
}
#####################
### HA Proxy Adds ###
#####################

# HAProxy hostname and ip list template #
data "template_file" "haproxy_hosts" {
  count    = "${length(var.vm_haproxy_ips)}"
  template = "${file("~/kubespray/inventory/poling/templates/ansible_hosts.tpl")}"

  vars = {
    hostname = "${var.prefix}-haproxy-${count.index}"
    host_ip  = "${lookup(var.vm_haproxy_ips, count.index)}"
  }
}

# HAProxy hostname list template #
data "template_file" "haproxy_hosts_list" {
  count    = "${length(var.vm_haproxy_ips)}"
  template = "${file("~/kubespray/inventory/poling/templates/ansible_hosts_list.tpl")}"

  vars = {
    hostname = "${var.prefix}-haproxy-${count.index}"
  }
}

# HAProxy template #
data "template_file" "haproxy" {
  template = "${file("~/kubespray/inventory/poling/templates/haproxy.tpl")}"

  vars = {
    bind_ip = "${var.vm_haproxy_vip}"
  }
}

# HAProxy server backend template #
data "template_file" "haproxy_backend" {
  count    = "${length(module.kubernetes.master_ip)}"
  template = "${file("~/kubespray/inventory/poling/templates/haproxy_backend.tpl")}"

  vars = {
    prefix_server     = "${var.prefix}"
    backend_server_ip = "${lookup(module.kubernetes.master_ip, count.index)}"
    count             = "${count.index}"
  }
}

# Keepalived master template #
data "template_file" "keepalived_master" {
  template = "${file("~/kubespray/inventory/poling/templates/keepalived_master.tpl")}"

  vars = {
    virtual_ip = "${var.vm_haproxy_vip}"
  }
}

# Keepalived slave template #
data "template_file" "keepalived_slave" {
  template = "${file("~/kubespray/inventory/poling/templates/keepalived_slave.tpl")}"

  vars = {
    virtual_ip = "${var.vm_haproxy_vip}"
  }
}

# Create HAProxy configuration from Terraform templates #
resource "local_file" "haproxy" {
  content  = "${data.template_file.haproxy.rendered}${join("", data.template_file.haproxy_backend.*.rendered)}"
  filename = "config/haproxy.cfg"
}

# Create Keepalived master configuration from Terraform templates #
resource "local_file" "keepalived_master" {
  content  = "${data.template_file.keepalived_master.rendered}"
  filename = "config/keepalived-master.cfg"
}

# Create Keepalived slave configuration from Terraform templates #
resource "local_file" "keepalived_slave" {
  content  = "${data.template_file.keepalived_slave.rendered}"
  filename = "config/keepalived-slave.cfg"
}

# Execute HAProxy Ansible playbook #
resource "null_resource" "haproxy_install" {
  count = "${var.action == "create" ? 1 : 0}"

  provisioner "local-exec" {
    command = "cd ansible/haproxy && ansible-playbook -i ../../config/hosts.ini -b -u ${var.vm_user} -e \"ansible_ssh_pass=$VM_PASSWORD ansible_become_pass=$VM_PRIVILEGE_PASSWORD\" ${lookup(local.extra_args, var.vm_distro)} -v haproxy.yml"

    environment = {
      VM_PASSWORD           = "${var.vm_password}"
      VM_PRIVILEGE_PASSWORD = "${var.vm_privilege_password}"
    }
  }

  depends_on = [local_file.kubespray_hosts, local_file.haproxy, null_resource.rhel_register, null_resource.rhel_firewalld, vsphere_virtual_machine.haproxy]
}

# Create a virtual machine folder for the Kubernetes VMs #
resource "vsphere_folder" "folder" {
  path          = "${var.folder}"
  type          = "vm"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

# Create the HAProxy load balancer VM #
resource "vsphere_virtual_machine" "haproxy" {
  count            = "${length(var.vm_haproxy_ips)}"
  name             = "${var.prefix}-haproxy-${count.index}"
  resource_pool_id = "${vsphere_resource_pool.resource_pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"
  folder           = "${vsphere_folder.folder.path}"

  num_cpus = "${var.vm_haproxy_cpu}"
  memory   = "${var.vm_haproxy_ram}"
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"

  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  disk {
    label            = "${var.prefix}-haproxy-${count.index}.vmdk"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"
    #linked_clone  = "${var.vm_linked_clone}" - Dont think I need this one.

    customize {
      timeout = "20"

      linux_options {
        host_name = "${var.prefix}-haproxy-${count.index}"
        domain    = "${var.vm_domain}"
      }

      network_interface {
        ipv4_address = "${lookup(var.vm_haproxy_ips, count.index)}"
        ipv4_netmask = "${var.vm_netmask}"
      }

      ipv4_gateway    = "${var.gateway}"
      dns_server_list = ["${var.dns_primary}"]
    }
  }
}

#===============================================================================
# Locals
#===============================================================================

# Extra args for ansible playbooks #
locals {
  extra_args = {
    ubuntu = "-T 300"
    debian = "-T 300 -e 'ansible_become_method=su'"
    centos = "-T 300"
    rhel   = "-T 300"
  }
}
