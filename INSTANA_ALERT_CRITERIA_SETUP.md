# Instana Alert Criteria Setup Guide

Complete guide to configure alert criteria for Robot Shop monitoring.

## 📋 Table of Contents
1. [Automatic System Alerts](#automatic-system-alerts)
2. [Custom Alert Criteria](#custom-alert-criteria)
3. [Manual Configuration Steps](#manual-configuration-steps)
4. [Alert Thresholds](#alert-thresholds)
5. [Testing Alerts](#testing-alerts)

---

## 🔔 Automatic System Alerts

These alerts are **ALREADY ACTIVE** via Terraform configuration:

### ✅ Currently Configured:
- **Alert Channel:** Robot Shop Alert Email
- **Email:** Daneshwari.Naganur1@ibm.com
- **Application Filter:** Robot-Shop-Microservices-Daneshwari-2026
- **Event Types:** Incident, Critical, Warning

### 📧 You Will Automatically Receive Alerts For:

1. **Container/Service Failures**
   - Container stops unexpectedly
   - Service becomes unavailable
   - Pod crashes (if using Kubernetes)

2. **Infrastructure Issues**
   - High CPU usage (>80% for 5 minutes)
   - High memory usage (>90% for 5 minutes)
   - Disk space low (<10% free)

3. **Network Issues**
   - Service unreachable
   - Connection timeouts
   - Network errors

---

## 🎯 Custom Alert Criteria

For application-specific alerts, you need to configure these **MANUALLY** in Instana UI.

### Alert Criteria to Configure:

#### 1. High Error Rate Alert

**Criteria:**
- **Name:** Robot Shop - High Error Rate
- **Entity Type:** Service
- **Condition:** Error rate > 5%
- **Time Window:** 5 minutes
- **Severity:** Warning

**When to Trigger:**
- More than 5% of requests return errors (4xx, 5xx)
- Sustained for at least 5 minutes

**Example Scenarios:**
- Database connection failures
- API endpoint errors
- Invalid requests

---

#### 2. High Response Time Alert

**Criteria:**
- **Name:** Robot Shop - High Response Time
- **Entity Type:** Service
- **Condition:** Mean latency > 1000ms
- **Time Window:** 5 minutes
- **Severity:** Warning

**When to Trigger:**
- Average response time exceeds 1 second
- Sustained for at least 5 minutes

**Example Scenarios:**
- Slow database queries
- Resource contention
- Network latency

---

#### 3. Service Availability Alert

**Criteria:**
- **Name:** Robot Shop - Service Down
- **Entity Type:** Service
- **Condition:** Service state = Erroneous
- **Time Window:** 1 minute
- **Severity:** Critical

**When to Trigger:**
- Service stops responding
- Health check fails
- Container crashes

**Example Scenarios:**
- Application crash
- Out of memory
- Configuration error

---

#### 4. High Traffic Alert

**Criteria:**
- **Name:** Robot Shop - Traffic Spike
- **Entity Type:** Service
- **Condition:** Call rate > 1000 calls/minute
- **Time Window:** 5 minutes
- **Severity:** Warning

**When to Trigger:**
- Sudden increase in traffic
- Potential DDoS or load spike

**Example Scenarios:**
- Marketing campaign
- Bot traffic
- Load testing

---

#### 5. Database Connection Pool Alert

**Criteria:**
- **Name:** Robot Shop - Database Connection Issues
- **Entity Type:** Service
- **Condition:** Database connection errors > 10
- **Time Window:** 5 minutes
- **Severity:** Critical

**When to Trigger:**
- Cannot connect to database
- Connection pool exhausted
- Database timeout

**Example Scenarios:**
- Database server down
- Too many connections
- Network issues

---

## 🛠️ Manual Configuration Steps

### Step 1: Create Custom Events

1. **Login to Instana:**
   - URL: https://ibmdevsandbox-instanaibm.instana.io
   - Use your IBM credentials

2. **Navigate to Events:**
   - Click **Events** in left sidebar
   - Click **Custom Events**
   - Click **+ New Event**

3. **Configure High Error Rate Event:**
   ```
   Name: Robot Shop - High Error Rate
   Description: Alert when error rate exceeds 5%
   Entity Type: Service
   Query: entity.application.name:"Robot-Shop-Microservices-Daneshwari-2026"
   
   Rule:
   - Metric: Erroneous Call Rate
   - Operator: >
   - Value: 5
   - Unit: Percent
   - Time Window: 5 minutes
   - Severity: Warning
   ```

4. **Configure High Response Time Event:**
   ```
   Name: Robot Shop - High Response Time
   Description: Alert when response time exceeds 1 second
   Entity Type: Service
   Query: entity.application.name:"Robot-Shop-Microservices-Daneshwari-2026"
   
   Rule:
   - Metric: Mean Latency
   - Operator: >
   - Value: 1000
   - Unit: Milliseconds
   - Time Window: 5 minutes
   - Severity: Warning
   ```

5. **Configure Service Down Event:**
   ```
   Name: Robot Shop - Service Down
   Description: Alert when service becomes unavailable
   Entity Type: Service
   Query: entity.application.name:"Robot-Shop-Microservices-Daneshwari-2026"
   
   Rule:
   - Metric: Service State
   - Operator: =
   - Value: Erroneous
   - Time Window: 1 minute
   - Severity: Critical
   ```

---

### Step 2: Link Events to Alert Channel

1. **Navigate to Alerting:**
   - Click **Settings** (gear icon)
   - Click **Alerting**
   - Find **"Robot Shop Monitoring Alerts"**

2. **Edit Alert Configuration:**
   - Click **Edit** button
   - Scroll to **Event Types**
   - Ensure these are selected:
     - ✅ Incident
     - ✅ Critical
     - ✅ Warning

3. **Add Custom Events:**
   - In **Event Filter**, add:
     ```
     entity.application.name:"Robot-Shop-Microservices-Daneshwari-2026"
     ```

4. **Save Configuration**

---

## 📊 Alert Thresholds Reference

| Alert Type | Metric | Threshold | Time Window | Severity |
|------------|--------|-----------|-------------|----------|
| **High Error Rate** | Error Rate | > 5% | 5 minutes | Warning |
| **Very High Error Rate** | Error Rate | > 20% | 5 minutes | Critical |
| **High Response Time** | Mean Latency | > 1000ms | 5 minutes | Warning |
| **Very High Response Time** | Mean Latency | > 3000ms | 5 minutes | Critical |
| **Service Down** | Service State | Erroneous | 1 minute | Critical |
| **High CPU** | CPU Usage | > 80% | 5 minutes | Warning |
| **Very High CPU** | CPU Usage | > 95% | 5 minutes | Critical |
| **High Memory** | Memory Usage | > 85% | 5 minutes | Warning |
| **Very High Memory** | Memory Usage | > 95% | 5 minutes | Critical |
| **Traffic Spike** | Call Rate | > 1000/min | 5 minutes | Warning |
| **Database Errors** | DB Connection Errors | > 10 | 5 minutes | Critical |

---

## 🧪 Testing Alerts

### Test 1: High Error Rate

**Generate 404 errors:**
```bash
# On VM (root@obscode1)
for i in {1..100}; do
  curl -s http://localhost:8080/nonexistent-page-$i > /dev/null
  sleep 0.5
done
```

**Expected Result:**
- Error rate increases in Instana
- Alert triggered after 5 minutes
- Email received: "Robot Shop - High Error Rate"

---

### Test 2: High Response Time

**Generate slow requests:**
```bash
# On VM
for i in {1..50}; do
  curl -s http://localhost:8080/api/slow-endpoint > /dev/null &
done
wait
```

**Expected Result:**
- Response time increases in Instana
- Alert triggered after 5 minutes
- Email received: "Robot Shop - High Response Time"

---

### Test 3: Service Down

**Stop a service:**
```bash
# On VM
cd /opt/robot-shop
docker-compose stop payment
```

**Expected Result:**
- Service state changes to "Erroneous"
- Alert triggered immediately
- Email received: "Robot Shop - Service Down"

**Restore service:**
```bash
docker-compose start payment
```

---

### Test 4: High Load

**Generate high traffic:**
```bash
# On VM
apt-get install -y apache2-utils
ab -n 10000 -c 100 http://localhost:8080/
```

**Expected Result:**
- Call rate increases
- CPU/Memory usage increases
- Multiple alerts may trigger
- Emails received for resource alerts

---

## 📧 Email Alert Format

### Example Alert Email:

```
Subject: [Instana Alert] Robot Shop Monitoring Alerts - High Error Rate

Alert Name: Robot Shop Monitoring Alerts
Application: Robot-Shop-Microservices-Daneshwari-2026
Service: payment
Event: Robot Shop - High Error Rate

Status: TRIGGERED
Severity: Warning
Timestamp: 2026-02-02 12:45:00 UTC

Details:
Error rate has exceeded 5% threshold
Current error rate: 12.5%
Time window: Last 5 minutes

Affected Endpoints:
- POST /api/payment/process (15% error rate)
- GET /api/payment/status (8% error rate)

View in Instana: [Link to Instana Dashboard]
```

---

## ✅ Verification Checklist

After configuration, verify:

- [ ] Email channel created and active
- [ ] Alert configuration linked to email channel
- [ ] Application filter applied (Robot-Shop-Microservices-Daneshwari-2026)
- [ ] Custom events created (High Error Rate, High Response Time, Service Down)
- [ ] Custom events linked to alert configuration
- [ ] Test alerts triggered successfully
- [ ] Email alerts received at Daneshwari.Naganur1@ibm.com
- [ ] Alert emails contain proper formatting (name, type, status)

---

## 🔧 Troubleshooting

### Not Receiving Alerts?

1. **Check Email Channel:**
   - Settings → Alert Channels
   - Verify "Robot Shop Alert Email" is active
   - Test email delivery

2. **Check Alert Configuration:**
   - Settings → Alerting
   - Verify "Robot Shop Monitoring Alerts" is active
   - Check event filter query

3. **Check Custom Events:**
   - Events → Custom Events
   - Verify events are enabled
   - Check event conditions

4. **Check Application Perspective:**
   - Applications → Robot-Shop-Microservices-Daneshwari-2026
   - Verify services are visible
   - Check metrics are being collected

5. **Check Spam Folder:**
   - Instana emails may be filtered
   - Add instana.io to safe senders

---

## 📞 Support

If alerts still not working:

1. **Check Instana Agent:**
   ```bash
   systemctl status instana-agent
   ```

2. **Check Agent Logs:**
   ```bash
   journalctl -u instana-agent -f
   ```

3. **Verify Terraform Applied:**
   ```bash
   terraform show | grep instana_alerting
   ```

4. **Contact Instana Support:**
   - Include: Alert configuration details
   - Include: Application name
   - Include: Email address

---

## 📚 Additional Resources

- [Instana Alert Documentation](https://www.ibm.com/docs/en/instana-observability/current?topic=instana-alerts)
- [Custom Events Guide](https://www.ibm.com/docs/en/instana-observability/current?topic=events-custom)
- [Alert Channels Guide](https://www.ibm.com/docs/en/instana-observability/current?topic=alerts-alert-channels)

---

**Last Updated:** 2026-02-02  
**Version:** 1.0  
**Author:** Bob (AI Assistant)