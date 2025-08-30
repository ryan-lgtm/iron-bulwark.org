#!/bin/bash

# Iron Bulwark - Basic VPS Setup Script (No Docker)
# Alternative setup for users who can't get Docker working

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
USER_HOME=$(eval echo ~$USER)
DOMAIN=""
EMAIL=""

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   log_error "This script should not be run as root. Please run as a regular user with sudo access."
   exit 1
fi

# Check if user has sudo access
if ! sudo -n true 2>/dev/null; then
    log_error "Your user needs sudo access to run this script."
    exit 1
fi

# Get domain and email
if [ -z "$1" ]; then
    read -p "Enter your domain name (e.g., iron-bulwark.org): " DOMAIN
else
    DOMAIN=$1
fi

if [ -z "$2" ]; then
    read -p "Enter your email for SSL certificates: " EMAIL
else
    EMAIL=$2
fi

log_info "Setting up Iron Bulwark blog (Basic Mode) for domain: $DOMAIN"

# Update system
log_info "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install essential tools
log_info "Installing essential tools..."
sudo apt install -y curl wget git htop ufw fail2ban unattended-upgrades software-properties-common

# Configure firewall
log_info "Configuring firewall..."
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw --force enable

# Install Node.js (for Ghost)
log_info "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install MySQL
log_info "Installing MySQL..."
sudo apt install -y mysql-server
sudo mysql_secure_installation

# Create project directory
log_info "Setting up project directory..."
PROJECT_DIR="$USER_HOME/iron-bulwark"
if [ ! -d "$PROJECT_DIR" ]; then
    mkdir -p $PROJECT_DIR
fi

# Ensure user owns the directory
sudo chown -R $USER:$USER $USER_HOME
chmod -R 755 $PROJECT_DIR

# Clone project
log_info "Cloning Iron Bulwark project..."
cd $PROJECT_DIR
if [ ! -d ".git" ]; then
    git clone https://github.com/ryan-lgtm/iron-bulwark.org.git .
fi

# Install Ghost CLI
log_info "Installing Ghost CLI..."
sudo npm install ghost-cli@latest -g

# Create Ghost directory
GHOST_DIR="$USER_HOME/ghost"
if [ ! -d "$GHOST_DIR" ]; then
    mkdir -p $GHOST_DIR
fi

cd $GHOST_DIR

# Install Ghost
log_info "Installing Ghost..."
ghost install local --no-setup-ssl --no-start

# Configure environment
log_info "Configuring Ghost environment..."
cat > .ghost-cli << EOF
{
  "running": "local",
  "environment": "production",
  "url": "https://$DOMAIN",
  "port": "2368",
  "process": "local",
  "database": {
    "client": "mysql",
    "connection": {
      "host": "localhost",
      "user": "ghost",
      "password": "password123",
      "database": "ghost_prod"
    }
  },
  "mail": {
    "transport": "Direct"
  }
}
EOF

# Set up MySQL database
log_info "Setting up MySQL database..."
sudo mysql -e "CREATE DATABASE ghost_prod;"
sudo mysql -e "CREATE USER 'ghost'@'localhost' IDENTIFIED BY 'password123';"
sudo mysql -e "GRANT ALL PRIVILEGES ON ghost_prod.* TO 'ghost'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Install Nginx
log_info "Installing and configuring Nginx..."
sudo apt install -y nginx

# Create Nginx configuration
sudo tee /etc/nginx/sites-available/$DOMAIN > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:2368;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:2368;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable site
sudo ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/ 2>/dev/null || true
sudo nginx -t

if [ $? -eq 0 ]; then
    sudo systemctl reload nginx
    log_success "Nginx configured successfully"
else
    log_error "Nginx configuration test failed"
fi

# Install Certbot for SSL
log_info "Installing Certbot for SSL certificates..."
sudo apt install -y certbot python3-certbot-nginx

# Start Ghost
log_info "Starting Ghost..."
cd $GHOST_DIR
ghost start

log_success "Basic setup completed!"
echo ""
echo "========================================"
echo "🎉 Iron Bulwark Blog Setup Complete!"
echo "========================================"
echo ""
echo "Your blog is now running at: http://$DOMAIN"
echo "Admin panel: http://$DOMAIN/ghost"
echo ""
echo "Next Steps:"
echo "1. Access http://$DOMAIN/ghost to complete setup"
echo "2. Set up SSL certificate: sudo certbot --nginx -d $DOMAIN"
echo "3. Upload the Iron Bulwark theme from $PROJECT_DIR/themes/iron-bulwark"
echo "4. Create the 'news-updates' and 'opinions' tags"
echo ""
echo "Project Directory: $PROJECT_DIR"
echo "Ghost Directory: $GHOST_DIR"
echo ""
log_warning "This is a basic setup. Consider using Docker for production deployment."
