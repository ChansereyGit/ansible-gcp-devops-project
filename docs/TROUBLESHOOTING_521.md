# Fixing Cloudflare Error 521 - Web Server Down

## 🔍 What is Error 521?

**Error 521** means Cloudflare successfully connected to your domain, but your origin web server (Nginx) is either:
- Not running
- Blocking Cloudflare's connection
- Configured incorrectly

## 🎯 Quick Fix Steps

### Step 1: Temporarily Disable Cloudflare Proxy

**This will help us diagnose if the issue is Cloudflare or your server.**

1. Go to Namecheap DNS settings
2. Click the **orange cloud 🟠** next to each A record to turn it **gray ☁️**:
   ```
   A Record | jenkins    | YOUR_IP | Auto | ☁️ (gray = DNS only)
   A Record | sonarqube  | YOUR_IP | Auto | ☁️ (gray = DNS only)
   A Record | nexus      | YOUR_IP | Auto | ☁️ (gray = DNS only)
   ```
3. Wait 2-3 minutes for DNS propagation
4. Try accessing: `https://jenkins.konpapa.online`

**If it works with gray cloud:** Issue is Cloudflare configuration
**If it still doesn't work:** Issue is on your server

### Step 2: Check Services on VMs

SSH into each VM and check status:

```bash
# SSH into jenkins-vm
gcloud compute ssh jenkins-vm --zone=asia-southeast1-c

# Check if Nginx is running
sudo systemctl status nginx

# Check if Jenkins container is running
docker ps | grep jenkins

# Check Nginx error logs
sudo tail -50 /var/log/nginx/error.log

# Check if Nginx is listening on ports
sudo netstat -tlnp | grep nginx
# Should show:
# tcp  0.0.0.0:80    LISTEN  nginx
# tcp  0.0.0.0:443   LISTEN  nginx
```

Repeat for sonarqube-vm and nexus-vm.

### Step 3: Common Issues and Fixes

#### Issue A: Nginx Not Running

```bash
# Start Nginx
sudo systemctl start nginx

# Enable on boot
sudo systemctl enable nginx

# Check status
sudo systemctl status nginx
```

#### Issue B: Certbot Failed During Configuration

If SSL certificate generation failed, Nginx config might be broken.

```bash
# Check Nginx configuration
sudo nginx -t

# If errors, temporarily remove SSL config
sudo nano /etc/nginx/sites-available/jenkins

# Comment out SSL lines:
# ssl_certificate /etc/letsencrypt/live/...
# ssl_certificate_key /etc/letsencrypt/live/...

# Reload Nginx
sudo systemctl reload nginx
```

#### Issue C: Docker Containers Not Running

```bash
# Check all containers
docker ps -a

# If containers stopped, start them
cd /opt/jenkins  # or /opt/sonarqube or /opt/nexus
docker-compose up -d

# Check logs
docker-compose logs -f
```

#### Issue D: Firewall Blocking Traffic

```bash
# Check if GCP firewall allows HTTPS
gcloud compute firewall-rules list | grep https

# Should see: allow-https with target-tags: https-server

# Check local firewall (UFW)
sudo ufw status

# If active and blocking, allow Nginx
sudo ufw allow 'Nginx Full'
```

## 🔧 Full Diagnostic Script

Run this on each VM:

```bash
#!/bin/bash
echo "=== VM Diagnostic ==="
echo "Hostname: $(hostname)"
echo "IP: $(hostname -I)"
echo ""

echo "=== Nginx Status ==="
sudo systemctl status nginx --no-pager
echo ""

echo "=== Nginx Ports ==="
sudo netstat -tlnp | grep nginx
echo ""

echo "=== Docker Containers ==="
docker ps
echo ""

echo "=== Nginx Configuration Test ==="
sudo nginx -t
echo ""

echo "=== Recent Nginx Errors ==="
sudo tail -20 /var/log/nginx/error.log
echo ""

echo "=== Certificate Status ==="
sudo certbot certificates
echo ""

echo "=== Disk Space ==="
df -h
echo ""

echo "=== Memory ==="
free -h
```

## 🎯 Most Likely Causes

### 1. SSL Certificate Not Configured (Most Common)

**Symptom:** Nginx fails to start or returns 502

**Fix:**
```bash
# Check if certificates exist
sudo ls -la /etc/letsencrypt/live/jenkins.konpapa.online/

# If missing, run certbot manually
sudo certbot --nginx -d jenkins.konpapa.online \
  --non-interactive --agree-tos -m admin@konpapa.online

# Reload Nginx
sudo systemctl reload nginx
```

### 2. Cloudflare Orange Cloud Without SSL Certificate

**Symptom:** Works with gray cloud, fails with orange cloud

**Cause:** Cloudflare expects HTTPS on your server, but you only have HTTP

**Fix Option 1: Disable Proxy (Quick)**
- Turn Cloudflare to gray cloud ☁️
- Use Let's Encrypt SSL directly

**Fix Option 2: Use Cloudflare Origin Certificate**
- Create Cloudflare Origin Certificate (see CLOUDFLARE_SETUP.md)
- Install on your servers
- Keep orange cloud enabled

**Fix Option 3: Change Cloudflare SSL Mode**
1. Cloudflare Dashboard → SSL/TLS
2. Change from "Full (strict)" to "Flexible"
   - **Warning:** This is less secure (Cloudflare→Server is HTTP only)

### 3. Nginx Configuration Error

**Symptom:** `nginx -t` shows errors

**Fix:**
```bash
# Check configuration
sudo nginx -t

# Common issues:
# - Missing semicolon
# - Invalid SSL certificate path
# - Port already in use

# If certificate paths wrong, update:
sudo nano /etc/nginx/sites-available/jenkins

# Fix paths or temporarily disable SSL
# Then reload:
sudo systemctl reload nginx
```

### 4. Container Not Running

**Symptom:** `docker ps` doesn't show your container

**Fix:**
```bash
# Navigate to service directory
cd /opt/jenkins  # or /opt/sonarqube, /opt/nexus

# Check if compose file exists
ls -la docker-compose.yml

# Start containers
docker-compose up -d

# Check logs for errors
docker-compose logs -f

# If port conflict:
docker-compose down
docker ps -a  # Check for conflicting containers
docker-compose up -d
```

## 🚀 Recommended Solution

For your setup, I recommend **Option 1: Gray Cloud + Let's Encrypt**:

### Why?
- ✅ Simpler setup
- ✅ Direct HTTPS (no Cloudflare SSL complexity)
- ✅ Free SSL with auto-renewal
- ✅ Works immediately after configuration

### Quick Setup:

1. **In Namecheap:**
   - Set all DNS to **gray cloud ☁️** (DNS only mode)

2. **On each VM:**
   ```bash
   # Obtain SSL certificate
   sudo certbot --nginx -d jenkins.konpapa.online \
     --non-interactive --agree-tos -m admin@konpapa.online
   
   # Certbot automatically configures Nginx
   # No manual config needed!
   ```

3. **Test:**
   ```bash
   curl -I https://jenkins.konpapa.online
   # Should return: HTTP/2 200
   ```

## 📊 Decision Matrix

| Setup | Complexity | SSL Validity | CDN | DDoS Protection | Best For |
|-------|-----------|--------------|-----|-----------------|----------|
| **Gray Cloud + Let's Encrypt** | Low | 90 days (auto) | ❌ | ❌ | Learning, Small Projects |
| **Orange Cloud + Cloudflare** | Medium | 15 years | ✅ | ✅ | Production, High Traffic |

## 🎯 Step-by-Step Fix (Recommended)

### Run This Now:

```bash
# 1. Check all VMs
for vm in jenkins-vm sonarqube-vm nexus-vm; do
  echo "=== Checking $vm ==="
  gcloud compute ssh $vm --zone=asia-southeast1-c --command="
    echo 'Nginx status:'
    sudo systemctl status nginx | head -5
    echo ''
    echo 'Docker containers:'
    docker ps
    echo ''
    echo 'Nginx config test:'
    sudo nginx -t
  "
  echo ""
done
```

### Then:

1. **If Nginx not running:**
   ```bash
   gcloud compute ssh jenkins-vm --zone=asia-southeast1-c
   sudo systemctl start nginx
   sudo systemctl enable nginx
   ```

2. **If Nginx config errors:**
   ```bash
   # View errors
   sudo nginx -t
   
   # Check certificate paths exist
   sudo ls -la /etc/letsencrypt/live/
   
   # If no certificates, obtain them:
   sudo certbot --nginx -d jenkins.konpapa.online \
     --non-interactive --agree-tos -m admin@konpapa.online
   ```

3. **If containers not running:**
   ```bash
   cd /opt/jenkins
   docker-compose up -d
   docker-compose logs -f
   ```

4. **In Namecheap - Disable Cloudflare proxy:**
   - Click orange cloud to turn gray for all records
   - Wait 2-3 minutes
   - Test: `https://jenkins.konpapa.online`

## ✅ Expected Results

After fixes, you should see:

```bash
$ curl -I https://jenkins.konpapa.online
HTTP/2 200
server: nginx
date: Mon, 22 Sep 2026 ...
content-type: text/html
x-jenkins: 2.x.x
```

## 📞 Still Not Working?

Run this diagnostic and share output:

```bash
# Create diagnostic report
cat > /tmp/diagnostic.sh << 'EOF'
#!/bin/bash
echo "=== System Info ==="
uname -a
echo ""

echo "=== Services Status ==="
sudo systemctl status nginx docker --no-pager
echo ""

echo "=== Nginx Config Test ==="
sudo nginx -t
echo ""

echo "=== Listening Ports ==="
sudo netstat -tlnp | grep -E '(nginx|docker)'
echo ""

echo "=== Docker Containers ==="
docker ps -a
echo ""

echo "=== SSL Certificates ==="
sudo certbot certificates 2>&1 || echo "Certbot not configured"
echo ""

echo "=== Recent Nginx Errors ==="
sudo tail -30 /var/log/nginx/error.log
echo ""

echo "=== Disk Space ==="
df -h /
EOF

chmod +x /tmp/diagnostic.sh
/tmp/diagnostic.sh
```

---

**Next Action:** Run the diagnostic script on each VM and share the output so I can help you pinpoint the exact issue.
