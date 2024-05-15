#!/bin/bash

# Increase size of logical volume rootvg/homelv.
sudo lvextend -L+10GB /dev/mapper/rootvg-homelv
sudo xfs_growfs /dev/rootvg/homelv

# Update all packages that have available updates.
sudo dnf update -y

# Install Python 3 and pip.
sudo dnf install -y python3-pip

# Upgrade pip3.
sudo pip3 install --upgrade pip

# Install Ansible.
sudo pip3 install ansible

# Install dependencies
wget https://raw.githubusercontent.com/ansible-collections/azure/dev/requirements.txt -O requirements-azure.txt
pip3 install -r requirements-azure.txt

# Install Ansible az collection for interacting with Azure.
ansible-galaxy collection install azure.azcollection  --force
ansible-galaxy collection install microsoft.ad  --force

# Update OAuth
pip install oauthlib
pip install pywinrm