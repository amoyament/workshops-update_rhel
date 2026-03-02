#!/bin/bash
curl -k  -L https://${SATELLITE_URL}/pub/katello-server-ca.crt -o /etc/pki/ca-trust/source/anchors/${SATELLITE_URL}.ca.crt
update-ca-trust
rpm -Uhv https://${SATELLITE_URL}/pub/katello-ca-consumer-latest.noarch.rpm || true

subscription-manager status >/dev/null 2>&1 || \
  subscription-manager register --org=${SATELLITE_ORG} --activationkey=${SATELLITE_ACTIVATIONKEY} --force
setenforce 0

# Create student user for workshop exercises
useradd -m student 2>/dev/null || true
echo "student:ansible123!" | chpasswd
echo "student ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/student
chmod 440 /etc/sudoers.d/student

# Setup SSH keys for student
sudo -u student mkdir -p /home/student/.ssh
sudo -u student chmod 700 /home/student/.ssh
if [ ! -f /home/student/.ssh/id_rsa ]; then
  sudo -u student ssh-keygen -q -t rsa -b 4096 -C "student@$(hostname)" -f /home/student/.ssh/id_rsa -N ""
fi
sudo -u student chmod 600 /home/student/.ssh/id_rsa*

# Create workshop directories for student
sudo -u student mkdir -p /home/student/rhel-workshop
sudo -u student mkdir -p /home/student/lab_inventory

# Also setup rhel user with sudo
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

# Override code-server to open in /home/student by default
mkdir -p /etc/systemd/system/code-server.service.d/
tee /etc/systemd/system/code-server.service.d/override.conf << 'EOF'
[Service]
WorkingDirectory=/home/student
EOF
systemctl daemon-reload

systemctl start code-server || true
dnf install -y unzip nano git podman ansible-core python3-pip || true

# Ensure ansible-galaxy exists; if not, install ansible-core via pip
if ! command -v ansible-galaxy >/dev/null 2>&1; then
  python3 -m pip install --upgrade pip >/dev/null 2>&1 || true
  python3 -m pip install ansible-core >/dev/null 2>&1 || true
fi

# Install ansible-lint for rhel user (pip; not always available via dnf)
sudo -u rhel bash -lc 'python3 -m pip install --user --upgrade pip >/dev/null 2>&1 && python3 -m pip install --user ansible-lint >/dev/null 2>&1' || true
