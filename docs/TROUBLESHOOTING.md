# Troubleshooting Guide

## Common Issues and Solutions

### Python Package Installation Issues (Ubuntu 24.04)

**Error:**
```
error: externally-managed-environment
× This environment is externally managed
```

**Cause:** Ubuntu 24.04 has stricter Python package management (PEP 668).

**Solutions:**

#### Option 1: Use System Packages (Recommended)
```bash
# Install Python packages via apt instead of pip
sudo apt-get install -y \
    python3-google-auth \
    python3-requests \
    python3-yaml \
    python3-jmespath \
    python3-netaddr
```

#### Option 2: Use pip with --break-system-packages (Quick Fix)
```bash
pip3 install --user --break-system-packages google-auth requests pyyaml jmespath netaddr
```

#### Option 3: Use pipx for Isolated Installations
```bash
# Install pipx
sudo apt install pipx -y
pipx ensurepath

# Install packages
pipx install google-auth
```

#### Option 4: Use Virtual Environment (Best Practice for Development)
```bash
# Create venv
python3 -m venv ~/ansible-venv
source ~/ansible-venv/bin/activate

# Install packages
pip install google-auth requests pyyaml jmespath netaddr ansible

# Use this venv for all Ansible commands
```

**Fixed Bootstrap Script:**

The updated `bootstrap-controller.sh` now tries apt first, then falls back to pip if needed.

---

### GCP Authentication Issues

**Error:**
```
No active GCP account found
```

**Solution:**
```bash
# Login to GCP
gcloud auth login

# Set application default credentials (required for Ansible)
gcloud auth application-default login

# Set project
gcloud config set project my-project-devops-504714

# Verify
gcloud auth list
```

---

### SSH Connection Refused

**Error:**
```
ssh: connect to host <ip> port 22: Connection refused
```

**Solutions:**

1. **Wait for VM to fully boot:**
```bash
# Wait 30-60 seconds after VM creation
sleep 60
just ping-all
```

2. **Check firewall rules:**
```bash
just check-firewall

# Create SSH rule if missing
gcloud compute firewall-rules create allow-ssh \
  --allow tcp:22 \
  --source-ranges 0.0.0.0/0 \
  --target-tags ssh-allowed
```

3. **Verify SSH keys are in GCP metadata:**
```bash
gcloud compute instances describe jenkins-vm \
  --zone=asia-southeast1-c \
  --format="get(metadata.items[key=ssh-keys].value)"
```

---

### Ansible Playbook Syntax Errors

**Error:**
```
ERROR! Syntax Error while loading YAML
```

**Solution:**
```bash
# Validate syntax
cd ansible
ansible-playbook playbooks/01-create-infrastructure.yaml --syntax-check

# Check YAML formatting
python3 -c "import yaml; yaml.safe_load(open('playbooks/01-create-infrastructure.yaml'))"
```

---

### Docker Container Won't Start

**Error:**
```
Container exited with code 1
```

**Solutions:**

1. **Check logs:**
```bash
# SSH into the VM
just ssh-jenkins

# View logs
docker logs jenkins --tail 100
docker logs jenkins -f  # Follow logs
```

2. **Check disk space:**
```bash
df -h
docker system df
```

3. **Check memory:**
```bash
free -h
docker stats --no-stream
```

4. **Restart container:**
```bash
cd ~/jenkins
docker compose restart
```

5. **Recreate container:**
```bash
cd ~/jenkins
docker compose down
docker compose up -d
```

---

### SSL Certificate Fails to Obtain

**Error:**
```
Failed authorization procedure. DNS problem: NXDOMAIN
```

**Solutions:**

1. **Verify DNS is propagated:**
```bash
nslookup jenkins.konpapa.online
dig jenkins.konpapa.online +short

# Wait 15-30 minutes after DNS changes
```

2. **Test HTTP first:**
```bash
curl -I http://jenkins.konpapa.online
# Should return 200 or 301
```

3. **Check Nginx is running:**
```bash
sudo systemctl status nginx
sudo nginx -t
```

4. **Manual certificate request:**
```bash
# SSH into VM
sudo certbot --nginx -d jenkins.konpapa.online \
  --non-interactive --agree-tos -m admin@konpapa.online
```

5. **Check Let's Encrypt rate limits:**
- Limit: 5 certificates per domain per week
- Wait if you hit the limit

---

### Nexus Initial Password Not Found

**Error:**
```
File not found: /nexus-data/admin.password
```

**Cause:** Nexus is still initializing (takes 2-3 minutes).

**Solution:**
```bash
# Wait for Nexus to fully start
sleep 120

# Check Nexus logs
docker logs nexus -f

# Look for: "Started Sonatype Nexus"

# Try again
cat ~/nexus/data/admin.password
```

---

### SonarQube Won't Start - vm.max_map_count Too Low

**Error:**
```
max virtual memory areas vm.max_map_count [65530] is too low
```

**Solution:**
```bash
# Set temporarily
sudo sysctl -w vm.max_map_count=262144

# Set permanently
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

---

### Playbook Hangs on "Gathering Facts"

**Cause:** SSH connectivity issues or slow DNS.

**Solutions:**

1. **Disable SSH host key checking:**
```bash
# Already set in ansible.cfg, but verify:
export ANSIBLE_HOST_KEY_CHECKING=False
```

2. **Use IP addresses instead of hostnames:**
```bash
# Edit inventory to use IPs directly
vim ansible/inventory/hosts.ini
```

3. **Increase timeout:**
```bash
# Edit ansible.cfg
[defaults]
timeout = 30
```

---

### Just Command Not Found

**Error:**
```
just: command not found
```

**Solution:**
```bash
# Install just
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | \
  bash -s -- --to ~/.local/bin

# Add to PATH
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify
just --version
```

---

### Ansible Collection Not Found

**Error:**
```
ERROR! couldn't resolve module/action 'google.cloud.gcp_compute_instance'
```

**Solution:**
```bash
# Install Google Cloud collection
ansible-galaxy collection install google.cloud

# Install Docker collection
ansible-galaxy collection install community.docker

# Verify
ansible-galaxy collection list
```

---

### Out of Disk Space

**Error:**
```
No space left on device
```

**Solutions:**

1. **Check disk usage:**
```bash
df -h
du -sh /*
```

2. **Clean Docker:**
```bash
docker system prune -a -f
docker volume prune -f
```

3. **Clean apt cache:**
```bash
sudo apt clean
sudo apt autoremove
```

4. **Increase disk size:**
```bash
# Edit config.yaml
disk_size: 100  # Increase from 50

# Recreate infrastructure
just destroy-infrastructure
just create-infrastructure
```

---

### Services Unreachable After Reboot

**Cause:** Systemd services not enabled or Docker containers not set to restart.

**Solution:**

Services should auto-start (systemd + restart:always), but if not:

```bash
# SSH into VM
just ssh-jenkins

# Start services manually
cd ~/jenkins
docker compose up -d

# Enable systemd service
sudo systemctl enable jenkins-docker
sudo systemctl start jenkins-docker
```

---

### DNS Records Not Propagating

**Cause:** DNS TTL, nameserver caching.

**Solutions:**

1. **Use different DNS servers:**
```bash
# Google DNS
nslookup jenkins.konpapa.online 8.8.8.8

# Cloudflare DNS
nslookup jenkins.konpapa.online 1.1.1.1
```

2. **Clear local DNS cache:**
```bash
# Windows
ipconfig /flushdns

# Linux/Mac
sudo systemd-resolve --flush-caches
```

3. **Lower TTL:**
- In Namecheap, set TTL to 300 seconds (5 minutes)
- Wait for old TTL to expire before checking

4. **Use direct IP temporarily:**
```bash
# Edit /etc/hosts
34.101.123.45 jenkins.konpapa.online
```

---

### Cost Concerns - Bills Too High

**Solutions:**

1. **Stop VMs when not using:**
```bash
gcloud compute instances stop jenkins-vm sonarqube-vm nexus-vm \
  --zone=asia-southeast1-c
```

2. **Use smaller machine types:**
```yaml
# Edit config.yaml
machine_type: "e2-small"  # Instead of e2-medium
```

3. **Use sustained use discounts:**
- VMs running >25% of month get automatic discounts

4. **Set up budget alerts:**
```bash
# In GCP Console: Billing → Budgets & alerts
# Set alert at $50, $100, $150
```

5. **Destroy when done learning:**
```bash
just destroy-infrastructure
```

---

### Nginx Configuration Test Fails

**Error:**
```
nginx: [emerg] invalid parameter
```

**Solution:**
```bash
# Test Nginx config
sudo nginx -t

# View detailed error
sudo nginx -t 2>&1

# Check syntax of specific file
sudo nginx -T | grep -A 20 jenkins.conf

# Reload after fixing
sudo systemctl reload nginx
```

---

### Docker Compose Version Issues

**Error:**
```
version is obsolete
```

**Solution:**

Modern Docker Compose doesn't need version in docker-compose.yml:

```yaml
# Old (don't use)
version: '3.8'

# New (already in templates)
# Just remove the version line
```

---

## Quick Diagnostic Commands

### Check Everything
```bash
# From controller VM
just check-services      # All Docker containers
just check-resources     # CPU, memory, disk
just show-inventory      # All VMs and IPs
just test-connectivity   # HTTP/HTTPS access
```

### Get Logs
```bash
just view-logs jenkins
just view-logs sonarqube
just view-logs nexus
```

### Restart Services
```bash
just restart-jenkins
just restart-sonarqube
just restart-nexus
```

---

## Still Having Issues?

1. **Enable verbose Ansible output:**
```bash
cd ansible
ansible-playbook playbooks/03-configure-all.yaml -vvv
```

2. **Check GCP Console:**
- Verify VMs are running
- Check firewall rules
- Review VPC network settings

3. **Run validation script:**
```bash
./scripts/validate-project.sh
```

4. **Manual SSH debug:**
```bash
ssh -vvv -i ~/.ssh/id_ed25519 samnangchanserey@<vm-ip>
```

5. **Start fresh:**
```bash
just destroy-infrastructure
just deploy-all
```

---

**If all else fails, destroy and recreate - that's the beauty of Infrastructure as Code! 🚀**
