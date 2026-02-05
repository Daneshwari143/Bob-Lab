# Network Connectivity Troubleshooting

## Current Issue
Server **9.30.213.70** (obscode1) is unreachable:
- 100% packet loss on ping
- SSH connection timeout

## Why 9.30.213.70 is Unreachable

The IP address `9.30.213.70` is in a **private/internal network range** (9.x.x.x). This means:

1. **Not directly accessible from the internet**
2. **Requires VPN or internal network access**
3. **Likely on IBM Cloud or corporate network**

## Immediate Actions Required

### Option 1: Connect to VPN First (Most Likely Solution)
```bash
# 1. Connect to your corporate/IBM VPN
# 2. Then try ping again
ping 9.30.213.70

# 3. If ping works, try SSH
ssh root@9.30.213.70
```

### Option 2: Deploy Locally for Testing
If you can't access the VM right now, test Robot Shop locally:

```bash
# 1. Ensure Docker Desktop is running
docker --version

# 2. Create docker-compose.yml locally
mkdir -p ~/robot-shop-test
cd ~/robot-shop-test

# 3. Download Robot Shop compose files
curl -o docker-compose.yml https://raw.githubusercontent.com/instana/robot-shop/master/docker-compose.yaml
curl -o docker-compose-load.yaml https://raw.githubusercontent.com/instana/robot-shop/master/docker-compose-load.yaml

# 4. Start Robot Shop
docker-compose up -d

# 5. Access web interface
open http://localhost:8080
```

## Recommended Approach

### Step 1: Connect to VPN

The VM at 9.30.213.70 is on a private network. You must:
1. **Connect to your corporate/IBM VPN**
2. **Verify connectivity**: `ping 9.30.213.70`
3. **Test SSH**: `ssh root@9.30.213.70`

### Step 2: Verify Inventory Configuration

Your current inventory.ini is correct:
```ini
[vm]
9.30.213.70 ansible_user=root ansible_password=pwd@FYRE1234567

[local]
localhost ansible_connection=local
```

### Step 3: Manual Fix on the Server

Once you can SSH to the server, run these commands to fix docker-compose:

```bash
# Remove old docker-compose
sudo pip3 uninstall -y docker-compose
sudo rm -f /usr/local/bin/docker-compose /usr/bin/docker-compose

# Install Docker Compose v2
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify
docker-compose --version
file /usr/local/bin/docker-compose

# Deploy Robot Shop
cd /opt/robot-shop
docker login  # Enter Docker Hub credentials
docker-compose pull
docker-compose up -d
docker ps
```

## Why This is Taking Time

The SSH connection is **timing out** (not refusing connection), which means:
- Packets are being sent but not reaching the destination
- No response from the server
- Network routing issue or firewall blocking

**This is NOT a server issue** - it's a **network connectivity issue**.

## Next Steps

1. **Connect to VPN** - The 9.30.213.70 IP is on an internal network
2. **Verify connectivity** - `ping 9.30.213.70` should work after VPN connection
3. **Run the playbook** - Once connected: `ansible-playbook -i inventory.ini playbook.yml`
4. **Or manual fix** - Follow the commands above if you prefer manual deployment
5. **Contact network admin** - If VPN doesn't resolve the connectivity issue

Once you're connected to the VPN and can access the server, the deployment will proceed successfully.