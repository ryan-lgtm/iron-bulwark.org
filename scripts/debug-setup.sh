#!/bin/bash

# Iron Bulwark - Debug Setup Script
# This script helps troubleshoot setup issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
USER_HOME=$(eval echo ~$USER)
PROJECT_DIR="$USER_HOME/iron-bulwark"

# Functions
log_info() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "========================================"
echo "🔍 Iron Bulwark Debug Information"
echo "========================================"

# System information
log_info "System Information:"
echo "User: $(whoami)"
echo "Home: $USER_HOME"
echo "Current Directory: $(pwd)"
echo "Project Directory: $PROJECT_DIR"
echo ""

# Check sudo access
log_info "Checking sudo access..."
if sudo -n true 2>/dev/null; then
    log_success "Sudo access: OK"
else
    log_error "Sudo access: FAILED"
    echo "Please ensure your user has sudo privileges"
fi
echo ""

# Check internet connection
log_info "Checking internet connection..."
if ping -c 1 google.com &> /dev/null; then
    log_success "Internet connection: OK"
else
    log_error "Internet connection: FAILED"
fi
echo ""

# Check Git
log_info "Checking Git installation..."
if command -v git &> /dev/null; then
    log_success "Git installed: $(git --version)"
else
    log_error "Git not installed"
fi
echo ""

# Check Docker
log_info "Checking Docker installation..."
if command -v docker &> /dev/null; then
    log_success "Docker installed: $(docker --version)"
else
    log_error "Docker not installed"
fi

# Test Docker permissions
log_info "Testing Docker permissions..."
if docker run --rm hello-world &> /dev/null; then
    log_success "Docker permissions: OK"
else
    log_warning "Docker permissions: FAILED"
    echo "Try: sudo systemctl restart docker"
    echo "Then logout and login again"
fi
echo ""

# Check directory permissions
log_info "Checking directory permissions..."
echo "User home permissions: $(ls -ld $USER_HOME)"
if [ -d "$PROJECT_DIR" ]; then
    echo "Project directory exists: $PROJECT_DIR"
    echo "Project directory permissions: $(ls -ld $PROJECT_DIR)"
    if [ -d "$PROJECT_DIR/.git" ]; then
        log_success "Git repository exists"
        echo "Git status: $(cd $PROJECT_DIR && git status --porcelain | wc -l) changes"
    else
        log_warning "No git repository found in project directory"
    fi
else
    log_info "Project directory does not exist: $PROJECT_DIR"
fi
echo ""

# Test GitHub access
log_info "Testing GitHub access..."
if git ls-remote https://github.com/ryan-lgtm/iron-bulwark.org.git &> /dev/null; then
    log_success "GitHub access: OK"
else
    log_error "GitHub access: FAILED"
    echo "Please check your internet connection and repository access"
fi
echo ""

# Test git clone
log_info "Testing git clone..."
TEMP_DIR="/tmp/iron-bulwark-test"
rm -rf $TEMP_DIR
if git clone https://github.com/ryan-lgtm/iron-bulwark.org.git $TEMP_DIR &> /dev/null; then
    log_success "Git clone: OK"
    if [ -f "$TEMP_DIR/env-example.txt" ]; then
        log_success "env-example.txt exists in repository"
    else
        log_error "env-example.txt missing from repository"
    fi
    rm -rf $TEMP_DIR
else
    log_error "Git clone: FAILED"
fi
echo ""

echo "========================================"
echo "📋 Recommended Actions:"
echo "========================================"

if ! docker run --rm hello-world &> /dev/null; then
    echo "1. Fix Docker permissions:"
    echo "   sudo systemctl restart docker"
    echo "   logout"
    echo "   # Then SSH back in"
fi

if [ ! -d "$PROJECT_DIR/.git" ]; then
    echo "2. Clone repository manually:"
    echo "   mkdir -p $PROJECT_DIR"
    echo "   cd $PROJECT_DIR"
    echo "   git clone https://github.com/ryan-lgtm/iron-bulwark.org.git ."
fi

echo "3. Then run the setup script again:"
echo "   ./setup.sh your-domain.com your-email@example.com"

echo ""
echo "For more help, check the QUICK_START.md file"
