#!/bin/bash
# Verify Instana Setup - Application Perspective and Alerts

echo "=========================================="
echo "Instana Configuration Verification"
echo "=========================================="
echo ""

# Check if application perspective exists
echo "1. Checking Application Perspective..."
if [ -f /tmp/instana_app_response.json ]; then
    response=$(cat /tmp/instana_app_response.json)
    if echo "$response" | grep -q "already used"; then
        echo "✅ Application Perspective EXISTS (name already in use)"
        echo "   Name: Robot-Shop-Microservices-Daneshwari-2026"
    elif echo "$response" | grep -q "id"; then
        echo "✅ Application Perspective CREATED successfully"
        echo "   Response: $response"
    else
        echo "⚠️  Unknown status: $response"
    fi
else
    echo "⚠️  No response file found - run terraform apply first"
fi
echo ""

# Check Terraform state
echo "2. Checking Terraform State..."
terraform state list 2>/dev/null | grep -E "(application_perspective|alerting)" | while read resource; do
    echo "   ✅ $resource"
done
echo ""

# Check alert channel
echo "3. Checking Alert Channel..."
terraform state show instana_alerting_channel.robot_shop_email[0] 2>/dev/null | grep -E "(id|name|emails)" | head -3
echo ""

# Check alert configuration
echo "4. Checking Alert Configuration..."
terraform state show instana_alerting_config.robot_shop[0] 2>/dev/null | grep -E "(id|alert_name|event_filter)" | head -5
echo ""

# Summary
echo "=========================================="
echo "Summary"
echo "=========================================="
echo ""
echo "To verify in Instana UI:"
echo "1. Login: https://ibmdevsandbox-instanaibm.instana.io"
echo "2. Check Applications → Robot-Shop-Microservices-Daneshwari-2026"
echo "3. Check Settings → Alert Channels → Robot Shop Alert Email"
echo "4. Check Settings → Alerting → Robot Shop Application Health Alerts"
echo ""
echo "To test alerts:"
echo "1. Settings → Alert Channels → Send Test Alert"
echo "2. Check email: Daneshwari.Naganur1@ibm.com"
echo ""

# Made with Bob
