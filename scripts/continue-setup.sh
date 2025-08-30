#!/bin/bash

# Iron Bulwark - Continue Setup Script
# Run this after Docker permissions are working

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

log_info "Continuing Iron Bulwark setup for domain: $DOMAIN"

# Test Docker again
log_info "Testing Docker installation..."
if docker run --rm hello-world >/dev/null 2>&1; then
    log_success "Docker is working correctly!"
else
    log_error "Docker is still not working. Please check Docker installation and permissions."
    log_info "Try: sudo systemctl restart docker"
    log_info "Or logout and login again"
    exit 1
fi

# Clone project if needed
log_info "Checking project setup..."
log_info "Target directory: $PROJECT_DIR"

if [ ! -d "$PROJECT_DIR/.git" ]; then
    log_info "Cloning Iron Bulwark project..."
    if git clone https://github.com/ryan-lgtm/iron-bulwark.org.git $PROJECT_DIR; then
        log_success "Repository cloned successfully"
    else
        log_error "Failed to clone repository. Checking if directory exists..."
        if [ -d "$PROJECT_DIR" ]; then
            log_info "Directory exists but no git repo. Please manually clone or remove the directory."
            exit 1
        else
            log_error "Clone failed. Please check your internet connection."
            exit 1
        fi
    fi
else
    log_info "Project directory exists, checking for updates..."
    cd $PROJECT_DIR
    if git pull; then
        log_success "Repository updated successfully"
    else
        log_warning "Failed to pull latest changes, continuing with existing version"
    fi
    cd -
fi

# Set up environment file
log_info "Setting up environment configuration..."
if [ ! -f "$PROJECT_DIR/.env" ]; then
    if [ -f "$PROJECT_DIR/env-example.txt" ]; then
        cp $PROJECT_DIR/env-example.txt $PROJECT_DIR/.env
    else
        log_error "env-example.txt not found in project directory. Please check the repository."
        exit 1
    fi

    # Generate strong passwords
    DB_PASSWORD=$(openssl rand -base64 32)
    ADMIN_PASSWORD=$(openssl rand -base64 16)

    # Update .env file with domain and generated passwords
    sed -i "s|https://your-domain.com|https://$DOMAIN|g" $PROJECT_DIR/.env
    sed -i "s|YOUR_STRONG_DB_PASSWORD|$DB_PASSWORD|g" $PROJECT_DIR/.env
    sed -i "s|CHANGE_THIS_STRONG_PASSWORD|$ADMIN_PASSWORD|g" $PROJECT_DIR/.env
    sed -i "s|admin@your-domain.com|admin@$DOMAIN|g" $PROJECT_DIR/.env

    log_warning "Generated passwords saved to .env file. Please save them securely!"
    log_warning "Database Password: $DB_PASSWORD"
    log_warning "Admin Password: $ADMIN_PASSWORD"
fi

# Clone project if needed
if [ ! -d "$PROJECT_DIR/.git" ]; then
    log_info "Cloning Iron Bulwark project..."
    git clone https://github.com/ryan-lgtm/iron-bulwark.org.git $PROJECT_DIR
fi

# Install Nginx
log_info "Installing and configuring Nginx..."
sudo apt install -y nginx

# Create initial HTTP-only Nginx configuration (no SSL yet)
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

# Enable site
sudo ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/ 2>/dev/null || true
sudo nginx -t

if [ $? -eq 0 ]; then
    sudo systemctl reload nginx
    log_success "Nginx configured successfully (HTTP only)"
else
    log_error "Nginx configuration test failed"
    exit 1
fi

# Install Certbot for SSL
log_info "Installing Certbot for SSL certificates..."
sudo apt install -y certbot python3-certbot-nginx

# Get SSL certificate
log_info "Obtaining SSL certificate..."
sudo certbot certonly --standalone -d $DOMAIN -d www.$DOMAIN --email $EMAIL --agree-tos --non-interactive

if [ $? -eq 0 ]; then
    log_success "SSL certificate obtained successfully"

    # Update Nginx configuration to include HTTPS
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

    # Test and reload nginx with SSL config
    sudo nginx -t
    if [ $? -eq 0 ]; then
        sudo systemctl reload nginx
        log_success "Nginx SSL configuration updated successfully"
    else
        log_error "SSL Nginx configuration test failed"
        log_warning "Your site will work on HTTP but SSL setup failed"
    fi
else
    log_warning "SSL certificate setup failed. Your site will work on HTTP only."
    log_info "You can manually set up SSL later with: sudo certbot --nginx -d $DOMAIN"
fi

# Set up automatic backups
log_info "Setting up backup system..."
CURRENT_USER=$(id -un)
CURRENT_GROUP=$(id -gn)
BACKUP_DIR="$USER_HOME/backups"
sudo mkdir -p $BACKUP_DIR
sudo chown $CURRENT_USER:$CURRENT_GROUP $BACKUP_DIR

# Create backup script
sudo tee $USER_HOME/backup.sh > /dev/null <<EOF
#!/bin/bash
DATE=\$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$USER_HOME/backups"
PROJECT_DIR="$USER_HOME/iron-bulwark"

# Database backup
cd \$PROJECT_DIR
docker-compose -f docker-compose.prod.yml exec -T mysql mysqldump -u ghost_prod -p\$DB_PASSWORD ghost_prod_db > \$BACKUP_DIR/db_\$DATE.sql

# Content backup
tar -czf \$BACKUP_DIR/content_\$DATE.tar.gz \$PROJECT_DIR/content/

# Clean old backups (keep last 7 days)
find \$BACKUP_DIR -name "*.sql" -mtime +7 -delete
find \$BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: \$DATE"
EOF

sudo chmod +x $USER_HOME/backup.sh

# Set up daily backup cron job
(crontab -l ; echo "0 2 * * * $USER_HOME/backup.sh") | crontab -

# Configure automatic security updates
log_info "Configuring automatic security updates..."
sudo dpkg-reconfigure --priority=low unattended-upgrades

# Start Ghost
log_info "Starting Ghost blog..."
cd $PROJECT_DIR
docker-compose -f docker-compose.prod.yml up -d

# Wait for services to start
log_info "Waiting for services to start..."
sleep 30

log_success "Setup completed!"
echo ""
echo "========================================"
echo "🎉 Iron Bulwark Blog Setup Complete!"
echo "========================================"
echo ""
echo "Your blog is now running at: https://$DOMAIN"
echo "Admin panel: https://$DOMAIN/ghost"
echo ""
echo "Important Information:"
echo "- Admin Email: admin@$DOMAIN"
echo "- Admin Password: (saved in $PROJECT_DIR/.env file)"
echo "- Database Password: (saved in $PROJECT_DIR/.env file)"
echo ""
echo "Next Steps:"
echo "1. Access https://$DOMAIN/ghost to complete setup"
echo "2. Upload the Iron Bulwark theme"
echo "3. Create the 'news-updates' and 'opinions' tags"
echo "4. Configure Mailgun for newsletters"
echo "5. Set up Facebook integration"
echo ""
echo "Backup Location: $USER_HOME/backups/"
echo "Project Directory: $PROJECT_DIR"
echo ""
log_warning "Please save your passwords securely and change the admin password after first login!"
