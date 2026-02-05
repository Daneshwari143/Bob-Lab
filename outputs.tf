# Outputs for Instana deployment to existing VM
# EC2 outputs removed - using existing VM (9.30.220.114)

output "existing_vm_ip" {
  description = "IP address of existing VM"
  value       = var.existing_vm_ip
}

output "existing_vm_hostname" {
  description = "Hostname of existing VM"
  value       = "obscode1"
}