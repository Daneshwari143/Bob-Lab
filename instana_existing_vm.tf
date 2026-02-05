# Terraform configuration to deploy Instana agent to existing VM
# and configure Instana monitoring resources

# Deploy Instana agent to existing VM using remote-exec
resource "null_resource" "deploy_instana_agent" {
  # Trigger on any change to Instana configuration
  triggers = {
    instana_agent_key     = var.instana_agent_key
    instana_endpoint_host = var.instana_endpoint_host
    instana_zone          = var.instana_zone
    vm_ip                 = var.existing_vm_ip
  }

  # Connection to existing VM
  connection {
    type     = "ssh"
    host     = var.existing_vm_ip
    user     = var.existing_vm_user
    password = var.existing_vm_password
    timeout  = "15m"
  }

  # Install Instana agent with better error handling and faster execution
  provisioner "remote-exec" {
    inline = [
      "echo 'Starting Instana agent installation...'",
      "if systemctl is-active --quiet instana-agent; then echo 'Instana agent already running'; exit 0; fi",
      "if [ -d /opt/instana/agent ]; then echo 'Instana agent already installed, starting...'; systemctl start instana-agent; exit 0; fi",
      "mkdir -p /opt/instana/agent/etc/instana",
      "echo 'Downloading Instana agent setup script...'",
      "curl -sSL -o /tmp/setup_agent.sh https://setup.instana.io/agent || { echo 'Failed to download agent'; exit 1; }",
      "chmod +x /tmp/setup_agent.sh",
      "echo 'Installing Instana agent (this may take 5-10 minutes)...'",
      "/tmp/setup_agent.sh -a ${var.instana_agent_key} -t dynamic -e ${var.instana_endpoint_host}:${var.instana_endpoint_port} -s -y 2>&1 | tee /tmp/instana_install.log",
      "echo 'Creating agent configuration...'",
      "cat > /opt/instana/agent/etc/instana/configuration.yaml <<EOF\ncom.instana.plugin.generic.hardware:\n  enabled: true\n  availability-zone: '${var.instana_zone}'\ncom.instana.plugin.host:\n  tags:\n    - 'robot-shop'\n    - 'terraform-managed'\n    - 'existing-vm'\n    - 'docker-host'\ncom.instana.plugin.docker:\n  enabled: true\nEOF",
      "echo 'Enabling and starting Instana agent...'",
      "systemctl enable instana-agent",
      "systemctl start instana-agent",
      "sleep 5",
      "if systemctl is-active --quiet instana-agent; then echo 'Instana agent started successfully!'; else echo 'Warning: Agent may not be running properly'; fi",
      "echo 'Installation completed!'"
    ]
  }

  # Note: Destroy provisioner removed to avoid dependency issues
  # To manually remove agent: ssh root@9.30.118.87 'systemctl stop instana-agent'
}

# Output agent installation status
output "instana_agent_deployed" {
  description = "Instana agent deployment status"
  value       = "Instana agent deployed to ${var.existing_vm_ip}"
  depends_on  = [null_resource.deploy_instana_agent]
}

output "instana_agent_check_command" {
  description = "Command to check Instana agent status"
  value       = "ssh ${var.existing_vm_user}@${var.existing_vm_ip} 'systemctl status instana-agent'"
}