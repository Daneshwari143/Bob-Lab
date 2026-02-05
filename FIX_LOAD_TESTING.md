# Fix Load Testing Command Issue

## Problem
You may see warnings about multiple config files:
```
WARN[0000] Found multiple config files with supported names: /opt/robot-shop/docker-compose.yml, /opt/robot-shop/docker-compose.yaml
```

This happens because you have both `docker-compose.yml` and `docker-compose.yaml` files.

## Quick Fix: Remove the Duplicate

```bash
cd /opt/robot-shop
# Remove the .yaml file (keep only .yml)
rm docker-compose.yaml
```

After removing the duplicate, the warnings will stop.

## Step 1: Download docker-compose-load.yaml (REQUIRED)

The file is missing on your server. Download it now:

```bash
cd /opt/robot-shop
curl -o docker-compose-load.yaml https://raw.githubusercontent.com/instana/robot-shop/master/docker-compose-load.yaml
```

**Note:** The URL uses `/master/` not `.git/master/` for raw file downloads.

Verify the file was downloaded:
```bash
ls -la docker-compose-load.yaml
cat docker-compose-load.yaml
```

## Step 2: Solution Options

### Option 1: Use Correct Filename (Recommended)
Use the correct filename in your command:

```bash
cd /opt/robot-shop
docker-compose -f docker-compose.yml -f docker-compose-load.yaml up -d
```

### Option 2: Create a Symlink
Create a symlink so both `.yml` and `.yaml` work:

```bash
cd /opt/robot-shop
ln -s docker-compose.yml docker-compose.yaml
docker-compose -f docker-compose.yaml -f docker-compose-load.yaml up -d
```

### Option 3: Rename the File
Rename the file to use `.yaml` extension:

```bash
cd /opt/robot-shop
mv docker-compose.yml docker-compose.yaml
docker-compose -f docker-compose.yaml -f docker-compose-load.yaml up -d
```

## Verify Files Exist
Before running the command, verify both files exist:

```bash
cd /opt/robot-shop
ls -la docker-compose*
```

You should see:
- `docker-compose.yml` (main compose file)
- `docker-compose-load.yaml` (load testing compose file)

## Complete Command Reference

### Start with Load Testing

You need to set environment variables for the load generator:

```bash
cd /opt/robot-shop
export REPO=robotshop
export TAG=latest
docker-compose -f docker-compose.yml -f docker-compose-load.yaml up -d
```

Or in a single command:
```bash
cd /opt/robot-shop
REPO=robotshop TAG=latest docker-compose -f docker-compose.yml -f docker-compose-load.yaml up -d
```

### Start without Load Testing
```bash
cd /opt/robot-shop
docker-compose up -d
```

### Stop Load Generator Only (Keep Robot Shop Running)
```bash
cd /opt/robot-shop
docker-compose -f docker-compose-load.yaml down
```

This stops only the load generator container while keeping all Robot Shop services running.

### Stop All Services
```bash
cd /opt/robot-shop
docker-compose -f docker-compose.yml -f docker-compose-load.yaml down
```

### View Logs
```bash
cd /opt/robot-shop

### Check Running Containers
```bash
cd /opt/robot-shop
docker-compose ps
```

### Restart Robot Shop Without Load Generator
```bash
cd /opt/robot-shop
docker-compose up -d
```
docker-compose -f docker-compose.yml -f docker-compose-load.yaml logs -f