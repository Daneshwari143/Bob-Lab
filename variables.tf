# Variables for Instana deployment to existing VM
# EC2-related variables removed - using existing VM
#9.30.220.114
#[2:28 PM]root/pwd@FYRE1234567

# Existing VM connection details
variable "existing_vm_ip" {
  description = "IP address of existing VM"
  type        = string
  default     = "9.30.220.114"
}

variable "existing_vm_user" {
  description = "SSH user for existing VM"
  type        = string
  default     = "root"
}

variable "existing_vm_password" {
  description = "SSH password for existing VM"
  type        = string
  default     = "pwd@FYRE1234567"
  sensitive   = true
}

# Instana Agent Configuration
variable "instana_agent_key" {
  description = "Instana agent key for authentication"
  type        = string
  sensitive   = true
}

variable "instana_endpoint_host" {
  description = "Instana backend endpoint host (e.g., ingress-red-saas.instana.io)"
  type        = string
}

variable "instana_endpoint_port" {
  description = "Instana backend endpoint port"
  type        = string
  default     = "443"
}

variable "instana_zone" {
  description = "Custom zone name for Instana agent"
  type        = string
  default     = "robot-shop-zone"
}

variable "instana_api_token" {
  description = "Instana API token for Terraform provider authentication"
  type        = string
  sensitive   = true
}

variable "instana_endpoint" {
  description = "Instana API endpoint (e.g., https://tenant-unit.instana.io)"
  type        = string
}

variable "enable_instana_config" {
  description = "Enable Instana configuration via Terraform provider"
  type        = bool
  default     = true
}