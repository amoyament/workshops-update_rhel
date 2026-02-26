#!/bin/bash

# Ansible for RHEL Workshop - VS Code Server Setup Script
# Configures devtools-ansible VM for student lab access

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

# Satellite registration
retry "curl -k -L https://${SATELLITE_URL}/pub/katello-server-ca.crt -o /etc/pki/ca-trust/source/anchors/${SATELLITE_URL}.ca.crt" "Downloading Satellite CA cert"
retry "update-ca-trust" "Updating CA trust"
retry "rpm -Uhv https://${SATELLITE_URL}/pub/katello-ca-consumer-latest.noarch.rpm" "Installing katello consumer RPM"
retry "subscription-manager register --org=${SATELLITE_ORG} --activationkey=${SATELLITE_ACTIVATIONKEY}" "Registering with Satellite"

# Disable firewalld and set SELinux permissive
setenforce 0
systemctl stop firewalld

# Reconfigure code-server for workshop access
systemctl stop code-server
mv /home/rhel/.config/code-server/config.yaml /home/rhel/.config/code-server/config.bk.yaml

tee /home/rhel/.config/code-server/config.yaml << EOF
bind-addr: 0.0.0.0:8080
auth: none
cert: false
EOF

systemctl start code-server

# Install additional packages
dnf install -y unzip nano git podman jq httpd

# Configure sudoers for rhel user
echo "%rhel ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/rhel_sudoers
chmod 440 /etc/sudoers.d/rhel_sudoers

# Create student user for workshop exercises
useradd -m student 2>/dev/null || true
echo "student:ansible123!" | chpasswd
echo "student ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/student

# Set up SSH keys for rhel user
echo "Checking SSH keys for rhel user..."
RHEL_SSH_DIR="/home/rhel/.ssh"
RHEL_PRIVATE_KEY="$RHEL_SSH_DIR/id_rsa"

if [ -f "$RHEL_PRIVATE_KEY" ]; then
    echo "SSH key already exists for rhel user: $RHEL_PRIVATE_KEY"
else
    echo "Creating SSH key for rhel user..."
    sudo -u rhel mkdir -p /home/rhel/.ssh
    sudo -u rhel chmod 700 /home/rhel/.ssh
    sudo -u rhel ssh-keygen -t rsa -b 4096 -C "rhel@$(hostname)" -f /home/rhel/.ssh/id_rsa -N "" -q
    sudo -u rhel chmod 600 /home/rhel/.ssh/id_rsa*

    if [ -f "$RHEL_PRIVATE_KEY" ]; then
        echo "SSH key created successfully for rhel user"
    else
        echo "Error: Failed to create SSH key for rhel user"
    fi
fi

# Environment variables for rhel user
echo 'export PATH=$HOME/.local/bin:$PATH' >> /home/rhel/.profile
chown rhel:rhel /home/rhel/.profile

# Enable linger for the rhel user
loginctl enable-linger rhel

# Upgrade ansible-dev-tools
pip3 install --upgrade --force-reinstall ansible-dev-tools

# Restart code-server to pick up any changes
systemctl start code-server
sleep 15

echo "VS Code setup completed successfully!"
