# Docker Cleanup Guide

This guide provides commands to remove running containers and images in your Docker environment.

## Remove Running Containers

### Stop and Remove a Specific Container
```bash
# Stop a running container
docker stop <container_id_or_name>

# Remove the stopped container
docker rm <container_id_or_name>

# Stop and remove in one command
docker rm -f <container_id_or_name>
```

### Stop and Remove All Running Containers
```bash
# Stop all running containers
docker stop $(docker ps -q)

# Remove all stopped containers
docker rm $(docker ps -a -q)

# Stop and remove all containers in one command
docker rm -f $(docker ps -a -q)
```

### Using Docker Compose
If you're using Docker Compose:
```bash
# Stop and remove containers defined in docker-compose.yml
docker-compose down

# Stop and remove containers, networks, and volumes
docker-compose down -v

# Stop and remove containers, networks, volumes, and images
docker-compose down --rmi all -v
```

## Remove Docker Images

### Remove a Specific Image
```bash
# Remove by image ID
docker rmi <image_id>

# Remove by image name and tag
docker rmi <image_name>:<tag>

# Force remove (even if containers are using it)
docker rmi -f <image_id>
```

### Remove All Images
```bash
# Remove all images
docker rmi $(docker images -q)

# Force remove all images
docker rmi -f $(docker images -q)
```

### Remove Dangling Images
Dangling images are layers that have no relationship to tagged images:
```bash
# Remove dangling images
docker image prune

# Remove dangling images without confirmation
docker image prune -f
```

### Remove All Unused Images
```bash
# Remove all unused images (not just dangling)
docker image prune -a

# Remove all unused images without confirmation
docker image prune -a -f
```

## Complete Cleanup Commands

### Clean Everything (Nuclear Option)
```bash
# Stop all containers
docker stop $(docker ps -a -q)

# Remove all containers
docker rm $(docker ps -a -q)

# Remove all images
docker rmi -f $(docker images -q)

# Remove all volumes
docker volume rm $(docker volume ls -q)

# Remove all networks (except default ones)
docker network prune -f
```

### Docker System Prune (Recommended)
```bash
# Remove all stopped containers, unused networks, dangling images, and build cache
docker system prune

# Remove everything including unused images
docker system prune -a

# Remove everything including volumes
docker system prune -a --volumes

# Without confirmation prompt
docker system prune -a -f
```

## Useful Commands for Inspection

### List Running Containers
```bash
docker ps
```

### List All Containers (including stopped)
```bash
docker ps -a
```

### List All Images
```bash
docker images
```

### List All Images with Sizes
```bash
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
```

### Check Disk Usage
```bash
docker system df
```

### Detailed Disk Usage
```bash
docker system df -v
```

## Selective Cleanup

### Remove Containers by Status
```bash
# Remove all exited containers
docker rm $(docker ps -a -f status=exited -q)

# Remove all created containers
docker rm $(docker ps -a -f status=created -q)
```

### Remove Images by Pattern
```bash
# Remove images matching a pattern
docker rmi $(docker images | grep "pattern" | awk '{print $3}')

# Example: Remove all images with "robot-shop" in name
docker rmi $(docker images | grep "robot-shop" | awk '{print $3}')
```

### Remove Old Images
```bash
# Remove images older than 24 hours
docker image prune -a --filter "until=24h"
```

## Safety Tips

1. **Always check what you're removing first:**
   ```bash
   docker ps -a  # Check containers
   docker images # Check images
   ```

2. **Use `--dry-run` when available** to see what would be removed

3. **Backup important data** before running cleanup commands

4. **Be careful with `-f` (force) flag** - it bypasses confirmations

5. **For production environments**, use selective cleanup instead of nuclear options

## Quick Reference Script

Create a cleanup script [`cleanup_docker.sh`](cleanup_docker.sh):
```bash
#!/bin/bash

echo "Docker Cleanup Script"
echo "===================="

# Show current usage
echo -e "\nCurrent Docker disk usage:"
docker system df

# Stop all running containers
echo -e "\nStopping all running containers..."
docker stop $(docker ps -q) 2>/dev/null || echo "No running containers"

# Remove all containers
echo -e "\nRemoving all containers..."
docker rm $(docker ps -a -q) 2>/dev/null || echo "No containers to remove"

# Remove all images
echo -e "\nRemoving all images..."
docker rmi -f $(docker images -q) 2>/dev/null || echo "No images to remove"

# Clean up system
echo -e "\nCleaning up system..."
docker system prune -a -f --volumes

# Show final usage
echo -e "\nFinal Docker disk usage:"
docker system df

echo -e "\nCleanup complete!"
```

Make it executable:
```bash
chmod +x cleanup_docker.sh
./cleanup_docker.sh
```

## For Your Robot Shop Project

Based on your project structure, here are specific commands:

### Stop Robot Shop Containers
```bash
# If using docker-compose
docker-compose down

# If containers are running individually
docker stop $(docker ps | grep robot-shop | awk '{print $1}')
```

### Remove Robot Shop Images
```bash
# Remove robot-shop images
docker rmi $(docker images | grep robot-shop | awk '{print $3}')
```

### Complete Robot Shop Cleanup
```bash
# Stop and remove everything related to robot-shop
docker-compose down --rmi all -v
docker system prune -f