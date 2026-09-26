# SSL Configuration Quick Reference

## 📍 Where to Configure SSL Settings

### 1. Email Address (For Expiry Notifications)

**File**: `ansible/vars/config.yaml`

```yaml
# Email for Let's Encrypt SSL certificates
letsencrypt_email: "admin@konpapa.online"  # ← Change this
```

### 2. Auto-Renewal Time

**File**: `ansible/roles/certbot/defaults/main.yaml`

```yaml
certbot_auto_renew_hour: "3"      # ← Change this (0-23)
certbot_auto_renew_minute: "30"   # ← Change this (0-59)
```

**Or add to** `ansible/vars/config.yaml`:
```yaml
# Add at the bottom
certbot_renewal_hour: "2"     # Run at 2 AM
certbot_renewal_minute: "0"   # At the top of the hour
```

### 3. Domain Names

**File**: `ansible/vars/config.yaml`

```yaml
# Domain Configuration
base_domain: "konpapa.online"
jenkins_domain: "jenkins.konpapa.online"      # ← Change these
sonarqube_domain: "sonarqube.konpapa.online"  # ← Change these
nexus_domain: "nexus.konpapa.online"          # ← Change these
```

---

## ⚙️ Common Configuration Changes

### Change Renewal Time to 2:00 AM

**Edit**: `ansible/vars/config.yaml`

```yaml
# Add these lines at the bottom:
certbot_renewal_hour: "2"
certbot_renewal_minute: "0"
```

**Apply changes:**
```bash
just configure-all
```

### Change Email for SSL Notifications

**Edit**: `ansible/vars/config.yaml`

```yaml
letsencrypt_email: "devops@yourcompany.com"  # New email
```

**Apply changes:**
```bash
just configure-all
```

### Enable Production-Grade Monitoring

**Create**: `ansible/roles/certbot/files/check-ssl.sh`

```bash
#!/bin/bash
# Check SSL certificate expiry

DOMAIN="$1"
DAYS=$(echo | openssl s_client -servername $DOMAIN -connect $DOMAIN:443 2>/dev/null | \
       openssl x509 -noout -dates | grep notAfter | sed 's/notAfter=//' | \
       xargs -I {} date -d "{}" +%s | awk -v now=$(date +%s) '{print int(($1 - now) / 86400)}')

if [ $DAYS -lt 15 ]; then
    echo "⚠️  WARNING: $DOMAIN certificate expires in $DAYS days!"
    exit 1
else
    echo "✅ $DOMAIN certificate valid for $DAYS days"
    exit 0
fi
```

**Add monitoring task** to `ansible/roles/certbot/tasks/main.yaml`:

```yaml
- name: Copy SSL monitoring script
  copy:
    src: check-ssl.sh
    dest: /usr/local/bin/check-ssl.sh
    mode: '0755'

- name: Add SSL monitoring cron job
  cron:
    name: "SSL certificate expiry check"
    minute: "0"
    hour: "8"
    job: "/usr/local/bin/check-ssl.sh {{ jenkins_domain if 'jenkins' in group_names else sonarqube_domain if 'sonarqube' in group_names else nexus_domain }}"
    user: root
    state: present
```

---

## 🎯 Production Configuration Example

**File**: `ansible/vars/config.yaml`

```yaml
# ============================================================================
# SSL/TLS Configuration
# ============================================================================

# Email for Let's Encrypt notifications (REQUIRED)
letsencrypt_email: "devops@yourcompany.com"

# Auto-renewal schedule (runs daily)
certbot_renewal_hour: "2"      # 2:00 AM (server time)
certbot_renewal_minute: "0"    # Top of the hour

# Enable renewal logging
certbot_enable_logging: true
certbot_log_file: "/var/log/letsencrypt/renewal.log"

# Email notifications on renewal
certbot_notify_on_renewal: true

# Staging mode (for testing, avoid rate limits)
certbot_staging: false  # Set to true for testing
```

---

## ✅ Your Current Setup Status

| Component | Status | Configuration File |
|-----------|--------|-------------------|
| **Certificate Validity** | 90 days | Let's Encrypt (fixed) |
| **Auto-Renewal** | ✅ Enabled | `certbot/defaults/main.yaml` |
| **Renewal Schedule** | Daily at 3:30 AM | `certbot/defaults/main.yaml` |
| **Renewal Trigger** | 30 days before expiry | Certbot (automatic) |
| **Email Notifications** | ✅ Configured | `config.yaml` |
| **Nginx Auto-Reload** | ✅ Enabled | `certbot/tasks/main.yaml` |
| **HTTPS Redirect** | ✅ Enabled | Nginx configs |

**Your setup is already production-ready!** ✨

---

## 🔍 Check Your Current Configuration

```bash
# On any VM, check certificate status
sudo certbot certificates

# Output shows:
# ✓ Certificate Name: jenkins.konpapa.online
# ✓ Expiry Date: 2026-12-20 (89 days remaining)
# ✓ Certificate Path: /etc/letsencrypt/live/jenkins.konpapa.online/fullchain.pem
```

```bash
# Check auto-renewal cron job
sudo crontab -l | grep certbot

# Output:
# 30 3 * * * certbot renew --quiet --post-hook 'systemctl reload nginx'
```

```bash
# Test renewal (dry run)
sudo certbot renew --dry-run

# Output:
# Congratulations, all renewals succeeded!
```

---

## 📊 Certificate Timeline

```
Day 0                    Day 60                    Day 90
[Certificate Issued] ──→ [Auto-Renewal] ────────→ [Would Expire]
                         ↑
                         Your cron job runs here
                         (actually runs daily, but
                          only renews when <30 days left)
```

**You get 3 chances to renew:**
- **Day 60-90**: 30 days window
- **Daily attempts**: 30 attempts
- **Email warnings**: Day 70 and Day 80

---

## 🚀 Quick Actions

### Test SSL Renewal Right Now

```bash
# SSH into each VM and test
ssh jenkins-vm
sudo certbot renew --dry-run

ssh sonarqube-vm
sudo certbot renew --dry-run

ssh nexus-vm
sudo certbot renew --dry-run
```

### Change Renewal Time to 2 AM

**1. Edit config:**
```bash
# Edit: ansible/vars/config.yaml
# Add at the bottom:
certbot_renewal_hour: "2"
certbot_renewal_minute: "0"
```

**2. Apply:**
```bash
just configure-all
```

**3. Verify:**
```bash
ssh jenkins-vm "sudo crontab -l | grep certbot"
# Should show: 0 2 * * * certbot renew...
```

### Force Manual Renewal (If Needed)

```bash
# Only needed if testing or emergency
ssh jenkins-vm
sudo certbot renew --force-renewal
sudo systemctl reload nginx
```

---

## 💡 Key Takeaways

1. **Certificates are valid for 90 days** (not 30!)
2. **Auto-renewal happens at day 60** (30 days before expiry)
3. **Your setup is already production-ready** - no changes needed
4. **Renewal runs daily at 3:30 AM** - you can change this
5. **You'll get email warnings** if renewal fails

---

## 📞 Need Help?

**Check logs:**
```bash
sudo tail -f /var/log/letsencrypt/letsencrypt.log
```

**Test configuration:**
```bash
sudo certbot renew --dry-run
```

**Check certificate expiry:**
```bash
echo | openssl s_client -servername jenkins.konpapa.online \
  -connect jenkins.konpapa.online:443 2>/dev/null | \
  openssl x509 -noout -dates
```

---

**Bottom Line:** Your SSL setup is production-ready. Let's Encrypt certificates last **90 days** and auto-renew at **60 days**. No changes needed! ✨
