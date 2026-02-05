#!/bin/bash

# Robot Shop Prerequisites Check Script
# Run this on the target VM to verify it meets requirements

echo "=========================================="
echo "Robot Shop Prerequisites Check"
echo "=========================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check functions
check_pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
}

check_fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
}

check_warn() {
    echo -e "${YELLOW}⚠ WARN${NC}: $1"
}

FAIL_COUNT=0
WARN_COUNT=0

# 1. Check OS
echo "1. Operating System:"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "   OS: $NAME $VERSION"
    if [[ "$NAME" == *"Amazon Linux"* ]]; then
        check_pass "Amazon Linux detected"
    else
        check_warn "Not Amazon Linux, may have compatibility issues"
        ((WARN_COUNT++))
    fi
else
    check_fail "Cannot determine OS"
    ((FAIL_COUNT++))
fi
echo ""

# 2. Check CPU
echo "2. CPU:"
CPU_COUNT=$(nproc)
echo "   CPU Cores: $CPU_COUNT"
if [ "$CPU_COUNT" -ge 2 ]; then
    check_pass "Sufficient CPU cores ($CPU_COUNT)"
else
    check_warn "Only $CPU_COUNT CPU core(s). Recommended: 2+"
    ((WARN_COUNT++))
fi
echo ""

# 3. Check Memory
echo "3. Memory:"
TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
AVAIL_MEM=$(free -m | awk '/^Mem:/{print $7}')
echo "   Total Memory: ${TOTAL_MEM}MB"
echo "   Available Memory: ${AVAIL_MEM}MB"
if [ "$TOTAL_MEM" -ge 3800 ]; then
    check_pass "Sufficient memory (${TOTAL_MEM}MB)"
elif [ "$TOTAL_MEM" -ge 1800 ]; then
    check_warn "Limited memory (${TOTAL_MEM}MB). Recommended: 4GB+"
    ((WARN_COUNT++))
else
    check_fail "Insufficient memory (${TOTAL_MEM}MB). Minimum: 2GB, Recommended: 4GB+"
    ((FAIL_COUNT++))
fi
echo ""

# 4. Check Disk Space
echo "4. Disk Space:"
ROOT_AVAIL=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
echo "   Available on /: ${ROOT_AVAIL}GB"
if [ "$ROOT_AVAIL" -ge 20 ]; then
    check_pass "Sufficient disk space (${ROOT_AVAIL}GB)"
elif [ "$ROOT_AVAIL" -ge 10 ]; then
    check_warn "Limited disk space (${ROOT_AVAIL}GB). Recommended: 20GB+"
    ((WARN_COUNT++))
else
    check_fail "Insufficient disk space (${ROOT_AVAIL}GB). Minimum: 10GB"
    ((FAIL_COUNT++))
fi
echo ""

# 5. Check Python
echo "5. Python:"
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    echo "   Python Version: $PYTHON_VERSION"
    PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
    PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)
    if [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -ge 9 ]; then
        check_pass "Python 3.9+ installed ($PYTHON_VERSION)"
    else
        check_warn "Python $PYTHON_VERSION found. Ansible requires 3.9+"
        ((WARN_COUNT++))
    fi
else
    check_fail "Python 3 not found"
    ((FAIL_COUNT++))
fi
echo ""

# 6. Check Docker
echo "6. Docker:"
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version 2>&1 | awk '{print $3}' | sed 's/,//')
    echo "   Docker Version: $DOCKER_VERSION"
    if systemctl is-active --quiet docker; then
        check_pass "Docker installed and running"
    else
        check_warn "Docker installed but not running"
        ((WARN_COUNT++))
    fi
else
    check_fail "Docker not installed"
    ((FAIL_COUNT++))
fi
echo ""

# 7. Check Docker Compose
echo "7. Docker Compose:"
if command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(docker-compose --version 2>&1 | awk '{print $4}' | sed 's/,//')
    echo "   Docker Compose Version: $COMPOSE_VERSION"
    check_pass "Docker Compose installed ($COMPOSE_VERSION)"
else
    check_fail "Docker Compose not installed"
    ((FAIL_COUNT++))
fi
echo ""

# 8. Check Network Connectivity
echo "8. Network Connectivity:"
if ping -c 1 8.8.8.8 &> /dev/null; then
    check_pass "Internet connectivity available"
else
    check_fail "No internet connectivity"
    ((FAIL_COUNT++))
fi
echo ""

# 9. Check Docker Hub Access
echo "9. Docker Hub Access:"
if curl -s --connect-timeout 5 https://hub.docker.com &> /dev/null; then
    check_pass "Can reach Docker Hub"
else
    check_warn "Cannot reach Docker Hub"
    ((WARN_COUNT++))
fi
echo ""

# 10. Check Port 8080
echo "10. Port Availability:"
if ! netstat -tuln 2>/dev/null | grep -q ':8080 '; then
    check_pass "Port 8080 is available"
else
    check_warn "Port 8080 is already in use"
    ((WARN_COUNT++))
fi
echo ""

# Summary
echo "=========================================="
echo "Summary:"
echo "=========================================="
if [ $FAIL_COUNT -eq 0 ] && [ $WARN_COUNT -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo "System is ready for Robot Shop deployment."
elif [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${YELLOW}⚠ $WARN_COUNT warning(s)${NC}"
    echo "System may work but could have issues."
else
    echo -e "${RED}✗ $FAIL_COUNT critical issue(s), $WARN_COUNT warning(s)${NC}"
    echo "System is NOT ready for Robot Shop deployment."
fi
echo ""

# Recommendations
if [ $FAIL_COUNT -gt 0 ] || [ $WARN_COUNT -gt 0 ]; then
    echo "Recommendations:"
    if [ "$TOTAL_MEM" -lt 3800 ]; then
        echo "  • Upgrade to t2.medium or larger instance (4GB+ RAM)"
    fi
    if [ "$CPU_COUNT" -lt 2 ]; then
        echo "  • Use instance with 2+ vCPUs"
    fi
    if ! command -v docker &> /dev/null; then
        echo "  • Install Docker: sudo yum install -y docker"
    fi
    if ! command -v docker-compose &> /dev/null; then
        echo "  • Install Docker Compose v2"
    fi
    if [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 9 ]; then
        echo "  • Install Python 3.9+ (required for Ansible)"
    fi
fi
echo ""

exit $FAIL_COUNT

# Made with Bob
