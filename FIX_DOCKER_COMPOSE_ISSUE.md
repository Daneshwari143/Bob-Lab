# Fix Docker Compose urllib3/OpenSSL Issue

## Problem
The error occurs because an old Python-based docker-compose (v1.x) is installed, which tries to use urllib3 v2 with an incompatible OpenSSL version (1.0.2k).

```
ImportError: urllib3 v2 only supports OpenSSL 1.1.1+, currently the 'ssl' module is compiled with 'OpenSSL 1.0.2k-fips  26 Jan 2017'
```

## Solution: Manual Fix on the Server

### Step 1: Connect to the Server
First, you need to establish SSH connectivity. The servers are currently unreachable:
- 9.30.213.70 (obscode1) - Connection timeout
- 52.201.238.154 (AWS EC2) - Connection timeout

**For AWS EC2 (52.201.238.154):**
```bash
# Check if instance is running
aws ec2 describe-instances --instance-ids <instance-id> --query 'Reservations[0].Instances[0].State.Name'

# Check security group allows SSH from your IP
aws ec2 describe-security-groups --group-ids <security-group-id>

# Connect with PEM key
ssh -i instanaconnect.pem ec2-user@52.201.238.154
```

**For Existing VM (9.30.213.70):**
```bash
# Verify you're on the correct network/VPN
ping 9.30.213.70

# Try SSH
ssh root@9.30.213.70
```

### Step 2: Remove Old Docker Compose
Once connected, run these commands:

```bash
# Remove Python-based docker-compose
pip3 uninstall -y docker-compose

# Remove any existing binaries
rm -f /usr/local/bin/docker-compose
rm -f /usr/bin/docker-compose

# Verify removal
which docker-compose  # Should return nothing
```

### Step 3: Install Docker Compose v2 (Standalone Binary)
```bash
# Download Docker Compose v2.24.0
curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose

# Make it executable
chmod +x /usr/local/bin/docker-compose

# Verify installation
docker-compose --version
# Should output: Docker Compose version v2.24.0

# Verify it's a binary, not a Python script
file /usr/local/bin/docker-compose
# Should output: /usr/local/bin/docker-compose: ELF 64-bit LSB executable
```

### Step 4: Deploy Robot Shop
```bash
# Navigate to Robot Shop directory
cd /opt/robot-shop

# Login to Docker Hub (to avoid rate limits)
docker login
# Enter your Docker Hub credentials

# Pull images
docker-compose pull

# Start containers
docker-compose up -d

# Verify containers are running
docker ps

# Check logs if needed
docker-compose logs -f
```

### Step 5: Verify Deployment
```bash
# Check all containers are running
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Test web interface
curl http://localhost:8080

# Or access from browser
# http://<server-ip>:8080
```

## Alternative: Use Docker Compose Plugin
If the standalone binary doesn't work, use the Docker Compose plugin:

```bash
# Install Docker Compose plugin
mkdir -p /usr/local/lib/docker/cli-plugins
curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-linux-x86_64" -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# Use with 'docker compose' (space, not hyphen)
docker compose version
docker compose -f /opt/robot-shop/docker-compose.yml up -d
```

## Troubleshooting Network Connectivity

### For AWS EC2:
1. **Check Instance State:**
   ```bash
   aws ec2 describe-instances --filters "Name=ip-address,Values=52.201.238.154"
   ```

2. **Update Security Group:**
   ```bash
   # Get your current IP
   curl ifconfig.me
   
   # Add SSH rule for your IP
   aws ec2 authorize-security-group-ingress \
     --group-id <sg-id> \
     --protocol tcp \
     --port 22 \
     --cidr <your-ip>/32
   ```

3. **Check if instance is stopped:**
   ```bash
   aws ec2 start-instances --instance-ids <instance-id>
   ```

### For Existing VM (9.30.213.70):
1. **Verify network connectivity:**
   ```bash
   ping 9.30.213.70
   traceroute 9.30.213.70
   ```

2. **Check if you need VPN:**
   - Internal IP (9.x.x.x) suggests it's on a private network
   - You may need to connect to VPN first

3. **Verify SSH service:**
   - Contact system administrator to verify VM is running
   - Check if SSH service is active on the VM

## Next Steps After Fixing Connectivity

1. Run the updated playbook:
   ```bash
   ansible-playbook -i inventory.ini playbook.yml
   ```

2. Or apply manual fixes as described above

3. Verify Robot Shop is accessible:
   - Web UI: http://<server-ip>:8080
   - Check all services are running

4. Configure Instana monitoring (if needed)