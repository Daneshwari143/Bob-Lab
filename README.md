# Robot Shop Application Deployment with Terraform + Ansible

Deploy the Robot Shop microservices application on AWS EC2 using Terraform and Ansible with Docker, including Instana monitoring.

## Overview

This project automates the deployment of the [Robot Shop](https://github.com/instana/robot-shop.git) application, a sample microservices e-commerce application. The deployment includes:

- **Infrastructure**: AWS EC2 instance provisioned with Terraform
- **Configuration**: Docker and Docker Compose installed via Ansible
- **Application**: Complete Robot Shop microservices stack deployed with Docker Compose
- **Monitoring**: Instana agent for comprehensive observability (optional)

### Robot Shop Architecture

The application consists of 11 microservices:
- **Web** - Frontend (Nginx + AngularJS) - Port 8080
- **Catalogue** - Product catalog service
- **User** - User management service
- **Cart** - Shopping cart service
- **Shipping** - Shipping calculation service
- **Payment** - Payment processing service
- **Ratings** - Product ratings service
- **Dispatch** - Order dispatch service
- **MongoDB** - Database for catalogue and user data
- **Redis** - Session and cart storage
- **RabbitMQ** - Message queue for dispatch
- **MySQL** - Database for shipping and ratings

## Quick Start (Automated Deployment)

The fastest way to deploy Robot Shop:

```bash
# 1. Configure AWS credentials
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"

# 2. Create terraform.tfvars
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and set your key_name and Instana credentials (optional)

# 3. Update ansible.cfg with your SSH key path
# Edit line 5: private_key_file = ~/.ssh/your-key.pem

# 4. (Optional) Configure Instana monitoring
export INSTANA_AGENT_KEY="your-instana-agent-key"
export INSTANA_ENDPOINT_HOST="ingress-red-saas.instana.io"
export INSTANA_ENDPOINT_PORT="443"
export INSTANA_ZONE="robot-shop-zone"

# 5. Run the automated deployment script
./deploy.sh
```

The script will:
- Initialize Terraform
- Deploy AWS infrastructure
- Wait for instance to be ready
- Test Ansible connectivity
- Deploy Robot Shop application
- Display access URL

**Total deployment time**: ~10-15 minutes

## Prerequisites

1. **AWS account** with credentials configured
2. **Terraform** installed (v1.0+)
3. **Ansible** installed (v2.9+)
4. **SSH key pair** created in AWS EC2 console
5. **Bash shell** (for automated deployment script)
6. **Instana account** (optional, for monitoring) - [Get free trial](https://www.instana.com/trial/)

## Manual Deployment (Step-by-Step)

If you prefer manual control over each step:

### Step 1: Deploy VM with Terraform

#### 1.1 Create terraform.tfvars

Copy the example file and edit it:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set your values:
```hcl
aws_region        = "us-east-1"
availability_zone = "us-east-1a"
instance_type     = "t2.micro"
key_name          = "your-key-pair-name"  # Your AWS key pair name
```

#### 1.2 Initialize and Deploy
```hcl
key_name = "my-key"  # Replace with your actual AWS key pair name
```

### 1.2 Deploy

```bash
terraform init
terraform plan
terraform apply
```

Type `yes` when prompted.

#### 1.3 Note the Public IP

Terraform will output the VM's public IP. Save it for the next step.

### Step 2: Configure and Deploy with Ansible

#### 2.1 Update Ansible Configuration

Edit `ansible.cfg` and update the SSH key path (line 5):
```ini
private_key_file = ~/.ssh/your-key.pem
```

**Note**: Terraform automatically generates `inventory.ini` with the VM's IP address.

#### 2.2 Test Connection

Wait 1-2 minutes for the instance to be ready, then test:

```bash
ansible vm -m ping
```

You should see a SUCCESS message.

#### 2.3 Deploy Robot Shop Application

```bash
ansible-playbook playbook.yml
```

This playbook will:
1. Update system packages
2. Install Docker and Docker Compose
3. Install required tools (git, curl, wget)
4. Start and enable Docker service
5. Add ec2-user to docker group
6. Create Robot Shop directory at `/opt/robot-shop`
7. Deploy docker-compose.yml with all microservices
8. Pull all Docker images
9. Start the complete Robot Shop application
10. Wait for the application to be ready

**Deployment time**: Approximately 5-10 minutes depending on network speed.

### Step 3: Access Robot Shop Application

#### 3.1 Get the Public IP

From Terraform output or run:
```bash
terraform output instance_public_ip
```

#### 3.2 Access the Application

Open your browser and navigate to:
```
http://<public-ip>:8080
```

You should see the Robot Shop e-commerce website.

#### 3.3 Verify All Services

SSH to the VM:
```bash
ssh -i ~/.ssh/your-key.pem ec2-user@<public-ip>
```

Check running containers:
```bash
docker ps
```

You should see 11 containers running:
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

View logs:
```bash
cd /opt/robot-shop
docker-compose logs -f
```

## What Gets Created

**AWS Infrastructure (Terraform):**
- 1 EC2 instance (t2.micro, Amazon Linux 2, 30GB storage)
- 1 Security group with ports:
  - 22 (SSH)
  - 80 (HTTP)
  - 443 (HTTPS)
  - 8080 (Robot Shop Web UI)
  - 42699, 42677 (Instana Agent)

**Application Stack (Ansible + Docker):**
- Docker Engine and Docker Compose
- Robot Shop microservices (11 containers)
- Persistent data volumes for databases
- Bridge network for inter-service communication

**Monitoring (Optional):**
- Instana agent for host, Docker, and application monitoring
- Automatic service discovery and tracing
- Custom zones and tags for organization

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS Cloud                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              EC2 Instance (Amazon Linux 2)            │  │
│  │                                                       │  │
│  │  ┌─────────────────────────────────────────────┐    │  │
│  │  │         Docker Compose Network              │    │  │
│  │  │                                             │    │  │
│  │  │  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐  │    │  │
│  │  │  │ Web  │  │Catalo│  │ User │  │ Cart │  │    │  │
│  │  │  │:8080 │◄─┤ gue  │◄─┤      │◄─┤      │  │    │  │
│  │  │  └──────┘  └──────┘  └──────┘  └──────┘  │    │  │
│  │  │      │                                     │    │  │
│  │  │  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐  │    │  │
│  │  │  │Ship  │  │Paymt │  │Rating│  │Dispat│  │    │  │
│  │  │  │ping  │  │      │  │      │  │  ch  │  │    │  │
│  │  │  └──────┘  └──────┘  └──────┘  └──────┘  │    │  │
│  │  │      │         │         │         │      │    │  │
│  │  │  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐  │    │  │
│  │  │  │MongoDB│ │ Redis│  │RabbitMQ│ │MySQL │  │    │  │
│  │  │  └──────┘  └──────┘  └──────┘  └──────┘  │    │  │
│  │  └─────────────────────────────────────────────┘    │  │
│  └───────────────────────────────────────────────────────┘  │
│                          │                                   │
│                    Security Group                            │
│              (22, 80, 443, 8080, 42699)                     │
└─────────────────────────────────────────────────────────────┘
                           │
                    Internet Gateway
                           │
                      Your Browser
                   http://<ip>:8080
```

## Monitoring and Management

### Instana Monitoring (Optional)

If you've configured Instana, you can monitor:
- **Host metrics**: CPU, memory, disk, network
- **Docker containers**: All 11 Robot Shop services
- **Application traces**: End-to-end request tracing
- **Service dependencies**: Automatic service map

**Documentation**:
- [INSTANA_SETUP.md](INSTANA_SETUP.md) - Agent installation and configuration
- [INSTANA_TERRAFORM_PROVIDER.md](INSTANA_TERRAFORM_PROVIDER.md) - Terraform provider for application perspectives, alerts, RBAC, and SLIs

### View Application Logs

```bash
# All services
cd /opt/robot-shop
docker-compose logs -f

# Specific service
docker-compose logs -f web
docker-compose logs -f catalogue
```

### Restart Services

```bash
cd /opt/robot-shop

# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart web
```

### Stop/Start Application

```bash
cd /opt/robot-shop

# Stop all services
docker-compose down

# Start all services
docker-compose up -d
```

### Check Service Health

```bash
# Check container status
docker ps

# Check resource usage
docker stats

# Inspect specific container
docker inspect web
```

## Cleanup

### Remove Application Only

SSH to VM and run:
```bash
cd /opt/robot-shop
docker-compose down -v  # -v removes volumes
```

### Destroy Complete Infrastructure

```bash
terraform destroy
```

Type `yes` when prompted. This will:
- Terminate the EC2 instance
- Delete the security group
- Remove all AWS resources

## Project Files

- `main.tf` - Terraform configuration for AWS infrastructure
- `variables.tf` - Terraform input variables
- `outputs.tf` - Terraform outputs (instance IP, DNS)
- `terraform.tfvars.example` - Example variables file
- `user_data.sh` - EC2 user data script for Instana agent installation
- `inventory.tpl` - Template for Ansible inventory
- `ansible.cfg` - Ansible configuration
- `inventory.ini` - Generated Ansible inventory (auto-created by Terraform)
- `playbook.yml` - Ansible playbook for Docker, Instana, and Robot Shop deployment
- `deploy.sh` - Automated deployment script
- `instana.tf` - Instana Terraform provider configuration (application perspectives, alerts, RBAC)
- `README.md` - This documentation
- `DEPLOYMENT_GUIDE.md` - Comprehensive deployment guide
- `INSTANA_SETUP.md` - Instana agent installation guide
- `INSTANA_TERRAFORM_PROVIDER.md` - Instana Terraform provider usage guide

## Troubleshooting

### Terraform Issues

**Error: Invalid AWS credentials**
```bash
# Configure AWS credentials
aws configure
# Or set environment variables
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
```

**Error: Key pair does not exist**
- Create a key pair in AWS EC2 console
- Update `key_name` in `terraform.tfvars`

### Ansible Issues

**Connection failed**
- Verify the IP in `inventory.ini` is correct (auto-generated by Terraform)
- Check SSH key path in `ansible.cfg`
- Ensure security group allows SSH (port 22)
- Wait 1-2 minutes after Terraform completes for instance to be ready

**Playbook fails during Docker installation**
- SSH to VM: `ssh -i ~/.ssh/your-key.pem ec2-user@<public-ip>`
- Check logs: `sudo journalctl -xe`
- Verify internet connectivity: `ping google.com`

### Application Issues

**Cannot access Robot Shop on port 8080**
- Verify security group allows port 8080
- Check if containers are running: `docker ps`
- Check web container logs: `docker logs web`
- Ensure you're using HTTP (not HTTPS): `http://<ip>:8080`

**Containers not starting**
```bash
# Check Docker service
sudo systemctl status docker

# Check container logs
cd /opt/robot-shop
docker-compose logs

# Restart services
docker-compose restart
```

**Out of memory errors**
- Consider using a larger instance type (t2.small or t2.medium)
- Update `instance_type` in `terraform.tfvars`
- Run `terraform apply` to resize

**Slow performance**
- Robot Shop requires at least 2GB RAM
- Recommended: t2.small (2GB) or t2.medium (4GB)
- Current default: t2.micro (1GB) - may be slow

## Cost Estimation

**AWS Resources:**
- EC2 t2.micro: ~$0.0116/hour (~$8.50/month)
- EBS 30GB gp3: ~$2.40/month
- Data transfer: Variable

**Total estimated cost**: ~$11/month for t2.micro

**Note**: Remember to run `terraform destroy` when done to avoid charges.

## Advanced Configuration

### Using a Different Instance Type

Edit `terraform.tfvars`:
```hcl
instance_type = "t2.small"  # 2GB RAM, recommended for better performance
```

### Changing AWS Region

Edit `terraform.tfvars`:
```hcl
aws_region        = "us-west-2"
availability_zone = "us-west-2a"
```

### Customizing Robot Shop

Edit the docker-compose.yml section in `playbook.yml` to:
- Change port mappings
- Add environment variables
- Configure resource limits
- Enable additional services

## Security Considerations

⚠️ **Important Security Notes:**

1. **SSH Access**: Current security group allows SSH from anywhere (0.0.0.0/0)
   - For production, restrict to your IP: `your-ip/32`

2. **Application Access**: Port 8080 is open to the internet
   - Consider using a load balancer with SSL/TLS
   - Implement authentication if needed

3. **SSH Keys**: Never commit private keys to version control
   - Keep your `.pem` file secure
   - Use appropriate file permissions: `chmod 400 ~/.ssh/your-key.pem`

4. **AWS Credentials**: Never commit AWS credentials
   - Use AWS IAM roles when possible
   - Rotate credentials regularly

## Additional Resources

- [Robot Shop GitHub Repository](https://github.com/instana/robot-shop.git)
- [Instana Agent Setup Guide](INSTANA_SETUP.md) - Agent installation and configuration
- [Instana Terraform Provider Guide](INSTANA_TERRAFORM_PROVIDER.md) - Application perspectives, alerts, RBAC, SLIs
- [Deployment Guide](DEPLOYMENT_GUIDE.md) - Comprehensive deployment instructions
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Instana Documentation](https://www.ibm.com/docs/en/instana-observability)
- [Instana Terraform Provider](https://registry.terraform.io/providers/gessnerfl/instana/latest/docs)

## Support

For issues related to:
- **Infrastructure/Deployment**: Check this README and troubleshooting section
- **Robot Shop Application**: Visit the [Robot Shop GitHub Issues](https://github.com/instana/robot-shop.git/issues)
- **AWS Services**: Consult [AWS Documentation](https://docs.aws.amazon.com/)

---

**Made with ❤️ using Terraform, Ansible, and Docker**