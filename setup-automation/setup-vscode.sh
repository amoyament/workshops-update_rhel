#!/bin/bash

# Ansible for RHEL Workshop - VS Code Server Setup Script
# This script configures the VS Code container for student lab access

set -e

echo "Starting VS Code setup..."

# Install required packages
echo "Installing dependencies..."
dnf install -y git openssh-clients vim nano

# Install code-server
echo "Installing code-server..."
curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=/usr/local
ln -sf /usr/local/bin/code-server /usr/bin/code-server

# Create coder user
echo "Creating coder user..."
useradd -u 1001 -g 0 -m coder || true

# Create workspace and config directories
echo "Setting up workspace directories..."
mkdir -p /opt/app-root/src/workspace/rhel-workshop
mkdir -p /opt/app-root/src/.local/share/code-server
chown -R coder:root /opt/app-root/src

# Configure code-server
echo "Configuring code-server..."
mkdir -p /home/coder/.config/code-server
cat > /home/coder/.config/code-server/config.yaml << 'EOF'
bind-addr: 0.0.0.0:8080
auth: password
password: ansible123!
cert: false
EOF
chown -R coder:root /home/coder/.config

# Set up SSH keys
echo "Setting up SSH..."
mkdir -p /home/coder/.ssh
if [ -n "$SSH_PRIVATE_KEY" ]; then echo "$SSH_PRIVATE_KEY" > /home/coder/.ssh/id_rsa; fi
if [ -n "$SSH_PUBLIC_KEY" ]; then echo "$SSH_PUBLIC_KEY" > /home/coder/.ssh/id_rsa.pub; fi
chown -R coder:root /home/coder/.ssh
chmod 700 /home/coder/.ssh
chmod 600 /home/coder/.ssh/id_rsa 2>/dev/null || true
chmod 644 /home/coder/.ssh/id_rsa.pub 2>/dev/null || true

# Create SSH config for lab hosts
echo "Creating SSH config..."
cat > /home/coder/.ssh/config << 'EOF'
Host control
    HostName control
    User student
    Port 22
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host node1
    HostName node1
    User student
    Port 22
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host node2
    HostName node2
    User student
    Port 22
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host node3
    HostName node3
    User student
    Port 22
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF
chown coder:root /home/coder/.ssh/config
chmod 600 /home/coder/.ssh/config

# Create VS Code workspace settings
echo "Creating VS Code workspace settings..."
mkdir -p /opt/app-root/src/workspace/rhel-workshop/.vscode
cat > /opt/app-root/src/workspace/rhel-workshop/.vscode/settings.json << 'EOF'
{
    "terminal.integrated.profiles.linux": {
        "SSH to control": {
            "path": "ssh",
            "args": ["control"]
        }
    },
    "terminal.integrated.defaultProfile.linux": "SSH to control"
}
EOF
chown -R coder:root /opt/app-root/src/workspace/rhel-workshop/.vscode

# Create supervisor script to keep code-server running
echo "Creating code-server supervisor..."
cat > /tmp/vscode-supervisor.sh << 'EOFSCRIPT'
#!/bin/bash
echo "VS Code Supervisor starting..."
while true; do
  echo "$(date): Starting code-server"
  cd /opt/app-root/src/workspace/rhel-workshop
  su - coder -c 'code-server --config /home/coder/.config/code-server/config.yaml --user-data-dir /opt/app-root/src/.local/share/code-server .'
  echo "$(date): code-server exited, restarting in 5 seconds..."
  sleep 5
done
EOFSCRIPT
chmod +x /tmp/vscode-supervisor.sh

# Start code-server via supervisor
echo "Starting code-server..."
nohup /tmp/vscode-supervisor.sh > /tmp/code-server.log 2>&1 &
sleep 5

echo "VS Code setup completed successfully!"
