
# Create the directory "/etc/ansible"

mkdir -p /etc/ansible

# Add the following line to the file "/etc/ansible/ansible.cfg"

```
cat << EOF > /etc/ansible/ansible.cfg
[defaults]
host_key_checking = False
EOF
```

# Ansible Inventory

```
cd $HOME
mkdir ansible
cd ansible
export MANAGED_NODE_IP=$MANAgED_NODE_IP
```

```
cd $HOME/ansible && cat << EOF > hosts
[web]
$MANAGED_NODE_IP
EOF
```
