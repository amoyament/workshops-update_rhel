#!/bin/bash
cd /tmp

curl -k  -L https://${SATELLITE_URL}/pub/katello-server-ca.crt -o /etc/pki/ca-trust/source/anchors/${SATELLITE_URL}.ca.crt
update-ca-trust
rpm -Uhv https://${SATELLITE_URL}/pub/katello-ca-consumer-latest.noarch.rpm || true

subscription-manager status >/dev/null 2>&1 || \
  subscription-manager register --org=${SATELLITE_ORG} --activationkey=${SATELLITE_ACTIVATIONKEY} --force
setenforce 0

# ─── Create student user ───
useradd -m student 2>/dev/null || true
echo "student:ansible123!" | chpasswd
echo "student ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/student_sudoers
chmod 440 /etc/sudoers.d/student_sudoers

# ─── SSH key setup for student ───
sudo -H -u student mkdir -p /home/student/.ssh
sudo -H -u student chmod 700 /home/student/.ssh
cp -a /root/.ssh/* /home/student/.ssh/ 2>/dev/null || true
if [ ! -f /home/student/.ssh/id_rsa ]; then
  sudo -H -u student ssh-keygen -q -t rsa -b 4096 -C "student@$(hostname)" -f /home/student/.ssh/id_rsa -N ""
fi
chown -R student:student /home/student/.ssh
chmod 600 /home/student/.ssh/id_rsa* 2>/dev/null || true

# ─── Firewall ───
systemctl stop firewalld

# ─── Code-server setup (runs as rhel, opens /home/student) ───
systemctl stop code-server || true
[ -f /home/rhel/.config/code-server/config.yaml ] && \
  mv /home/rhel/.config/code-server/config.yaml /home/rhel/.config/code-server/config.bk.yaml || true

mkdir -p /home/rhel/.config/code-server
tee /home/rhel/.config/code-server/config.yaml << 'EOF'
bind-addr: 0.0.0.0:8080
auth: none
cert: false
EOF

# Make student's home accessible to code-server (rhel user)
chmod 755 /home/student

# Override code-server to open /home/student by default
mkdir -p /etc/systemd/system/code-server.service.d
CODE_SERVER_BIN=$(grep -oP 'ExecStart=\K\S+' /usr/lib/systemd/system/code-server*.service 2>/dev/null | head -1)
CODE_SERVER_BIN=${CODE_SERVER_BIN:-/usr/bin/code-server}
cat > /etc/systemd/system/code-server.service.d/override.conf << EOF
[Service]
ExecStart=
ExecStart=${CODE_SERVER_BIN} /home/student
EOF
systemctl daemon-reload

# Configure VS Code settings: hide dotfiles and set terminal to login as student
mkdir -p /home/rhel/.local/share/code-server/User
cat > /home/rhel/.local/share/code-server/User/settings.json << 'SETTINGS'
{
  "files.exclude": {
    "**/.ssh": true,
    "**/.config": true,
    "**/.cache": true,
    "**/.local": true,
    "**/.ansible": true,
    "**/.bash_logout": true,
    "**/.bash_profile": true,
    "**/.bashrc": true,
    "**/.ansible-navigator.yml": true
  },
  "terminal.integrated.profiles.linux": {
    "student": {
      "path": "/usr/bin/sudo",
      "args": ["-iu", "student"]
    }
  },
  "terminal.integrated.defaultProfile.linux": "student"
}
SETTINGS

systemctl start code-server || true

# ─── Install packages ───
dnf install -y unzip nano git podman python3-pip || true

# Install ansible-core and ansible-navigator via pip (not available via dnf on this image)
export PATH="/usr/local/bin:$PATH"
python3 -m pip install --upgrade pip 2>/dev/null || true
python3 -m pip install ansible-core ansible-navigator 2>/dev/null || true

# Verify ansible-galaxy is available
if ! command -v ansible-galaxy >/dev/null 2>&1; then
  echo "ERROR: ansible-galaxy not found after pip install"
  find / -name ansible-galaxy -type f 2>/dev/null | head -5
  exit 1
fi

# ─── Ansible collections (used across modules 3-7) ───
echo "Installing Ansible collections..."
ansible-galaxy collection install ansible.posix --force
ansible-galaxy collection install community.general --force
sudo -H -u student ansible-galaxy collection install ansible.posix --force 2>/dev/null || true
sudo -H -u student ansible-galaxy collection install community.general --force 2>/dev/null || true

# ─── Lab Inventory Setup ───
echo "Creating lab_inventory for student user..."
sudo -H -u student mkdir -p /home/student/lab_inventory

cat > /home/student/lab_inventory/hosts << 'INVENTORY'
[web]
node1 ansible_host=node01
node2 ansible_host=node02

[db]
node3 ansible_host=node03

[all:vars]
ansible_user=student
ansible_password=ansible123!
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
INVENTORY

cat > /home/student/lab_inventory/ansible.cfg << 'ANSIBLECFG'
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
ANSIBLECFG

# Install ansible.cfg system-wide so EEs can access it via volume mount
mkdir -p /etc/ansible
cp /home/student/lab_inventory/ansible.cfg /etc/ansible/ansible.cfg

chown -R student:student /home/student/lab_inventory
chmod 644 /home/student/lab_inventory/hosts /home/student/lab_inventory/ansible.cfg

# ─── Ansible Navigator Setup (Modules 6+) ───
cat > /home/student/.ansible-navigator.yml << 'EOF'
---
ansible-navigator:
  ansible:
    inventory:
      entries:
      - /home/student/lab_inventory/hosts

  execution-environment:
    image: quay.io/acme_corp/rhel_90_ee:latest
    enabled: true
    container-engine: podman
    pull:
      policy: missing
    volume-mounts:
    - src: "/etc/ansible/"
      dest: "/etc/ansible/"
    - src: "/usr/share/ansible/collections/"
      dest: "/usr/share/ansible/collections/"
    - src: "/home/student/.ansible/collections/"
      dest: "/home/student/.ansible/collections/"

  mode: stdout
EOF

chown student:student /home/student/.ansible-navigator.yml
chmod 644 /home/student/.ansible-navigator.yml

# Enable linger for student user (required for rootless podman)
loginctl enable-linger student

# Pre-pull the Execution Environment image (public, no auth needed)
echo "Pulling Execution Environment image..."
sudo -H -u student podman pull quay.io/acme_corp/rhel_90_ee:latest

# Install ansible-lint for student user
sudo -H -u student bash -lc 'python3 -m pip install --user ansible-lint >/dev/null 2>&1' || true
