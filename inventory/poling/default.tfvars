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

gateway = "i-did-not-read-the-docs" # e.g. 192.168.0.1

ssh_public_keys = [
  # Put your public SSH key here
  "ssh-rsa I-did-not-read-the-docs",
]

vsphere_datacenter      = "Home"
vsphere_compute_cluster = "cluster01" # e.g. Cluster
vsphere_datastore       = "vmw-nfs" # e.g. ssd-000000
vsphere_server          = "vcenter.home.local" # e.g. vsphere.server.com

template_name = "i-did-not-read-the-docs" # e.g. ubuntu-bionic-18.04-cloudimg

vsphere_user = "administrator@home.local"
vsphere_password = "Yobiesa01!"