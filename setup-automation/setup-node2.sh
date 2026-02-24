#!/bin/bash

# Ansible for RHEL Workshop - Node2 Setup Script
# This script configures node2 for the workshop exercises

set -e

echo "Starting node2 setup..."

# Install httpd (Apache) for web server exercises
echo "Installing httpd..."
dnf install -y httpd

# Create a default index.html page
echo "Creating default web page..."
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Node2 - Ansible Workshop</title>
    <style>
        body {
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            font-family: Arial, sans-serif;
            background-color: #e8f4f8;
            color: #333;
        }
        h1 {
            font-size: 3em;
            text-align: center;
        }
    </style>
</head>
<body>
    <h1>Welcome to Node2 - Ansible for RHEL Workshop</h1>
</body>
</html>
EOF

# Configure firewall to allow HTTP traffic
echo "Configuring firewall..."
firewall-cmd --permanent --add-service=http 2>/dev/null || true
firewall-cmd --reload 2>/dev/null || true

# Enable and start httpd service
echo "Enabling and starting httpd..."
systemctl enable httpd
systemctl start httpd

# Set proper SELinux context
restorecon -Rv /var/www/html/ 2>/dev/null || true

echo "node2 setup completed successfully!"
