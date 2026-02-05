#!/bin/bash
# Deploy Robot Shop via SSH
# This script runs all deployment steps on the remote VM

set -e

INSTANA_AGENT_KEY="$1"
INSTANA_ENDPOINT_HOST="$2"
INSTANA_ENDPOINT_PORT="$3"
INSTANA_ZONE="$4"

echo "=== Starting Robot Shop Deployment ==="
echo "Instana Endpoint: ${INSTANA_ENDPOINT_HOST}:${INSTANA_ENDPOINT_PORT}"
echo "Instana Zone: ${INSTANA_ZONE}"

# Check if Docker is already installed
if command -v docker &> /dev/null; then
    echo "✓ Docker is already installed"
    docker --version
else
    echo "Installing Docker..."
    apt-get update
    apt-get install -y ca-certificates curl gnupg lsb-release git wget
    
    # Add Docker GPG key
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Start Docker
    systemctl start docker
    systemctl enable docker
    echo "✓ Docker installed successfully"
fi

# Check if Robot Shop is already deployed
if [ -d "/opt/robot-shop" ]; then
    echo "✓ Robot Shop directory exists, updating..."
    cd /opt/robot-shop
    docker compose down || true
else
    echo "Cloning Robot Shop repository..."
    mkdir -p /opt
    cd /opt
    git clone https://github.com/instana/robot-shop.git
    cd robot-shop
fi

# Deploy Robot Shop
echo "Deploying Robot Shop containers..."
cd /opt/robot-shop
export REPO=robotshop
export TAG=latest
docker compose up -d

echo "Waiting for containers to start..."
sleep 10

# Check container status
echo "=== Container Status ==="
docker compose ps

# Check if Instana agent is already installed
if systemctl is-active --quiet instana-agent; then
    echo "✓ Instana agent is already running"
else
    echo "Installing Instana agent..."
    curl -o setup_agent.sh https://setup.instana.io/agent
    chmod +x setup_agent.sh
    ./setup_agent.sh -a "${INSTANA_AGENT_KEY}" -t dynamic -e "${INSTANA_ENDPOINT_HOST}:${INSTANA_ENDPOINT_PORT}" -s -z "${INSTANA_ZONE}"
    echo "✓ Instana agent installed"
fi

echo "=== Deployment Complete ==="
echo "Robot Shop URL: http://$(hostname -I | awk '{print $1}'):8080"
echo "Instana Zone: ${INSTANA_ZONE}"

# Made with Bob
