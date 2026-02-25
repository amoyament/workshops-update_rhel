#!/bin/bash

# Ansible for RHEL Workshop - Control Node Setup Script
# This script configures the control node for the workshop

retry() {
    for i in {1..3}; do
        echo "Attempt $i: $2"
        if $1; then
            return 0
        fi
        [ $i -lt 3 ] && sleep 5
    done
    echo "Failed after 3 attempts: $2"
    exit 1
}

retry "subscription-manager clean"
retry "curl -k -L https://${SATELLITE_URL}/pub/katello-server-ca.crt -o /etc/pki/ca-trust/source/anchors/${SATELLITE_URL}.ca.crt"
retry "update-ca-trust"
KATELLO_INSTALLED=$(rpm -qa | grep -c katello)
if [ $KATELLO_INSTALLED -eq 0 ]; then
  retry "rpm -Uhv https://${SATELLITE_URL}/pub/katello-ca-consumer-latest.noarch.rpm"
fi
subscription-manager status
if [ $? -ne 0 ]; then
    retry "subscription-manager register --org=${SATELLITE_ORG} --activationkey=${SATELLITE_ACTIVATIONKEY}"
fi
retry "dnf install -y python3-pip python3-libsemanage"

# Disable systemd-tmpfiles-setup to avoid conflicts
systemctl stop systemd-tmpfiles-setup.service 2>/dev/null || true
systemctl disable systemd-tmpfiles-setup.service 2>/dev/null || true

# Install required Ansible collections
echo "Installing Ansible collections..."
ansible-galaxy collection install ansible.posix --force
ansible-galaxy collection install community.general --force
ansible-galaxy collection install ansible.controller --force

# Create lab directories for student user
echo "Creating lab directories..."
mkdir -p /home/student/lab_inventory
mkdir -p /home/student/rhel-workshop
chown -R student:student /home/student/lab_inventory
chown -R student:student /home/student/rhel-workshop

# Create inventory file for command-line exercises
echo "Creating inventory file..."
cat > /home/student/lab_inventory/hosts << 'EOF'
[web]
node1
node2

[db]
node3

[all:vars]
ansible_user=student
ansible_password=ansible123!
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

chown student:student /home/student/lab_inventory/hosts
chmod 644 /home/student/lab_inventory/hosts

# Create ansible.cfg for easier command-line usage
cat > /home/student/lab_inventory/ansible.cfg << 'EOF'
[defaults]
inventory = hosts
remote_user = student
host_key_checking = False
deprecation_warnings = False

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False
EOF

chown student:student /home/student/lab_inventory/ansible.cfg
chmod 644 /home/student/lab_inventory/ansible.cfg

# Configure Automation Controller using ansible.controller collection
echo "Configuring Ansible Automation Platform..."

# Create AAP setup playbook
cat > /tmp/aap-setup.yml << 'EOFAAP'
---
- name: Configure Ansible Automation Platform for RHEL Workshop
  hosts: localhost
  connection: local
  collections:
    - ansible.controller
  vars:
    controller_host: "https://localhost"
    controller_username: admin
    controller_password: ansible123!
    validate_certs: false
  tasks:

    - name: Create Workshop Organization
      ansible.controller.organization:
        name: "Workshop"
        description: "Ansible for RHEL Workshop Organization"
        state: present
        controller_host: "{{ controller_host }}"
        controller_username: "{{ controller_username }}"
        controller_password: "{{ controller_password }}"
        validate_certs: "{{ validate_certs }}"

    - name: Add Machine Credential for managed nodes
      ansible.controller.credential:
        name: 'Workshop Credential'
        organization: Workshop
        credential_type: Machine
        controller_host: "{{ controller_host }}"
        controller_username: "{{ controller_username }}"
        controller_password: "{{ controller_password }}"
        validate_certs: "{{ validate_certs }}"
        inputs:
          username: student
          password: ansible123!

    - name: Create Workshop Inventory
      ansible.controller.inventory:
        name: "Workshop Inventory"
        description: "RHEL nodes for workshop"
        organization: Workshop
        controller_host: "{{ controller_host }}"
        controller_username: "{{ controller_username }}"
        controller_password: "{{ controller_password }}"
        validate_certs: "{{ validate_certs }}"
        state: present

    - name: Add web group to inventory
      ansible.controller.group:
        name: web
        inventory: "Workshop Inventory"
        controller_host: "{{ controller_host }}"
        controller_username: "{{ controller_username }}"
        controller_password: "{{ controller_password }}"
        validate_certs: "{{ validate_certs }}"
        state: present

    - name: Add db group to inventory
      ansible.controller.group:
        name: db
        inventory: "Workshop Inventory"
        controller_host: "{{ controller_host }}"
        controller_username: "{{ controller_username }}"
        controller_password: "{{ controller_password }}"
        validate_certs: "{{ validate_certs }}"
        state: present

    - name: Add node1 to inventory
      ansible.controller.host:
        name: node1
        inventory: "Workshop Inventory"
        controller_host: "{{ controller_host }}"
        controller_username: "{{ controller_username }}"
        controller_password: "{{ controller_password }}"
        validate_certs: "{{ validate_certs }}"
        state: present

    - name: Add node1 to web group
      ansible.controller.group:
        name: web
        inventory: "Workshop Inventory"
        hosts:
          - node1
        controller_host: "{{ controller_host }}"
        controller_username: "{{ controller_username }}"
        controller_password: "{{ controller_password }}"
        validate_certs: "{{ validate_certs }}"
        state: present

    - name: Add node2 to inventory
      ansible.controller.host:
        name: node2
        inventory: "Workshop Inventory"
        controller_host: "{{ controller_host }}"
        controller_username: "{{ controller_username }}"
        controller_password: "{{ controller_password }}"
        validate_certs: "{{ validate_certs }}"
        state: present

    - name: Add node2 to web group
      ansible.controller.group:
        name: web
        inventory: "Workshop Inventory"
        hosts:
          - node2
        controller_host: "{{ controller_host }}"
        controller_username: "{{ controller_username }}"
        controller_password: "{{ controller_password }}"
        validate_certs: "{{ validate_certs }}"
        state: present

    - name: Add node3 to inventory
      ansible.controller.host:
        name: node3
        inventory: "Workshop Inventory"
        controller_host: "{{ controller_host }}"
        controller_username: "{{ controller_username }}"
        controller_password: "{{ controller_password }}"
        validate_certs: "{{ validate_certs }}"
        state: present

    - name: Add node3 to db group
      ansible.controller.group:
        name: db
        inventory: "Workshop Inventory"
        hosts:
          - node3
        controller_host: "{{ controller_host }}"
        controller_username: "{{ controller_username }}"
        controller_password: "{{ controller_password }}"
        validate_certs: "{{ validate_certs }}"
        state: present

EOFAAP

# Execute AAP setup playbook
ansible-playbook /tmp/aap-setup.yml

# Set proper ownership
chown -R student:student /home/student

echo "Control node setup completed successfully!"
