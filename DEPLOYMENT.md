# Deployment Guide - Cape Noor System

## Overview

This guide covers deploying both the PHP API and the Admin Web Dashboard for the Cape Noor mosque management system.

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Admin Users (Web Browser)                │
└──────────────────────────┬──────────────────────────────────┘
                           │
                    ┌──────▼────────┐
                    │  Admin Web UI  │
                    │  (HTML/JS/CSS) │
                    └──────┬─────────┘
                           │
         ┌─────────────────┼─────────────────┐
         │ /v2/admin/* routes (JWT protected) │
         └─────────────────┼─────────────────┘
                           │
                    ┌──────▼─────────┐
                    │  PHP Slim 4    │
                    │  API Server    │
                    └──────┬─────────┘
                           │
                    ┌──────▼─────────┐
                    │   MySQL 8.0    │
                    │   Database     │
                    └────────────────┘
```

## Prerequisites

### For Local Development

- PHP 8.1+ with mbstring, json, pdo extensions
- MySQL 8.0+
- Composer
- Docker (optional, for containerized deployment)
- Node.js/npm (optional, for web development tools)

### For Production

- Ubuntu 20.04 or CentOS 8+
- PHP 8.1+ with FPM or as Apache module
- MySQL 8.0+
- Nginx or Apache web server
- SSL certificate (Let's Encrypt recommended)
- Domain name
- Enough disk space for prayer times cache and backups

## Part 1: API Deployment

### Option A: Traditional VPS/Dedicated Server

#### 1. SSH into your server

```bash
ssh user@your-server.com
cd /var/www/html
```

#### 2. Clone repository

```bash
git clone https://github.com/r-r-developers/cape-noor-apk-web-ui.git cape-noor
cd cape-noor/api
```

#### 3. Install dependencies

```bash
composer install --no-dev --optimize-autoloader
```

#### 4. Setup environment

```bash
cp .env.example .env
nano .env
```

Configure these critical values:

```
DB_HOST=localhost
DB_USER=cape_noor_user
DB_PASS=secure_password_here
DB_NAME=cape_noor_db
PORT=8080
JWT_SECRET=generate-random-secret-key-here
```

#### 5. Setup database

```bash
# Create database
mysql -u root -p << EOF
CREATE DATABASE cape_noor_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'cape_noor_user'@'localhost' IDENTIFIED BY 'secure_password_here';
GRANT ALL PRIVILEGES ON cape_noor_db.* TO 'cape_noor_user'@'localhost';
FLUSH PRIVILEGES;
EOF

# Run migrations
mysql -u cape_noor_user -p cape_noor_db < migrations/001_existing_tables.sql
mysql -u cape_noor_user -p cape_noor_db < migrations/002_app_user_tables.sql
mysql -u cape_noor_user -p cape_noor_db < migrations/003_duas_tables.sql
```

#### 6. Setup PHP-FPM with Nginx

Create `/etc/nginx/sites-available/cape-noor-api`:

```nginx
upstream php_backend {
    server unix:/run/php/php8.1-fpm.sock;
}

server {
    listen 80;
    listen [::]:80;
    server_name api.cape-noor.com;

    root /var/www/html/cape-noor/api/public;
    index index.php;

    # Log files
    access_log /var/log/nginx/cape-noor-api-access.log;
    error_log /var/log/nginx/cape-noor-api-error.log;

    # Gzip compression
    gzip on;
    gzip_types text/plain application/json;

    # Main location
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    # PHP handling
    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_pass php_backend;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    # Deny access to sensitive files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    location ~ /migrations/ {
        deny all;
    }

    location ~ /secrets/ {
        deny all;
    }
}
```

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/cape-noor-api /etc/nginx/sites-enabled/
sudo systemctl restart nginx
```

#### 7. Setup SSL with Let's Encrypt

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot certonly --nginx -d api.cape-noor.com
```

Update Nginx config to use SSL:

```nginx
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    
    ssl_certificate /etc/letsencrypt/live/api.cape-noor.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.cape-noor.com/privkey.pem;
    
    # ... rest of config
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name api.cape-noor.com;
    return 301 https://$server_name$request_uri;
}
```

#### 8. Create system user for API

```bash
sudo useradd -r -s /bin/false cape-noor
sudo chown -R cape-noor:www-data /var/www/html/cape-noor/api
sudo chmod -R 750 /var/www/html/cape-noor/api
sudo chmod -R 770 /var/www/html/cape-noor/api/cache
```

#### 9. Create cron job for prayer times scraping

```bash
# Edit crontab
crontab -e

# Add this line to run at 2 AM daily
0 2 * * * cd /var/www/html/cape-noor/api && /usr/bin/php bin/scrape-prayer-times.php >> /var/log/cape-noor-scraper.log 2>&1
```

### Option B: Docker Deployment

#### 1. Setup Docker and Docker Compose

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

#### 2. Deploy with Docker Compose

```bash
cd /var/www/cape-noor

cat > docker-compose.prod.yml << 'EOF'
version: '3.8'

services:
  api:
    image: php:8.1-fpm-alpine
    volumes:
      - ./api:/var/www/html
    environment:
      - DB_HOST=mysql
      - DB_USER=cape_noor_user
      - DB_PASS=${CAPE_NOOR_DB_PASS}
      - DB_NAME=cape_noor_db
      - JWT_SECRET=${JWT_SECRET}
      - ENVIRONMENT=production
    depends_on:
      - mysql
    restart: always
    networks:
      - cape-noor

  mysql:
    image: mysql:8.0-alpine
    environment:
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASS}
      - MYSQL_DATABASE=cape_noor_db
      - MYSQL_USER=cape_noor_user
      - MYSQL_PASSWORD=${CAPE_NOOR_DB_PASS}
    volumes:
      - mysql_data:/var/lib/mysql
      - ./api/migrations:/docker-entrypoint-initdb.d
    restart: always
    networks:
      - cape-noor

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./api/public:/usr/share/nginx/html
      - ./nginx.conf:/etc/nginx/conf.d/default.conf
      - /etc/letsencrypt:/etc/letsencrypt
    depends_on:
      - api
    restart: always
    networks:
      - cape-noor

networks:
  cape-noor:
    driver: bridge

volumes:
  mysql_data:
EOF

# Create .env file
cat > .env.prod << 'EOF'
CAPE_NOOR_DB_PASS=very_secure_password_change_this
MYSQL_ROOT_PASS=mysql_root_password_change_this
JWT_SECRET=your-jwt-secret-key-change-this
EOF

# Deploy
docker-compose -f docker-compose.prod.yml up -d
```

## Part 2: Admin Web UI Deployment

### Option A: Standalone (Recommended)

#### 1. Copy files to web server

```bash
cd /var/www/html
cp -r cape-noor/admin-web ./cape-noor-admin
cd cape-noor-admin
```

#### 2. Setup Nginx for admin dashboard

Create `/etc/nginx/sites-available/cape-noor-admin`:

```nginx
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name admin.cape-noor.com;

    root /var/www/html/cape-noor-admin;
    index index.html;

    ssl_certificate /etc/letsencrypt/live/admin.cape-noor.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/admin.cape-noor.com/privkey.pem;

    # Compression
    gzip on;
    gzip_types text/html text/css text/javascript application/javascript;

    # Security headers
    add_header X-Content-Type-Options "nosniff";
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1h;
        add_header Cache-Control "public, immutable";
    }

    # HTML - no cache
    location ~* \.html$ {
        expires -1;
        add_header Cache-Control "public, must-revalidate";
    }

    # SPA routing
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Deny sensitive files
    location ~ /\. {
        deny all;
    }
}

# HTTP redirect
server {
    listen 80;
    listen [::]:80;
    server_name admin.cape-noor.com;
    return 301 https://$server_name$request_uri;
}
```

#### 3. Update API URL

Edit `config.js` and update the API_BASE_URL:

```javascript
const CONFIG = {
    API_BASE_URL: 'https://api.cape-noor.com/api',
    // ... rest of config
};
```

#### 4. Enable and test

```bash
sudo ln -s /etc/nginx/sites-available/cape-noor-admin /etc/nginx/sites-enabled/
sudo systemctl restart nginx
```

Visit `https://admin.cape-noor.com` in your browser.

### Option B: Docker Deployment

```bash
cd /var/www/cape-noor/admin-web

docker build -t cape-noor-admin .
docker run -d \
  -p 8081:80 \
  -e API_BASE_URL=https://api.cape-noor.com/api \
  --name cape-noor-admin \
  cape-noor-admin
```

## Monitoring & Maintenance

### Monitor API logs

```bash
# If using Docker
docker logs -f cape-noor_api_1

# If using traditional setup
tail -f /var/log/php8.1-fpm.log
tail -f /var/log/nginx/cape-noor-api-error.log
```

### Database backups

```bash
# Daily backup script
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
mysqldump -u cape_noor_user -p cape_noor_db > /backups/cape-noor-${DATE}.sql.gz

# Add to crontab
0 3 * * * /path/to/backup-script.sh
```

### Monitor disk space

```bash
# Prayer times cache cleanup (runs monthly)
find /var/www/html/cape-noor/api/cache -type f -mtime +90 -delete
```

### Update system

```bash
# Keep PHP and dependencies updated
sudo apt update
sudo apt upgrade
composer update --no-dev

# Restart services
sudo systemctl restart php8.1-fpm
sudo systemctl restart nginx
```

## Troubleshooting

### API returns 500 error

1. Check logs: `tail -f /var/log/php-fpm.log`
2. Verify database connection
3. Check JWT_SECRET is set

### Admin dashboard shows "Connection refused"

1. Check API_BASE_URL is correct in config.js
2. Visit API directly to test: `curl https://api.cape-noor.com/api/v2/mosques`
3. Check CORS headers are set in API

### Database errors

```bash
# Check database connection
mysql -u cape_noor_user -p -h localhost cache_noor_db

# Check table structure
SHOW TABLES;
DESCRIBE users;
```

### SSL certificate issues

```bash
# Renew certificate
sudo certbot renew

# Force renewal
sudo certbot renew --force-renewal
```

## Security Checklist

- [ ] Change all default passwords
- [ ] Setup SSL/TLS certificates
- [ ] Configure firewall rules
- [ ] Enable database backups
- [ ] Setup monitoring/alerting
- [ ] Configure rate limiting
- [ ] Setup access logs
- [ ] Create API rate limiting
- [ ] Setup intrusion detection
- [ ] Regular security updates
- [ ] Two-factor authentication for super admins
- [ ] Database connection SSL enabled

## Performance Optimization

### PHP-FPM tuning

```ini
[global]
pm = dynamic
pm.max_children = 50
pm.start_servers = 20
pm.min_spare_servers = 10
pm.max_spare_servers = 30
```

### MySQL optimization

```sql
-- Add indexes for common queries
CREATE INDEX idx_user_id ON user_mosques(user_id);
CREATE INDEX idx_mosque_slug ON user_mosques(mosque_slug);
CREATE INDEX idx_status ON pending_changes(status);
```

### Redis caching (optional)

```bash
docker run -d \
  -p 6379:6379 \
  --name cape-noor-redis \
  redis:alpine
```

## Support & Escalation

For deployment issues:
1. Check logs and error messages
2. Review this guide
3. Check GitHub issues
4. Contact development team

## Additional Resources

- [Slim Framework Documentation](https://www.slimframework.com/)
- [PHP-FPM Configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [MySQL Security](https://dev.mysql.com/doc/mysql-security-excerpt/8.0/en/)
