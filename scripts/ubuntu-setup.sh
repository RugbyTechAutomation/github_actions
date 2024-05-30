#!/bin/bash
sudo ufw enable
sudo ufw allow ssh
sudo apt update && sudo apt install pipx -y
pipx install --include-deps ansible pywinrm
# pipx install --include-deps pywinrm
pipx ensurepath
sudo mkdir -p /etc/ansible
# sudo cat << EOF > /etc/ansible/ansible.cfg
# [defaults]
# host_key_checking = False
# EOF


# # Increase size of logical volume rootvg/homelv.
# sudo lvextend -L+10GB /dev/mapper/rootvg-homelv
# sudo xfs_growfs /dev/rootvg/homelv

# # Update all packages that have available updates.
# sudo dnf update -y

# # Install Python 3 and pip.
# sudo dnf install -y python3-pip

# # Upgrade pip3.
# sudo pip3 install --upgrade pip

# # Install Ansible.
# sudo pip3 install ansible

# # Install Ansible az collection for interacting with Azure.

sudo apt install python3-pip -y
ansible-galaxy collection install azure.azcollection microsoft.ad community.azure
wget https://raw.githubusercontent.com/ansible-collections/azure/dev/requirements.txt
sed -i 's/==.*//' requirements.txt
pip3 install -r requirements.txt
pip3 install -r requirements.txt --upgrade


pipx install --include-deps azure-mgmt-resource azure-cli #-core

# # pip3 install azure-cli --upgrade
# #
# # sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
# # sudo dnf install -y https://packages.microsoft.com/config/rhel/9.0/packages-microsoft-prod.rpm
# # sudo dnf install azure-cli -y

# # pipx install azure-mgmt-resource azure-cli-core
# # pip3 install ansible[azure] --force
# pip3 install oauthlib --upgrade
# pip3 install pywinrm --upgrade