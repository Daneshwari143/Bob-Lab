# Docker Hub Rate Limit Solution Guide

## Problem
You've hit Docker Hub's unauthenticated pull rate limit (100 pulls per 6 hours per IP address).

## Current Status
- ✅ VM configured: 9.30.213.70 (Ubuntu 22.04)
- ✅ Docker installed and running
- ✅ Docker Compose v2 installed
- ✅ Robot Shop configuration ready at /opt/robot-shop
- ❌ Cannot pull images due to rate limit

## Solution: Create Free Docker Hub Account

### Step 1: Create Docker Hub Account (2 minutes)
1. Go to: https://hub.docker.com/signup
2. Fill in:
   - Username: (choose any)
   - Email: your email
   - Password: (choose secure password)
3. Verify email
4. Free account gives you 200 pulls per 6 hours (vs 100 unauthenticated)

### Step 2: Login on VM (1 minute)
```bash
# SSH to VM
ssh root@9.30.213.70
# Password: pwd@FYRE1234567

# Login to Docker Hub
docker login
# Enter your Docker Hub username
# Enter your Docker Hub password
```

### Step 3: Pull Images and Start Robot Shop (3-5 minutes)
```bash
# Navigate to Robot Shop directory
cd /opt/robot-shop

# Pull all images (now authenticated)
docker-compose pull

# Start all services
docker-compose up -d

# Verify all 11 containers are running
docker ps

# Expected output: 11 containers
# - mongodb
# - redis
# - rabbitmq
# - catalogue
# - user
# - cart
# - mysql
# - shipping
# - ratings
# - payment
# - dispatch
# - web
```

### Step 4: Access Robot Shop
Open browser: http://9.30.213.70:8080

## Alternative: Wait for Rate Limit Reset

If you don't want to create an account, wait 6 hours and run:
```bash
ssh root@9.30.213.70
cd /opt/robot-shop
docker-compose up -d
```

## Troubleshooting

### If containers fail to start:
```bash
# Check logs
docker-compose logs

# Check specific container
docker logs <container_name>

# Restart services
docker-compose restart

# Stop and start fresh
docker-compose down
docker-compose up -d
```

### If port 8080 is not accessible:
```bash
# Check if web container is running
docker ps | grep web

# Check firewall
sudo ufw status

# Check if port is listening
netstat -tuln | grep 8080
```

### If images still won't pull after login:
```bash
# Verify login
docker info | grep Username

# Try pulling individual images
docker pull redis:6.2-alpine
docker pull rabbitmq:3.11-management-alpine
docker pull robotshop/rs-mongodb:latest
# ... etc
```

## Complete Manual Deployment Commands

If you want to do everything manually:

```bash
# 1. SSH to VM
ssh root@9.30.213.70

# 2. Login to Docker Hub (if you have account)
docker login

# 3. Navigate to directory
cd /opt/robot-shop

# 4. Pull images
docker-compose pull

# 5. Start services
docker-compose up -d

# 6. Check status
docker ps
docker-compose ps

# 7. View logs
docker-compose logs -f

# 8. Test web interface
curl http://localhost:8080

# 9. Access from browser
# http://9.30.213.70:8080
```

## Summary

**Fastest Solution:** Create free Docker Hub account (5 minutes total)
- Signup: 2 minutes
- Login on VM: 1 minute  
- Pull and start: 3 minutes
- Total: ~6 minutes to fully working Robot Shop

**Alternative:** Wait 6 hours for rate limit reset (no account needed)

## Next Steps After Deployment

Once Robot Shop is running:

1. **Verify all services:**
   ```bash
   docker ps
   # Should show 11 containers all "Up"
   ```

2. **Test the application:**
   - Open http://9.30.213.70:8080
   - Browse products
   - Add items to cart
   - Test checkout flow

3. **Configure Instana monitoring** (if needed):
   - Set environment variables for Instana
   - Re-run Ansible playbook for Instana agent installation

4. **Monitor logs:**
   ```bash
   docker-compose logs -f
   ```

## Contact

If you continue to have issues after creating Docker Hub account, the problem may be:
- Network connectivity
- Firewall rules
- VM resources (though Ubuntu 22.04 should be fine)
- Docker daemon issues

Check logs and system resources:
```bash
docker info
free -h
df -h
systemctl status docker