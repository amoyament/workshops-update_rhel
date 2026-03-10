#!/bin/bash
curl -k  -L https://${SATELLITE_URL}/pub/katello-server-ca.crt -o /etc/pki/ca-trust/source/anchors/${SATELLITE_URL}.ca.crt
update-ca-trust
rpm -Uhv https://${SATELLITE_URL}/pub/katello-ca-consumer-latest.noarch.rpm || true

subscription-manager status >/dev/null 2>&1 || \
  subscription-manager register --org=${SATELLITE_ORG} --activationkey=${SATELLITE_ACTIVATIONKEY} --force
setenforce 0
echo "%rhel ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/rhel_sudoers
chmod 440 /etc/sudoers.d/rhel_sudoers
sudo -u rhel mkdir -p /home/rhel/.ssh
sudo -u rhel chmod 700 /home/rhel/.ssh
if [ ! -f /home/rhel/.ssh/id_rsa ]; then
sudo -u rhel ssh-keygen -q -t rsa -b 4096 -C "rhel@$(hostname)" -f /home/rhel/.ssh/id_rsa -N ""
fi
sudo -u rhel chmod 600 /home/rhel/.ssh/id_rsa*

systemctl stop firewalld
systemctl stop code-server || true
[ -f /home/rhel/.config/code-server/config.yaml ] && \
  mv /home/rhel/.config/code-server/config.yaml /home/rhel/.config/code-server/config.bk.yaml || true

tee /home/rhel/.config/code-server/config.yaml << EOF
bind-addr: 0.0.0.0:8080
auth: none
cert: false
EOF

systemctl start code-server || true
dnf install -y unzip nano git podman ansible-core ansible-navigator python3-pip || true

# Ensure ansible-galaxy exists; if not, install ansible-core via pip
if ! command -v ansible-galaxy >/dev/null 2>&1; then
  python3 -m pip install --upgrade pip >/dev/null 2>&1 || true
  python3 -m pip install ansible-core >/dev/null 2>&1 || true
fi

# Ensure ansible-navigator exists; if not, install via pip
if ! command -v ansible-navigator >/dev/null 2>&1; then
  python3 -m pip install ansible-navigator >/dev/null 2>&1 || true
fi

# Install required Ansible collections (used across modules 3-7)
echo "Installing Ansible collections..."
ansible-galaxy collection install ansible.posix --force
ansible-galaxy collection install community.general --force

# ─── Lab Inventory Setup ───
# Create lab_inventory directory and inventory file for workshop exercises
echo "Creating lab_inventory for rhel user..."
sudo -u rhel mkdir -p /home/rhel/lab_inventory

cat > /home/rhel/lab_inventory/hosts << 'EOF'
[web]
node1 ansible_host=node01
node2 ansible_host=node02

[db]
node3 ansible_host=node03

[all:vars]
ansible_user=rhel
ansible_password=ansible123!
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

cat > /home/rhel/lab_inventory/ansible.cfg << 'EOF'
[defaults]
inventory = hosts
remote_user = rhel
host_key_checking = False
deprecation_warnings = False

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False
EOF

# Also install ansible.cfg system-wide so EEs can access it
cp /home/rhel/lab_inventory/ansible.cfg /etc/ansible/ansible.cfg 2>/dev/null || true
mkdir -p /etc/ansible && cp /home/rhel/lab_inventory/ansible.cfg /etc/ansible/ansible.cfg

chown -R rhel:rhel /home/rhel/lab_inventory
chmod 644 /home/rhel/lab_inventory/hosts /home/rhel/lab_inventory/ansible.cfg

# ─── Ansible Navigator Setup (Modules 6+) ───
# Place navigator config in home directory (standard location)
cat > /home/rhel/.ansible-navigator.yml << 'EOF'
---
ansible-navigator:
  ansible:
    inventory:
      entries:
      - /home/rhel/lab_inventory/hosts

  execution-environment:
    image: registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest
    enabled: true
    container-engine: podman
    pull:
      policy: missing
    volume-mounts:
    - src: "/etc/ansible/"
      dest: "/etc/ansible/"

  mode: stdout
EOF

chown rhel:rhel /home/rhel/.ansible-navigator.yml
chmod 644 /home/rhel/.ansible-navigator.yml

# Pre-pull the Execution Environment image (requires registry.redhat.io access)
# If registry auth is available, pull the EE; otherwise skip gracefully
echo "Pulling Execution Environment image..."
if sudo -u rhel podman pull registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest 2>/dev/null; then
  echo "EE image pulled successfully."
else
  echo "WARNING: Could not pull EE from registry.redhat.io (auth may be required)."
  echo "Trying public fallback EE image..."
  if sudo -u rhel podman pull quay.io/ansible/creator-ee:latest 2>/dev/null; then
    echo "Fallback EE image pulled. Tagging as expected image..."
    sudo -u rhel podman tag quay.io/ansible/creator-ee:latest \
      registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest 2>/dev/null || true
  else
    echo "WARNING: No EE image available. ansible-navigator will attempt to pull at runtime."
  fi
fi

# Install ansible-lint for rhel user (pip; not always available via dnf)
sudo -u rhel bash -lc 'python3 -m pip install --user --upgrade pip >/dev/null 2>&1 && python3 -m pip install --user ansible-lint >/dev/null 2>&1' || true
