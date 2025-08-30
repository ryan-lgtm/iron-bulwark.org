# 🚀 Iron Bulwark Quick Start Guide

Get your Iron County community blog up and running in minutes!

## Prerequisites

- Domain name (e.g., iron-bulwark.org)
- VPS with Ubuntu 20.04+ (1GB RAM minimum, 2GB recommended)
- SSH access to your VPS

## 1. VPS Setup (5 minutes)

### Automated Setup (Recommended)

```bash
# Connect to your VPS
ssh ubuntu@your-vps-ip

# Download and run setup script
wget https://raw.githubusercontent.com/ryan-lgtm/iron-bulwark.org/main/scripts/setup.sh
chmod +x setup.sh
./setup.sh your-domain.com your-email@example.com

# The script will automatically:
# - Install Docker and Docker Compose
# - Clone the Iron Bulwark repository
# - Set up environment variables
# - Configure Nginx and SSL
# - Start the Ghost blog

# Important: If you see "Docker test failed" message:
# Option 1: Continue with continue-setup script
# wget https://raw.githubusercontent.com/ryan-lgtm/iron-bulwark.org/main/scripts/continue-setup.sh
# chmod +x continue-setup.sh
# ./continue-setup.sh your-domain.com your-email@example.com

# Option 2: Manual steps
# 1. Log out: logout
# 2. SSH back in: ssh your-user@your-server
# 3. Run: sudo systemctl restart docker
# 4. Test Docker: docker run --rm hello-world
# 5. Continue with remaining setup steps
```

### Troubleshooting Docker Issues

If you encounter Docker permission issues:

1. **Log out and back in** after Docker installation:
   ```bash
   logout
   # Then SSH back in
   ```

2. **Manual Docker setup** (if needed):
   ```bash
   # Add your user to docker group
   sudo usermod -aG docker $USER

   # Restart Docker service
   sudo systemctl restart docker

   # Log out and back in again
   logout
   ```

3. **Alternative: Rootless Docker** (if you can't get permissions):
   ```bash
   # Install rootless Docker
   curl -fsSL https://get.docker.com/rootless | sh
   ```

### Alternative: Basic Setup (No Docker)

If Docker setup fails completely, try the basic setup script:

```bash
# Download and run basic setup script (no Docker required)
wget https://raw.githubusercontent.com/ryan-lgtm/iron-bulwark.org/main/scripts/setup-basic.sh
chmod +x setup-basic.sh
./setup-basic.sh your-domain.com your-email@example.com
```

**Note:** The basic setup installs Ghost directly on your server without Docker. It's simpler but less flexible for updates and scaling.

### Manual Setup

If both automated setups fail:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Clone project
git clone https://github.com/ryan-lgtm/iron-bulwark.org.git iron-bulwark
cd iron-bulwark

# Configure environment
cp env-example.txt .env
nano .env  # Edit with your settings

# Start services
docker-compose -f docker-compose.prod.yml up -d
```

## 2. Domain & SSL (5 minutes)

```bash
# Point your domain to your VPS IP address
# Then get SSL certificate:
sudo apt install -y certbot python3-certbot-nginx
sudo certbot certonly --standalone -d your-domain.com

# Configure Nginx (copy from nginx.conf.example)
sudo cp nginx.conf.example /etc/nginx/sites-available/your-domain.com
sudo ln -s /etc/nginx/sites-available/your-domain.com /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

## 3. Ghost Initial Setup (3 minutes)

1. **Access your blog**: https://your-domain.com
2. **Go to admin**: https://your-domain.com/ghost
3. **Complete setup wizard**:
   - Site title: "Iron County Community Blog"
   - Site description: "Stay informed about Iron County government, taxes, and community news"
   - Your name and email

## 4. Theme Installation (2 minutes)

1. **Download theme**:
   ```bash
   cd iron-bulwark/themes/iron-bulwark
   yarn install && yarn zip
   ```

2. **Upload to Ghost**:
   - Go to Admin → Design → Themes
   - Upload the generated `iron-bulwark.zip`
   - Activate the theme

## 5. Content Setup (5 minutes)

### Create Categories

In Ghost admin, go to **Tags** and create:

1. **news-updates**
   - Name: "News & Updates"
   - Description: "Government decisions, tax information, community announcements"
   - URL: `/tag/news-updates`

2. **opinions**
   - Name: "Opinions"
   - Description: "Local perspectives, editorials, community voices"
   - URL: `/tag/opinions`

### Configure Theme Settings

Go to **Design** → **Theme Settings**:

- **County Name**: "Iron County, Utah"
- **Tagline**: "Community News, Government Updates & Local Voices"
- **Facebook Group ID**: `1465849137537076`
- **Show Facebook Feed**: Enable
- **Show Newsletter Signup**: Enable

## 6. Email Setup (Mailgun - 5 minutes)

1. **Sign up**: [mailgun.com](https://www.mailgun.com)
2. **Verify domain**: Add your domain to Mailgun
3. **Get SMTP credentials**
4. **Configure in Ghost**:
   - Admin → Settings → Email newsletter
   - Select "Mailgun"
   - Enter your credentials

## 7. Facebook Integration (Optional - 10 minutes)

1. **Create Facebook App**: [developers.facebook.com](https://developers.facebook.com)
2. **Configure permissions**
3. **Update theme settings** with App ID and Secret
4. **Test integration**

## 8. Create Your First Posts

1. **News Update Post**:
   - Title: "Welcome to Iron County Community Blog"
   - Add tag: `news-updates`
   - Write about your mission

2. **Opinion Post**:
   - Title: "Why Community Voices Matter"
   - Add tag: `opinions`
   - Share your perspective

## 9. Image Setup

Place images in these directories:

```
content/images/
├── featured/     # Post featured images (1200x600)
├── authors/      # Author profile pictures (200x200)
├── logos/        # Site logos
└── social/       # Social media graphics
```

## 10. Final Checks

- ✅ Blog loads at https://your-domain.com
- ✅ Admin panel works
- ✅ Theme is active
- ✅ Categories are created
- ✅ Newsletter signup works
- ✅ SSL certificate is valid
- ✅ Facebook integration (if enabled)

## 🚨 Important Security Steps

1. **Change default password** in Ghost admin
2. **Set up backups** (automated with setup script)
3. **Configure monitoring**
4. **Enable 2FA** on admin account

## 📊 Your Blog is Live!

**Public URL**: https://your-domain.com
**Admin URL**: https://your-domain.com/ghost

## Next Steps

1. **Customize design** in Theme Settings
2. **Add team members** as contributors
3. **Set up Google Analytics** for visitor tracking
4. **Configure social sharing**
5. **Create editorial calendar**

## Support

- **Documentation**: See main README.md
- **Ghost Help**: [ghost.org/docs](https://ghost.org/docs)
- **Theme Issues**: Check theme README.md

## Quick Commands

```bash
# Check services
docker-compose -f docker-compose.prod.yml ps

# View logs
docker-compose -f docker-compose.prod.yml logs -f

# Restart services
docker-compose -f docker-compose.prod.yml restart

# Update theme
cd themes/iron-bulwark && yarn zip
# Then upload new zip in Ghost admin
```

---

**🎉 Congratulations! Your Iron County community blog is now live and ready to serve your community!**
