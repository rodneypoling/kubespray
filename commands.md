#*Commands needed to build K8s Cluster

##Terraform Infra Build

terraform -chdir=contrib/terraform/vsphere apply -var-file ~/kubespray/inventory/poling/default.tfvars

##Terraform Infra Destroy

terraform -chdir=contrib/terraform/vsphere destroy -var-file ~/kubespray/inventory/poling/default.tfvars

##Ansible - K8 Cluster Build

#Connect to the hosts

  ansible -i inventory/poling/hosts.yaml -m ping all

#SSH Key Copy

  ssh-copy-id rodney@10.0.51.150
  
  ssh-copy-id rodney@10.0.51.160
  
  ssh-copy-id rodney@10.0.51.161
  
#Install Cluster

  ansible-playbook -i inventory/poling/hosts.yaml --become --become-user=root cluster.yml

#Creds

  export KUBECONFIG=~/kubespray/inventory/poling/artifacts/admin.conf
