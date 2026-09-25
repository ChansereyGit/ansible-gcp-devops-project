# Deployment Guide

## Quick Reference

This guide provides step-by-step instructions for deploying the complete infrastructure.

---

## Prerequisites Checklist

Before starting, ensure you have:

- [ ] GCP account with billing enabled
- [ ] GCP Project created (`my-project-devops-504714`)
- [ ] Domain name available (`konpapa.online`)
- [ ] Access to DNS management (Namecheap)
- [ ] gcloud CLI installed and authenticated
- [ ] Ansible installed (on controller VM)
- [ ] Just command runner installed
- [ ] SSH keys generated (`~/.ssh/id_ed25519`)

---

## Phase 1: Initial Setup (One-Time)

### 1.1 Authenticate to GCP

```bash
# Login to GCP
gcloud auth login

# Set application default credentials (for Ansible)
gcloud auth application-default login

# Set your project
gcloud config set project my-project-devops-504714

# Verify authentication
gcloud auth list
```

### 1.2 Enable Required APIs

```bash
# Enable Compute Engine API
gcloud services enable compute.googleapis.com

# Enable Cloud Resource Manager API
gcloud services enable cloudresourcemanager.googleapis.com
```

### 1.3 Create Firewall Rules (if not exist)

```bash
# Allow SSH
gcloud compute firewall-rules create allow-ssh \
  --allow tcp:22 \
  --source-ranges 0.0.0.0/0 \
  --target-tags ssh-allowed

# Allow HTTP
gcloud compute firewall-rules create allow-http \
  --allow tcp:80 \
  --source-ranges 0.0.0.0/0 \
  --target-tags http-server

# Allow HTTPS
gcloud compute firewall-rules create allow-https \
  --allow tcp:443 \
  --source-ranges 0.0.0.0/0 \
  --target-tags https-server
```

---

## Phase 2: Create Infrastructure

### 2.1 Review Configuration

```bash
# Edit configuration if needed
vim ansible/vars/config.yaml

# Verify settings:
# - google_project_id
# - google_zone
# - ssh_username
# - base_domain
# - VM specifications
```

### 2.2 Create VMs

```bash
# Create all 4 VMs
just create-infrastructure

# Expected output:
# - jenkins-vm created
# - sonarqube-vm created
# - nexus-vm created
# - Dynamic inventory generated at ansible/inventory/hosts.ini
```

**Duration:** ~3-5 minutes

### 2.3 Note the IP Addresses

```bash
# Display all VMs and their IPs
just show-inventory

# Or
just list-gcp-instances
```

Example output:
```
jenkins-vm: 34.101.123.45
jenkins-vm: 34.101.123.45
sonarqube-vm: 34.101.123.46
nexus-vm: 34.101.123.47
```

---

## Phase 3: Configure DNS

**📖 Detailed Guide:** See [NAMECHEAP_DNS_SETUP.md](./NAMECHEAP_DNS_SETUP.md) for step-by-step instructions with screenshots.

**⚠️ IMPORTANT:** SSL setup requires DNS to be working first! This is why configuration is split into two phases:

### Why SSL is Separate from configure-all?

**Reason 1: DNS Propagation Required**
- Let's Encrypt validates domain ownership by checking DNS
- DNS propagation takes 10-30 minutes after adding records
- If you run SSL setup before DNS is ready, it will fail
- Separating the steps ensures DNS is propagated first

**Reason 2: Let's Encrypt Rate Limits**
- Let's Encrypt has strict rate limits (5 failed attempts per hour)
- If SSL setup fails, you need to wait 1 hour before retry
- Splitting allows you to verify DNS is working before attempting SSL

**Reason 3: Flexibility**
- You might want to test services on HTTP first
- You might want to use Cloudflare SSL instead of Let's Encrypt
- You might want to skip HTTPS for development/testing

**Workflow:**
```
1. Configure services → Test on HTTP → Verify working
2. Configure DNS → Wait for propagation → Verify DNS
3. Setup SSL → Test on HTTPS → Production ready
```

**Note:** In the current playbook, `03-configure-all.yaml` already includes the `certbot` role, so SSL setup happens automatically if DNS is ready. The separate `just setup-ssl` command is provided as a convenience if you need to retry SSL setup later.

### 3.1 Get Your VM IPs

```bash
# Display all VMs and their IPs
cd ~/ansible-gcp-devops-project/ansible
cat inventory/hosts.ini
```

Note down the external IPs for each VM.

### 3.2 Add DNS A Records on Namecheap

1. Login to https://www.namecheap.com
2. Go to **Domain List** → Find **konpapa.online** → Click **MANAGE**
3. Click **Advanced DNS** tab
4. Add 3 A Records:

| Type | Host | Value | TTL |
|------|------|-------|-----|
| A | jenkins | `<jenkins-vm-ip>` | Automatic |
| A | sonarqube | `<sonarqube-vm-ip>` | Automatic |
| A | nexus | `<nexus-vm-ip>` | Automatic |

5. Click **SAVE ALL CHANGES**

**Example:**
```
A Record | jenkins    | 34.142.147.236 | Automatic
A Record | sonarqube  | 34.21.213.214  | Automatic
A Record | nexus      | 34.21.132.214  | Automatic
```

### 3.3 Wait for DNS Propagation

DNS changes take **10-30 minutes** to propagate. Wait before proceeding.

### 3.4 Verify DNS Propagation

```bash
# Test DNS resolution
dig jenkins.konpapa.online +short
dig sonarqube.konpapa.online +short
dig nexus.konpapa.online +short

# Or use nslookup
nslookup jenkins.konpapa.online
nslookup sonarqube.konpapa.online
nslookup nexus.konpapa.online
```

**Expected:** Each command should return the correct IP address.

**If DNS not working after 30 min:** Check [NAMECHEAP_DNS_SETUP.md](./NAMECHEAP_DNS_SETUP.md) troubleshooting section.

---

## Phase 4: Test Connectivity

### 4.1 Test SSH Access

```bash
# Test all hosts
just ping-all

# Test individual hosts
just ping-jenkins
just ping-sonarqube
just ping-nexus
```

**Expected output:**
```
jenkins-vm | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

### 4.2 Troubleshooting Connectivity

If ping fails:

```bash
# Check SSH keys are correct
cat ~/.ssh/id_ed25519.pub

# Verify keys in GCP metadata
gcloud compute instances describe jenkins-vm \
  --zone=asia-southeast1-c \
  --format="get(metadata.items[key=ssh-keys].value)"

# Try manual SSH
ssh -i ~/.ssh/id_ed25519 samnangchanserey@<jenkins-ip>
```

---

## Phase 5: Configure Services

### 5.1 Run Configuration Playbook

```bash
# Configure all VMs and services
just configure-all
```

**Duration:** ~10-15 minutes

**What this does:**
1. Updates system packages
2. Installs Docker and Docker Compose
3. Deploys Jenkins (port 8080)
4. Deploys SonarQube + PostgreSQL (port 9000)
5. Deploys Nexus (ports 8081, 5000)
6. Configures Nginx reverse proxy
7. Sets up systemd services for auto-start

### 5.2 Monitor Progress

```bash
# Check service status
just check-services

# View specific logs
just view-logs jenkins
just view-logs sonarqube
just view-logs nexus
```

### 5.3 Get Initial Passwords

```bash
# Get Jenkins password
just get-jenkins-password

# Get Nexus password
just get-nexus-password
```

**Save these passwords!** You'll need them for initial setup.

---

## Phase 6: Setup HTTPS

### 6.1 Verify DNS is Propagated

```bash
# Test HTTP access first
curl -I http://jenkins.konpapa.online
curl -I http://sonarqube.konpapa.online
curl -I http://nexus.konpapa.online

# Should return 200 OK or redirect
```

### 6.2 Obtain SSL Certificates

```bash
# Setup SSL for all services
just setup-ssl
```

**Duration:** ~2-3 minutes

**What this does:**
1. Installs Certbot on each VM
2. Obtains Let's Encrypt certificates
3. Updates Nginx configs for HTTPS
4. Sets up auto-renewal cron job

### 6.3 Verify HTTPS

```bash
# Test HTTPS access
curl -I https://jenkins.konpapa.online
curl -I https://sonarqube.konpapa.online
curl -I https://nexus.konpapa.online

# Should return 200 OK
```

---

## Phase 7: Access and Configure Services

### 7.1 Jenkins

**URL:** https://jenkins.konpapa.online

1. Open URL in browser
2. Enter initial admin password (from `just get-jenkins-password`)
3. Select "Install suggested plugins"
4. Create first admin user
5. Complete setup wizard

**Recommended plugins:**
- Docker Pipeline
- SonarQube Scanner
- Nexus Artifact Uploader
- GitHub

### 7.2 SonarQube

**URL:** https://sonarqube.konpapa.online

1. Login with default credentials:
   - Username: `admin`
   - Password: `admin`
2. Change password when prompted
3. Create a project
4. Generate authentication token
5. Note token for Jenkins integration

### 7.3 Nexus

**URL:** https://nexus.konpapa.online

1. Login with admin credentials (from `just get-nexus-password`)
2. Complete setup wizard
3. Change admin password
4. Configure anonymous access (optional)
5. Create repositories:
   - Docker (hosted) on port 5000
   - Maven releases
   - Maven snapshots
   - npm hosted

---

## Phase 8: Integration

### 8.1 Configure Jenkins → SonarQube

1. In Jenkins: Manage Jenkins → Configure System
2. Add SonarQube server:
   - Name: `SonarQube`
   - Server URL: `https://sonarqube.konpapa.online`
   - Server authentication token: (from SonarQube)

### 8.2 Configure Jenkins → Nexus

1. In Jenkins: Manage Jenkins → Configure System
2. Add Nexus credentials
3. Install "Nexus Artifact Uploader" plugin
4. Configure Nexus URL in pipelines

---

## Phase 9: Verification

### 9.1 Service Health Check

```bash
# Check all Docker containers
just check-services

# Should show all services running
```

### 9.2 Test Pipeline (Optional)

Create a test Jenkins pipeline:

```groovy
pipeline {
    agent any
    stages {
        stage('Test') {
            steps {
                echo 'Hello from Jenkins!'
            }
        }
    }
}
```

---

## Phase 10: Backup and Maintenance

### 10.1 Initial Backup

```bash
# Backup all service data
just backup-all
```

### 10.2 Schedule Regular Maintenance

Add to crontab on jenkins-server (your controller VM):

```bash
# Weekly backup at 2 AM Sunday
0 2 * * 0 cd /path/to/project && just backup-all

# Monthly system updates
0 3 1 * * cd /path/to/project && just update-systems
```

---

## Common Issues and Solutions

### Issue: VMs created but can't SSH

**Solution:**
```bash
# Wait 30 seconds for VM initialization
sleep 30

# Retry ping
just ping-all

# Check GCP firewall
just check-firewall
```

### Issue: Docker container fails to start

**Solution:**
```bash
# SSH into the VM
just ssh-jenkins

# Check Docker logs
docker logs jenkins -f

# Restart service
cd ~/jenkins
docker compose restart
```

### Issue: SSL certificate fails

**Solution:**
```bash
# Verify DNS is fully propagated
nslookup jenkins.konpapa.online

# Wait 15 minutes after DNS changes
# Then retry
just setup-ssl
```

### Issue: Out of disk space

**Solution:**
```bash
# Check disk usage
just check-resources

# Clean up Docker
ssh user@vm "docker system prune -a"

# Or upgrade disk size in config.yaml and recreate
```

---

## Cleanup and Destroy

### Complete Destruction

```bash
# Destroy all infrastructure
just destroy-infrastructure

# Confirm by typing 'yes'
# This will:
# - Delete all 4 VMs
# - Delete all disks
# - Remove inventory file
```

**Note:** This does NOT:
- Delete firewall rules
- Remove DNS records
- Delete GCP project

Manual cleanup of these is recommended if no longer needed.

---

## Next Steps

After successful deployment:

1. **Configure CI/CD pipelines** in Jenkins
2. **Setup SonarQube quality gates**
3. **Configure Nexus repositories** for your projects
4. **Integrate with GitHub/GitLab**
5. **Setup monitoring** (Prometheus/Grafana)
6. **Configure backup automation**
7. **Document custom configurations**

---

## Quick Command Reference

| Action | Command |
|--------|---------|
| Create infrastructure | `just create-infrastructure` |
| Configure services | `just configure-all` |
| Complete deployment | `just deploy-all` |
| Setup SSL | `just setup-ssl` |
| Check services | `just check-services` |
| Get Jenkins password | `just get-jenkins-password` |
| Get Nexus password | `just get-nexus-password` |
| Show service URLs | `just show-urls` |
| Backup all | `just backup-all` |
| Destroy everything | `just destroy-infrastructure` |

---

## Estimated Timeline

| Phase | Duration | Can Parallelize |
|-------|----------|-----------------|
| Initial Setup | 10 min | No |
| Create Infrastructure | 5 min | No |
| DNS Configuration | 15 min (propagation) | Yes (configure while waiting) |
| Configure Services | 15 min | No |
| Setup HTTPS | 3 min | No |
| Service Configuration | 20 min | Yes (all three services) |
| **Total** | **~68 minutes** | **~45 minutes with parallelization** |

---

**Happy Deploying! 🚀**
