prefix = "k8s"

folder = "k8s"

inventory_file = "inventory.ini"

network = "kubespray"

dns_primary = "10.0.20.72"
dns_secondary = "10.0.100.42"

machines = {
  "master-0" : {
    "node_type" : "master",
    "ip" : "10.0.51.150", # e.g. 192.168.0.10
    "netmask" : "24"
  },
  "worker-0" : {
    "node_type" : "worker",
    "ip" : "10.0.51.160", # e.g. 192.168.0.20
    "netmask" : "24"
  },
  "worker-1" : {
    "node_type" : "worker",
    "ip" : "10.0.51.161", # e.g. 192.168.0.21
    "netmask" : "24"
  }
}

gateway = "10.0.51.1" # e.g. 192.168.0.1

ssh_public_keys = [
  # Put your public SSH key here
  "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAHuZ+lFvjFYMKrcPyWLOw9G09W0Etze6+f6vM164abVlatm0CGiaV/Y1f1t2mmQQH6xKl2K5Vx0yHjSfdNBd2o4yQA6se59RrwAtLNUAeFhSj7ideQEGQ1fuHXi107q5/VJc/1XPJ6o1qVD1uvAWOATwECOqP2qOuVLUlSQ9EDwbUHFuw== rodney@k8spray.poling.local",
]

vsphere_datacenter      = "Home"
vsphere_compute_cluster = "cluster01" # e.g. Cluster
vsphere_datastore       = "vmw-nfs" # e.g. ssd-000000
vsphere_server          = "vcenter.poling.local" # e.g. vsphere.server.com

template_name = "templates/ubuntu/packer-ubuntu-20.04" # e.g. ubuntu-bionic-18.04-cloudimg

vsphere_user = "administrator@home.local"
vsphere_password = "Yobiesa01!"

#===============================================================================
# Global virtual machines parameters - haproxy
#===============================================================================

# Username used to SSH to the virtual machines #
vm_user = "rodney"
vm_password = "Yobiesa01"
vm_privilege_password = "Yobiesa01"

# The name of the vSphere virtual machine and template folder that will be created to store the virtual machines #
vm_folder = "k8s-kubespray"

# The domain name used by the virtual machines #
vm_domain = "poling.local"

# vSphere resource pool name that will be created to deploy the virtual machines #
vsphere_resource_pool = "k8s-kubespray"

#===============================================================================
# HAProxy load balancer virtual machine parameters
#===============================================================================

# The number of vCPU allocated to the load balancer virtual machine #
vm_haproxy_cpu = "1"

# The amount of RAM allocated to the load balancer virtual machine #
vm_haproxy_ram = "2048"

# The IP address of the load balancer floating VIP #
vm_haproxy_vip = "10.0.51.100"

# The IP address of the load balancer virtual machine #
vm_haproxy_ips = {
  "0" = "10.0.51.101"
  "1" = "10.0.51.102"
}

# The netmask used to configure the network cards of the virtual machines (example: 24)#
vm_netmask = "24"

