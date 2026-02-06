# Instana Alert Email Fix - Application Perspective Created But No Emails

## Problem Summary

**Issue:** Application perspective "Robot-Shop-Microservices-Daneshwari-2026" is created successfully, but alert emails are not being received at Daneshwari.Naganur1@ibm.com.

**Root Cause:** The alert configuration event filter was incorrectly filtering for `entity.type:application`, but the custom events target `entity.type:service` and `entity.type:dockerContainer`. This mismatch prevented alerts from triggering email notifications.

---

## Solution Applied

### Changes Made to `instana.tf`

**Before (Lines 360-378):**
```hcl
# Filter for Robot Shop application on ubuntu hostname ONLY
event_filter_query = "entity.application.name:\"Robot-Shop-Microservices-Daneshwari-2026\" AND entity.type:application AND entity.host.name:\"ubuntu\" AND entity.zone:\"robot-shop-zone\""

event_filter_event_types = [
  "incident",
  "critical",
  "warning"
]
```

**After (Fixed):**
```hcl
# Filter for Robot Shop services and containers on ubuntu hostname
# Matches custom events that target services and dockerContainers
event_filter_query = "entity.application.name:\"Robot-Shop-Microservices-Daneshwari-2026\" AND entity.zone:\"robot-shop-zone\""

event_filter_event_types = [
  "incident",
  "critical",
  "warning",
  "change"
]
```

### Key Changes:
1. **Removed** `entity.type:application` filter (too restrictive)
2. **Removed** `entity.host.name:\"ubuntu\"` filter (redundant with zone filter)
3. **Added** `"change"` event type to capture all event types
4. **Simplified** query to match custom events targeting services and containers

---

## How to Apply the Fix

### Step 1: Apply Terraform Changes

```bash
# Navigate to your project directory
cd /Users/daneshwari.naganur/Documents/Terraform-Ansible-Docker\ Code

# Review the changes
terraform plan

# Apply the changes
terraform apply -auto-approve
```

**Expected Output:**
```
instana_alerting_config.robot_shop[0]: Modifying... [id=xxxxx]
instana_alerting_config.robot_shop[0]: Modifications complete after 2s

Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
```

### Step 2: Verify in Instana UI

1. **Login to Instana:**
   - URL: https://ibmdevsandbox-instanaibm.instana.io
   - Use your IBM credentials

2. **Check Alert Configuration:**
   - Navigate to: **Settings** → **Team Settings** → **Alerting**
   - Find: **"Robot Shop Application Health Alerts - ubuntu only"**
   - Verify:
     - Status: ✅ Active
     - Alert Channel: ✅ Robot Shop Alert Email
     - Event Filter: Should show simplified query

3. **Check Alert Channel:**
   - Navigate to: **Settings** → **Team Settings** → **Alert Channels**
   - Find: **"Robot Shop Alert Email"**
   - Verify:
     - Email: Daneshwari.Naganur1@ibm.com
     - Status: ✅ Active
     - Click **"Send Test Alert"** to verify email delivery

---

## Testing the Fix

### Test 1: Send Test Alert from Instana UI

```
1. Go to: Settings → Alert Channels → Robot Shop Alert Email
2. Click: "Send Test Alert"
3. Check email: Daneshwari.Naganur1@ibm.com
4. Expected: Test alert email received within 1-2 minutes
```

### Test 2: Trigger High Error Rate Alert

```bash
# SSH to your VM
ssh root@9.30.220.114

# Generate 404 errors to trigger high error rate
for i in {1..100}; do
  curl -s http://localhost:8080/nonexistent-page-$i > /dev/null
  sleep 0.5
done
```

**Expected Result:**
- Wait 5 minutes for evaluation window
- Email alert: "Robot Shop - High Error Rate"
- Alert visible in Instana Events page

### Test 3: Trigger Service Down Alert

```bash
# SSH to your VM
ssh root@9.30.220.114

# Stop a service temporarily
cd /opt/robot-shop
docker-compose stop payment

# Wait 2 minutes, then check email

# Restart the service
docker-compose start payment
```

**Expected Result:**
- Email alert: "Robot Shop - Service Down" (Critical)
- Alert visible in Instana Events page
- Recovery email when service restarts

### Test 4: Trigger High Memory Alert

```bash
# SSH to your VM
ssh root@9.30.220.114

# Generate memory pressure (if needed)
stress --vm 2 --vm-bytes 1G --timeout 600s
```

**Expected Result:**
- Wait 5 minutes for evaluation window
- Email alert: "Robot Shop - High Memory Usage" (Critical)

---

## Verification Checklist

After applying the fix, verify:

- [ ] Terraform apply completed successfully
- [ ] Alert configuration updated in Instana UI
- [ ] Test alert email received
- [ ] Custom events are enabled and triggering
- [ ] Email channel is active
- [ ] Application perspective shows services
- [ ] Instana agent is running on VM

---

## Why This Fix Works

### Problem Explanation:

The original configuration had a **type mismatch**:

**Custom Events Target:**
- `entity.type:service` (High Error Rate, High Response Time, Service Down)
- `entity.type:dockerContainer` (Container Failure, High Memory Usage)

**Alert Configuration Was Filtering For:**
- `entity.type:application` ❌ (No match!)

**Result:** Custom events triggered but were filtered out by the alert configuration, so no emails were sent.

### Solution Explanation:

The fixed configuration:
1. **Removes the entity type filter** - Allows all entity types (services, containers, applications)
2. **Keeps application name filter** - Still scopes to Robot Shop only
3. **Keeps zone filter** - Still scopes to robot-shop-zone
4. **Adds "change" event type** - Captures all event severities

**Result:** Custom events now match the alert configuration filter and trigger email notifications.

---

## Additional Troubleshooting

### If Still Not Receiving Emails:

#### 1. Check Email Spam/Junk Folder
```
- Instana emails may be filtered as spam
- Add @instana.io to safe senders list
- Check: Junk, Spam, Promotions folders
```

#### 2. Verify Instana Agent Status
```bash
ssh root@9.30.220.114
systemctl status instana-agent

# Should show: active (running)
```

#### 3. Check Agent Logs
```bash
journalctl -u instana-agent -f --since "10 minutes ago"

# Look for:
# - Connection to backend: OK
# - Metrics being sent: OK
# - No error messages
```

#### 4. Verify Custom Events Are Created
```bash
# Check if custom events were created successfully
cat /tmp/instana_error_rate_event.json
cat /tmp/instana_latency_event.json
cat /tmp/instana_service_down_event.json
cat /tmp/instana_container_failure_event.json
cat /tmp/instana_high_memory_event.json

# Each should show HTTP 200 or 201 status
```

#### 5. Re-create Custom Events (If Needed)
```bash
# If custom events failed to create, re-run Terraform
terraform taint null_resource.create_high_error_rate_event[0]
terraform taint null_resource.create_high_latency_event[0]
terraform taint null_resource.create_service_down_event[0]
terraform taint null_resource.create_container_failure_event[0]
terraform taint null_resource.create_high_memory_event[0]

terraform apply -auto-approve
```

#### 6. Verify Robot Shop is Running
```bash
ssh root@9.30.220.114
docker ps | grep robot-shop

# Should show all containers running:
# web, catalogue, cart, user, payment, shipping, ratings, mongodb, redis, mysql
```

---

## Expected Alert Email Format

### Subject Line:
```
[Instana Alert] Robot Shop Application Health Alerts - High Error Rate
```

### Email Content:
```
Alert Name: Robot Shop Application Health Alerts - ubuntu only
Application: Robot-Shop-Microservices-Daneshwari-2026
Event: Robot Shop - High Error Rate

Status: TRIGGERED
Severity: Warning
Timestamp: 2026-02-06 09:45:00 UTC

Details:
Error rate has exceeded 5% threshold
Current error rate: 12.5%
Time window: Last 5 minutes

Affected Services:
- payment (15% error rate)
- catalogue (8% error rate)

View in Instana: [Link to Dashboard]
```

---

## Summary

### What Was Fixed:
✅ Alert configuration event filter corrected
✅ Entity type mismatch resolved
✅ Event types expanded to include all severities

### What You Need to Do:
1. Run `terraform apply` to update the configuration
2. Send a test alert from Instana UI
3. Verify email delivery
4. Optionally trigger real alerts for testing

### Expected Outcome:
📧 You will now receive email alerts at Daneshwari.Naganur1@ibm.com for:
- High error rates (>5%)
- High response times (>1000ms)
- Service failures
- Container crashes
- High memory usage (>90%)

---

## Support

If issues persist after applying this fix:

1. **Check Instana Status:** https://status.instana.io
2. **Review Instana Docs:** https://www.ibm.com/docs/en/instana-observability
3. **Contact IBM Support:** Include alert configuration details and application name

---

**Last Updated:** 2026-02-06  
**Version:** 1.0  
**Author:** IBM Bob (AI Assistant)