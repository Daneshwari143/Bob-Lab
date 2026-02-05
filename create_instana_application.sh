#!/bin/bash
# Script to create Instana Application Perspective without Terraform
# Usage: ./create_instana_application.sh

set -e

# Configuration
INSTANA_API_TOKEN="${INSTANA_API_TOKEN:-}"
INSTANA_ENDPOINT="${INSTANA_ENDPOINT:-ibmdevsandbox-instanaibm.instana.io}"
APP_NAME="Robot-Shop-Microservices-Daneshwari-2026"

# Check if API token is provided
if [ -z "$INSTANA_API_TOKEN" ]; then
    echo "Error: INSTANA_API_TOKEN environment variable is required"
    echo "Usage: INSTANA_API_TOKEN=your-token ./create_instana_application.sh"
    exit 1
fi

echo "=========================================="
echo "Creating Instana Application Perspective"
echo "=========================================="
echo "Endpoint: https://$INSTANA_ENDPOINT"
echo "Application: $APP_NAME"
echo ""

# Create Application Perspective
echo "Creating Application Perspective..."
HTTP_CODE=$(curl -X POST "https://$INSTANA_ENDPOINT/api/application-monitoring/settings/application" \
  -H "Authorization: apiToken $INSTANA_API_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -w "%{http_code}" \
  -o /tmp/instana_app_response.json \
  -s \
  -d '{
    "label": "'"$APP_NAME"'",
    "scope": "INCLUDE_ALL_DOWNSTREAM",
    "boundaryScope": "ALL",
    "matchSpecification": {
      "type": "TAG_FILTER",
      "key": "service.name",
      "operator": "CONTAINS",
      "value": "robot-shop"
    }
  }')

echo "HTTP Status Code: $HTTP_CODE"
echo ""

if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
    echo "✓ Application Perspective created successfully!"
    echo ""
    echo "Response:"
    cat /tmp/instana_app_response.json | python3 -m json.tool 2>/dev/null || cat /tmp/instana_app_response.json
elif [ "$HTTP_CODE" -eq 409 ]; then
    echo "⚠ Application Perspective already exists (HTTP 409)"
    echo ""
    echo "Response:"
    cat /tmp/instana_app_response.json
else
    echo "✗ Failed to create Application Perspective (HTTP $HTTP_CODE)"
    echo ""
    echo "Response:"
    cat /tmp/instana_app_response.json
    exit 1
fi

echo ""
echo "=========================================="
echo "✓ Setup Complete!"
echo "=========================================="
echo ""
echo "Next Steps:"
echo "1. Go to Instana UI: https://$INSTANA_ENDPOINT"
echo "2. Navigate to Applications"
echo "3. Find: $APP_NAME"
echo "4. Configure alerts and SLIs as needed"
echo ""

# Made with Bob
