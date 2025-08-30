#!/bin/bash

# Iron Bulwark - Manual SSL Setup Script
# Run this if SSL certificate setup fails in the main script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[SSL]${NC} $1"
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

# Get domain
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

log_info "Setting up SSL certificates for domain: $DOMAIN"

# Check if nginx is installed
if ! command -v nginx &> /dev/null; then
    log_info "Installing Nginx..."
    sudo apt update
    sudo apt install -y nginx
fi

# Check if certbot is installed
if ! command -v certbot &> /dev/null; then
    log_info "Installing Certbot..."
    sudo apt install -y certbot python3-certbot-nginx
fi

# Stop nginx temporarily for standalone certbot
log_info "Stopping Nginx temporarily for SSL certificate generation..."
sudo systemctl stop nginx

# Get SSL certificate
log_info "Obtaining SSL certificate..."

# Check if port 80 is in use and handle it
if sudo lsof -i :80 | grep -q LISTEN; then
    log_warning "Port 80 is in use (likely by nginx). Stopping nginx temporarily for SSL setup..."
    NGINX_WAS_RUNNING=true
    sudo systemctl stop nginx

    # Get SSL certificate
    if sudo certbot certonly --standalone -d $DOMAIN -d www.$DOMAIN --email $EMAIL --agree-tos --non-interactive; then
        log_success "SSL certificate obtained successfully"
        SSL_SUCCESS=true
    else
        log_warning "SSL certificate setup failed"
        SSL_SUCCESS=false
    fi

    # Restart nginx if it was running
    if [ "$NGINX_WAS_RUNNING" = true ]; then
        log_info "Restarting nginx..."
        sudo systemctl start nginx
    fi
else
    # Port 80 is free, use standalone method
    if sudo certbot certonly --standalone -d $DOMAIN -d www.$DOMAIN --email $EMAIL --agree-tos --non-interactive; then
        log_success "SSL certificate obtained successfully"
        SSL_SUCCESS=true
    else
        log_warning "SSL certificate setup failed"
        SSL_SUCCESS=false
    fi
fi

if [ "$SSL_SUCCESS" = true ]; then
    log_success "SSL certificate obtained successfully!"

    # Update Nginx configuration with SSL
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

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    location / {
        proxy_pass http://127.0.0.1:2368;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

    # Enable site if not already enabled
    if [ ! -L /etc/nginx/sites-enabled/$DOMAIN ]; then
        sudo ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/ 2>/dev/null || true
    fi

    # Test nginx configuration
    if sudo nginx -t; then
        log_success "Nginx SSL configuration is valid"
        sudo systemctl start nginx
        log_success "Nginx started with SSL configuration!"
        echo ""
        echo "========================================"
        echo "🎉 SSL Setup Complete!"
        echo "========================================"
        echo ""
        echo "Your site is now available at:"
        echo "🔒 HTTPS: https://$DOMAIN"
        echo "🔄 HTTP redirects to HTTPS automatically"
        echo ""
        echo "SSL certificates will auto-renew before expiration."
    else
        log_error "Nginx configuration test failed"
        sudo systemctl start nginx  # Start nginx anyway with the old config
        log_warning "Nginx started with previous configuration"
    fi

else
    log_error "SSL certificate generation failed"
    log_info "Common issues:"
    log_info "1. Domain DNS not pointing to this server"
    log_info "2. Firewall blocking port 80"
    log_info "3. Domain already has SSL certificates from another provider"
    echo ""
    log_info "You can try again later or use a self-signed certificate:"
    echo "sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/selfsigned.key -out /etc/ssl/certs/selfsigned.crt"
fi
