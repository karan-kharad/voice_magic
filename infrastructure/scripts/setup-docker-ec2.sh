#!/usr/bin/env bash
# ==============================================================================
# One-Click Docker & Docker Compose Setup on AWS EC2 (Ubuntu 22.04 / 24.04 LTS)
# Usage: sudo bash setup-docker-ec2.sh
# ==============================================================================
set -euo pipefail

echo "=========================================="
echo "Installing Docker & Docker Compose on EC2"
echo "=========================================="

# Update APT repository
apt-get update && apt-get install -y ca-certificates curl gnupg lsb-release ufw

# Add Docker’s official GPG key
install -m 0755 -d /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
fi

# Set up the Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable and start Docker service
systemctl enable docker
systemctl start docker

# Add current user to docker group if exists
if id -u ubuntu >/dev/null 2>&1; then
    usermod -aG docker ubuntu
fi

# Configure UFW Firewall (Allow HTTP, HTTPS, SSH, deny PostgreSQL port 5432)
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

echo "=========================================="
echo "Docker & Docker Compose installation complete!"
echo "Docker version: $(docker --version)"
echo "Compose version: $(docker compose version)"
echo "=========================================="
