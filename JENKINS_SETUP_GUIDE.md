# Jenkins Setup and Execution Guide

## Prerequisites

1. **Jenkins Server** - You need a Jenkins server installed and running
2. **Required Jenkins Plugins:**
   - Pipeline plugin
   - Git plugin
   - Credentials Binding plugin
   - SSH Agent plugin

## Step 1: Set Up Jenkins Credentials

Before running the pipeline, you need to add your credentials to Jenkins:

### 1.1 Add Instana API Token
1. Go to Jenkins Dashboard → Manage Jenkins → Credentials
2. Click on "System" → "Global credentials (unrestricted)"
3. Click "Add Credentials"
4. Fill in:
   - **Kind**: Secret text
   - **Secret**: Your Instana API token
   - **ID**: `instana-api-token`
   - **Description**: Instana API Token
5. Click "OK"

### 1.2 Add Instana Agent Key
1. Click "Add Credentials" again
2. Fill in:
   - **Kind**: Secret text
   - **Secret**: Your Instana Agent Key
   - **ID**: `instana-agent-key`
   - **Description**: Instana Agent Key
3. Click "OK"

### 1.3 Add SSH Key (if needed)
1. Click "Add Credentials"
2. Fill in:
   - **Kind**: SSH Username with private key
   - **Username**: root
   - **Private Key**: Enter directly or from file
   - **ID**: `vm-ssh-key`
   - **Description**: VM SSH Key
3. Click "OK"

## Step 2: Create Jenkins Pipeline Job

### 2.1 Create New Pipeline
1. Go to Jenkins Dashboard
2. Click "New Item"
3. Enter name: `Robot-Shop-Deployment`
4. Select "Pipeline"
5. Click "OK"

### 2.2 Configure Pipeline

#### General Settings
- Check "This project is parameterized" (optional, parameters are defined in Jenkinsfile)
- Add description: "Automated deployment of Robot Shop with Instana monitoring"

#### Pipeline Configuration
1. In the "Pipeline" section:
   - **Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: Your Git repository URL (e.g., `https://github.com/yourusername/robot-shop-deployment.git`)
   - **Credentials**: Select your Git credentials (if private repo)
   - **Branch**: `*/main` or `*/master`
   - **Script Path**: `Jenkinsfile`

2. Click "Save"

## Step 3: Run the Pipeline

### 3.1 First Run
1. Go to your pipeline job
2. Click "Build with Parameters"
3. Select parameters:
   - **ACTION**: `deploy` (or `plan` for dry run)
   - **SKIP_TERRAFORM**: `false`
   - **SKIP_ANSIBLE**: `false`
4. Click "Build"

### 3.2 Monitor Execution
1. Click on the build number (e.g., #1)
2. Click "Console Output" to see real-time logs
3. Watch the pipeline stages execute:
   - Checkout
   - Validate Configuration
   - Terraform Init
   - Terraform Plan
   - Terraform Apply
   - Wait for VM
   - Run Ansible Playbook
   - Deploy Load Testing
   - Verify Deployment
   - Verify Instana Integration

## Step 4: Alternative - Run Without Jenkins

If you don't have Jenkins, you can run the deployment manually:

### 4.1 Set Environment Variables
```bash
export INSTANA_API_TOKEN="your-api-token"
export INSTANA_AGENT_KEY="your-agent-key"
export INSTANA_ENDPOINT_HOST="https://ibmdevsandbox-instanaibm.instana.io"
export INSTANA_ENDPOINT_PORT="443"
export INSTANA_ZONE="robot-shop-zone"
export TF_VAR_existing_vm_ip="9.30.213.70"
```

### 4.2 Run Terraform
```bash
# Initialize Terraform
terraform init

# Plan changes
terraform plan \
    -var="instana_api_token=${INSTANA_API_TOKEN}" \
    -var="instana_agent_key=${INSTANA_AGENT_KEY}" \
    -out=tfplan

# Apply changes
terraform apply -auto-approve tfplan
```

### 4.3 Run Ansible
```bash
ansible-playbook -i inventory.ini playbook.yml \
    -e "instana_agent_key=${INSTANA_AGENT_KEY}" \
    -e "instana_endpoint_host=${INSTANA_ENDPOINT_HOST}" \
    -e "instana_endpoint_port=${INSTANA_ENDPOINT_PORT}" \
    -e "instana_zone=${INSTANA_ZONE}" \
    -v
```

### 4.4 Deploy Load Testing
```bash
ssh root@9.30.213.70 "cd /opt/robot-shop && curl -o docker-compose-load.yaml https://raw.githubusercontent.com/instana/robot-shop/master/docker-compose-load.yaml"
```

## Step 5: Verify Deployment

### 5.1 Check Robot Shop
```bash
# Access Robot Shop web interface
curl http://9.30.213.70:8080

# Or open in browser
open http://9.30.213.70:8080
```

### 5.2 Check Instana
1. Log in to Instana: https://ibmdevsandbox-instanaibm.instana.io
2. Go to Applications
3. Look for "Robot-Shop-Microservices-Daneshwari-2026"
4. Verify all services are being monitored

## Troubleshooting

### Pipeline Fails at Terraform Stage
- Check credentials are correctly configured
- Verify Instana API token and agent key are valid
- Check network connectivity to Instana endpoint

### Pipeline Fails at Ansible Stage
- Verify SSH connectivity to VM: `ssh root@9.30.213.70`
- Check VM has internet access
- Verify Docker is installed on VM

### Load Testing Not Working
- See [`FIX_LOAD_TESTING.md`](FIX_LOAD_TESTING.md) for detailed troubleshooting

## Pipeline Parameters

The Jenkinsfile supports these parameters:

- **ACTION**: 
  - `deploy` - Deploy infrastructure and application
  - `destroy` - Destroy all resources
  - `plan` - Show what would be deployed

- **SKIP_TERRAFORM**: 
  - `false` - Run Terraform (default)
  - `true` - Skip Terraform, only run Ansible

- **SKIP_ANSIBLE**: 
  - `false` - Run Ansible (default)
  - `true` - Skip Ansible, only run Terraform

## Next Steps

After successful deployment:

1. **Access Robot Shop**: http://9.30.213.70:8080
2. **Start Load Testing**: See [`FIX_LOAD_TESTING.md`](FIX_LOAD_TESTING.md)
3. **Monitor in Instana**: https://ibmdevsandbox-instanaibm.instana.io
4. **Check Alerts**: Email at Daneshwari.Naganur1@ibm.com

## Additional Resources

- [README.md](README.md) - Project overview
- [INSTANA_SETUP.md](INSTANA_SETUP.md) - Instana configuration
- [FIX_LOAD_TESTING.md](FIX_LOAD_TESTING.md) - Load testing guide
- [MANUAL_SETUP_GUIDE.md](MANUAL_SETUP_GUIDE.md) - Manual deployment steps