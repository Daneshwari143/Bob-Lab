
# Robot Shop Microservices - Solution Architecture

## Executive Summary

This document presents the solution architecture for deploying and monitoring the Robot Shop e-commerce microservices application with Instana APM on IBM infrastructure.

---

## 1. Solution Overview

### Business Context
- **Application**: Robot Shop - Microservices-based e-commerce platform
- **Purpose**: Demonstrate modern cloud-native architecture with comprehensive monitoring
- **Target Environment**: IBM Private Cloud (9.30.x.x network)
- **Monitoring**: Instana Application Performance Monitoring (APM)

### Key Objectives
1. Deploy polyglot microservices architecture (8 services in 6 languages)
2. Implement automated CI/CD pipeline
3. Enable real-time application monitoring
4. Configure intelligent alerting system
5. Ensure high availability and scalability

---

## 2. High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          SOLUTION ARCHITECTURE                               │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────┐         ┌──────────────────┐         ┌──────────────────┐
│   Development    │         │   CI/CD Layer    │         │  Monitoring      │
│   Environment    │────────▶│   (Jenkins)      │────────▶│  Platform        │
│                  │         │                  │         │  (Instana)       │
│  • Git Repo      │         │  • Build         │         │                  │
│  • Terraform     │         │  • Test          │         │  • APM           │
│  • Ansible       │         │  • Deploy        │         │  • Alerts        │
│  • Configs       │         │  • Verify        │         │  • Analytics     │
└──────────────────┘         └──────────────────┘         └──────────────────┘
         │                            │                            ▲
         │                            │                            │
         │                            ▼                            │
         │                   ┌──────────────────┐                 │
         │                   │  Infrastructure  │                 │
         └──────────────────▶│  Provisioning    │                 │
                             │  (Terraform)     │                 │
                             └──────────────────┘                 │
                                      │                            │
                                      ▼                            │
                             ┌──────────────────┐                 │
                             │  Configuration   │                 │
                             │  Management      │                 │
                             │  (Ansible)       │                 │
                             └──────────────────┘                 │
                                      │                            │
                                      ▼                            │
         ┌────────────────────────────────────────────────────────┤
         │                                                         │
         │              RUNTIME ENVIRONMENT                        │
         │         VM: 9.30.213.70 (obscode1)                     │
         │         OS: Ubuntu 22.04 LTS                           │
         │                                                         │
         │  ┌─────────────────────────────────────────────────┐  │
         │  │         Docker Container Platform               │  │
         │  │                                                 │  │
         │  │  ┌──────────────┐  ┌──────────────┐           │  │
         │  │  │  Frontend    │  │  Business    │           │  │
         │  │  │  Layer       │  │  Logic       │           │  │
         │  │  │              │  │  Layer       │           │  │
         │  │  │  • Web UI    │  │  • Cart      │           │  │
         │  │  │    (8080)    │  │  • Catalogue │           │  │
         │  │  │              │  │  • User      │           │  │
         │  │  │              │  │  • Payment   │           │  │
         │  │  │              │  │  • Shipping  │           │  │
         │  │  │              │  │  • Dispatch  │           │  │
         │  │  │              │  │  • Ratings   │           │  │
         │  │  └──────────────┘  └──────────────┘           │  │
         │  │                                                │  │
         │  │  ┌──────────────────────────────────────────┐ │  │
         │  │  │         Data Layer                       │ │  │
         │  │  │                                          │ │  │
         │  │  │  • MySQL (Shipping, Ratings)            │ │  │
         │  │  │  • MongoDB (Catalogue, User)            │ │  │
         │  │  │  • Redis (Cart Cache)                   │ │  │
         │  │  │  • RabbitMQ (Dispatch Queue)            │ │  │
         │  │  └──────────────────────────────────────────┘ │  │
         │  │                                                │  │
         │  │  ┌──────────────────────────────────────────┐ │  │
         │  │  │         Instana Agent                    │ │  │
         │  │  │  • Container Monitoring                  │ │  │
         │  │  │  • Metrics Collection                    │ │  │
         │  │  │  • Trace Aggregation                     │ │  │
         │  │  └──────────────────────────────────────────┘ │  │
         │  └─────────────────────────────────────────────────┘  │
         └─────────────────────────────────────────────────────────┘
                                      │
                                      │ Metrics & Traces
                                      │
                                      ▼
                             ┌──────────────────┐
                             │  Instana Cloud   │
                             │  Platform        │
                             │                  │
                             │  • Data Analysis │
                             │  • Alerting      │
                             │  • Dashboards    │
                             └──────────────────┘
```

---

## 3. Component Architecture

### 3.1 Application Layer

#### Frontend Services
```
┌─────────────────────────────────────────────────────────────┐
│                    FRONTEND LAYER                            │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │  Web Service (Port 8080)                           │    │
│  │  ─────────────────────────────────────────────     │    │
│  │  Technology: nginx + Angular                       │    │
│  │  Purpose: User interface and static content        │    │
│  │  Responsibilities:                                 │    │
│  │    • Serve web application                         │    │
│  │    • Route API requests                            │    │
│  │    • Handle user interactions                      │    │
│  │    • Display product catalog                       │    │
│  │    • Manage shopping cart UI                       │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

#### Business Logic Services
```
┌─────────────────────────────────────────────────────────────┐
│                  BUSINESS LOGIC LAYER                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Cart       │  │  Catalogue   │  │    User      │     │
│  │  (Node.js)   │  │  (Node.js)   │  │  (Node.js)   │     │
│  │              │  │              │  │              │     │
│  │ • Add items  │  │ • Products   │  │ • Auth       │     │
│  │ • Update qty │  │ • Search     │  │ • Profile    │     │
│  │ • Checkout   │  │ • Categories │  │ • Register   │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Payment    │  │   Shipping   │  │   Dispatch   │     │
│  │  (Python)    │  │   (Java)     │  │    (Go)      │     │
│  │              │  │              │  │              │     │
│  │ • Process    │  │ • Calculate  │  │ • Queue      │     │
│  │ • Validate   │  │ • Track      │  │ • Notify     │     │
│  │ • Confirm    │  │ • Deliver    │  │ • Status     │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│                                                              │
│  ┌──────────────┐                                           │
│  │   Ratings    │                                           │
│  │    (PHP)     │                                           │
│  │              │                                           │
│  │ • Reviews    │                                           │
│  │ • Stars      │                                           │
│  │ • Comments   │                                           │
│  └──────────────┘                                           │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

#### Data Layer
```
┌─────────────────────────────────────────────────────────────┐
│                      DATA LAYER                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐  ┌──────────────┐                        │
│  │    MySQL     │  │   MongoDB    │                        │
│  │   (5.7)      │  │     (4)      │                        │
│  │              │  │              │                        │
│  │ • Shipping   │  │ • Catalogue  │                        │
│  │ • Ratings    │  │ • User       │                        │
│  │ • Orders     │  │ • Products   │                        │
│  └──────────────┘  └──────────────┘                        │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐                        │
│  │    Redis     │  │  RabbitMQ    │                        │
│  │     (6)      │  │    (3.8)     │                        │
│  │              │  │              │                        │
│  │ • Cart Cache │  │ • Dispatch   │                        │
│  │ • Sessions   │  │ • Messages   │                        │
│  │ • Temp Data  │  │ • Events     │                        │
│  └──────────────┘  └──────────────┘                        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 Infrastructure Layer

```
┌─────────────────────────────────────────────────────────────┐
│                  INFRASTRUCTURE LAYER                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Virtual Machine (9.30.213.70 - obscode1)                   │
│  ─────────────────────────────────────────────────          │
│  • Operating System: Ubuntu 22.04 LTS                       │
│  • CPU: Multi-core                                          │
│  • Memory: Sufficient for 12 containers                     │
│  • Storage: Local disk                                      │
│  • Network: Private IP (9.30.x.x range)                     │
│  • Access: VPN required                                     │
│                                                              │
│  Container Platform                                          │
│  ─────────────────────────────────────────────────          │
│  • Docker Engine: 24.0.7                                    │
│  • Docker Compose: v2.24.0 (standalone)                     │
│  • Container Runtime: containerd                            │
│  • Network Mode: Bridge                                     │
│  • Volume Management: Local volumes                         │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 3.3 Monitoring Layer

```
┌─────────────────────────────────────────────────────────────┐
│                   MONITORING LAYER                           │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Instana Platform (ibmdevsandbox-instanaibm.instana.io)     │
│  ─────────────────────────────────────────────────────────  │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │  Application Perspective                           │    │
│  │  ────────────────────────────────────────────      │    │
│  │  Name: Robot-Shop-Microservices-Daneshwari-2026   │    │
│  │  Scope: All Robot Shop services                   │    │
│  │  Metrics: Response time, error rate, throughput   │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │  Custom Alert Events (5)                           │    │
│  │  ────────────────────────────────────────────      │    │
│  │  1. High Error Rate (>5%)                          │    │
│  │     • Trigger: Error rate exceeds threshold        │    │
│  │     • Severity: Critical                           │    │
│  │     • Action: Immediate investigation              │    │
│  │                                                     │    │
│  │  2. High Response Time (>1000ms)                   │    │
│  │     • Trigger: Latency exceeds 1 second            │    │
│  │     • Severity: Warning                            │    │
│  │     • Action: Performance optimization             │    │
│  │                                                     │    │
│  │  3. Service Down                                   │    │
│  │     • Trigger: Service unavailable                 │    │
│  │     • Severity: Critical                           │    │
│  │     • Action: Immediate restart/recovery           │    │
│  │                                                     │    │
│  │  4. Container Failure                              │    │
│  │     • Trigger: Container crash/exit                │    │
│  │     • Severity: Critical                           │    │
│  │     • Action: Container restart                    │    │
│  │                                                     │    │
│  │  5. High Memory Usage (>90%)                       │    │
│  │     • Trigger: Memory threshold exceeded           │    │
│  │     • Severity: Warning                            │    │
│  │     • Action: Resource scaling                     │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │  Alert Channel                                     │    │
│  │  ────────────────────────────────────────────      │    │
│  │  Type: Email                                       │    │
│  │  Recipient: Daneshwari.Naganur1@ibm.com           │    │
│  │  Events: Incident, Critical, Warning               │    │
│  │  Filter: Robot-Shop-Microservices-Daneshwari-2026 │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │  Instana Agent (VM-based)                          │    │
│  │  ────────────────────────────────────────────      │    │
│  │  • Auto-discovery of containers                    │    │
│  │  • Metrics collection (CPU, Memory, Network)       │    │
│  │  • Distributed tracing                             │    │
│  │  • Log aggregation                                 │    │
│  │  • Real-time data streaming                        │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 3.4 CI/CD Pipeline

```
┌─────────────────────────────────────────────────────────────┐
│                    CI/CD PIPELINE                            │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Jenkins Pipeline (Automated Deployment)                     │
│  ─────────────────────────────────────────────────────────  │
│                                                              │
│  Stage 1: Checkout                                           │
│  ┌────────────────────────────────────────────────────┐    │
│  │  • Clone Git repository                            │    │
│  │  • Fetch latest code                               │    │
│  │  • Load configuration files                        │    │
│  └────────────────────────────────────────────────────┘    │
│                          ↓                                   │
│  Stage 2: Validate                                           │
│  ┌────────────────────────────────────────────────────┐    │
│  │  • Validate Terraform syntax                       │    │
│  │  • Check Ansible playbook                          │    │
│  │  • Verify configuration files                      │    │
│  └────────────────────────────────────────────────────┘    │
│                          ↓                                   │
│  Stage 3: Terraform Init                                     │
│  ┌────────────────────────────────────────────────────┐    │
│  │  • Initialize Terraform                            │    │
│  │  • Download providers                              │    │
│  │  • Setup backend                                   │    │
│  └────────────────────────────────────────────────────┘    │
│                          ↓                                   │
│  Stage 4: Terraform Plan                                     │
│  ┌────────────────────────────────────────────────────┐    │
│  │  • Generate execution plan                         │    │
│  │  • Show resource changes                           │    │
│  │  • Validate configuration                          │    │
│  └────────────────────────────────────────────────────┘    │
│                          ↓                                   │
│  Stage 5: Terraform Apply                                    │
│  ┌────────────────────────────────────────────────────┐    │
│  │  • Create Instana resources                        │    │
│  │    - Application Perspective                       │    │
│  │    - Custom Alert Events (5)                       │    │
│  │    - Email Alert Channel                           │    │
│  │    - Alert Configuration                           │    │
│  │    - API Token                                     │    │
│  └────────────────────────────────────────────────────┘    │
│                          ↓                                   │
│  Stage 6: Wait for VM                                        │
│  ┌────────────────────────────────────────────────────┐    │
│  │  • Check VM connectivity                           │    │
│  │  • Verify SSH access                               │    │
│  │  • Ensure VM is ready                              │    │
│  └────────────────────────────────────────────────────┘    │
│                          ↓                                   │
│  Stage 7: Run Ansible                                        │
│  ┌────────────────────────────────────────────────────┐    │
│  │  • Install Docker & Docker Compose                 │    │
│  │  • Install Instana agent                           │    │
│  │  • Create configuration files                      │    │
│  │  • Deploy Robot Shop containers                    │    │
│  │  • Configure monitoring                            │    │
│  └────────────────────────────────────────────────────┘    │
│                          ↓                                   │
│  Stage 8: Verify Deployment                                  │
│  ┌────────────────────────────────────────────────────┐    │
│  │  • Check all 12 containers running                 │    │
│  │  • Verify container health                         │    │
│  │  • Test web interface (port 8080)                  │    │
│  │  • Validate service connectivity                   │    │
│  └────────────────────────────────────────────────────┘    │
│                          ↓                                   │
│  Stage 9: Verify Instana                                     │
│  ┌────────────────────────────────────────────────────┐    │
│  │  • Confirm agent connection                        │    │
│  │  • Verify metrics collection                       │    │
│  │  • Check alert configuration                       │    │
│  │  • Validate monitoring setup                       │    │
│  └────────────────────────────────────────────────────┘    │
│                          ↓                                   │
│  ✓ Deployment Complete                                       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. Data Flow Architecture

### 4.1 User Request Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    USER REQUEST FLOW                         │
└─────────────────────────────────────────────────────────────┘

1. User Access
   ↓
   [User Browser] → http://9.30.213.70:8080
   ↓
2. Frontend Layer
   ↓
   [Web Service (nginx + Angular)]
   • Serves static content
   • Routes API requests
   • Handles user interactions
   ↓
3. API Gateway Layer
   ↓
   [Cart Service] ←→ [Catalogue Service] ←→ [User Service]
   • Process business logic
   • Validate requests
   • Coordinate operations
   ↓
4. Backend Services Layer
   ↓
   [Payment] ←→ [Shipping] ←→ [Dispatch] ←→ [Ratings]
   • Execute transactions
   • Process orders
   • Handle notifications
   ↓
5. Data Layer
   ↓
   [MySQL] ←→ [MongoDB] ←→ [Redis] ←→ [RabbitMQ]
   • Persist data
   • Cache results
   • Queue messages
   ↓
6. Response
   ↓
   [User Browser] ← Response with data
```

### 4.2 Monitoring Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                  MONITORING DATA FLOW                        │
└─────────────────────────────────────────────────────────────┘

1. Container Metrics
   ↓
   [12 Docker Containers]
   • CPU usage
   • Memory consumption
   • Network traffic
   • Disk I/O
   ↓
2. Agent Collection
   ↓
   [Instana Agent on VM]
   • Auto-discover containers
   • Collect metrics (1-second granularity)
   • Aggregate traces
   • Buffer data
   ↓
3. Data Transmission
   ↓
   [Secure Connection to Instana Cloud]
   • Encrypted transmission
   • Real-time streaming
   • Batch processing
   ↓
4. Platform Processing
   ↓
   [Instana Platform]
   • Data analysis
   • Pattern recognition
   • Anomaly detection
   • Correlation
   ↓
5. Alert Evaluation
   ↓
   [Alert Engine]
   • Check thresholds
   • Evaluate conditions
   • Trigger events
   ↓
6. Notification
   ↓
   [Email Alert Channel]
   • Format message
   • Send to: Daneshwari.Naganur1@ibm.com
   • Include context and details
```

---

## 5. Security Architecture

### 5.1 Network Security

```
┌─────────────────────────────────────────────────────────────┐
│                   NETWORK SECURITY                           │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Network Isolation                                           │
│  ─────────────────────────────────────────────────────────  │
│  • Private IP Range: 9.30.x.x                               │
│  • VPN Required: Yes                                        │
│  • Firewall: Configured                                     │
│  • Port Exposure: Minimal (8080 only)                       │
│                                                              │
│  Access Control                                              │
│  ─────────────────────────────────────────────────────────  │
│  • SSH Access: Password-based (root)                        │
│  • Web Access: Port 8080                                    │
│  • Container Network: Bridge mode (isolated)                │
│  • Inter-service Communication: Internal only               │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 5.2 Authentication & Authorization

```
┌─────────────────────────────────────────────────────────────┐
│            AUTHENTICATION & AUTHORIZATION                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Instana Access                                              │
│  ─────────────────────────────────────────────────────────  │
│  • API Token: Read-only access                              │
│  • Endpoint: ibmdevsandbox-instanaibm.instana.io            │
│  • Authentication: Token-based                              │
│  • Scope: Application monitoring only                       │
│                                                              │
│  VM Access                                                   │
│  ─────────────────────────────────────────────────────────  │
│  • User: root                                               │
│  • Authentication: Password                                 │
│  • Access Method: SSH (via VPN)                             │
│                                                              │
│  Application Access                                          │
│  ─────────────────────────────────────────────────────────  │
│  • User Service: Authentication required                    │
│  • Session Management: Redis-based                          │
│  • Token Validation: JWT                                    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 6. Scalability & High Availability

### 6.1 Current Architecture

```
┌─────────────────────────────────────────────────────────────┐
│              CURRENT DEPLOYMENT MODEL                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Single VM Deployment                                        │
│  ─────────────────────────────────────────────────────────  │
│  • VM: 9.30.213.70 (obscode1)                               │
│  • Containers: 12 (all on single host)                      │
│  • Availability: Single point of failure                    │
│  • Scalability: Vertical scaling only                       │
│                                                              │
│  Container Orchestration                                     │
│  ─────────────────────────────────────────────────────────  │
│  • Tool: Docker Compose                                     │
│  • Restart Policy: Always                                   │
│  • Health Checks: Configured                                │
│  • Auto-restart: Enabled                                    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 6.2 Future Scalability Options

```
┌─────────────────────────────────────────────────────────────┐
│              SCALABILITY ROADMAP                             │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Phase 1: Horizontal Scaling (Future)                        │
│  ─────────────────────────────────────────────────────────  │
│  • Multiple VM instances                                    │
│  • Load balancer                                            │
│  • Shared data stores                                       │
│  • Session replication                                      │
│                                                              │
│  Phase 2: Container Orchestration (Future)                   │
│  ─────────────────────────────────────────────────────────  │
│  • Kubernetes/OpenShift                                     │
│  • Auto-scaling                                             │
│  • Self-healing                                             │
│  • Rolling updates                                          │
│                                                              │
│  Phase 3: Cloud-Native (Future)                              │
│  ─────────────────────────────────────────────────────────  │
│  • Managed services                                         │
│  • Serverless functions                                     │
│  • CDN integration                                          │
│  • Global distribution                                      │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 7. Technology Stack

### 7.1 Infrastructure Technologies

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| **Operating System** | Ubuntu | 22.04 LTS | Base OS |
| **Container Runtime** | Docker | 24.0.7 | Container execution |
| **Container Orchestration** | Docker Compose | v2.24.0 | Multi-container management |
| **Infrastructure as Code** | Terraform | Latest | Resource provisioning |
| **Configuration Management** | Ansible | Latest | VM configuration |
| **CI/CD** | Jenkins | Latest | Automated deployment |

### 7.2 Application Technologies

| Service | Language/Framework | Version | Purpose |
|---------|-------------------|---------|---------|
| **Web** | nginx + Angular | Latest | Frontend UI |
| **Cart** | Node.js | Latest | Shopping cart |
| **Catalogue** | Node.js | Latest | Product catalog |
| **User** | Node.js | Latest | User management |
| **Payment** | Python | Latest | Payment processing |
| **Shipping** | Java | Latest | Shipping calculation |
| **Dispatch** | Go | Latest | Order dispatch |
| **Ratings** | PHP | Latest | Product ratings |

### 7.3 Data Store Technologies

| Store | Technology | Version | Purpose |
|-------|-----------|---------|---------|
| **Relational DB** | MySQL | 5.7 | Shipping, Ratings data |
| **Document DB** | MongoDB | 4 | Catalogue, User data |
| **Cache** | Redis | 6 | Cart cache, Sessions |
| **Message Queue** | RabbitMQ | 3.8 | Dispatch messages |

### 7.4 Monitoring Technologies

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **APM Platform** | Instana | Application monitoring |
| **Agent** | Instana Agent | Metrics collection |
| **Alerting** | Instana Alerts | Event notifications |
| **Notification** | Email | Alert delivery |

---

## 8. Deployment Architecture

### 8.1 Deployment Topology

```
┌─────────────────────────────────────────────────────────────┐
│                  DEPLOYMENT TOPOLOGY                         │
└─────────────────────────────────────────────────────────────┘

                    [Developer Workstation]
                             │
                             │ Git Push
                             ↓
                      [Git Repository]
                             │
                             │ Webhook
                             ↓
                    [Jenkins CI/CD Server]
                             │
                    ┌────────┴────────┐
                    │                 │
                    ↓                 ↓
            [Terraform]        [Ansible]
                    │                 │
                    │                 │
                    ↓                 ↓
            [Instana Cloud]    [VM: 9.30.213.70]
                    │                 │
                    │                 ↓
                    │         [Docker Containers]
                    │                 │
                    │                 │
                    └────────┬────────┘
                             │
                             ↓
                    [Monitoring & Alerts]
```

### 8.2 Container Deployment

```
┌─────────────────────────────────────────────────────────────┐
│              CONTAINER DEPLOYMENT LAYOUT                     │
└─────────────────────────────────────────────────────────────┘

VM: 9.30.213.70 (obscode1)
│
├── Docker Network: robot-shop
│   │
│   ├── Frontend Tier
│   │   └── web:8080 (nginx + Angular)
│   │
│   ├── Application Tier
│   │   ├── cart:8080 (Node.js)
│   │   ├── catalogue:8080 (Node.js)
│   │   ├── user:8080 (Node.js)
│   │   ├── payment:8080 (Python)
│   │   ├── shipping:8080 (Java)
│   │   ├── dispatch:8080 (Go)
│   │   └── ratings:8080 (PHP)
│   │
│   └── Data Tier
│       ├── mysql:3306 (MySQL 5.7)
│       ├── mongodb:27017 (MongoDB 4)
│       ├── redis:6379 (Redis 6)
│       └── rabbitmq:5672 (RabbitMQ 3.8)
│
└── Instana Agent (Host-based)
    └── Monitors all containers
```

---

## 9. Monitoring & Observability

### 9.1 Monitoring Strategy

```
┌─────────────────────────────────────────────────────────────┐
│                 MONITORING STRATEGY                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Application Performance Monitoring (APM)                    │
│  ─────────────────────────────────────────────────────────  │
│  • Real-time metrics (1-second granularity)                 │
│  • Distributed tracing                                      │
│  • Service dependency mapping                               │
│  • Error tracking                                           │
│  • Performance analytics                                    │
│                                                              │
│  Infrastructure Monitoring                                   │
│  ─────────────────────────────────────────────────────────  │
│  • Container health                                         │
│  • Resource utilization (CPU, Memory, Disk, Network)        │
│  • Host metrics                                             │
│  • Docker daemon status                                     │
│                                                              │
│  Business Metrics                                            │
│  ─────────────────────────────────────────────────────────  │
│  • Request rate                                             │
│  • Response time                                            │
│  • Error rate                                               │
│  • Throughput                                               │
│  • User transactions                                        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 9.2 Alert Configuration

```
┌─────────────────────────────────────────────────────────────┐
│                  ALERT CONFIGURATION                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Alert Event 1: High Error Rate                             │
│  ─────────────────────────────────────────────────────────  │
│  Condition: Error rate > 5%                                 │
│  Severity: Critical                                         │
│  Threshold: 5% of requests                                  │
│  Duration: Immediate                                        │
│  Action: Email notification                                 │
│  Impact: Service degradation                                │
│                                                              │
│  Alert Event 2: High Response Time                          │
│  ─────────────────────────────────────────────────────────  │
│  Condition: Response time > 1000ms                          │
│  Severity: Warning                                          │
│  Threshold: 1 second                                        │
│  Duration: Sustained for 2 minutes                          │
│  Action: Email notification                                 │
│  Impact: Poor user experience                               │
│                                                              │
│  Alert Event 3: Service Down                                │
│  ─────────────────────────────────────────────────────────  │
│  Condition: Service unavailable                             │
│  Severity: Critical                                         │
│  Threshold: No response                                     │
│  Duration: Immediate                                        │
│  Action: Email notification                                 │
│  Impact: Service outage                                     │
│                                                              │
│  Alert Event 4: Container Failure                           │
│  ─────────────────────────────────────────────────────────  │
│  Condition: Container crash/exit                            │
│  Severity: Critical                                         │
│  Threshold: Container stopped                               │
│  Duration: Immediate                                        │
│  Action: Email notification + Auto-restart                  │
│  Impact: Service disruption                                 │
│                                                              │
│  Alert Event 5: High Memory Usage                           │
│  ─────────────────────────────────────────────────────────  │
│  Condition: Memory usage > 90%                              │
│  Severity: Warning                                          │
│  Threshold: 90% of available memory                         │
│  Duration: Sustained for 5 minutes                          │
│  Action: Email notification                                 │
│  Impact: Potential OOM kill                                 │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 10. Operational Procedures

### 10.1 Deployment Process

```
┌─────────────────────────────────────────────────────────────┐
│                  DEPLOYMENT PROCESS                          │
└─────────────────────────────────────────────────────────────┘

1. Pre-Deployment
   ├── Connect to VPN (9.30.x.x network access)
   ├── Verify VM accessibility (9.30.213.70)
   ├── Check prerequisites (Docker, Docker Compose)
   └── Validate configuration files

2. Infrastructure Provisioning (Terraform)
   ├── terraform init
   ├── terraform plan
   ├── terraform apply
   └── Create Instana resources
       ├── Application Perspective
       ├── Custom Alert Events (5)
       ├── Email Alert Channel
       ├── Alert Configuration
       └── API Token

3. Configuration Management (Ansible)
   ├── Install Docker & Docker Compose
   ├── Install Instana agent
   ├── Create docker-compose.yml
   ├── Create instana-config.yaml
   └── Configure monitoring

4. Application Deployment
   ├── Pull Docker images
   ├── Start containers (docker-compose up -d)
   ├── Verify container status
   └── Check logs

5. Verification
   ├── Test web interface (http://9.30.213.70:8080)
   ├── Verify all 12 containers running
   ├── Check Instana agent connection
   ├── Validate metrics collection
   └── Test alert configuration

6. Post-Deployment
   ├── Monitor application health
   ├── Review Instana dashboards
   ├── Verify alert notifications
   └── Document deployment
```

### 10.2 Troubleshooting Guide

```
┌─────────────────────────────────────────────────────────────┐
│                 TROUBLESHOOTING GUIDE                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Issue: Cannot access VM                                     │
│  ─────────────────────────────────────────────────────────  │
│  Symptoms: SSH timeout, connection refused                  │
│  Cause: Not connected to VPN                                │
│  Solution: Connect to VPN for 9.30.x.x network access       │
│                                                              │
│  Issue: Container fails to start                            │
│  ─────────────────────────────────────────────────────────  │
│  Symptoms: Container exits immediately                      │
│  Cause: Configuration error, missing dependencies           │
│  Solution:                                                  │
│    1. Check logs: docker logs <container_name>              │
│    2. Verify configuration files                            │
│    3. Check resource availability                           │
│    4. Restart container: docker-compose restart <service>   │
│                                                              │
│  Issue: High error rate alert                               │
│  ─────────────────────────────────────────────────────────  │
│  Symptoms: Instana alert email received                     │
│  Cause: Application errors, service failures                │
│  Solution:                                                  │
│    1. Check Instana dashboard for error details             │
│    2. Review application logs                               │
│    3. Identify failing service                              │
│    4. Restart affected containers                           │
│    5. Investigate root cause                                │
│                                                              │
│  Issue: Instana agent not reporting                         │
│  ─────────────────────────────────────────────────────────  │
│  Symptoms: No metrics in Instana platform                   │
│  Cause: Agent not running, configuration error              │
│  Solution:                                                  │
│    1. Check agent status: systemctl status instana-agent    │
│    2. Verify configuration: /opt/instana/agent/etc/         │
│    3. Check API key and endpoint                            │
│    4. Restart agent: systemctl restart instana-agent        │
│    5. Review agent logs: /opt/instana/agent/data/log/       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 11. Performance Considerations

### 11.1 Resource Requirements

```
┌─────────────────────────────────────────────────────────────┐
│                 RESOURCE REQUIREMENTS                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  VM Resources (Minimum)                                      │
│  ─────────────────────────────────────────────────────────  │
│  • CPU: 4 cores                                             │
│  • Memory: 8 GB RAM                                         │
│  • Disk: 50 GB                                              │
│  • Network: 1 Gbps                                          │
│                                                              │
│  Container Resources (Per Service)                           │
│  ─────────────────────────────────────────────────────────  │
│  • Frontend (web): 512 MB RAM, 0.5 CPU                     │
│  • Business Logic: 256-512 MB RAM, 0.25-0.5 CPU            │
│  • Data Stores:                                             │
│    - MySQL: 1 GB RAM, 1 CPU                                │
│    - MongoDB: 1 GB RAM, 1 CPU                              │
│    - Redis: 256 MB RAM, 0.25 CPU                           │
│    - RabbitMQ: 512 MB RAM, 0.5 CPU                         │
│                                                              │
│  Total Resources (12 Containers)                             │
│  ─────────────────────────────────────────────────────────  │
│  • Memory: ~6-7 GB                                          │
│  • CPU: ~4-5 cores                                          │
│  • Disk: ~20 GB (images + data)                            │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 11.2 Performance Optimization

```
┌─────────────────────────────────────────────────────────────┐
│              PERFORMANCE OPTIMIZATION                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Application Level                                           │
│  ─────────────────────────────────────────────────────────  │
│  • Redis caching for cart data                              │
│  • Database connection pooling                              │
│  • Async processing for dispatch                            │
│  • CDN for static assets (future)                           │
│                                                              │
│  Container Level                                             │
│  ─────────────────────────────────────────────────────────  │
│  • Resource limits configured                               │
│  • Health checks enabled                                    │
│  • Restart policies set                                     │
│  • Log rotation configured                                  │
│                                                              │
│  Infrastructure Level                                        │
│  ─────────────────────────────────────────────────────────  │
│  • Docker bridge network                                    │
│  • Volume mounts for persistence                            │
│  • Optimized Docker images                                  │
│  • Regular cleanup of unused resources                      │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 12. Disaster Recovery

### 12.1 Backup Strategy

```
┌─────────────────────────────────────────────────────────────┐
│                   BACKUP STRATEGY                            │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Configuration Backups                                       │
