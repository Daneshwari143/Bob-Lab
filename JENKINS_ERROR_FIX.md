# Jenkins Pipeline Setup - Complete Guide

## ✅ Issues Fixed

### 1. Git Repository Setup
- **Problem**: Large Terraform provider files (724 MB) exceeded GitHub's 100 MB limit
- **Solution**: 
  - Created `.gitignore` to exclude `.terraform/`, `*.tfstate`, `*.pem` files
  - Reset Git repository and pushed clean version
  - Repository URL: https://github.com/Daneshwari143/Bob-Lab.git

### 2. Terraform Installation
- **Problem**: Jenkins agent (Mac) didn't have Terraform installed
- **Solution**: Installing Terraform via Homebrew: `brew install terraform`

## 📋 Next Steps

### Step 1: Verify Terraform Installation
```bash
terraform version
```

### Step 2: Configure Jenkins Job
1. Go to Jenkins → **Robot shop deployment** → **Configure**
2. Under **Pipeline** section:
   - Definition: **Pipeline script from SCM**
   - SCM: **Git**
   - Repository URL: **https://github.com/Daneshwari143/Bob-Lab.git**
   - Branch Specifier: ***/main**
   - Script Path: **Jenkinsfile**
3. Click **Save**

### Step 3: Run Pipeline
1. Click **"Build Now"**
2. Monitor the pipeline execution

## 🎯 Expected Pipeline Flow

```
1. Checkout Code from Git ✓
   └─> All Terraform files available in workspace

2. Terraform - Instana Resources
   ├─> terraform init
   ├─> terraform plan
   └─> terraform apply
       ├─> Create Application Perspective
       ├─> Create 5 Custom Alert Events
       ├─> Create Email Alert Channel
       ├─> Create Alert Configuration
       └─> Create API Token (RBAC)

3. Ansible - Deploy Robot Shop
   ├─> Install Docker & Docker Compose
   ├─> Deploy Robot Shop containers
   └─> Install Instana agent

4. Deploy Load Testing
   └─> Start load generation script
```

## 📁 Files in Repository

### Configuration Files
- `instana.tf` - Instana resources (Application + Alerts + RBAC)
- `variables.tf` - Variable definitions
- `terraform.tfvars` - Variable values (VM IP: 9.30.220.114)
- `outputs.tf` - Output definitions
- `playbook.yml` - Ansible playbook for deployment
- `inventory.ini` - Ansible inventory (VM: 9.30.220.114)
- `Jenkinsfile` - Jenkins pipeline definition

### Documentation
- `README.md` - Project overview
- `INSTANA_TERRAFORM_DEPLOYMENT.md` - Instana setup guide
- `JENKINS_SETUP_GUIDE.md` - Jenkins configuration guide
- Various troubleshooting guides

### Scripts
- `create_instana_application.sh` - Standalone script to create Instana app
- `check_prerequisites.sh` - Prerequisite checker

## 🔧 Current Configuration

- **VM IP**: 9.30.220.114
- **Instana API Token**: -M4zm_2RQpOIMgQvU3dj8A
- **Instana Endpoint**: instana.ibm.com
- **Application Name**: Robot-Shop-Microservices-Daneshwari-2026
- **Alert Email**: Daneshwari.Naganur1@ibm.com

## ⚠️ Important Notes

1. **Sensitive Files Excluded**: `.gitignore` prevents committing:
   - `.terraform/` directory (large provider binaries)
   - `*.tfstate` files (may contain sensitive data)
   - `*.pem` files (SSH keys)

2. **Terraform State**: State files are local only, not in Git

3. **Jenkins Credentials**: Ensure these are configured in Jenkins:
   - `instana-api-token` (Instana API token)
   - `vm-ssh-key` (SSH key for VM access)

## 🐛 Troubleshooting

### If Terraform fails in Jenkins:
```bash
# Verify Terraform is in PATH
which terraform
terraform version
```

### If Git checkout fails:
- Verify repository URL in Jenkins configuration
- Check Git credentials if repository is private

### If Ansible fails:
- Verify SSH key is configured in Jenkins credentials
- Test SSH connection: `ssh -i key.pem ubuntu@9.30.220.114`

## 📞 Support

If issues persist, check:
1. Jenkins console output for detailed error messages
2. Terraform logs: `terraform.log`
3. Ansible verbose output: Add `-vvv` flag in Jenkinsfile