# Manual Robot Shop Setup Guide

## Prerequisites Check

Before setting up Robot Shop, verify your VM meets these requirements:

### Minimum System Requirements:
- **Instance Type**: t2.medium or larger (2 vCPU, 4GB RAM minimum)
- **OS**: Amazon Linux 2 or Amazon Linux 2023
- **Disk Space**: At least 20GB free
- **Python**: 3.9+ (for Ansible compatibility)
- **Docker**: Latest version
- **Docker Compose**: v2.x

### Why t2.micro Fails:
- **RAM**: 1GB is insufficient for:
  - Python 3.9 compilation (~500MB)
  - Docker daemon (~200MB)
  - Instana agent (~150MB)
  - 11 Robot Shop containers (~2-3GB total)
- **CPU**: Single vCPU struggles with compilation and container orchestration

## Manual Setup Steps

### Step 1: Connect to VM
```bash
ssh -i ./instanaconnect.pem ec2-user@100.53.171.208
```

### Step 2: Check System Resources
```bash
# Check available memory
free -h

# Check disk space
df -h

# Check CPU
lscpu

# Check OS version
cat /etc/os-release
```

### Step 3: Install Docker (if not installed)
```bash
# Update system
sudo yum update -y

# Install Docker
sudo yum install -y docker

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker ec2-user

# Verify Docker
docker --version

# Log out and back in for group changes to take effect
exit
```

### Step 4: Install Docker Compose v2
```bash
# Download Docker Compose v2
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose

# Make it executable
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker-compose --version
```

### Step 5: Create Robot Shop Directory
```bash
# Create directory
sudo mkdir -p /opt/robot-shop
cd /opt/robot-shop
```

### Step 6: Create docker-compose.yml
```bash
sudo tee /opt/robot-shop/docker-compose.yml > /dev/null <<'EOF'
version: '3'
services:
  mongodb:
    image: robotshop/rs-mongodb:latest
    container_name: mongodb
    networks:
      - robot-shop
    restart: always

  redis:
    image: redis:6.2-alpine
    container_name: redis
    networks:
      - robot-shop
    restart: always

  rabbitmq:
    image: rabbitmq:3.11-management-alpine
    container_name: rabbitmq
    networks:
      - robot-shop
    restart: always

  catalogue:
    image: robotshop/rs-catalogue:latest
    container_name: catalogue
    depends_on:
      - mongodb
    networks:
      - robot-shop
    restart: always

  user:
    image: robotshop/rs-user:latest
    container_name: user
    depends_on:
      - mongodb
      - redis
    networks:
      - robot-shop
    restart: always

  cart:
    image: robotshop/rs-cart:latest
    container_name: cart
    depends_on:
      - redis
    networks:
      - robot-shop
    restart: always

  mysql:
    image: robotshop/rs-mysql-db:latest
    container_name: mysql
    networks:
      - robot-shop
    restart: always

  shipping:
    image: robotshop/rs-shipping:latest
    container_name: shipping
    depends_on:
      - mysql
    networks:
      - robot-shop
    restart: always

  ratings:
    image: robotshop/rs-ratings:latest
    container_name: ratings
    depends_on:
      - mysql
    networks:
      - robot-shop
    restart: always

  payment:
    image: robotshop/rs-payment:latest
    container_name: payment
    depends_on:
      - rabbitmq
    networks:
      - robot-shop
    restart: always

  dispatch:
    image: robotshop/rs-dispatch:latest
    container_name: dispatch
    depends_on:
      - rabbitmq
    networks:
      - robot-shop
    restart: always

  web:
    image: robotshop/rs-web:latest
    container_name: web
    depends_on:
      - catalogue
      - user
      - cart
      - shipping
      - payment
    ports:
      - "8080:8080"
    networks:
      - robot-shop
    restart: always

networks:
  robot-shop:
    driver: bridge
EOF
```

### Step 7: Pull Docker Images
```bash
cd /opt/robot-shop
sudo docker-compose pull
```

This will download all required images (~2-3GB total).

### Step 8: Start Robot Shop
```bash
cd /opt/robot-shop
sudo docker-compose up -d
```

### Step 9: Verify Deployment
```bash
# Check running containers
docker ps

# Check logs
docker-compose logs -f

# Test web interface
curl http://localhost:8080
```

### Step 10: Access Robot Shop
Open browser: `http://100.53.171.208:8080`

## Troubleshooting

### If VM is Unresponsive:
1. **Reboot the instance** from AWS Console
2. **Or recreate with larger instance**:
   ```bash
   # Update terraform.tfvars
   instance_type = "t2.medium"
   
   # Recreate infrastructure
   terraform destroy -auto-approve
   terraform apply -auto-approve
   ```

### If Docker Fails:
```bash
# Check Docker service
sudo systemctl status docker

# Restart Docker
sudo systemctl restart docker

# Check Docker logs
sudo journalctl -u docker -n 50
```

### If Containers Fail to Start:
```bash
# Check container logs
docker logs <container_name>

# Check system resources
docker stats

# Free up memory
docker system prune -a
```

### Memory Issues:
```bash
# Check memory usage
free -h
docker stats --no-stream

# If low memory, stop some containers
docker-compose stop mongodb redis rabbitmq
```

## Quick Recovery Script

Save this as `setup_robotshop.sh`:

```bash
#!/bin/bash
set -e

echo "=== Robot Shop Manual Setup ==="

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
   echo "Please run with sudo"
   exit 1
fi

# Install Docker if needed
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    yum install -y docker
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user
fi

# Install Docker Compose if needed
if [ ! -f /usr/local/bin/docker-compose ]; then
    echo "Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# Create directory
mkdir -p /opt/robot-shop
cd /opt/robot-shop

# Create docker-compose.yml (content from Step 6 above)

# Pull and start
echo "Pulling images..."
docker-compose pull

echo "Starting Robot Shop..."
docker-compose up -d

echo "=== Setup Complete ==="
echo "Access Robot Shop at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
docker ps
```

## Recommendation

**For production use, upgrade to t2.medium or larger:**
- More reliable
- Better performance
- Can handle all services simultaneously
- No compilation timeouts
- Sufficient memory for monitoring tools
