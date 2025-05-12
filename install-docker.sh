#!/bin/bash

set -e

echo "🔧 Manual Docker + Compose Installer (No apt issues)"

# Step 1: Remove old stuff if any
sudo rm -rf /usr/bin/docker /usr/bin/docker-compose /usr/local/bin/docker /usr/local/bin/docker-compose
sudo rm -rf /var/lib/docker /var/lib/containerd
sudo groupadd docker 2>/dev/null || true

# Step 2: Download Docker binaries
echo "📦 Downloading Docker..."
curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-25.0.3.tgz -o docker.tgz
tar xzvf docker.tgz
sudo cp docker/* /usr/bin/
rm -rf docker docker.tgz

# Step 3: Install Docker Compose
echo "⚙️ Installing Docker Compose..."
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
-o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Step 4: Setup Docker service manually
echo "🛠️ Setting up Docker service..."
sudo mkdir -p /etc/systemd/system
cat <<EOF | sudo tee /etc/systemd/system/docker.service > /dev/null
[Unit]
Description=Docker Service
After=network.target

[Service]
ExecStart=/usr/bin/dockerd
Restart=always
ExecReload=/bin/kill -s HUP \$MAINPID
TimeoutSec=0
RestartSec=2
StartLimitBurst=3
StartLimitIntervalSec=60
LimitNOFILE=1048576
LimitNPROC=1048576

[Install]
WantedBy=multi-user.target
EOF

# Step 5: Enable and start
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable docker
sudo systemctl start docker

# Step 6: Permissions
sudo usermod -aG docker $USER
newgrp docker

# Final test
echo "✅ Docker version:"
docker --version
echo "✅ Docker Compose version:"
docker-compose --version
