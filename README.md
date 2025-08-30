# Iron Bulwark - Iron County Utah Community Blog

A comprehensive Ghost-based blogging platform for Iron County, Utah residents to stay informed about local government, taxes, community news, and share local perspectives.

## 🚀 Quick Start

### Local Development with Docker

1. **Clone and setup**:
   ```bash
   git clone <repository-url>
   cd iron-bulwark.org
   ```

2. **Start the development environment**:
   ```bash
   docker-compose up -d
   ```

3. **Access your site**:
   - Blog: http://localhost:2368
   - Admin: http://localhost:2368/ghost

4. **Default admin credentials**:
   - Email: admin@example.com
   - Password: changeme123

### Theme Development

```bash
cd themes/iron-bulwark
yarn install
yarn dev
```

## 📋 Features

- ✅ **News & Updates** category for government and community announcements
- ✅ **Opinions** category for local voices and perspectives
- ✅ **Facebook Group Integration** for automatic post feeds
- ✅ **Mailgun Newsletter** support for email campaigns
- ✅ **Admin Authentication** with secure login
- ✅ **Responsive Design** optimized for all devices
- ✅ **SEO Optimized** with proper meta tags and structured data
- ✅ **Image Management** with automatic resizing

## 🏗️ VPS Deployment

### Minimum Server Requirements

**Recommended VPS Specifications:**
- **CPU**: 1 vCPU (2.4 GHz or higher)
- **RAM**: 1 GB minimum (2 GB recommended, 4 GB for high traffic)
- **Storage**: 25 GB SSD minimum
- **OS**: Ubuntu 20.04 LTS or later
- **Network**: 100 Mbps bandwidth

**Memory Requirements Breakdown:**
- **1GB RAM**: Basic Ghost installation with low traffic (~100 daily visitors)
- **2GB RAM**: Recommended for most community blogs with moderate traffic (~500 daily visitors)
- **4GB RAM**: High-traffic sites or sites with many plugins/images (~2000+ daily visitors)
- **Additional overhead**: MySQL database, Nginx, system processes

**Why these specs:**
- Ghost core requires ~512MB RAM for basic operation
- MySQL database needs ~256MB minimum, more for active sites
- PHP/Node.js processes and caching add memory overhead
- SSD storage provides better performance for content delivery
- Ubuntu LTS ensures long-term stability and security updates

### Step-by-Step VPS Setup

#### 1. Initial Server Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install essential tools
sudo apt install -y curl wget git htop ufw fail2ban

# Configure firewall
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw --force enable
```

#### 2. Install Docker and Docker Compose

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Logout and login again for docker group changes
```

#### 3. Clone and Configure Project

```bash
# Clone your project
git clone <your-repository-url> iron-bulwark
cd iron-bulwark

# Copy and configure environment
cp .env.example .env
nano .env  # Edit with your settings
```

#### 4. Production Docker Configuration

Create a `docker-compose.prod.yml`:

```yaml
version: '3.8'

services:
  ghost:
    image: ghost:5-alpine
    container_name: iron-bulwark-prod
    restart: always
    ports:
      - "2368:2368"
    environment:
      - NODE_ENV=production
      - url=https://your-domain.com
      - database__client=mysql
      - database__connection__host=mysql
      - database__connection__user=ghost_prod
      - database__connection__password=YOUR_STRONG_PASSWORD
      - database__connection__database=ghost_prod_db
      - mail__transport=SMTP
      - mail__options__service=Mailgun
      - mail__options__auth__user=postmaster@your-domain.mailgun.org
      - mail__options__auth__pass=YOUR_MAILGUN_PASSWORD
    volumes:
      - ./content:/var/lib/ghost/content
      - ./themes:/var/lib/ghost/content/themes
    depends_on:
      - mysql
    networks:
      - ghost-network

  mysql:
    image: mysql:8.0
    container_name: iron-bulwark-mysql-prod
    restart: always
    environment:
      - MYSQL_ROOT_PASSWORD=YOUR_ROOT_PASSWORD
      - MYSQL_DATABASE=ghost_prod_db
      - MYSQL_USER=ghost_prod
      - MYSQL_PASSWORD=YOUR_STRONG_PASSWORD
    volumes:
      - mysql_data:/var/lib/mysql
      - ./backups:/backups
    networks:
      - ghost-network

volumes:
  mysql_data:

networks:
  ghost-network:
    driver: bridge
```

#### 5. SSL Configuration with Let's Encrypt

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Get SSL certificate (replace with your domain)
sudo certbot certonly --standalone -d your-domain.com

# Configure Nginx reverse proxy
sudo apt install -y nginx
```

Create `/etc/nginx/sites-available/iron-bulwark`:

```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com www.your-domain.com;

    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:2368;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/iron-bulwark /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

#### 6. Start Production Environment

```bash
# Start services
docker-compose -f docker-compose.prod.yml up -d

# Check logs
docker-compose -f docker-compose.prod.yml logs -f ghost
```

## 🔧 Configuration

### Environment Variables (.env)

```bash
# Database
DB_HOST=mysql
DB_USER=ghost_prod
DB_PASSWORD=your_strong_password
DB_NAME=ghost_prod_db

# Site
SITE_URL=https://your-domain.com
SITE_TITLE="Iron County Community Blog"

# Mailgun
MAILGUN_API_KEY=your_mailgun_api_key
MAILGUN_DOMAIN=your-domain.mailgun.org

# Facebook
FACEBOOK_APP_ID=your_facebook_app_id
FACEBOOK_APP_SECRET=your_facebook_app_secret
FACEBOOK_GROUP_ID=1465849137537076
```

### Ghost Admin Setup

1. Access `https://your-domain.com/ghost`
2. Complete initial setup wizard
3. Configure:
   - Site title and description
   - Upload Iron Bulwark theme
   - Set up Mailgun integration
   - Configure Facebook integration

### Content Categories Setup

Create these tags in Ghost admin:

1. **news-updates** - Government decisions, tax info, community news
2. **opinions** - Local perspectives and editorials

## 📸 Image Management

### Directory Structure

```
content/
├── images/
│   ├── featured/          # Featured post images
│   ├── authors/           # Author profile pictures
│   ├── logos/             # Site logos and branding
│   └── social/            # Social media graphics
└── themes/
    └── iron-bulwark/      # Custom theme files
```

### Image Guidelines

- **Featured Images**: 1200x600px minimum, 16:9 aspect ratio
- **Author Photos**: 200x200px, square format
- **Logos**: SVG format preferred, max 500px width
- **Social Graphics**: 1200x630px for optimal sharing

## 🔒 Security Best Practices

### VPS Security

```bash
# Disable root login
sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# Set up automatic updates
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades

# Configure fail2ban for SSH protection
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### Ghost Security

- Keep Ghost updated to latest version
- Use strong admin passwords
- Enable 2FA for admin accounts
- Regularly backup content and database
- Monitor logs for suspicious activity

## 📧 Mailgun Setup

1. Sign up for [Mailgun](https://www.mailgun.com/)
2. Verify your domain
3. Get SMTP credentials
4. Configure in Ghost admin under Settings > Email
5. Test newsletter functionality

## 📘 Facebook Integration

### Setup Steps

1. Create Facebook App at [developers.facebook.com](https://developers.facebook.com)
2. Configure Facebook Login and Groups API permissions
3. Get App ID and Secret
4. Configure in theme settings
5. Test group feed integration

### Facebook Group Settings

Ensure your Facebook group:
- Is public or has proper API access
- Allows app integration
- Has appropriate privacy settings for public content

## 🔄 Backup Strategy

### Automated Backups

```bash
# Create backup script
cat > /home/ubuntu/backup.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/home/ubuntu/backups"

# Database backup
docker exec iron-bulwark-mysql-prod mysqldump -u ghost_prod -p$DB_PASSWORD ghost_prod_db > $BACKUP_DIR/db_$DATE.sql

# Content backup
tar -czf $BACKUP_DIR/content_$DATE.tar.gz /home/ubuntu/iron-bulwark/content/

# Clean old backups (keep last 7 days)
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
EOF

chmod +x /home/ubuntu/backup.sh
```

### Cron Job for Daily Backups

```bash
# Add to crontab
crontab -e
# Add this line for daily backups at 2 AM
0 2 * * * /home/ubuntu/backup.sh
```

## 📊 Monitoring

### Basic Monitoring Commands

```bash
# Check service status
docker-compose -f docker-compose.prod.yml ps

# Monitor logs
docker-compose -f docker-compose.prod.yml logs -f

# Check disk usage
df -h

# Monitor system resources
htop
```

### Log Rotation

```bash
# Configure logrotate for Docker logs
cat > /etc/logrotate.d/docker-ghost << EOF
/var/lib/docker/containers/*/*.log {
    rotate 7
    daily
    compress
    missingok
    delaycompress
    copytruncate
}
EOF
```

## 🚨 Troubleshooting

### Common Issues

**Ghost won't start:**
- Check database connection
- Verify environment variables
- Check Docker logs: `docker-compose logs ghost`

**SSL certificate issues:**
- Renew Let's Encrypt: `sudo certbot renew`
- Check Nginx configuration: `sudo nginx -t`

**Email not sending:**
- Verify Mailgun credentials
- Check spam folder
- Review Mailgun logs

**Slow performance:**
- Check server resources
- Optimize images
- Enable caching in Ghost admin

## 📞 Support

- **Ghost Documentation**: https://ghost.org/docs/
- **Docker Issues**: Check Docker logs and official documentation
- **VPS Issues**: Contact your hosting provider
- **Theme Issues**: Check theme README.md

## 📋 Development Checklist

- [ ] Domain purchased and configured
- [ ] VPS server provisioned
- [ ] Docker and Docker Compose installed
- [ ] SSL certificate obtained
- [ ] Ghost theme uploaded and activated
- [ ] Mailgun configured
- [ ] Facebook integration tested
- [ ] Content categories created
- [ ] Backup system configured
- [ ] Monitoring set up

---

**Ready to launch your Iron County community blog!** 🎉
