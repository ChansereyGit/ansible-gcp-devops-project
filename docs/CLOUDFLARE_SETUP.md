# Cloudflare Setup Guide with Orange Cloud Proxy

## Overview

This guide shows how to use **Cloudflare as a proxy/CDN** for your services while maintaining proper SSL configuration.

## Architecture with Cloudflare

```
User Browser (HTTPS)
    ↓
Cloudflare CDN (Edge Server)
    ↓ (Cloudflare SSL)
Your Nginx (HTTPS with Cloudflare Origin Certificate)
    ↓ (HTTP)
Application (Jenkins/SonarQube/Nexus on localhost)
```

---

## Step 1: Verify Cloudflare Proxy is Enabled

In **Namecheap**:
1. Domain List → konpapa.online → MANAGE
2. Advanced DNS tab
3. Check your A records have **🟠 orange cloud** (proxy enabled)

If not orange, click to enable:

```
✅ A Record | jenkins    | 34.142.147.236 | Auto | 🟠
✅ A Record | sonarqube  | 34.21.213.214  | Auto | 🟠
✅ A Record | nexus      | 34.21.132.214  | Auto | 🟠
```

**Note:** With orange cloud, DNS will resolve to Cloudflare IPs (this is correct!)

---

## Step 2: Configure Cloudflare SSL Settings

### Login to Cloudflare

1. Go to https://dash.cloudflare.com
2. Login with your account
3. Select your domain: **konpapa.online**

### Set SSL/TLS Mode

1. Click **SSL/TLS** in left menu
2. Select **Full (strict)** mode

**SSL Modes explained:**
- ❌ **Off**: No encryption (insecure)
- ❌ **Flexible**: Cloudflare ↔ User (HTTPS), Cloudflare ↔ Origin (HTTP) - Not ideal
- ✅ **Full**: Both encrypted, but doesn't verify origin certificate
- ✅ **Full (strict)**: Both encrypted, verifies origin certificate (RECOMMENDED)

---

## Step 3: Create Cloudflare Origin Certificate

This certificate secures traffic between Cloudflare and your servers.

### Generate Certificate

1. In Cloudflare dashboard: **SSL/TLS** → **Origin Server**
2. Click **Create Certificate**
3. Configure:
   - **Private key type**: RSA (2048)
   - **Hostnames**: 
     ```
     *.konpapa.online
     konpapa.online
     ```
   - **Certificate Validity**: 15 years
4. Click **Create**

### Save Certificate Files

Cloudflare will show you two text blocks:

#### Origin Certificate (save as `origin-cert.pem`)
```
-----BEGIN CERTIFICATE-----
MIIEpDCCA...
(long text)
-----END CERTIFICATE-----
```

#### Private Key (save as `origin-key.pem`)
```
-----BEGIN PRIVATE KEY-----
MIIEvQIBA...
(long text)
-----END PRIVATE KEY-----
```

**Important:** Save both immediately! You can't view the private key again.

---

## Step 4: Upload Certificates to Your VMs

### Create Certificate Files on Each VM

On **jenkins-vm**:
```bash
# Create SSL directory
sudo mkdir -p /etc/nginx/ssl
cd /etc/nginx/ssl

# Create certificate file
sudo nano origin-cert.pem
# Paste the Origin Certificate, save and exit

# Create private key file
sudo nano origin-key.pem
# Paste the Private Key, save and exit

# Set permissions
sudo chmod 600 origin-key.pem
sudo chmod 644 origin-cert.pem
```

Repeat for **sonarqube-vm** and **nexus-vm**.

---

## Step 5: Update Nginx Configuration

### Nginx Config with Cloudflare Origin Certificate

For **Jenkins** (`/etc/nginx/sites-available/jenkins`):

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name jenkins.konpapa.online;
    
    # Redirect HTTP to HTTPS
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name jenkins.konpapa.online;

    # Cloudflare Origin Certificate
    ssl_certificate /etc/nginx/ssl/origin-cert.pem;
    ssl_certificate_key /etc/nginx/ssl/origin-key.pem;

    # SSL Configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Cloudflare Real IP
    set_real_ip_from 173.245.48.0/20;
    set_real_ip_from 103.21.244.0/22;
    set_real_ip_from 103.22.200.0/22;
    set_real_ip_from 103.31.4.0/22;
    set_real_ip_from 141.101.64.0/18;
    set_real_ip_from 108.162.192.0/18;
    set_real_ip_from 190.93.240.0/20;
    set_real_ip_from 188.114.96.0/20;
    set_real_ip_from 197.234.240.0/22;
    set_real_ip_from 198.41.128.0/17;
    set_real_ip_from 162.158.0.0/15;
    set_real_ip_from 104.16.0.0/13;
    set_real_ip_from 104.24.0.0/14;
    set_real_ip_from 172.64.0.0/13;
    set_real_ip_from 131.0.72.0/22;
    real_ip_header CF-Connecting-IP;

    # Logging
    access_log /var/log/nginx/jenkins.access.log;
    error_log /var/log/nginx/jenkins.error.log;

    # Proxy settings
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Jenkins specific
        proxy_buffering off;
        proxy_request_buffering off;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
    }
}
```

Similar configs for **SonarQube** (port 9000) and **Nexus** (port 8081).

---

## Step 6: Configure Cloudflare Firewall (Optional)

### Block Direct IP Access

Force all traffic through Cloudflare by blocking direct IP access:

1. In Cloudflare: **Security** → **WAF**
2. Create a **Firewall Rule**:
   - **Name**: Block Direct IP Access
   - **Field**: Hostname
   - **Operator**: does not equal
   - **Value**: `jenkins.konpapa.online` OR `sonarqube.konpapa.online` OR `nexus.konpapa.online`
   - **Action**: Block

### Allow Only Cloudflare IPs in GCP

Update GCP firewall to only accept traffic from Cloudflare:

```bash
# Get Cloudflare IP ranges
curl https://www.cloudflare.com/ips-v4

# Create GCP firewall rule
gcloud compute firewall-rules create allow-cloudflare-https \
  --direction=INGRESS \
  --priority=1000 \
  --network=default \
  --action=ALLOW \
  --rules=tcp:443 \
  --source-ranges=173.245.48.0/20,103.21.244.0/22,103.22.200.0/22,103.31.4.0/22,141.101.64.0/18,108.162.192.0/18,190.93.240.0/20,188.114.96.0/20,197.234.240.0/22,198.41.128.0/17,162.158.0.0/15,104.16.0.0/13,104.24.0.0/14,172.64.0.0/13,131.0.72.0/22 \
  --target-tags=https-server
```

---

## Step 7: Enable Cloudflare Features

### 7.1 Performance Features

1. **Auto Minify**: Speed → Optimization
   - Enable: JavaScript, CSS, HTML

2. **Brotli Compression**: Speed → Optimization
   - Enable

3. **Rocket Loader**: Speed → Optimization
   - Optional (test with your apps)

### 7.2 Security Features

1. **Security Level**: Security → Settings
   - Set to: Medium or High

2. **Challenge Passage**: Security → Settings
   - Set to: 30 minutes

3. **Browser Integrity Check**: Security → Settings
   - Enable

---

## Step 8: Test Your Setup

### Test HTTPS

```bash
# Test from anywhere (your laptop, another server)
curl -I https://jenkins.konpapa.online
curl -I https://sonarqube.konpapa.online
curl -I https://nexus.konpapa.online
```

### Verify SSL Certificate

```bash
# Check certificate issuer
openssl s_client -connect jenkins.konpapa.online:443 -servername jenkins.konpapa.online < /dev/null | grep -i issuer
```

Should show: `issuer=Cloudflare`

### Check Real IP is Logged

On your VM, check Nginx logs:
```bash
tail -f /var/log/nginx/jenkins.access.log
```

Should show visitor's real IP, not Cloudflare IP.

---

## Ansible Automation (Future Enhancement)

We can create an Ansible role to automate this:

```yaml
# roles/cloudflare-ssl/tasks/main.yaml
- name: Create SSL directory
  file:
    path: /etc/nginx/ssl
    state: directory
    mode: '0755'

- name: Copy Cloudflare origin certificate
  copy:
    content: "{{ cloudflare_origin_cert }}"
    dest: /etc/nginx/ssl/origin-cert.pem
    mode: '0644'

- name: Copy Cloudflare origin key
  copy:
    content: "{{ cloudflare_origin_key }}"
    dest: /etc/nginx/ssl/origin-key.pem
    mode: '0600'
  no_log: true

- name: Configure Nginx with Cloudflare SSL
  template:
    src: nginx-cloudflare.conf.j2
    dest: "/etc/nginx/sites-available/{{ service_name }}"
  notify: reload nginx
```

Store certificates in Ansible vault:
```bash
ansible-vault create vars/cloudflare-secrets.yaml
```

---

## Comparison: Cloudflare vs Let's Encrypt

| Feature | Cloudflare Origin | Let's Encrypt |
|---------|------------------|---------------|
| **Validity** | 15 years | 90 days |
| **Renewal** | Manual (long validity) | Auto (every 60 days) |
| **CDN** | ✅ Included | ❌ None |
| **DDoS Protection** | ✅ Included | ❌ None |
| **Setup** | Medium (one-time) | Easy (automated) |
| **Cost** | Free | Free |
| **Certificate Authority** | Cloudflare | Let's Encrypt |
| **Browser Trust** | Through Cloudflare | Direct |

---

## Troubleshooting

### Error: "Your connection is not private"

**Cause:** Nginx doesn't have Cloudflare certificate, or SSL mode is wrong.

**Fix:**
1. Check certificate files exist: `ls -la /etc/nginx/ssl/`
2. Verify Cloudflare SSL mode: Full (strict)
3. Check Nginx config: `sudo nginx -t`

### Error: "Too many redirects"

**Cause:** SSL mode mismatch.

**Fix:**
- Set Cloudflare SSL to **Full** or **Full (strict)**, not Flexible

### Cloudflare IPs in Logs

**Cause:** `real_ip_header` not configured.

**Fix:** Add Cloudflare IP ranges and `real_ip_header CF-Connecting-IP` to Nginx.

---

## Summary

✅ **With Cloudflare Proxy Enabled:**

1. Keep orange cloud 🟠 in Namecheap
2. Create Cloudflare Origin Certificate
3. Upload certificate to all VMs
4. Configure Nginx with Cloudflare certificate
5. Set Cloudflare SSL mode to Full (strict)
6. Enable Cloudflare features (CDN, security)

✅ **Benefits:**
- Free CDN (faster globally)
- DDoS protection
- SSL managed by Cloudflare
- Firewall/WAF
- Hidden origin IPs
- 15-year certificates (no renewal needed)

---

## Next Steps

1. Generate Cloudflare Origin Certificate
2. Save certificate and key
3. Upload to VMs manually (or via Ansible)
4. Update Nginx configs
5. Test HTTPS access

Let me know when you have the Cloudflare certificates, and I can help automate the deployment!
