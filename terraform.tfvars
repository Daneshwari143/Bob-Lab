# Terraform configuration for Instana deployment to existing VM
# No EC2 creation - using existing VM (9.30.220.114)

# Existing VM Details
existing_vm_ip       = "9.30.220.114"
existing_vm_user     = "root"
existing_vm_password = "pwd@FYRE1234567"

# Instana Agent Configuration
# Get these values from your Instana account
instana_agent_key      = "uBp4GXpZQpKrHxMXNcvInQ"
instana_endpoint_host  = "ingress-orange-saas.instana.io"  # Or your Instana backend host
instana_endpoint_port  = "443"
instana_zone           = "robot-shop-zone"

# Instana Terraform Provider Configuration
# API token for managing Instana resources (application perspectives, alerts, RBAC)
# Get from: Instana UI -> Settings -> Team Settings -> API Tokens
instana_api_token      = "-M4zm_2RQpOIMgQvU3dj8A"
instana_endpoint       = "ibmdevsandbox-instanaibm.instana.io"  # Your Instana API endpoint (hostname only, no https://)
enable_instana_config  = true  # Set to false to skip Instana resource configuration