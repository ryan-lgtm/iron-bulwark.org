#!/bin/bash

# Iron Bulwark - Manual Setup Script
# Step-by-step manual setup for users having issues with automated scripts

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
    echo -e "${BLUE}[MANUAL]${NC} $1"
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
echo "🛠️  Iron Bulwark Manual Setup"
echo "========================================"
echo ""
echo "This script will guide you through each step manually."
echo "Press Enter after each step to continue."
echo ""

# Get domain and email
read -p "Enter your domain name (e.g., iron-bulwark.org): " DOMAIN
read -p "Enter your email for SSL certificates: " EMAIL

echo ""
log_info "Starting manual setup for domain: $DOMAIN"

# Step 1: Clean up any existing directory
echo ""
log_info "Step 1: Cleaning up any existing files..."
echo "Command: rm -rf $PROJECT_DIR"
read -p "Press Enter to execute: "
rm -rf $PROJECT_DIR 2>/dev/null || true
log_success "Cleanup complete"

# Step 2: Clone repository
echo ""
log_info "Step 2: Cloning repository..."
echo "Command: git clone https://github.com/ryan-lgtm/iron-bulwark.org.git $PROJECT_DIR"
read -p "Press Enter to execute: "
if git clone https://github.com/ryan-lgtm/iron-bulwark.org.git $PROJECT_DIR; then
    log_success "Repository cloned successfully"
else
    log_error "Failed to clone repository"
    exit 1
fi

# Step 3: Set up environment
echo ""
log_info "Step 3: Setting up environment variables..."
cd $PROJECT_DIR
echo "Command: cp env-example.txt .env"
read -p "Press Enter to execute: "
cp env-example.txt .env

# Generate passwords
DB_PASSWORD=$(openssl rand -base64 32)
ADMIN_PASSWORD=$(openssl rand -base64 16)

echo "Updating .env file with your settings..."
sed -i "s|https://your-domain.com|https://$DOMAIN|g" .env
sed -i "s|YOUR_STRONG_DB_PASSWORD|$DB_PASSWORD|g" .env
sed -i "s|CHANGE_THIS_STRONG_PASSWORD|$ADMIN_PASSWORD|g" .env
sed -i "s|admin@your-domain.com|admin@$DOMAIN|g" .env

log_success "Environment configured"
echo "Database Password: $DB_PASSWORD"
echo "Admin Password: $ADMIN_PASSWORD"

# Step 4: Start Docker services
echo ""
log_info "Step 4: Starting Docker services..."
echo "Command: docker-compose -f docker-compose.prod.yml up -d"
read -p "Press Enter to execute: "
if docker-compose -f docker-compose.prod.yml up -d; then
    log_success "Docker services started"
else
    log_error "Failed to start Docker services"
    exit 1
fi

# Step 5: Wait for services
echo ""
log_info "Step 5: Waiting for services to start..."
echo "Waiting 30 seconds for containers to initialize..."
sleep 30
log_success "Services should be ready"

# Step 6: Install Nginx
echo ""
log_info "Step 6: Installing Nginx..."
echo "Command: sudo apt install -y nginx"
read -p "Press Enter to execute: "
sudo apt install -y nginx

# Step 7: Configure Nginx (HTTP only first)
echo ""
log_info "Step 7: Configuring Nginx (HTTP only)..."
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
EOF

sudo ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
log_success "Nginx configured for HTTP"

# Step 8: SSL Setup
echo ""
log_info "Step 8: Setting up SSL certificates..."
echo "Command: sudo apt install -y certbot python3-certbot-nginx"
read -p "Press Enter to execute: "
sudo apt install -y certbot python3-certbot-nginx

echo "Getting SSL certificate..."
sudo certbot certonly --standalone -d $DOMAIN -d www.$DOMAIN --email $EMAIL --agree-tos --non-interactive

if [ $? -eq 0 ]; then
    log_success "SSL certificate obtained"

    # Update to HTTPS config
    sudo tee /etc/nginx/sites-available/$DOMAIN > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    return 301 https://\$server_name\$request_uri;
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

    sudo nginx -t && sudo systemctl reload nginx
    log_success "SSL configuration complete"
else
    log_warning "SSL setup failed - site will work on HTTP only"
fi

echo ""
echo "========================================"
echo "🎉 Manual Setup Complete!"
echo "========================================"
echo ""
echo "Your Iron Bulwark blog is now running at:"
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    echo "🔒 HTTPS: https://$DOMAIN"
else
    echo "🌐 HTTP: http://$DOMAIN"
fi
echo ""
echo "Admin panel: http://$DOMAIN/ghost"
echo "Admin Password: $ADMIN_PASSWORD"
echo ""
echo "Next steps:"
echo "1. Visit your site and complete Ghost setup"
echo "2. Upload the Iron Bulwark theme"
echo "3. Create 'news-updates' and 'opinions' tags"
echo "4. Configure Mailgun for newsletters"
echo ""
log_success "Manual setup completed successfully!"
