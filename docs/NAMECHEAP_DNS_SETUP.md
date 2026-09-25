# Namecheap DNS Setup Guide

## Overview
This guide walks you through setting up DNS records on Namecheap to point your subdomains to your GCP VMs.

## Prerequisites
- ✅ 3 VMs created on GCP (jenkins-vm, sonarqube-vm, nexus-vm)
- ✅ Domain: konpapa.online registered on Namecheap
- ✅ External IPs from your VMs

---

## Step 1: Get Your VM External IPs

On your **jenkins-server** VM, run:

```bash
cd ~/ansible-gcp-devops-project/ansible
cat inventory/hosts.ini
```

You should see output like:
```ini
[jenkins]
jenkins-vm ansible_host=34.142.147.236

[sonarqube]
sonarqube-vm ansible_host=34.21.213.214

[nexus]
nexus-vm ansible_host=34.21.132.214
```

**Write down these IPs:**
- Jenkins IP: `_________________`
- SonarQube IP: `_________________`
- Nexus IP: `_________________`

---

## Step 2: Login to Namecheap

1. Go to https://www.namecheap.com
2. Click **Sign In** (top right)
3. Enter your username and password
4. Click **Sign In**

---

## Step 3: Access Domain Management

1. After login, you'll see your **Dashboard**
2. On the left sidebar, click **Domain List**
3. Find **konpapa.online** in the list
4. Click the **MANAGE** button next to it

![Namecheap Dashboard](https://i.imgur.com/example.png)

---

## Step 4: Access Advanced DNS Settings

1. On the domain management page, click the **Advanced DNS** tab at the top
2. You'll see a section called **HOST RECORDS**

---

## Step 5: Add DNS A Records

Now you need to add 3 A records (one for each subdomain).

### 5.1 Add Jenkins Subdomain

1. Click **ADD NEW RECORD** button
2. Fill in the form:
   - **Type**: Select `A Record` from dropdown
   - **Host**: Enter `jenkins`
   - **Value**: Enter your Jenkins VM IP (e.g., `34.142.147.236`)
   - **TTL**: Select `Automatic` (or `300` for 5 minutes)
3. Click the **✓ (checkmark)** or **Save** button

### 5.2 Add SonarQube Subdomain

1. Click **ADD NEW RECORD** button again
2. Fill in the form:
   - **Type**: Select `A Record`
   - **Host**: Enter `sonarqube`
   - **Value**: Enter your SonarQube VM IP (e.g., `34.21.213.214`)
   - **TTL**: Select `Automatic`
3. Click the **✓ (checkmark)** button

### 5.3 Add Nexus Subdomain

1. Click **ADD NEW RECORD** button again
2. Fill in the form:
   - **Type**: Select `A Record`
   - **Host**: Enter `nexus`
   - **Value**: Enter your Nexus VM IP (e.g., `34.21.132.214`)
   - **TTL**: Select `Automatic`
3. Click the **✓ (checkmark)** button

---

## Step 6: Verify Your DNS Records

After adding all 3 records, your **HOST RECORDS** section should look like this:

| Type | Host | Value | TTL |
|------|------|-------|-----|
| A Record | jenkins | 34.142.147.236 | Automatic |
| A Record | sonarqube | 34.21.213.214 | Automatic |
| A Record | nexus | 34.21.132.214 | Automatic |

**Important Notes:**
- Replace the IPs above with YOUR actual VM IPs
- Make sure there are NO typos in the Host names
- Make sure you clicked the checkmark to save each record

---

## Step 7: Save All Changes

1. Scroll down to the bottom of the page
2. Click **SAVE ALL CHANGES** button (if present)
3. You should see a green success message

---

## Step 8: Wait for DNS Propagation

DNS changes can take time to propagate:
- **Minimum**: 5-10 minutes
- **Average**: 30 minutes to 1 hour
- **Maximum**: 24-48 hours (rare)

With Namecheap and TTL=Automatic, it usually takes **10-30 minutes**.

---

## Step 9: Test DNS Resolution

After waiting 10-15 minutes, test if DNS is working.

### 9.1 Test from Your Local Machine (Windows)

Open PowerShell and run:

```powershell
nslookup jenkins.konpapa.online
nslookup sonarqube.konpapa.online
nslookup nexus.konpapa.online
```

**Expected output:**
```
Server:  dns.google
Address:  8.8.8.8

Non-authoritative answer:
Name:    jenkins.konpapa.online
Address:  34.142.147.236
```

### 9.2 Test from Jenkins-Server VM (Linux)

SSH to jenkins-server and run:

```bash
dig jenkins.konpapa.online +short
dig sonarqube.konpapa.online +short
dig nexus.konpapa.online +short
```

**Expected output:**
```
34.142.147.236
34.21.213.214
34.21.132.214
```

### 9.3 Test with curl

```bash
curl -I http://jenkins.konpapa.online
curl -I http://sonarqube.konpapa.online
curl -I http://nexus.konpapa.online
```

If DNS is working, you should get a response (might be 404 or 502 if services aren't running yet - that's OK).

---

## Step 10: Verify DNS is Working

Once DNS resolves correctly, you can proceed to configure the services.

On **jenkins-server**, run:

```bash
cd ~/ansible-gcp-devops-project
ansible-playbook playbooks/03-configure-all.yaml
```

This will:
1. Install Docker on all VMs
2. Deploy Jenkins, SonarQube, Nexus via Docker Compose
3. Install and configure Nginx reverse proxy
4. Setup SSL certificates with Let's Encrypt

---

## Troubleshooting

### DNS Not Resolving After 30 Minutes

1. **Check Namecheap DNS Settings:**
   - Go back to Namecheap → Domain List → MANAGE → Advanced DNS
   - Verify all 3 A records are present and saved
   - Check there are no typos in Host or Value fields

2. **Check Nameservers:**
   - On the same page, look for **NAMESERVERS** section
   - Should be: **Namecheap BasicDNS** or **Namecheap PremiumDNS**
   - If it says "Custom DNS", you might need to change it back to Namecheap DNS

3. **Clear DNS Cache (Windows):**
   ```powershell
   ipconfig /flushdns
   ```

4. **Clear DNS Cache (Linux):**
   ```bash
   sudo systemd-resolve --flush-caches
   ```

5. **Use Google DNS for Testing:**
   ```bash
   nslookup jenkins.konpapa.online 8.8.8.8
   ```

### Still Not Working?

Check if your domain is using Namecheap nameservers:

```bash
nslookup -type=NS konpapa.online
```

**Expected output should include:**
```
dns1.registrar-servers.com
dns2.registrar-servers.com
```

If you see different nameservers (e.g., from another DNS provider), you need to change them back to Namecheap.

---

## Visual Reference

Here's what the Namecheap Advanced DNS page should look like:

```
┌─────────────────────────────────────────────────────────────┐
│ Advanced DNS                                                 │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│ HOST RECORDS                                   ADD NEW RECORD│
│                                                              │
│ ┌────────┬──────────┬──────────────────┬──────────┬────┐   │
│ │ Type   │ Host     │ Value            │ TTL      │    │   │
│ ├────────┼──────────┼──────────────────┼──────────┼────┤   │
│ │ A Rec. │ jenkins  │ 34.142.147.236   │ Auto     │ ✓  │   │
│ ├────────┼──────────┼──────────────────┼──────────┼────┤   │
│ │ A Rec. │ sonarqube│ 34.21.213.214    │ Auto     │ ✓  │   │
│ ├────────┼──────────┼──────────────────┼──────────┼────┤   │
│ │ A Rec. │ nexus    │ 34.21.132.214    │ Auto     │ ✓  │   │
│ └────────┴──────────┴──────────────────┴──────────┴────┘   │
│                                                              │
│                                        SAVE ALL CHANGES      │
└─────────────────────────────────────────────────────────────┘
```

---

## Summary

✅ **What You Did:**
1. Logged into Namecheap
2. Accessed konpapa.online → Advanced DNS
3. Added 3 A Records:
   - `jenkins` → Jenkins VM IP
   - `sonarqube` → SonarQube VM IP
   - `nexus` → Nexus VM IP
4. Waited for DNS propagation
5. Tested with nslookup/dig

✅ **Next Step:**
Run the configuration playbook to install services and setup SSL:

```bash
cd ~/ansible-gcp-devops-project
ansible-playbook playbooks/03-configure-all.yaml
```

---

## Quick Reference Commands

```bash
# Get VM IPs
cat ~/ansible-gcp-devops-project/ansible/inventory/hosts.ini

# Test DNS resolution
dig jenkins.konpapa.online +short
dig sonarqube.konpapa.online +short
dig nexus.konpapa.online +short

# Test HTTP connectivity
curl -I http://jenkins.konpapa.online
curl -I http://sonarqube.konpapa.online
curl -I http://nexus.konpapa.online

# Run configuration playbook
cd ~/ansible-gcp-devops-project
ansible-playbook playbooks/03-configure-all.yaml
```

---

**Need Help?** Check the main README.md or open an issue on GitHub.
