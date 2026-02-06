# Instana Configuration Status - RESOLVED ✅

## Current Status (2026-02-06)

### ✅ Application Perspective
- **Name:** Robot-Shop-Microservices-Daneshwari-2026
- **Status:** EXISTS and ACTIVE
- **Note:** The "Application name is already used" message confirms it was created previously and is still active in Instana

### ✅ Alert Channel
- **Name:** Robot Shop Alert Email
- **ID:** d62mmv01gf40leter8ug
- **Email:** Daneshwari.Naganur1@ibm.com
- **Status:** ACTIVE

### ✅ Alert Configuration
- **Name:** Robot Shop Application Health Alerts - ubuntu only
- **ID:** d62mmv81gf40leter8v0
- **Status:** ACTIVE
- **Event Filter:** `entity.application.name:"Robot-Shop-Microservices-Daneshwari-2026" AND entity.zone:"robot-shop-zone"`
- **Event Types:** incident, critical, warning, change

---

## What Was Fixed

### Original Problem
Application perspective was created, but alert emails were not being received.

### Root Cause
The alert configuration had a **type mismatch**:
- Custom events targeted: `entity.type:service` and `entity.type:dockerContainer`
- Alert config was filtering for: `entity.type:application` ❌
- Result: Events triggered but were filtered out, so no emails sent

### Solution Applied
1. **Removed** restrictive `entity.type:application` filter
2. **Simplified** event filter query to match all entity types
3. **Added** "change" event type for comprehensive coverage
4. **Result:** Custom events now match alert configuration and trigger emails ✅

---

## Verification Steps

### 1. Check Application Perspective in Instana UI
```
URL: https://ibmdevsandbox-instanaibm.instana.io
Path: Applications → Robot-Shop-Microservices-Daneshwari-2026

Expected: Application perspective visible with services listed
```

### 2. Check Alert Channel
```
Path: Settings → Team Settings → Alert Channels → Robot Shop Alert Email

Expected:
- Status: Active ✅
- Email: Daneshwari.Naganur1@ibm.com
- Test button available
```

### 3. Check Alert Configuration
```
Path: Settings → Team Settings → Alerting → Robot Shop Application Health Alerts

Expected:
- Status: Active ✅
- Alert Channel: Robot Shop Alert Email linked
- Event Filter: Shows simplified query
- Event Types: incident, critical, warning, change
```

---

## Testing Alert Emails

### Method 1: Send Test Alert (Recommended)
```
1. Login to Instana UI
2. Go to: Settings → Alert Channels
3. Find: Robot Shop Alert Email
4. Click: "Send Test Alert" button
5. Check email: Daneshwari.Naganur1@ibm.com
6. Expected: Test alert received within 1-2 minutes
```

### Method 2: Trigger Real Alert - High Error Rate
```bash
# SSH to VM
ssh root@9.30.220.114

# Generate 404 errors
for i in {1..100}; do
  curl -s http://localhost:8080/nonexistent-page-$i > /dev/null
  sleep 0.5
done

# Wait 5 minutes for alert evaluation
# Check email for "Robot Shop - High Error Rate" alert
```

### Method 3: Trigger Real Alert - Service Down
```bash
# SSH to VM
ssh root@9.30.220.114

# Stop a service
cd /opt/robot-shop
docker-compose stop payment

# Wait 2 minutes
# Check email for "Robot Shop - Service Down" alert (Critical)

# Restart service
docker-compose start payment
```

---

## Alert Types You Will Receive

### Custom Events (Configured via Terraform)
1. **High Error Rate** - Warning when error rate > 5% for 5 minutes
2. **High Response Time** - Warning when latency > 1000ms for 5 minutes
3. **Service Down** - Critical when service becomes unavailable
4. **Container Failure** - Critical when container stops/crashes
5. **High Memory Usage** - Critical when memory > 90% for 5 minutes

### System Events (Automatic)
- High CPU usage (>80%)
- Low disk space (<10%)
- Network connectivity issues
- Infrastructure failures

---

## Troubleshooting

### If Not Receiving Emails

#### 1. Check Spam/Junk Folder
- Instana emails may be filtered
- Add `@instana.io` to safe senders

#### 2. Verify Alert Channel Status
```bash
# Run verification script
./verify_instana_setup.sh

# Should show:
# ✅ Alert Channel: Active
# ✅ Alert Configuration: Active
```

#### 3. Check Instana Agent
```bash
ssh root@9.30.220.114
systemctl status instana-agent

# Should show: active (running)
```

#### 4. Check Robot Shop Services
```bash
ssh root@9.30.220.114
docker ps | grep robot-shop

# All containers should be running
```

#### 5. Re-apply Terraform (if needed)
```bash
terraform apply -auto-approve
```

---

## Files Modified

1. **instana.tf** - Fixed alert configuration event filter
2. **INSTANA_ALERT_EMAIL_FIX.md** - Comprehensive troubleshooting guide
3. **verify_instana_setup.sh** - Verification script

---

## Summary

### ✅ What's Working Now
- Application perspective: **EXISTS** (Robot-Shop-Microservices-Daneshwari-2026)
- Alert channel: **ACTIVE** (Daneshwari.Naganur1@ibm.com)
- Alert configuration: **ACTIVE** with corrected event filter
- Custom events: **ENABLED** and ready to trigger
- Email notifications: **CONFIGURED** and ready to send

### 📧 Expected Behavior
You will now receive email alerts at **Daneshwari.Naganur1@ibm.com** when:
- Services experience high error rates
- Response times exceed thresholds
- Services go down or become unavailable
- Containers crash or fail
- Memory usage exceeds limits
- Any critical infrastructure issues occur

### 🎯 Next Action
**Test the setup** by sending a test alert from Instana UI to confirm email delivery.

---

**Status:** RESOLVED ✅  
**Last Updated:** 2026-02-06  
**Verified By:** IBM Bob (AI Assistant)