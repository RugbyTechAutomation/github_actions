#cloud-config
package_update: true
package_upgrade: true

packages:
  - ufw
  - pipx

runcmd:
  - sudo systemctl enable --now ssh
  - sudo ufw enable
  - sudo ufw allow ssh
  - pipx ensurepath
  - pipx install --include-deps ansible
  - sudo mkdir -p /etc/ansible
  - |
    sudo bash -c 'cat << EOF > /etc/ansible/ansible.cfg
    [defaults]
    host_key_checking = False
    EOF'
