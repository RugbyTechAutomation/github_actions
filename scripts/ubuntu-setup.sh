#!/bin/bash
sudo ufw enable
sudo ufw allow ssh
sudo apt update && sudo apt install pipx -y
pipx install --include-deps ansible pywinrm azure-mgmt-resource azure-cli
# pipx install --include-deps pywinrm
pipx ensurepath



sudo mkdir -p /etc/ansible
sudo mkdir -p /etc/ansible/inventories/production
sudo mkdir -p /etc/ansible/inventories/production/hosts
sudo mkdir -p /etc/ansible/inventories/production/group_vars
sudo mkdir -p /etc/ansible/inventories/production/host_vars
sudo mkdir -p /etc/ansible/inventories/staging/hosts
sudo mkdir -p /etc/ansible/inventories/staging/group_vars
sudo mkdir -p /etc/ansible/inventories/staging/host_vars
sudo mkdir -p /etc/ansible/group_vars
sudo mkdir -p /etc/ansible/host_vars
sudo mkdir -p /etc/ansible/library
sudo mkdir -p /etc/ansible/module_utils
sudo mkdir -p /etc/ansible/filter_plugins
sudo mkdir -p /etc/ansible/roles/common
sudo mkdir -p /etc/ansible/roles/webtier
sudo mkdir -p /etc/ansible/roles/monitoring
sudo mkdir -p /etc/ansible/roles/common

# sudo cat << EOF > /etc/ansible/ansible.cfg
# [defaults]
# host_key_checking = False
# EOF


# # Increase size of logical volume rootvg/homelv.
# sudo lvextend -L+10GB /dev/mapper/rootvg-homelv
# sudo xfs_growfs /dev/rootvg/homelv

# # Install Ansible az collection for interacting with Azure.

sudo apt install python3-pip -y
ansible-galaxy collection install azure.azcollection microsoft.ad community.azure
wget https://raw.githubusercontent.com/ansible-collections/azure/dev/requirements.txt
sed -i 's/==.*//' requirements.txt
pip3 install -r requirements.txt
pip3 install -r requirements.txt --upgrade

# pipx install --include-deps azure-mgmt-resource azure-cli #-core

# # pip3 install ansible[azure] --force

sudo apt-get install python3-oauthlib --upgrade