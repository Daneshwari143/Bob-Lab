# Instana Terraform Provider Configuration
# Using official IBM Instana provider
# Note: This is a minimal configuration. Advanced features should be configured in Instana UI.
# Alerts : will get alert when service down, hight error rate, response time is late, container failure, high memory usage
#RBAC: Creating API token for the user to access the instana API 

terraform {
  required_providers {
    instana = {
      source  = "instana/instana"
      version = "~> 3.0"
    }
  }
}

# Configure Instana provider
provider "instana" {
  api_token = var.instana_api_token
  endpoint  = var.instana_endpoint
}

# Application Perspective for Robot Shop
# Using null_resource with local-exec to call Instana API
# since instana_application_config resource is not available in the provider

resource "null_resource" "create_application_perspective" {
  count = var.enable_instana_config ? 1 : 0

  # Trigger recreation if configuration changes
  triggers = {
    app_name    = "Robot-Shop-Microservices-Daneshwari-2026"
    api_token   = var.instana_api_token
    endpoint    = var.instana_endpoint
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      echo "Creating Application Perspective: Robot-Shop-Microservices-Daneshwari-2026"
      echo "API Endpoint: https://${var.instana_endpoint}"
      
      # Create application perspective
      HTTP_CODE=$(curl -X POST "https://${var.instana_endpoint}/api/application-monitoring/settings/application" \
        -H "Authorization: apiToken ${var.instana_api_token}" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -w "%%{http_code}" \
        -o /tmp/instana_app_response.json \
        -s \
        -d '{
          "label": "Robot-Shop-Microservices-Daneshwari-2026",
          "scope": "INCLUDE_ALL_DOWNSTREAM",
          "boundaryScope": "ALL",
          "matchSpecification": {
            "type": "TAG_FILTER",
            "key": "agent.tag",
            "operator": "EQUALS",
            "value": "appname:robot-shop-oas"
          }
        }')
      
      echo "HTTP Status Code: $HTTP_CODE"
      echo "Response:"
      cat /tmp/instana_app_response.json 2>/dev/null || echo "No response file"
      
      if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
        echo "✓ Application Perspective created successfully!"
      elif [ "$HTTP_CODE" -eq 409 ]; then
        echo "⚠ Application Perspective already exists (HTTP 409)"
      else
        echo "✗ Failed to create Application Perspective (HTTP $HTTP_CODE)"
        cat /tmp/instana_app_response.json 2>/dev/null
      fi
    EOT
  }

  # Remove dependency to allow parallel execution
  # depends_on removed to speed up application creation
}

# Custom Event 1: High Error Rate
#Severity: Warning, Trigger: Error rate ≥ 5%, Window: 5 minutes, Impact: Failed transactions, checkout errors

# Using API call since Terraform provider has limitations
resource "null_resource" "create_high_error_rate_event" {
  count = var.enable_instana_config ? 1 : 0

  triggers = {
    api_token = var.instana_api_token
    endpoint  = var.instana_endpoint
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -X POST "https://${var.instana_endpoint}/api/events/settings/custom-events" \
        -H "Authorization: apiToken ${var.instana_api_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "name": "Robot Shop - High Error Rate",
          "description": "Alert when error rate exceeds 5% in Robot Shop services",
          "query": "entity.application.name:\"Robot-Shop-Microservices-Daneshwari-2026\" AND entity.type:service AND entity.zone:robot-shop-zone",
          "enabled": true,
          "triggering": true,
          "entityType": "service",
          "rules": [
            {
              "severity": "warning",
              "metricName": "errors",
              "aggregation": "sum",
              "conditionOperator": ">=",
              "conditionValue": 5.0,
              "window": 300000
            }
          ]
        }' \
        -w "\nHTTP Status: %%{http_code}\n" \
        -o /tmp/instana_error_rate_event.json || true
      
      echo "High Error Rate Event creation response:"
      cat /tmp/instana_error_rate_event.json 2>/dev/null || echo "Response file not found"
    EOT
  }

  depends_on = [
    null_resource.create_application_perspective
  ]
}

# Custom Event 2: High Response Time
resource "null_resource" "create_high_latency_event" {
  count = var.enable_instana_config ? 1 : 0

  triggers = {
    api_token = var.instana_api_token
    endpoint  = var.instana_endpoint
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -X POST "https://${var.instana_endpoint}/api/events/settings/custom-events" \
        -H "Authorization: apiToken ${var.instana_api_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "name": "Robot Shop - High Response Time",
          "description": "Alert when response time exceeds 1000ms in Robot Shop services",
          "query": "entity.application.name:\"Robot-Shop-Microservices-Daneshwari-2026\" AND entity.type:service AND entity.zone:robot-shop-zone",
          "enabled": true,
          "triggering": true,
          "entityType": "service",
          "rules": [
            {
              "severity": "warning",
              "metricName": "latency",
              "aggregation": "avg",
              "conditionOperator": ">=",
              "conditionValue": 1000.0,
              "window": 300000
            }
          ]
        }' \
        -w "\nHTTP Status: %%{http_code}\n" \
        -o /tmp/instana_latency_event.json || true
      
      echo "High Response Time Event creation response:"
      cat /tmp/instana_latency_event.json 2>/dev/null || echo "Response file not found"
    EOT
  }

  depends_on = [
    null_resource.create_application_perspective
  ]
}

# Custom Event 3: Service Down
resource "null_resource" "create_service_down_event" {
  count = var.enable_instana_config ? 1 : 0

  triggers = {
    api_token = var.instana_api_token
    endpoint  = var.instana_endpoint
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -X POST "https://${var.instana_endpoint}/api/events/settings/custom-events" \
        -H "Authorization: apiToken ${var.instana_api_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "name": "Robot Shop - Service Down",
          "description": "Alert when Robot Shop service becomes unavailable",
          "query": "entity.application.name:\"Robot-Shop-Microservices-Daneshwari-2026\" AND entity.type:service AND entity.zone:robot-shop-zone",
          "enabled": true,
          "triggering": true,
          "entityType": "service",
          "rules": [
            {
              "severity": "critical",
              "metricName": "erroneous",
              "aggregation": "sum",
              "conditionOperator": ">=",
              "conditionValue": 1.0,
              "window": 60000
            }
          ]
        }' \
        -w "\nHTTP Status: %%{http_code}\n" \
        -o /tmp/instana_service_down_event.json || true
      
      echo "Service Down Event creation response:"
      cat /tmp/instana_service_down_event.json 2>/dev/null || echo "Response file not found"
    EOT
  }

  depends_on = [
    null_resource.create_application_perspective
  ]
}

# Custom Event 4: Container Failure (CRITICAL)
resource "null_resource" "create_container_failure_event" {
  count = var.enable_instana_config ? 1 : 0

  triggers = {
    api_token = var.instana_api_token
    endpoint  = var.instana_endpoint
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -X POST "https://${var.instana_endpoint}/api/events/settings/custom-events" \
        -H "Authorization: apiToken ${var.instana_api_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "name": "Robot Shop - Container Failure",
          "description": "Alert when Robot Shop container stops or crashes",
          "query": "entity.application.name:\"Robot-Shop-Microservices-Daneshwari-2026\" AND entity.type:dockerContainer AND entity.zone:robot-shop-zone",
          "enabled": true,
          "triggering": true,
          "entityType": "dockerContainer",
          "rules": [
            {
              "severity": "critical",
              "metricName": "state",
              "aggregation": "sum",
              "conditionOperator": "!=",
              "conditionValue": 1.0,
              "window": 60000
            }
          ]
        }' \
        -w "\nHTTP Status: %%{http_code}\n" \
        -o /tmp/instana_container_failure_event.json || true
      
      echo "Container Failure Event creation response:"
      cat /tmp/instana_container_failure_event.json 2>/dev/null || echo "Response file not found"
    EOT
  }

  depends_on = [
    null_resource.create_application_perspective
  ]
}

# Custom Event 5: High Memory Usage (CRITICAL)
resource "null_resource" "create_high_memory_event" {
  count = var.enable_instana_config ? 1 : 0

  triggers = {
    api_token = var.instana_api_token
    endpoint  = var.instana_endpoint
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -X POST "https://${var.instana_endpoint}/api/events/settings/custom-events" \
        -H "Authorization: apiToken ${var.instana_api_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "name": "Robot Shop - High Memory Usage",
          "description": "Alert when memory usage exceeds 90% for Robot Shop containers",
          "query": "entity.application.name:\"Robot-Shop-Microservices-Daneshwari-2026\" AND entity.type:dockerContainer AND entity.zone:robot-shop-zone",
          "enabled": true,
          "triggering": true,
          "entityType": "dockerContainer",
          "rules": [
            {
              "severity": "critical",
              "metricName": "memory.usage",
              "aggregation": "avg",
              "conditionOperator": ">=",
              "conditionValue": 90.0,
              "window": 300000
            }
          ]
        }' \
        -w "\nHTTP Status: %%{http_code}\n" \
        -o /tmp/instana_high_memory_event.json || true
      
      echo "High Memory Usage Event creation response:"
      cat /tmp/instana_high_memory_event.json 2>/dev/null || echo "Response file not found"
    EOT
  }

  depends_on = [
    null_resource.create_application_perspective
  ]
}

# API Token for Robot Shop monitoring (read-only)
resource "instana_api_token" "robot_shop_readonly" {
  count = var.enable_instana_config ? 1 : 0

  name = "robot-shop-readonly-token"
  
  # Read-only permissions
  can_configure_service_mapping           = false
  can_configure_eum_applications          = false
  can_configure_mobile_app_monitoring     = false
  can_configure_users                     = false
  can_install_new_agents                  = false
  can_configure_integrations              = false
  can_configure_custom_alerts             = false
  can_configure_api_tokens                = false
  can_configure_agent_run_mode            = false
  can_view_audit_log                      = true
  can_configure_agents                    = false
  can_configure_authentication_methods    = false
  can_configure_applications              = false
  can_configure_teams                     = false
  can_configure_releases                  = false
  can_configure_log_management            = false
  can_create_public_custom_dashboards     = false
  can_view_logs                           = true
  can_view_trace_details                  = true
}

# Alert Channel - Email notification
resource "instana_alerting_channel" "robot_shop_email" {
  count = var.enable_instana_config ? 1 : 0

  name = "Robot Shop Alert Email"
  
  email {
    emails = ["Daneshwari.Naganur1@ibm.com"]
  }
}

# Alert Configuration - Link alerts to channels
# Filters events for Robot Shop services and containers on ubuntu hostname
resource "instana_alerting_config" "robot_shop" {
  count = var.enable_instana_config ? 1 : 0

  alert_name = "Robot Shop Application Health Alerts - ubuntu only"
  
  integration_ids = var.enable_instana_config ? [
    instana_alerting_channel.robot_shop_email[0].id
  ] : []

  # Filter for Robot Shop services and containers on ubuntu hostname
  # Matches custom events that target services and dockerContainers
  event_filter_query = "entity.application.name:\"Robot-Shop-Microservices-Daneshwari-2026\" AND entity.zone:\"robot-shop-zone\""
  
  # Filter for all event types including custom events
  event_filter_event_types = [
    "incident",
    "critical",
    "warning",
    "change"
  ]
}

# Output the API token for use in CI/CD or monitoring tools
output "instana_readonly_token" {
  description = "Read-only API token for Robot Shop monitoring"
  value       = var.enable_instana_config ? instana_api_token.robot_shop_readonly[0].access_granting_token : null
  sensitive   = true
}