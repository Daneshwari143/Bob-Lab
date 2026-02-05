# Instana Agent Deployment Guide

This guide explains how to deploy and configure the Instana agent for monitoring your Robot Shop application on AWS EC2.

> **Note**: This guide covers Instana agent installation. For configuring Instana resources (application perspectives, alerts, RBAC) using Terraform, see [INSTANA_TERRAFORM_PROVIDER.md](INSTANA_TERRAFORM_PROVIDER.md).

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Configuration](#configuration)
4. [Deployment](#deployment)
5. [Verification](#verification)
6. [Monitoring Features](#monitoring-features)
7. [Advanced Configuration](#advanced-configuration)
8. [Troubleshooting](#troubleshooting)

## Overview

The Instana agent is automatically deployed to your EC2 instance through two methods:
1. **Terraform user_data**: Initial installation during VM provisioning
2. **Ansible playbook**: Configuration and verification during application deployment

### What Gets Monitored

- **Host Metrics**: CPU, memory, disk, network
- **Docker Containers**: All Robot Shop services
- **Application Performance**: Service traces and metrics
- **Infrastructure**: AWS EC2 instance details

## Prerequisites

### 1. Instana Account

You need an active Instana account. Sign up at:
- **SaaS**: https://www.instana.com/trial/
- **On-Premise**: Contact your Instana administrator

### 2. Get Instana Credentials

From your Instana dashboard:

1. Navigate to **Settings** → **Agents**
2. Click **"Installing Instana Agents"**
3. Note down:
   - **Agent Key**: Your unique agent authentication key
   - **Endpoint Host**: Your Instana backend URL (e.g., `ingress-red-saas.instana.io`)
   - **Endpoint Port**: Usually `443` for HTTPS

Example values:
```
Agent Key: abc123def456ghi789jkl012mno345pqr678
Endpoint Host: ingress-red-saas.instana.io
Endpoint Port: 443
```

## Configuration

### Step 1: Update terraform.tfvars

Add Instana configuration to your `terraform.tfvars` file:

```hcl
# AWS Configuration
aws_region        = "us-east-1"
availability_zone = "us-east-1a"
instance_type     = "t2.micro"
key_name          = "your-key-pair-name"

# Instana Agent Configuration
instana_agent_key      = "your-instana-agent-key-here"
instana_endpoint_host  = "ingress-red-saas.instana.io"
instana_endpoint_port  = "443"
instana_zone           = "robot-shop-zone"
```

### Step 2: Set Environment Variables (for Ansible)

Export Instana credentials as environment variables:

```bash
export INSTANA_AGENT_KEY="your-instana-agent-key-here"
export INSTANA_ENDPOINT_HOST="ingress-red-saas.instana.io"
export INSTANA_ENDPOINT_PORT="443"
export INSTANA_ZONE="robot-shop-zone"
```

Or add them to your shell profile (`~/.bashrc` or `~/.zshrc`):

```bash
# Instana Configuration
export INSTANA_AGENT_KEY="your-instana-agent-key-here"
export INSTANA_ENDPOINT_HOST="ingress-red-saas.instana.io"
export INSTANA_ENDPOINT_PORT="443"
export INSTANA_ZONE="robot-shop-zone"
```

Then reload:
```bash
source ~/.bashrc  # or source ~/.zshrc
```

### Step 3: Verify Configuration

Check that variables are set:

```bash
echo $INSTANA_AGENT_KEY
echo $INSTANA_ENDPOINT_HOST
```

## Deployment

### Option 1: Automated Deployment

Use the deployment script which handles everything:

```bash
./deploy.sh
```

The script will:
1. Deploy EC2 instance with Instana agent (via Terraform)
2. Configure and verify Instana agent (via Ansible)
3. Deploy Robot Shop application
4. Display monitoring status

### Option 2: Manual Deployment

#### Step 1: Deploy Infrastructure

```bash
terraform init
terraform plan
terraform apply
```

The Instana agent will be installed automatically via user_data script during VM provisioning.

#### Step 2: Wait for Instance

Wait 2-3 minutes for the instance to boot and Instana agent to initialize:

```bash
sleep 120
```

#### Step 3: Run Ansible Playbook

```bash
ansible-playbook playbook.yml
```

The playbook will:
- Verify Instana agent installation
- Configure agent with custom zone and tags
- Enable Docker monitoring
- Start the agent service

## Verification

### 1. Check Agent Status on VM

SSH to your VM:

```bash
ssh -i ~/.ssh/robot-shop-key.pem ec2-user@<public-ip>
```

Check Instana agent status:

```bash
# Check service status
sudo systemctl status instana-agent

# Check agent logs
sudo journalctl -u instana-agent -f

# Check agent configuration
cat /opt/instana/agent/etc/instana/configuration.yaml

# Check agent connectivity
curl -v http://localhost:42699/
```

### 2. Verify in Instana Dashboard

1. Log in to your Instana dashboard
2. Navigate to **Infrastructure** → **Hosts**
3. Look for your EC2 instance (should appear within 1-2 minutes)
4. Verify:
   - Host is visible with correct zone (`robot-shop-zone`)
   - Tags are applied: `robot-shop`, `terraform-managed`, `aws-ec2`, `docker-host`
   - Docker containers are detected (11 containers)

### 3. Check Docker Monitoring

In Instana dashboard:
1. Go to **Infrastructure** → **Docker**
2. Verify all Robot Shop containers are visible:
   - web
   - catalogue
   - user
   - cart
   - shipping
   - payment
   - ratings
   - dispatch
   - mongodb
   - redis
   - rabbitmq
   - mysql

### 4. Verify Application Monitoring

1. Navigate to **Applications** in Instana
2. Look for Robot Shop services
3. Check for:
   - Service traces
   - API endpoints
   - Database queries
   - Service dependencies

## Monitoring Features

### Host Monitoring

The Instana agent monitors:
- **CPU**: Usage, load average, processes
- **Memory**: Used, free, cached, swap
- **Disk**: I/O, space usage, latency
- **Network**: Traffic, connections, errors

### Docker Monitoring

Automatic monitoring of:
- Container metrics (CPU, memory, network)
- Container lifecycle events
- Image information
- Volume usage

### Application Performance Monitoring (APM)

For Robot Shop services:
- **Traces**: End-to-end request tracing
- **Metrics**: Response times, error rates
- **Dependencies**: Service-to-service communication
- **Database**: Query performance

### Custom Tags and Zones

The deployment configures:
- **Zone**: `robot-shop-zone` (customizable)
- **Tags**: 
  - `robot-shop`: Application identifier
  - `terraform-managed`: Infrastructure as code
  - `aws-ec2`: Cloud provider
  - `docker-host`: Container platform

## Troubleshooting

### Agent Not Appearing in Dashboard

**Check 1: Verify agent is running**
```bash
sudo systemctl status instana-agent
```

**Check 2: Check agent logs**
```bash
sudo journalctl -u instana-agent -n 100
```

**Check 3: Verify connectivity**
```bash
# Test connection to Instana backend
curl -v https://<instana-endpoint-host>:<port>

# Check agent key
grep -r "agent.key" /opt/instana/agent/etc/
```

**Check 4: Restart agent**
```bash
sudo systemctl restart instana-agent
sudo systemctl status instana-agent
```

### Agent Key Issues

**Error**: "Invalid agent key" or "Authentication failed"

**Solution**:
1. Verify agent key in Instana dashboard
2. Check `terraform.tfvars` has correct key
3. Verify environment variable:
   ```bash
   echo $INSTANA_AGENT_KEY
   ```
4. Redeploy with correct key:
   ```bash
   terraform apply
   ansible-playbook playbook.yml
   ```

### Network Connectivity Issues

**Error**: "Cannot connect to Instana backend"

**Solution**:
1. Check security group allows outbound HTTPS (port 443)
2. Verify endpoint host is correct
3. Test connectivity:
   ```bash
   telnet <instana-endpoint-host> 443
   curl -v https://<instana-endpoint-host>
   ```

### Docker Containers Not Monitored

**Check 1: Verify Docker plugin is enabled**
```bash
cat /opt/instana/agent/etc/instana/configuration.yaml | grep -A 5 docker
```

**Check 2: Restart agent after Docker starts**
```bash
sudo systemctl restart instana-agent
```

**Check 3: Check agent has Docker socket access**
```bash
ls -la /var/run/docker.sock
sudo usermod -aG docker instana-agent
```

### Agent Configuration Not Applied

**Solution**: Restart the agent after configuration changes
```bash
sudo systemctl restart instana-agent
```

### High Resource Usage

If Instana agent uses too much CPU/memory:

1. **Adjust agent configuration** (`/opt/instana/agent/etc/instana/configuration.yaml`):
   ```yaml
   com.instana.agent:
     mode: APM  # Use APM mode instead of INFRASTRUCTURE
   ```

2. **Disable unnecessary sensors**:
   ```yaml
   com.instana.plugin.some-plugin:
     enabled: false
   ```

3. **Restart agent**:
   ```bash
   sudo systemctl restart instana-agent
   ```

## Advanced Configuration

### Custom Agent Configuration

Edit `/opt/instana/agent/etc/instana/configuration.yaml`:

```yaml
# Custom zone and tags
com.instana.plugin.generic.hardware:
  enabled: true
  availability-zone: 'production-zone'

com.instana.plugin.host:
  tags:
    - 'environment:production'
    - 'team:platform'
    - 'application:robot-shop'

# Docker monitoring with custom settings
com.instana.plugin.docker:
  enabled: true
  poll_rate: 5  # seconds

# Enable additional plugins
com.instana.plugin.nginx:
  enabled: true

com.instana.plugin.mysql:
  enabled: true
```

### Multiple Zones

To deploy multiple environments with different zones:

```hcl
# terraform.tfvars for production
instana_zone = "robot-shop-production"

# terraform.tfvars for staging
instana_zone = "robot-shop-staging"
```

### Agent Proxy Configuration

If using a proxy:

```yaml
# In configuration.yaml
com.instana.agent:
  proxy:
    type: HTTP
    host: proxy.example.com
    port: 8080
    user: username
    password: password
```

## Security Best Practices

1. **Protect Agent Key**: Never commit agent key to version control
   ```bash
   # Add to .gitignore
   echo "terraform.tfvars" >> .gitignore
   ```

2. **Use Environment Variables**: Store sensitive data in environment variables

3. **Restrict Security Group**: Limit Instana agent ports to necessary IPs

4. **Rotate Keys**: Regularly rotate agent keys in Instana dashboard

5. **Use IAM Roles**: For AWS, use IAM roles instead of access keys when possible

## Useful Commands

```bash
# Agent service management
sudo systemctl start instana-agent
sudo systemctl stop instana-agent
sudo systemctl restart instana-agent
sudo systemctl status instana-agent

# View logs
sudo journalctl -u instana-agent -f
sudo journalctl -u instana-agent --since "10 minutes ago"

# Check configuration
cat /opt/instana/agent/etc/instana/configuration.yaml

# Test agent API
curl http://localhost:42699/

# Check agent version
/opt/instana/agent/bin/instana-agent --version

# Manual agent update
sudo /opt/instana/agent/bin/update-agent.sh
```

## Advanced Configuration

### Terraform Provider for Instana

For advanced Instana configuration using Terraform, including:
- Application perspectives
- Smart alerts and custom events
- RBAC roles and permissions
- Alert channels (email, Slack, PagerDuty)
- SLI/SLO configurations
- API token management

See the comprehensive guide: **[INSTANA_TERRAFORM_PROVIDER.md](INSTANA_TERRAFORM_PROVIDER.md)**

This allows you to manage all Instana configuration as code alongside your infrastructure.

## Resources

- **Instana Terraform Provider Guide**: [INSTANA_TERRAFORM_PROVIDER.md](INSTANA_TERRAFORM_PROVIDER.md)
- **Instana Documentation**: https://www.ibm.com/docs/en/instana-observability
- **Agent Installation**: https://www.ibm.com/docs/en/instana-observability/current?topic=instana-installing-host-agent
- **Docker Monitoring**: https://www.ibm.com/docs/en/instana-observability/current?topic=technologies-monitoring-docker
- **Configuration Reference**: https://www.ibm.com/docs/en/instana-observability/current?topic=agent-configuration
- **Terraform Provider**: https://registry.terraform.io/providers/gessnerfl/instana/latest/docs

## Support

For issues or questions:
1. Check Instana agent logs
2. Review this troubleshooting guide
3. Contact Instana support: https://www.ibm.com/mysupport
4. Community forum: https://www.ibm.com/community/instana/

---

**Last Updated**: January 2026
**Version**: 1.0