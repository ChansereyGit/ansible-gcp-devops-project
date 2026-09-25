# DevOps Infrastructure Automation Project
## Presentation Script & Demo Guide

---

## 📋 Project Overview

**Title:** Automated DevOps Infrastructure on GCP using Ansible

**Objective:** Create a fully automated, production-ready DevOps infrastructure that deploys Jenkins, SonarQube, and Nexus on Google Cloud Platform with HTTPS, using Infrastructure as Code principles.

**Technologies Used:**
- **Cloud Platform:** Google Cloud Platform (GCP)
- **Infrastructure as Code:** Ansible
- **Containerization:** Docker & Docker Compose
- **CI/CD:** Jenkins
- **Code Quality:** SonarQube
- **Artifact Repository:** Nexus Repository Manager
- **Web Server:** Nginx (reverse proxy)
- **SSL:** Let's Encrypt / Cloudflare
- **DNS:** Namecheap
- **Automation:** Justfile (command runner)

---

## 🎯 Project Goals

1. **Full Automation:** One command creates entire infrastructure
2. **Reproducibility:** Destroy and recreate anytime
3. **Production-Ready:** HTTPS, security, monitoring
4. **Best Practices:** IaC, idempotency, modularity
5. **Cloud-Native:** Leverages GCP features

---

## 🏗️ Architecture Overview

### High-Level Architecture

```
                        Internet
                           |
                    [Cloudflare CDN]
                           |
                    DNS: konpapa.online
                           |
        ┌──────────────────┼──────────────────┐
        |                  |                  |
jenkins.konpapa     sonarqube.konpapa    nexus.konpapa
    .online              .online           .online
        |                  |                  |
        ▼                  ▼                  ▼
┌───────────────┐  ┌───────────────┐  ┌───────────────┐
│  jenkins-vm   │  │ sonarqube-vm  │  │   nexus-vm    │
│  34.x.x.x     │  │  34.x.x.x     │  │  34.x.x.x     │
│               │  │               │  │               │
│ Nginx:443 ────┼─►│ Nginx:443 ────┼─►│ Nginx:443 ────┤
│     ↓         │  │     ↓         │  │     ↓         │
│ Jenkins:8080  │  │ SonarQube:9000│  │ Nexus:8081    │
│               │  │ PostgreSQL:5432│  │ Docker:5000   │
│ Docker        │  │ Docker        │  │ Docker        │
└───────────────┘  └───────────────┘  └───────────────┘
```

### Infrastructure Components

| Component | VM | Machine Type | vCPU | RAM | Disk | Purpose |
|-----------|-----|--------------|------|-----|------|---------|
| **Jenkins** | jenkins-vm | e2-standard-2 | 2 | 8GB | 50GB | CI/CD Pipeline |
| **SonarQube** | sonarqube-vm | e2-medium | 2 | 4GB | 50GB | Code Quality Analysis |
| **Nexus** | nexus-vm | e2-medium | 2 | 4GB | 50GB | Artifact Repository |

**Total Resources:** 6 vCPUs, 16GB RAM, 150GB disk

---

## 📁 Project Structure

```
ansible-gcp-devops-project/
├── ansible/
│   ├── inventory/
│   │   ├── bootstrap.ini         # Initial controller inventory
│   │   └── hosts.ini             # Generated dynamic inventory
│   ├── playbooks/
│   │   ├── 01-create-infrastructure.yaml    # Create GCP VMs
│   │   ├── 02-destroy-infrastructure.yaml   # Delete all VMs
│   │   └── 03-configure-all.yaml            # Configure services
│   ├── roles/
│   │   ├── common/               # Base system config
│   │   ├── docker/               # Docker installation
│   │   ├── jenkins/              # Jenkins deployment
│   │   ├── sonarqube/            # SonarQube deployment
│   │   ├── nexus/                # Nexus deployment
│   │   ├── nginx/                # Nginx reverse proxy
│   │   └── certbot/              # SSL certificates
│   ├── templates/
│   │   ├── inventory-template.j2 # Dynamic inventory generator
│   │   └── docker-compose.yml.j2 # Service configurations
│   ├── vars/
│   │   └── config.yaml           # Global configuration
│   └── ansible.cfg               # Ansible settings
├── docs/
│   ├── DEPLOYMENT_GUIDE.md       # Complete deployment guide
│   ├── NAMECHEAP_DNS_SETUP.md    # DNS configuration
│   ├── CLOUDFLARE_SETUP.md       # Cloudflare integration
│   └── TROUBLESHOOTING.md        # Common issues
├── scripts/
│   └── bootstrap-controller.sh   # Controller VM setup
├── Justfile                      # Command automation
└── README.md                     # Project documentation
```

---

## 🚀 Demo Script

### Part 1: Introduction (2 minutes)

**"Hello everyone! Today I'll demonstrate an automated DevOps infrastructure deployment on Google Cloud Platform using Ansible."**

**Show slides or explain:**
- Problem: Manual infrastructure setup is time-consuming, error-prone
- Solution: Infrastructure as Code with full automation
- Benefits: Reproducibility, consistency, speed

### Part 2: Architecture Overview (3 minutes)

**"Let me show you the architecture we'll be deploying."**

**Open:** `README.md` or architecture diagram

**Explain:**
1. **Three VMs** running on GCP
2. **Each VM** has Docker, Nginx, and a specific service
3. **Jenkins** for CI/CD pipelines
4. **SonarQube** for code quality analysis with PostgreSQL database
5. **Nexus** for artifact management (Maven, Docker, npm)
6. **HTTPS** via Nginx reverse proxy with SSL certificates
7. **DNS** pointing to each service

**"The entire infrastructure is defined as code using Ansible, making it fully reproducible."**

### Part 3: Configuration Overview (2 minutes)

**"All configuration is centralized in one file."**

**Show:** `ansible/vars/config.yaml`

```bash
cat ansible/vars/config.yaml
```

**Highlight:**
- GCP project ID and zone
- SSH configuration
- Domain names (jenkins.konpapa.online, etc.)
- Machine specifications
- Service ports
- All customizable!

**"This makes it easy to deploy to different environments - just change this config file!"**

### Part 4: Pre-Deployment Check (1 minute)

**"Before deploying, let's verify we're authenticated to GCP."**

```bash
# Check GCP authentication
gcloud auth list

# Check current project
gcloud config get-value project

# Verify no VMs exist yet
gcloud compute instances list
```

**Expected:** Empty list or existing VMs

### Part 5: Infrastructure Creation (5 minutes)

**"Now, let's create the entire infrastructure with ONE command!"**

```bash
cd ~/ansible-gcp-devops-project
just create-infrastructure
```

**While running, explain what's happening:**

1. **Authentication Check** - Verifies GCP credentials
2. **Reading SSH Key** - Injects public key into VM metadata
3. **Creating VMs** (takes ~2-3 minutes)
   - jenkins-vm (e2-standard-2)
   - sonarqube-vm (e2-medium)
   - nexus-vm (e2-medium)
4. **Startup Scripts** - Each VM runs initialization:
   - Updates system packages
   - Sets timezone to Asia/Bangkok
   - Disables swap (required for SonarQube)
   - Increases vm.max_map_count for Elasticsearch
5. **Dynamic Inventory Generation** - Creates `inventory/hosts.ini`
6. **SSH Readiness Check** - Waits for all VMs to accept connections

**Show output:**
```
✓ VMs Created Successfully!

jenkins-vm:
  - External IP: 34.142.147.236
  - Machine Type: e2-standard-2
  - Zone: asia-southeast1-c
...
```

**Verify in GCP Console:**
```bash
gcloud compute instances list
```

**Show:** Three VMs running with external IPs

### Part 6: Connectivity Testing (1 minute)

**"Let's verify we can connect to all VMs via SSH."**

```bash
just ping-all
```

**Expected output:**
```
jenkins-vm | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
sonarqube-vm | SUCCESS => { ... }
nexus-vm | SUCCESS => { ... }
```

**"All VMs are reachable! Now we can configure them."**

### Part 7: DNS Configuration (2 minutes)

**"Before configuring services, we need to set up DNS records."**

**Show:** Namecheap dashboard (prepared screenshot)

**Explain:**
- Added 3 A records in Namecheap DNS
- jenkins.konpapa.online → Jenkins VM IP
- sonarqube.konpapa.online → SonarQube VM IP
- nexus.konpapa.online → Nexus VM IP
- Disabled Cloudflare proxy (gray cloud) for Let's Encrypt

**Verify DNS:**
```bash
dig jenkins.konpapa.online +short
dig sonarqube.konpapa.online +short
dig nexus.konpapa.online +short
```

**Expected:** Shows actual VM IPs (34.x.x.x)

### Part 8: Service Configuration (10 minutes)

**"Now for the magic - deploying all services with ONE command!"**

```bash
just configure-all
```

**While running, explain each phase:**

#### Phase 1: Common Configuration (all VMs)
- Updates apt cache and upgrades packages
- Installs common tools (curl, wget, git, vim, htop)
- Installs Python packages for Ansible
- Configures system limits (file descriptors, processes)
- Sets sysctl parameters (vm.max_map_count)
- Disables swap permanently

#### Phase 2: Docker Installation (all VMs)
- Removes old Docker versions
- Installs Docker prerequisites
- Adds Docker GPG key and repository
- Installs Docker Engine and CLI
- Installs Docker Compose V2
- Adds user to docker group
- Starts and enables Docker service
- Creates Docker network for applications

#### Phase 3: Jenkins Deployment
- Creates Jenkins directories
- Deploys docker-compose.yml:
  ```yaml
  services:
    jenkins:
      image: jenkins/jenkins:lts
      ports: 8080:8080, 50000:50000
      volumes: jenkins_home
  ```
- Waits for Jenkins to start
- Reads initial admin password
- Creates systemd service for auto-start

#### Phase 4: SonarQube Deployment
- Creates SonarQube directories
- Deploys docker-compose.yml:
  ```yaml
  services:
    sonarqube:
      image: sonarqube:community
      depends_on: postgres
      ports: 9000:9000
    postgres:
      image: postgres:16
      volumes: postgres_data
  ```
- Waits for SonarQube to be ready
- Verifies health check
- Creates systemd service

#### Phase 5: Nexus Deployment
- Creates Nexus directories with correct permissions (UID 200)
- Deploys docker-compose.yml:
  ```yaml
  services:
    nexus:
      image: sonatype/nexus3
      ports: 8081:8081, 5000:5000
      volumes: nexus_data
  ```
- Waits for Nexus initialization (~60 seconds)
- Reads initial admin password
- Creates systemd service

#### Phase 6: Nginx Configuration (all VMs)
- Installs Nginx
- Configures reverse proxy for each service:
  - HTTP → redirects to HTTPS
  - HTTPS → proxies to Docker container
- Enables sites
- Tests and reloads Nginx

**Total Duration:** ~5-8 minutes

**Show output at the end:**
```
✓ Configuration Complete!

Jenkins:    https://jenkins.konpapa.online
SonarQube:  https://sonarqube.konpapa.online
Nexus:      https://nexus.konpapa.online

Default Credentials:
- Jenkins: [initial password shown]
- SonarQube: admin / admin
- Nexus: [initial password shown]
```

### Part 9: SSL Certificate Setup (3 minutes)

**"The services are running on HTTP. Let's add HTTPS with Let's Encrypt!"**

```bash
just setup-ssl
```

**Note:** If certbot role has tags configured, this will:
- Install Certbot on all VMs
- Request certificates from Let's Encrypt
- Update Nginx configs for HTTPS
- Set up auto-renewal cron job

**Alternative (manual demo):**
```bash
# Show that HTTPS is already configured
curl -I https://jenkins.konpapa.online
curl -I https://sonarqube.konpapa.online
curl -I https://nexus.konpapa.online
```

**Explain:**
- SSL certificates secure communication
- Let's Encrypt provides free certificates
- Auto-renewal every 90 days
- Nginx handles SSL termination

### Part 10: Service Demonstration (5 minutes)

**"Let's access each service and verify they're working!"**

#### Jenkins
```bash
# Get Jenkins password
just get-jenkins-password
```

**Open browser:** https://jenkins.konpapa.online

**Show:**
1. Login page with initial password
2. Plugin installation screen
3. Dashboard (if time permits)

**Explain Jenkins features:**
- Build automation
- Pipeline as Code
- Plugin ecosystem
- Integration with Git, Docker, SonarQube

#### SonarQube

**Open browser:** https://sonarqube.konpapa.online

**Show:**
1. Login page (admin/admin)
2. Change password prompt
3. Dashboard

**Explain SonarQube features:**
- Static code analysis
- Code quality metrics
- Security vulnerabilities
- Technical debt tracking

#### Nexus

```bash
# Get Nexus password
just get-nexus-password
```

**Open browser:** https://nexus.konpapa.online

**Show:**
1. Login page
2. Repository browser
3. Available repository types

**Explain Nexus features:**
- Artifact repository manager
- Supports Maven, Docker, npm, Python, etc.
- Caching proxy for external repositories
- Version management

### Part 11: Useful Commands (2 minutes)

**"The Justfile provides many helpful commands for management."**

```bash
# Show all available commands
just --list
```

**Demonstrate a few:**

```bash
# Check all services status
just check-services

# View logs
just view-logs jenkins

# Check system resources
just check-resources

# Show all URLs
just show-urls
```

**"These commands make it easy to manage the infrastructure without remembering complex Ansible syntax."**

### Part 12: Verification & Testing (3 minutes)

**"Let's verify everything is working properly."**

#### Test Docker Containers
```bash
# SSH to jenkins-vm
just ssh-jenkins

# Check containers
docker ps

# Check Docker network
docker network ls

# Exit
exit
```

#### Test Nginx Configuration
```bash
# Test from anywhere
curl -I https://jenkins.konpapa.online
curl -I https://sonarqube.konpapa.online
curl -I https://nexus.konpapa.online
```

**Expected:** HTTP 200 or 403 responses (service is working)

#### Test Service Integration
**Open Jenkins → Manage Jenkins → System**
- Show ability to configure SonarQube server
- Show ability to configure Nexus credentials

### Part 13: Infrastructure Cleanup (2 minutes)

**"When we're done, we can destroy everything with ONE command!"**

```bash
just destroy-infrastructure
```

**This prompts for confirmation:**
```
⚠️  WARNING: You are about to DESTROY all infrastructure!
This will permanently delete:
- jenkins-vm
- sonarqube-vm
- nexus-vm

Type 'yes' to confirm destruction
```

**Type:** `yes`

**While running, explain:**
- Deletes all GCP VMs
- Removes generated inventory file
- Cleans up local state files
- Infrastructure is completely gone

**Verify:**
```bash
gcloud compute instances list
```

**"And just like that, everything is cleaned up! No manual cleanup needed."**

---

## 💡 Key Talking Points

### Benefits Demonstrated

1. **Speed**
   - Manual setup: 2-3 hours
   - Automated: 10-15 minutes
   - **80-90% time savings**

2. **Consistency**
   - Every deployment identical
   - No human error
   - Documented in code

3. **Reproducibility**
   - Destroy and recreate anytime
   - Multiple environments (dev, staging, prod)
   - Disaster recovery

4. **Scalability**
   - Easy to add more VMs
   - Easy to change VM sizes
   - Easy to replicate to other regions

5. **Maintainability**
   - All configuration in one place
   - Version controlled
   - Easy to update

### Technical Highlights

1. **Ansible Best Practices**
   - Role-based organization
   - Idempotency
   - Variable separation
   - Templating (Jinja2)
   - Dynamic inventory

2. **Docker Benefits**
   - Containerization
   - Easy updates (pull new image)
   - Isolation
   - Resource management
   - Docker Compose for multi-container apps

3. **Security Features**
   - HTTPS everywhere
   - SSL certificates
   - Firewall rules (GCP tags)
   - Nginx reverse proxy
   - Initial passwords displayed only once

4. **Automation**
   - Justfile command runner
   - Shell scripts for bootstrap
   - Systemd services for auto-start
   - Cron jobs for SSL renewal

### Challenges Solved

1. **Ubuntu 24.04 PEP 668**
   - Problem: pip packages blocked
   - Solution: Use apt packages instead

2. **Docker Group Membership**
   - Problem: User added to docker group not effective immediately
   - Solution: `meta: reset_connection` in Ansible

3. **File Permissions**
   - Problem: Docker volume files owned by container user
   - Solution: Use `become: yes` to read as root

4. **DNS Propagation**
   - Problem: SSL setup fails if DNS not ready
   - Solution: Document DNS wait time, provide testing commands

---

## 📊 Presentation Slides Outline

### Slide 1: Title
- Project name
- Your name
- Date

### Slide 2: Agenda
- Problem statement
- Solution overview
- Architecture
- Demo
- Results
- Q&A

### Slide 3: Problem Statement
- Manual infrastructure setup challenges
- Time consuming
- Error prone
- Not reproducible
- Difficult to maintain

### Slide 4: Solution
- Infrastructure as Code (IaC)
- Ansible for automation
- Docker for containerization
- One-command deployment

### Slide 5: Architecture Diagram
- 3 VMs on GCP
- Service components
- Network flow
- Technologies used

### Slide 6: Technology Stack
- Cloud: Google Cloud Platform
- IaC: Ansible
- Containers: Docker & Docker Compose
- CI/CD: Jenkins
- Code Quality: SonarQube
- Artifacts: Nexus
- Web Server: Nginx
- SSL: Let's Encrypt
- Automation: Justfile

### Slide 7: Project Structure
- File tree overview
- Playbooks
- Roles
- Configuration

### Slide 8: Demo Time!
- Live demonstration
- (This is where you do the actual demo)

### Slide 9: Results & Metrics
- Deployment time: 10-15 minutes
- Time saved: 80-90%
- Lines of code: ~2000+ lines
- Roles: 7 roles
- Playbooks: 3 playbooks
- Commands: 40+ automation commands

### Slide 10: Key Features
- Full automation
- HTTPS everywhere
- Monitoring ready
- Auto-scaling capable
- Multi-environment support
- Disaster recovery ready

### Slide 11: Lessons Learned
- Ubuntu 24.04 compatibility
- Docker permissions
- DNS propagation timing
- SSL certificate challenges
- Ansible best practices

### Slide 12: Future Enhancements
- Add monitoring (Prometheus + Grafana)
- Implement backup automation
- Add Kubernetes cluster
- Implement GitOps workflow
- Add more security hardening
- Cost optimization

### Slide 13: Conclusion
- Successful automation achieved
- Production-ready infrastructure
- Fully reproducible
- Time and cost savings
- Best practices demonstrated

### Slide 14: Q&A
- Thank you
- Questions?
- Contact information

---

## 🎤 Presentation Tips

### Before Presentation

1. **Prepare Demo Environment**
   - Test full workflow beforehand
   - Have screenshots ready as backup
   - Prepare a "already deployed" environment in case demo fails
   - Have GCP Console open in another tab

2. **Practice Timing**
   - Full demo: 30-40 minutes
   - Short demo: 15-20 minutes (skip some verification steps)
   - Adjust based on audience

3. **Prepare for Questions**
   - Review all documentation
   - Understand every component
   - Know the costs (estimate GCP costs)
   - Know alternatives (other tools, approaches)

### During Presentation

1. **Start Strong**
   - Clear introduction
   - Explain the problem
   - Show enthusiasm

2. **Demo Best Practices**
   - Explain what you're doing BEFORE you do it
   - Show command, explain it, then run it
   - While waiting, explain what's happening
   - Have monitoring/logs visible

3. **Handle Issues**
   - If demo fails, have screenshots ready
   - Explain what SHOULD happen
   - Show alternative (pre-deployed environment)
   - Stay calm and confident

4. **Engage Audience**
   - Ask if they've faced similar problems
   - Invite questions during demo (if time allows)
   - Show passion for automation

### Common Questions & Answers

**Q: How much does this cost on GCP?**
A: Approximately $50-80/month for 3 VMs running 24/7. Can reduce costs by:
- Stopping VMs when not in use
- Using smaller machine types
- Using preemptible VMs
- Deleting when not needed (just recreate later)

**Q: Can this work on other cloud providers?**
A: Yes! Ansible has modules for AWS, Azure, DigitalOcean, etc. The roles (Docker, Jenkins, etc.) would remain the same. Only the infrastructure creation playbook needs modification.

**Q: How do you handle secrets?**
A: Currently in config.yaml, but production should use:
- Ansible Vault for encrypting sensitive data
- GCP Secret Manager
- HashiCorp Vault
- Environment variables

**Q: What about backups?**
A: Current project uses Docker volumes. For production:
- Automated backup scripts (already in Justfile)
- GCP snapshots
- Backup to Cloud Storage
- Database dumps scheduled via cron

**Q: How do you update services?**
A: 
- Pull new Docker images
- Run `docker compose up -d` (recreates containers)
- Or use Ansible playbook to orchestrate updates
- Zero-downtime updates possible with load balancers

**Q: Is this production-ready?**
A: It's a solid foundation! For true production, add:
- Monitoring (Prometheus/Grafana)
- Logging aggregation (ELK stack)
- High availability (multiple replicas)
- Load balancing
- Database backups
- Secrets management
- Cost monitoring

**Q: How long did this take to build?**
A: Honest answer! Include:
- Planning and architecture
- Writing Ansible code
- Testing and debugging
- Documentation
- Troubleshooting issues

---

## 📝 Cheat Sheet for Live Demo

### Pre-Demo Checklist
```bash
# 1. Authenticate to GCP
gcloud auth login
gcloud auth application-default login

# 2. Set project
gcloud config set project my-project-devops-504714

# 3. Verify no VMs exist (or clean up)
gcloud compute instances list

# 4. Verify DNS records are configured
dig jenkins.konpapa.online +short
dig sonarqube.konpapa.online +short
dig nexus.konpapa.online +short

# 5. Open necessary tabs
# - GCP Console (compute instances)
# - Namecheap DNS page
# - Jenkins URL
# - SonarQube URL
# - Nexus URL
```

### Demo Commands (in order)
```bash
# 1. Show config
cat ansible/vars/config.yaml

# 2. Check authentication
gcloud auth list

# 3. Create infrastructure
just create-infrastructure
# ⏱️ Wait ~3-5 minutes

# 4. Verify in GCP Console
gcloud compute instances list

# 5. Test connectivity
just ping-all

# 6. Show DNS (already done)
dig jenkins.konpapa.online +short

# 7. Configure services
just configure-all
# ⏱️ Wait ~5-8 minutes

# 8. Get passwords
just get-jenkins-password
just get-nexus-password

# 9. Access services
curl -I https://jenkins.konpapa.online
curl -I https://sonarqube.konpapa.online
curl -I https://nexus.konpapa.online

# 10. Open in browser
# - https://jenkins.konpapa.online
# - https://sonarqube.konpapa.online
# - https://nexus.konpapa.online

# 11. Show useful commands
just --list
just check-services
just show-urls

# 12. Cleanup (optional)
just destroy-infrastructure
```

### Backup Commands (if issues)
```bash
# If create fails, check logs
cat /tmp/ansible.log

# If DNS not working
sudo systemd-resolve --flush-caches

# If service not starting
docker logs jenkins
docker logs sonarqube
docker logs nexus

# If Nginx issues
sudo nginx -t
sudo systemctl status nginx

# Manual password retrieval
sudo cat /home/samnangchanserey/jenkins/data/secrets/initialAdminPassword
sudo cat /home/samnangchanserey/nexus/data/admin.password
```

---

## 🎬 Closing

**"Thank you for your attention! As you've seen, we've successfully automated the entire DevOps infrastructure deployment from scratch to production-ready services in just 15 minutes. This demonstrates the power of Infrastructure as Code and automation."**

**"The code is fully documented, open source, and can be adapted for your own projects. I'm happy to answer any questions!"**

---

## 📎 Additional Resources

**GitHub Repository:** [Your repo URL]

**Documentation:**
- README.md - Quick start guide
- DEPLOYMENT_GUIDE.md - Detailed deployment
- CLOUDFLARE_SETUP.md - SSL with Cloudflare
- TROUBLESHOOTING.md - Common issues

**Contact:** [Your email/LinkedIn]

---

**Good luck with your presentation! 🚀**
