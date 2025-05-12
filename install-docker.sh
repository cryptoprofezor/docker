#!/bin/bash

set -e

echo "🚀 Starting Docker + Compose install for Ubuntu 24.04..."

# Step 1: Clean up any existing Docker
echo "🧹 Cleaning old Docker installs..."
sudo apt remove -y docker docker-engine docker.io containerd runc docker-ce docker-ce-cli containerd.io || true
sudo rm -rf /var/lib/docker /var/lib/containerd
sudo rm -f /etc/apt/sources.list.d/docker.list
sudo rm -f /usr/local/bin/docker-compose

# Step 2: Install required dependencies
echo "📦 Installing dependencies..."
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release jq

# Step 3: Add Docker GPG key
echo "🔑 Adding Docker GPG key..."
sudo mkdir -p /usr/share/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Step 4: Add repo manually with jammy (works for Ubuntu 24.04 too)
echo "➕ Adding Docker repo (jammy workaround)..."
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
https://download.docker.com/linux/ubuntu jammy stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Force clear and refresh apt
sudo rm -rf /var/lib/apt/lists/*
sudo apt update

# Step 5: Install Docker engine
echo "🐳 Installing Docker engine..."
if ! sudo apt install -y docker-ce docker-ce-cli containerd.io; then
  echo "❌ Docker install failed. Try again or check sources."
  exit 1
fi

# Step 6: Enable and start Docker service
echo "🔁 Enabling Docker service..."
sudo systemctl enable --now docker

# Step 7: Add user to docker group
echo "👤 Adding current user to docker group..."
sudo groupadd docker 2>/dev/null || true
sudo usermod -aG docker $USER
newgrp docker

# Step 8: Install Docker Compose (latest)
echo "⚙️ Installing Docker Compose..."
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
-o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Step 9: Verify everything
echo "🎉 Docker version:"
docker --version
echo "🎉 Docker Compose version:"
docker-compose --version

echo "✅ Installation successful! Restart terminal or run: newgrp docker"
