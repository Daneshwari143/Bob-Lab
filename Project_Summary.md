# Robot Shop Microservices Deployment - Project Summary

## Overview
Automated deployment solution for Robot Shop e-commerce application using Infrastructure as Code (IaC) with comprehensive monitoring via Instana APM.

## Architecture
**Microservices Application**: 11-service polyglot architecture (Node.js, Python, Java, Go, PHP)
- **Frontend**: Web UI (nginx + Angular) on port 8080
- **Business Logic**: Cart, Catalogue, User, Payment, Shipping, Dispatch, Ratings
- **Data Layer**: MySQL, MongoDB, Redis, RabbitMQ

**Infrastructure**: Ubuntu 22.04 VM (9.30.220.114) with Docker containerization

## Key Components

### 1. Infrastructure as Code
- **Terraform**: Provisions Instana monitoring resources (application perspectives, 5 custom alert events, email channels, RBAC tokens)
- **Ansible**: Configures VM, installs Docker/Docker Compose, deploys Instana agent, launches 12 containers

### 2. CI/CD Pipeline
**Jenkins automation** with stages:
- Terraform initialization and resource creation
- Robot Shop deployment via SSH
- Load testing setup
- Deployment verification

### 3. Monitoring & Alerting
**Instana APM** with:
- Application Perspective: Robot-Shop-Microservices-Daneshwari-2026
- **5 Custom Alerts**: High error rate (>5%), high latency (>1000ms), service down, container failure, high memory (>90%)
- Email notifications to Daneshwari.Naganur1@ibm.com
- Read-only API token for RBAC

## Deployment Methods
1. **Automated**: `./deploy.sh` script (10-15 minutes)
2. **Manual**: Step-by-step Terraform + Ansible
3. **CI/CD**: Jenkins pipeline with parameterized builds

## Technical Stack
- **Container Platform**: Docker 24.0.7, Docker Compose v2.24.0
- **IaC**: Terraform (Instana provider v3.0), Ansible
- **Monitoring**: Instana agent with 1-second metric granularity
- **Languages**: 6 languages across 8 microservices

## Key Features
✓ One-click automated deployment
✓ Comprehensive monitoring with distributed tracing
✓ Intelligent alerting system
✓ Load testing capability
✓ Complete documentation (README, architecture diagrams, troubleshooting guides)
✓ Security: VPN-required private network (9.30.x.x), RBAC implementation

## Access
- **Application**: http://9.30.220.114:8080
- **Monitoring**: https://ibmdevsandbox-instanaibm.instana.io
- **Zone**: robot-shop-zone