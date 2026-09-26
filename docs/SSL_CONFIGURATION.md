# SSL Certificate Configuration Guide

## 📋 Overview

Your project uses **Let's Encrypt** for free, automated SSL certificates with the following setup:

- **Certificate Authority**: Let's Encrypt (Trusted by all major browsers)
- **Certificate Validity**: 90 days
- **Auto-Renewal**: Yes (runs daily at 3:30 AM)
- **Renewal Trigger**: Automatically renews when 30 days remain (at 60-day mark)
- **Rate Limits**: 50 certificates per domain per week

---

## 🔧 Configuration Files

### Main Configuration: `ansible/vars/config.yaml`

```yaml
# Domain Configuration
base_domain: "konpapa.online"
jenkins_domain: "jenkins.konpapa.online"
sonarqube_domain: "sonarqube.konpapa.online"
nexus_domain: "nexus.konpapa.online"

# Email for Let's Encrypt SSL certificates
letsencrypt_email: "admin@konpapa.online"
```

### Certbot Role: `ansible/roles/certbot/defaults/main.yaml`

```yaml
certbot_admin_email: "{{ letsencrypt_email }}"
certbot_create_if_missing: true
certbot_auto_renew: true
certbot_auto_renew_hour: "3"      # 3 AM
certbot_auto_renew_minute: "30"   # 30 minutes past the hour
```

---

## ⚡ Quick Configuration Changes

### Change Renewal Time

If you want to change when auto-renewal runs:

**Option 1: Edit `config.yaml`**
```yaml
# Add these lines to ansible/vars/config.yaml
certbot_renewal_hour: "2"     # 2 AM instead of 3 AM
certbot_renewal_minute: "0"   # At the top of the hour
```

**Option 2: Edit role defaults**
```bash
# Edit: ansible/roles/certbot/defaults/main.yaml
certbot_auto_renew_hour: "2"
certbot_auto_renew_minute: "0"
```

### Change Email Address

```yaml
# In ansible/vars/config.yaml
letsencrypt_email: "your-new-email@example.com"
```

**Then re-run configuration:**
```bash
just configure-all
```

---

## 🚀 Testing SSL Setup

### Check Current Certificate Status

SSH into each VM and check:

```bash
# Check certificate validity
sudo certbot certificates

# Output shows:
# - Domain names
# - Expiry date
# - Certificate path
# - Key path
```

### Test Auto-Renewal

```bash
# Dry run (doesn't actually renew)
sudo certbot renew --dry-run

# Force renewal (only if needed for testing)
sudo certbot renew --force-renewal
```

### View Auto-Renewal Cron Job

```bash
# Check cron job
sudo crontab -l | grep certbot

# Should show:
# 30 3 * * * certbot renew --quiet --post-hook 'systemctl reload nginx'
```

---

## 🎯 Production Best Practices

### ✅ Current Setup (Already Production-Ready)

Your current configuration follows all best practices:

1. **✓ Auto-renewal enabled** - Runs daily at 3:30 AM
2. **✓ Nginx reload on renewal** - Automatically applies new certificates
3. **✓ Valid email for notifications** - Let's Encrypt sends expiry warnings
4. **✓ Rate limit aware** - Uses `--non-interactive` to avoid hitting limits
5. **✓ HTTPS redirect enabled** - All HTTP traffic redirects to HTTPS

### 🔧 Optional Enhancements

#### 1. Add Monitoring

Create a monitoring script to check certificate expiry:

```bash
# Create: /usr/local/bin/check-ssl-expiry.sh
#!/bin/bash

DAYS_UNTIL_EXPIRY=$(echo | openssl s_client -servername jenkins.konpapa.online \
  -connect jenkins.konpapa.online:443 2>/dev/null | openssl x509 -noout -dates | \
  grep notAfter | sed 's/notAfter=//' | xargs -I {} date -d "{}" +%s | \
  awk -v now=$(date +%s) '{print int(($1 - now) / 86400)}')

if [ $DAYS_UNTIL_EXPIRY -lt 15 ]; then
  echo "WARNING: SSL certificate expires in $DAYS_UNTIL_EXPIRY days!"
  # Send alert (email, Slack, etc.)
fi
```

#### 2. Enable Certbot Logs

```yaml
# Add to ansible/roles/certbot/tasks/main.yaml after the cron task

- name: Enable detailed certbot logging
  cron:
    name: "Certbot automatic renewal with logging"
    minute: "{{ certbot_auto_renew_minute | default('30') }}"
    hour: "{{ certbot_auto_renew_hour | default('3') }}"
    job: >
      certbot renew --quiet
      --post-hook 'systemctl reload nginx'
      --log-file /var/log/letsencrypt/renewal.log
    user: root
    state: present
```

#### 3. Add Email Notifications on Renewal

```yaml
- name: Setup renewal notification script
  copy:
    dest: /usr/local/bin/certbot-notify.sh
    mode: '0755'
    content: |
      #!/bin/bash
      echo "SSL Certificate renewed on $(hostname) at $(date)" | \
        mail -s "SSL Certificate Renewed - $(hostname)" {{ letsencrypt_email }}

- name: Update cron with notification
  cron:
    name: "Certbot automatic renewal"
    minute: "{{ certbot_auto_renew_minute | default('30') }}"
    hour: "{{ certbot_auto_renew_hour | default('3') }}"
    job: >
      certbot renew --quiet
      --post-hook 'systemctl reload nginx && /usr/local/bin/certbot-notify.sh'
    user: root
    state: present
```

---

## 📊 Certificate Information

### Check Certificate Details

```bash
# View certificate information
sudo certbot certificates

# Example output:
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Found the following certs:
#   Certificate Name: jenkins.konpapa.online
#     Serial Number: 3c8f2a1b4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a
#     Key Type: ECDSA
#     Domains: jenkins.konpapa.online
#     Expiry Date: 2026-12-20 15:30:00+00:00 (VALID: 89 days)
#     Certificate Path: /etc/letsencrypt/live/jenkins.konpapa.online/fullchain.pem
#     Private Key Path: /etc/letsencrypt/live/jenkins.konpapa.online/privkey.pem
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
```

### Check Certificate Chain

```bash
# View full certificate chain
openssl x509 -in /etc/letsencrypt/live/jenkins.konpapa.online/fullchain.pem -text -noout

# Check what's trusted by browsers
openssl s_client -connect jenkins.konpapa.online:443 -servername jenkins.konpapa.online
```

---

## 🔄 Manual Certificate Operations

### Obtain New Certificate

```bash
# For a new domain
sudo certbot --nginx -d new-subdomain.konpapa.online \
  --non-interactive --agree-tos -m admin@konpapa.online
```

### Renew All Certificates

```bash
# Renew all certificates (if within 30 days of expiry)
sudo certbot renew

# Force renewal (for testing)
sudo certbot renew --force-renewal

# Renew specific certificate
sudo certbot renew --cert-name jenkins.konpapa.online
```

### Revoke Certificate

```bash
# Revoke if compromised
sudo certbot revoke --cert-path /etc/letsencrypt/live/jenkins.konpapa.online/cert.pem

# Revoke and delete
sudo certbot revoke --cert-path /etc/letsencrypt/live/jenkins.konpapa.online/cert.pem --delete-after-revoke
```

### Delete Certificate

```bash
# Delete without revoking
sudo certbot delete --cert-name jenkins.konpapa.online
```

---

## 🚨 Troubleshooting

### Issue: Certificate Not Renewing

**Check renewal status:**
```bash
sudo certbot renew --dry-run
```

**Check cron job:**
```bash
sudo systemctl status cron
sudo crontab -l
```

**Check logs:**
```bash
sudo tail -f /var/log/letsencrypt/letsencrypt.log
```

### Issue: Rate Limit Hit

Let's Encrypt limits:
- **50 certificates per domain per week**
- **5 duplicate certificates per week**

**Solution:**
- Wait for the weekly limit to reset
- Use staging server for testing:
```bash
sudo certbot --nginx -d test.konpapa.online \
  --staging \
  --non-interactive --agree-tos -m admin@konpapa.online
```

### Issue: DNS Not Propagating

**Check DNS:**
```bash
# Check if DNS is resolving correctly
dig jenkins.konpapa.online +short
nslookup jenkins.konpapa.online

# Wait for propagation (can take up to 48 hours)
```

**Use DNS challenge instead of HTTP:**
```bash
sudo certbot certonly --manual --preferred-challenges dns \
  -d jenkins.konpapa.online \
  -m admin@konpapa.online
```

### Issue: Nginx Not Reloading

**Check Nginx config:**
```bash
sudo nginx -t
```

**Manually reload:**
```bash
sudo systemctl reload nginx
```

**Check if certificate is being used:**
```bash
openssl s_client -connect jenkins.konpapa.online:443 -servername jenkins.konpapa.online | openssl x509 -noout -dates
```

---

## 📈 Monitoring & Alerts

### Certificate Expiry Monitoring

**Option 1: Using Certbot Built-in**
```bash
# Certbot sends email warnings 20 and 10 days before expiry
# Ensure email is set correctly in config.yaml
```

**Option 2: External Monitoring**
- [SSL Labs](https://www.ssllabs.com/ssltest/) - Test SSL configuration
- [UptimeRobot](https://uptimerobot.com/) - Monitor certificate expiry
- [Prometheus SSL Exporter](https://github.com/ribbybibby/ssl_exporter) - For Prometheus/Grafana

**Option 3: Custom Script**
```bash
# Add to cron to check daily
0 9 * * * /usr/local/bin/check-ssl-expiry.sh
```

---

## 🔐 Security Best Practices

### Current Security (Already Implemented)

- ✅ **Strong SSL/TLS** - Modern ciphers enabled
- ✅ **HTTP to HTTPS redirect** - All traffic encrypted
- ✅ **HSTS enabled** - Browser forces HTTPS
- ✅ **Auto-renewal** - No expired certificates

### Additional Security Enhancements

**1. Add OCSP Stapling** (already in nginx configs):
```nginx
ssl_stapling on;
ssl_stapling_verify on;
```

**2. Monitor SSL Labs Grade:**
```bash
# Test your SSL configuration
curl "https://api.ssllabs.com/api/v3/analyze?host=jenkins.konpapa.online"
```

**3. Enable Certificate Transparency:**
- Already enabled by Let's Encrypt
- Monitor at: https://crt.sh/?q=konpapa.online

---

## 📝 Configuration Summary

### Your Current Setup

| Setting | Value | Production Ready? |
|---------|-------|-------------------|
| Certificate Provider | Let's Encrypt | ✅ Yes |
| Certificate Validity | 90 days | ✅ Yes |
| Auto-Renewal | Enabled (Daily at 3:30 AM) | ✅ Yes |
| Renewal Trigger | 30 days before expiry | ✅ Yes |
| Nginx Reload on Renewal | Enabled | ✅ Yes |
| Email Notifications | Configured | ✅ Yes |
| HTTPS Redirect | Enabled | ✅ Yes |
| Rate Limit Protection | Implemented | ✅ Yes |

**Verdict: Your SSL setup is production-ready! 🎉**

---

## 🎯 Recommended Actions

For **testing** your current setup:

```bash
# 1. Check certificate status on each VM
ssh jenkins-vm "sudo certbot certificates"
ssh sonarqube-vm "sudo certbot certificates"
ssh nexus-vm "sudo certbot certificates"

# 2. Test auto-renewal (dry run)
ssh jenkins-vm "sudo certbot renew --dry-run"

# 3. Check cron job
ssh jenkins-vm "sudo crontab -l | grep certbot"

# 4. View renewal logs
ssh jenkins-vm "sudo cat /var/log/letsencrypt/letsencrypt.log"
```

For **production**, your current setup needs **no changes**. It will:
- Automatically renew certificates every 60 days
- Reload Nginx to apply new certificates
- Send email alerts if renewal fails
- Keep your sites secure with valid SSL certificates

---

## 📚 Additional Resources

- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [Certbot Documentation](https://certbot.eff.org/docs/)
- [SSL Best Practices](https://wiki.mozilla.org/Security/Server_Side_TLS)
- [SSL Labs Testing](https://www.ssllabs.com/ssltest/)

---

**Your SSL is production-ready! No changes needed unless you want to customize renewal times or add monitoring.** ✨
