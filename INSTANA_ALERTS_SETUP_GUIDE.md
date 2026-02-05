# How to Get Alerts from Instana - Complete Setup Guide

## Prerequisites
✅ Instana agent deployed on VM (9.30.213.70)
✅ Robot Shop application running
✅ Email alert channel configured (Daneshwari.Naganur1@ibm.com)

## Step-by-Step: Configure Alerts in Instana UI

### Step 1: Login to Instana
```
URL: https://test-instana.instana.io
Login: Use your IBM credentials
```

### Step 2: Create Application Perspective

1. **Navigate to Applications**
   - Click **Applications** in left sidebar
   - Click **+ Create Application Perspective**

2. **Configure Application**
   - **Name**: `Robot Shop`
   - **Scope**: Select `Include all downstream services`
   - **Boundary Scope**: `All Calls`

3. **Add Tag Filter**
   - Click **Add Filter**
   - Select: `Tag` → `service.name`
   - Operator: `CONTAINS`
   - Value: `robot-shop`
   - Click **Create**

### Step 3: Create Custom Event - High Error Rate

1. **Navigate to Events**
   - Click **Events** in left sidebar
   - Click **Custom Events** tab
   - Click **+ New Event**

2. **Configure Event**
   - **Name**: `Robot Shop - High Error Rate`
   - **Description**: `Alert when error rate exceeds threshold`
   - **Entity Type**: Select `Service`
   - **Enabled**: ✅ Check
   - **Triggering**: ✅ Check

3. **Add Query Filter**
   - Click **Add Filter**
   - Select: `Tag` → `service.name`
   - Operator: `CONTAINS`
   - Value: `robot-shop`

4. **Add Condition**
   - Click **Add Condition**
   - **Metric**: Select `Erroneous Call Rate`
   - **Operator**: `>`
   - **Value**: `5` (5% error rate)
   - **Time Window**: `5 minutes`
   - **Severity**: `Warning`

5. **Save Event**
   - Click **Create**

### Step 4: Create Custom Event - High Response Time

1. **Create New Event**
   - Events → Custom Events → **+ New Event**

2. **Configure Event**
   - **Name**: `Robot Shop - High Response Time`
   - **Description**: `Alert when response time is high`
   - **Entity Type**: `Service`
   - **Enabled**: ✅ Check
   - **Triggering**: ✅ Check

3. **Add Query Filter**
   - Tag: `service.name` CONTAINS `robot-shop`

4. **Add Condition**
   - **Metric**: `Latency` or `Mean Response Time`
   - **Operator**: `>`
   - **Value**: `1000` (1000ms = 1 second)
   - **Time Window**: `5 minutes`
   - **Severity**: `Warning`

5. **Save Event**

### Step 5: Link Alerts to Email Channel

1. **Navigate to Alert Channels**
   - Click **Settings** (gear icon)
   - Click **Team Settings**
   - Click **Alert Channels**

2. **Verify Email Channel**
   - You should see: `Robot Shop Alert Email`
   - Email: `Daneshwari.Naganur1@ibm.com`
   - Status: Active ✅

3. **Create Alert Configuration**
   - Click **Alerting** in Settings
   - Click **+ New Alert Configuration**

4. **Configure Alert**
   - **Name**: `Robot Shop Monitoring Alerts`
   - **Alert on Events**: Select `Custom Events`
   - **Scope**: Select `Application` → `Robot Shop`

5. **Select Events**
   - ✅ `Robot Shop - High Error Rate`
   - ✅ `Robot Shop - High Response Time`
   - ✅ System events (CPU, Memory, Disk)

6. **Select Alert Channels**
   - ✅ `Robot Shop Alert Email`

7. **Configure Severity**
   - ✅ Critical
   - ✅ Warning
   - ✅ Change (optional)

8. **Save Configuration**
   - Click **Create**

### Step 6: Test Alerts (Optional)

#### Method 1: Trigger High Error Rate
```bash
# SSH to server
ssh root@9.30.213.70

# Generate errors by stopping a service temporarily
docker stop catalogue

# Wait 5 minutes, then restart
docker start catalogue
```

#### Method 2: Trigger High Response Time
```bash
# Generate load on the application
for i in {1..100}; do
  curl http://9.30.213.70:8080 &
done
```

#### Method 3: Use Instana Test Alert
1. Go to: Settings → Alert Channels
2. Click on `Robot Shop Alert Email`
3. Click **Send Test Alert**
4. Check your email

## How Alerts Work

### Alert Flow:
```
1. Instana Agent collects metrics from Robot Shop
   ↓
2. Metrics are analyzed against custom event conditions
   ↓
3. If condition is met (e.g., error rate > 5%)
   ↓
4. Custom Event is triggered
   ↓
5. Alert Configuration matches the event
   ↓
6. Email is sent to Daneshwari.Naganur1@ibm.com
   ↓
7. Alert appears in Instana UI (Events page)
```

### Alert Timing:
- **Detection**: Real-time (within seconds)
- **Evaluation**: Based on time window (e.g., 5 minutes)
- **Notification**: Immediate after condition is met
- **Email Delivery**: Within 1-2 minutes

## Where to See Alerts

### 1. Email Inbox
- **To**: Daneshwari.Naganur1@ibm.com
- **Subject**: `[Instana Alert] Robot Shop - High Error Rate`
- **Content**: Alert details, severity, affected service, link to Instana

### 2. Instana UI - Events Page
```
URL: https://test-instana.instana.io/#/events
```
- View all active and historical events
- Filter by severity, time, application
- Click event for detailed analysis

### 3. Instana UI - Application Dashboard
```
URL: https://test-instana.instana.io/#/applications
```
- Select `Robot Shop` application
- See application health and active alerts
- View service dependency map with issues highlighted

### 4. Instana Mobile App (Optional)
- Download Instana mobile app
- Login with same credentials
- Receive push notifications for critical alerts

## Alert Types You'll Receive

### 1. Custom Events (Configured Above)
- ✅ High Error Rate (>5%)
- ✅ High Response Time (>1000ms)

### 2. System Events (Automatic)
- High CPU usage (>80%)
- High memory usage (>90%)
- Low disk space (<10%)
- Container crashes
- Service unavailability

### 3. Infrastructure Events (Automatic)
- Host down
- Docker daemon issues
- Network connectivity problems

## Troubleshooting: Not Receiving Alerts

### Check 1: Verify Email Channel
```
Settings → Alert Channels → Robot Shop Alert Email
Status should be: Active ✅
```

### Check 2: Verify Custom Events
```
Events → Custom Events
Both events should be: Enabled ✅, Triggering ✅
```

### Check 3: Verify Alert Configuration
```
Settings → Alerting
Robot Shop Monitoring Alerts should be: Active ✅
```

### Check 4: Check Email Spam Folder
- Instana emails might be filtered as spam
- Add `@instana.io` to safe senders list

### Check 5: Verify Instana Agent
```bash
# SSH to server
ssh root@9.30.213.70

# Check agent status
systemctl status instana-agent

# Check agent logs
journalctl -u instana-agent -f
```

### Check 6: Verify Robot Shop is Running
```bash
# Check containers
docker ps

# All services should be running:
# web, catalogue, cart, user, payment, shipping, ratings, mongodb, redis, mysql
```

## Quick Reference Commands

### Check Alert Configuration
```bash
# Via Terraform
terraform output

# Shows:
# - instana_readonly_token (for API access)
# - Alert channel ID
```

### Manual Alert Test
```bash
# Send test email from Instana UI
Settings → Alert Channels → Robot Shop Alert Email → Send Test Alert
```

### View Recent Alerts
```bash
# In Instana UI
Events → Filter by: Last 24 hours, Application: Robot Shop
```

## Summary Checklist

To receive alerts, ensure:
- ✅ Instana agent is running on VM
- ✅ Robot Shop containers are running
- ✅ Application Perspective created
- ✅ Custom Events configured and enabled
- ✅ Alert Configuration created and active
- ✅ Email channel verified
- ✅ Email address correct: Daneshwari.Naganur1@ibm.com

**Once all steps are complete, you will receive alerts via email and see them in Instana UI.**

## Next Steps

1. **Connect to VPN** (to access 9.30.213.70)
2. **Deploy Robot Shop** (run playbook or manual commands)
3. **Wait 10 minutes** for Instana to collect initial data
4. **Configure alerts** following this guide
5. **Test alerts** by triggering conditions
6. **Monitor** via email and Instana UI

For questions or issues, check Instana documentation: https://www.ibm.com/docs/en/instana-observability