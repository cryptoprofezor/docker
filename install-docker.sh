#!/bin/bash

set -e

echo "🔧 Manual Docker + Compose Installer for Ubuntu 24.04 (No apt)"

# Clean any junk
sudo rm -rf /usr/bin/docker /usr/bin/dockerd /usr/bin/docker* /usr/local/bin/docker-compose
sudo rm -rf /var/lib/docker /var/lib/containerd
sudo systemctl stop docker || true
sudo systemctl disable docker || true

# Download Docker binary
echo "📦 Downloading Docker binaries..."
curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-25.0.3.tgz -o docker.tgz
tar xzvf docker.tgz
sudo cp docker/* /usr/bin/
rm -rf docker docker.tgz

# Install Docker Compose latest
echo "⚙️ Installing Docker Compose..."
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)
sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
-o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Setup Docker systemd manually
echo "🛠️ Creating Docker service manually..."
sudo tee /etc/systemd/system/docker.service > /dev/null <<EOF
[Unit]
Description=Docker Service
After=network.target

[Service]
ExecStart=/usr/bin/dockerd
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start docker
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable docker
sudo systemctl start docker

# Permissions
sudo groupadd docker 2>/dev/null || true
sudo usermod -aG docker $USER
newgrp docker

# Final check
echo "✅ Docker installed:"
docker --version

echo "✅ Docker Compose installed:"
docker-compose --version

echo "🔥 Done! Docker running without apt package problems. Restart terminal or run: newgrp docker"
