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
dnf install -y unzip nano git podman python3-pip || true

# Install ansible-core and ansible-navigator via pip (not available via dnf on this image)
export PATH="/usr/local/bin:$PATH"
python3 -m pip install --upgrade pip 2>/dev/null || true
python3 -m pip install ansible-core ansible-navigator 2>/dev/null || true

# Verify ansible-galaxy is available
if ! command -v ansible-galaxy >/dev/null 2>&1; then
  echo "ERROR: ansible-galaxy not found after pip install"
  # Try to find it
  find / -name ansible-galaxy -type f 2>/dev/null | head -5
  exit 1
fi

# Install required Ansible collections (used across modules 3-7)
# Install system-wide (for root/pip ansible-galaxy) and for rhel user
echo "Installing Ansible collections..."
ansible-galaxy collection install ansible.posix --force
ansible-galaxy collection install community.general --force
sudo -u rhel ansible-galaxy collection install ansible.posix --force 2>/dev/null || true
sudo -u rhel ansible-galaxy collection install community.general --force 2>/dev/null || true

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

# Install ansible.cfg system-wide so EEs can access it via volume mount
mkdir -p /etc/ansible
cp /home/rhel/lab_inventory/ansible.cfg /etc/ansible/ansible.cfg

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
    - src: "/usr/share/ansible/collections/"
      dest: "/usr/share/ansible/collections/"
    - src: "/home/rhel/.ansible/collections/"
      dest: "/home/rhel/.ansible/collections/"

  mode: stdout
EOF

chown rhel:rhel /home/rhel/.ansible-navigator.yml
chmod 644 /home/rhel/.ansible-navigator.yml

# Enable linger for rhel user (required for rootless podman)
loginctl enable-linger rhel

# Pre-pull the Execution Environment image
echo "Pulling Execution Environment image..."
RUNAS="sudo -u rhel"
$RUNAS bash<<'EOF'
podman login --username $REG_USER --password $REG_PASS registry.redhat.io
podman pull registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9:latest
EOF

# Install ansible-lint for rhel user
sudo -u rhel bash -lc 'python3 -m pip install --user ansible-lint >/dev/null 2>&1' || true
