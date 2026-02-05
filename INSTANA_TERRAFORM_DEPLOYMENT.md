# Instana Deployment with Terraform for Existing VM

This guide shows how to deploy Instana agent to an existing VM (9.30.213.70) and configure Instana monitoring resources using Terraform.

## Prerequisites

- Existing VM: 9.30.213.70 (Ubuntu 22.04)
- SSH access: root / pwd@FYRE1234567
- Instana account with API token
- Terraform installed on your local machine

## Architecture

```
Your MacBook (Terraform)
    ↓ SSH (remote-exec)
Existing VM (9.30.213.70)
    ↓ Installs
Instana Agent
    ↓ Reports to
Instana Backend (ingress-orange-saas.instana.io)
```

## Configuration Files

### 1. instana_existing_vm.tf
Deploys Instana agent to existing VM using null_resource with remote-exec provisioner.

### 2. instana.tf
Configures Instana resources:
- Application Perspective
- Smart Alerts (Error Rate, Response Time)
- RBAC (API Token)
- Alert Channels (Email)
- Alert Configuration

## Deployment Steps

### Step 1: Verify Configuration

Check `terraform.tfvars`:
```hcl
# Instana Agent Configuration
instana_agent_key      = "uBp4GXpZQpKrHxMXNcvInQ"
instana_endpoint_host  = "ingress-orange-saas.instana.io"
instana_endpoint_port  = "443"
instana_zone           = "robot-shop-zone"

# Instana Terraform Provider
instana_api_token      = "lDKVCHodR7O1UObsi2FRAA"
instana_endpoint       = "ibmdevsandbox-instanaibm.instana.io"
enable_instana_config  = true
```

### Step 2: Initialize Terraform

```bash
# Initialize Terraform providers
terraform init

# This will download:
# - Instana provider (~3.0)
# - Null provider (for remote-exec)
```

### Step 3: Plan Deployment

```bash
# Review what will be created
terraform plan

# Expected resources:
# - null_resource.deploy_instana_agent (agent installation)
# - instana_application_config.robot_shop (app perspective)
# - instana_custom_event_specification.high_error_rate (alert)
# - instana_custom_event_specification.high_response_time (alert)
# - instana_api_token.robot_shop_readonly (RBAC token)
# - instana_alerting_channel.robot_shop_email (email channel)
# - instana_alerting_config.robot_shop (alert config)
```

### Step 4: Deploy Everything

```bash
# Deploy Instana agent and configure monitoring
terraform apply

# Type 'yes' when prompted
```

### Step 5: Verify Deployment

```bash
# Check Terraform outputs
terraform output

# Expected outputs:
# - instana_agent_deployed
# - instana_agent_check_command
# - instana_readonly_token (sensitive)
# - instana_application_id
```

## What Gets Deployed

### On the VM (9.30.213.70):

1. **Instana Agent Installation**
   - Downloads agent from setup.instana.io
   - Installs with agent key
   - Configures endpoint and zone
   - Enables Docker monitoring
   - Starts agent service

2. **Agent Configuration** (`/opt/instana/agent/etc/instana/configuration.yaml`)
   ```yaml
   com.instana.plugin.generic.hardware:
     enabled: true
     availability-zone: 'robot-shop-zone'
   
   com.instana.plugin.host:
     tags:
       - 'robot-shop'
       - 'terraform-managed'
       - 'existing-vm'
       - 'docker-host'
   
   com.instana.plugin.docker:
     enabled: true
   ```

### In Instana Backend:

1. **Application Perspective**
   - Name: "Robot Shop Application"
   - Scope: Include all downstream services
   - Filter: `service.name CONTAINS 'robot-shop'`

2. **Smart Alerts**
   
   **High Error Rate:**
   - Name: "Robot Shop - High Error Rate"
   - Query: `entity.type:service AND entity.tag.application:robot-shop`
   - Rule: `entity.erroneous.calls.rate`
   - Severity: Warning

   **High Response Time:**
   - Name: "Robot Shop - High Response Time"
   - Query: `entity.type:service AND entity.tag.application:robot-shop`
   - Rule: `entity.latency`
   - Severity: Warning

3. **RBAC - API Token**
   - Name: "robot-shop-readonly-token"
   - Permissions: Read-only
   - Can view: Audit logs, logs, trace details
   - Cannot configure anything

4. **Alert Channel**
   - Type: Email
   - Recipient: Daneshwari.Naganur1@ibm.com

5. **Alert Configuration**
   - Links alerts to email channel
   - Filters: `entity.tag.application:robot-shop`
   - Event types: incident, critical, warning

## Verification

### Check Agent on VM

```bash
# SSH to VM
ssh root@9.30.213.70

# Check agent status
systemctl status instana-agent

# Check agent logs
journalctl -u instana-agent -n 50

# Check agent configuration
cat /opt/instana/agent/etc/instana/configuration.yaml

# Check if agent is reporting
curl http://localhost:42699/com.instana.plugin.generic.hardware
```

### Check in Instana UI

1. **Agent Registration**
   - Go to: Infrastructure → Hosts
   - Look for: obscode1 or 9.30.213.70
   - Zone: robot-shop-zone
   - Tags: robot-shop, terraform-managed, existing-vm, docker-host

2. **Application Perspective**
   - Go to: Applications
   - Find: "Robot Shop Application"
   - Should show all Robot Shop services

3. **Smart Alerts**
   - Go to: Events → Custom Events
   - Find: "Robot Shop - High Error Rate"
   - Find: "Robot Shop - High Response Time"

4. **API Token**
   - Go to: Settings → API Tokens
   - Find: "robot-shop-readonly-token"
   - Copy token for use in CI/CD

5. **Alert Channel**
   - Go to: Settings → Alert Channels
   - Find: "Robot Shop Alert Email"
   - Verify email: Daneshwari.Naganur1@ibm.com

## Troubleshooting

### Agent Installation Fails

```bash
# Check SSH connectivity
ssh root@9.30.213.70

# Check if agent installer is accessible
curl -I https://setup.instana.io/agent

# Check VM has internet access
ping -c 3 8.8.8.8

# Manually install agent
curl -o /tmp/setup_agent.sh https://setup.instana.io/agent
chmod +x /tmp/setup_agent.sh
/tmp/setup_agent.sh -a uBp4GXpZQpKrHxMXNcvInQ \
  -t dynamic \
  -e ingress-orange-saas.instana.io:443 \
  -s -y
```

### Agent Not Reporting

```bash
# Check agent service
systemctl status instana-agent

# Restart agent
systemctl restart instana-agent

# Check agent logs
journalctl -u instana-agent -f

# Check network connectivity to Instana
telnet ingress-orange-saas.instana.io 443
```

### Terraform Provider Errors

```bash
# Verify API token is correct
curl -H "Authorization: apiToken lDKVCHodR7O1UObsi2FRAA" \
  https://ibmdevsandbox-instanaibm.instana.io/api/infrastructure-monitoring/snapshots

# Re-initialize Terraform
rm -rf .terraform .terraform.lock.hcl
terraform init
```

## Update Configuration

### Update Agent Configuration

```bash
# Modify instana_existing_vm.tf
# Change configuration in the remote-exec inline script

# Apply changes
terraform apply -target=null_resource.deploy_instana_agent

# Or manually on VM
ssh root@9.30.213.70
vi /opt/instana/agent/etc/instana/configuration.yaml
systemctl restart instana-agent
```

### Update Instana Resources

```bash
# Modify instana.tf
# Change application perspective, alerts, etc.

# Apply specific resource
terraform apply -target=instana_application_config.robot_shop

# Or apply all Instana resources
terraform apply
```

## Cleanup

### Remove Instana Agent from VM

```bash
# Destroy null_resource (stops agent)
terraform destroy -target=null_resource.deploy_instana_agent

# Manually remove agent from VM
ssh root@9.30.213.70
systemctl stop instana-agent
systemctl disable instana-agent
rm -rf /opt/instana
```

### Remove Instana Resources

```bash
# Remove all Instana configuration
terraform destroy -target=instana_application_config.robot_shop
terraform destroy -target=instana_custom_event_specification.high_error_rate
terraform destroy -target=instana_custom_event_specification.high_response_time
terraform destroy -target=instana_api_token.robot_shop_readonly
terraform destroy -target=instana_alerting_channel.robot_shop_email
terraform destroy -target=instana_alerting_config.robot_shop
```

## Best Practices

1. **Keep Credentials Secure**
   - Don't commit terraform.tfvars to git
   - Use environment variables for sensitive data
   - Use Terraform Cloud for state encryption

2. **Version Control**
   - Commit .tf files to git
   - Use .gitignore for sensitive files
   - Tag releases for tracking

3. **State Management**
   - Use remote state (S3, Terraform Cloud)
   - Enable state locking
   - Regular state backups

4. **Testing**
   - Test in dev environment first
   - Use terraform plan before apply
   - Verify in Instana UI after deployment

5. **Monitoring**
   - Check agent status regularly
   - Review alert configurations
   - Monitor alert notifications

## Additional Resources

- [Instana Terraform Provider Docs](https://registry.terraform.io/providers/instana/instana/latest/docs)
- [Instana Agent Installation](https://www.ibm.com/docs/en/instana-observability/current?topic=instana-installing-host-agent)
- [Instana API Documentation](https://instana.github.io/openapi/)

## Support

For issues:
1. Check Terraform logs: `terraform apply -debug`
2. Check agent logs: `journalctl -u instana-agent -n 100`
3. Check Instana UI: Infrastructure → Hosts
4. Contact Instana support with agent ID

---

**Created with Terraform and Bob** 🤖