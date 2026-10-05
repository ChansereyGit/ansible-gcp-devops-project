# Ansible GCP DevOps Infrastructure Automation

Automated deployment of DevOps tools (Jenkins, SonarQube, Nexus) on Google Cloud Platform using Ansible.

## 🎯 Project Overview

This project automates the complete setup of a DevOps infrastructure on GCP, including:
- Infrastructure provisioning (VMs, firewall rules, networking)
- Docker installation and configuration
- Jenkins CI/CD server deployment
- SonarQube code quality platform
- Nexus repository manager
- Nginx reverse proxy with SSL/TLS (Let's Encrypt)

## 📋 Prerequisites

- GCP account with billing enabled
- GCP project created
- Domain name (for SSL certificates)
- Ubuntu 24.04 VM (as Ansible controller) or local machine with Ansible

## 🛠️ Technology Stack

- **Cloud Provider**: Google Cloud Platform (GCP)
- **Configuration Management**: Ansible 2.16+
- **Containerization**: Docker & Docker Compose
- **Web Server**: Nginx
- **SSL/TLS**: Let's Encrypt (Certbot)
- **Operating System**: Ubuntu 24.04 LTS

## 📁 Project Structure

```
ansible-gcp-devops-project/
├── ansible/
│   ├── inventory/
│   │   ├── bootstrap.ini          # Initial inventory (localhost)
│   │   └── hosts.ini              # Generated inventory (VMs)
│   ├── playbooks/
│   │   ├── 01-create-infrastructure.yaml
│   │   ├── 02-destroy-infrastructure.yaml
│   │   └── 03-configure-all.yaml
│   ├── roles/
│   │   ├── common/                # System updates, packages
│   │   ├── docker/                # Docker installation
│   │   ├── jenkins/               # Jenkins deployment
│   │   ├── sonarqube/             # SonarQube deployment
│   │   ├── nexus/                 # Nexus deployment
│   │   ├── nginx/                 # Nginx reverse proxy
│   │   └── certbot/               # SSL certificate management
│   └── vars/
│       └── config.yaml            # Main configuration file
├── scripts/
│   ├── bootstrap-controller.sh    # Setup Ansible controller
│   └── setup-passwordless-sudo.sh # Configure passwordless sudo
├── Justfile                       # Command shortcuts
└── README.md
```

## ⚙️ Configuration

Edit `ansible/vars/config.yaml` with your settings:

```yaml
# GCP Configuration
google_project_id: "your-project-id"
google_zone: "asia-southeast1-c"
google_region: "asia-southeast1"

# Domain Configuration
base_domain: "yourdomain.com"
jenkins_domain: "jenkins.yourdomain.com"
sonarqube_domain: "sonarqube.yourdomain.com"
nexus_domain: "nexus.yourdomain.com"

# Let's Encrypt Email
letsencrypt_email: "admin@yourdomain.com"

# SSH Configuration
ssh_username: "your-username"
```

## 🚀 Quick Start

### 1. Setup Ansible Controller

```bash
# Clone the repository
git clone https://github.com/yourusername/ansible-gcp-devops-project.git
cd ansible-gcp-devops-project

# Run bootstrap script
chmod +x scripts/bootstrap-controller.sh
./scripts/bootstrap-controller.sh
```

### 2. Authenticate with GCP

```bash
# Login to GCP
gcloud auth login

# Set default project
gcloud config set project YOUR_PROJECT_ID

# Create application default credentials
gcloud auth application-default login
```

### 3. Configure Project

```bash
# Edit configuration file
nano ansible/vars/config.yaml

# Update:
# - google_project_id
# - base_domain and subdomains
# - letsencrypt_email
# - ssh_username
```

### 4. Deploy Infrastructure

```bash
# Create VMs and firewall rules
just create-infrastructure

# Configure all services
just configure-all
```

### 5. Access Services

After deployment completes, access your services:

- **Jenkins**: `https://jenkins.yourdomain.com`
- **SonarQube**: `https://sonarqube.yourdomain.com`
- **Nexus**: `https://nexus.yourdomain.com`

## 📝 Available Commands

Using `just` command shortcuts:

```bash
# Infrastructure Management
just create-infrastructure     # Create all GCP resources
just destroy-infrastructure    # Destroy all GCP resources
just configure-all            # Configure all VMs and services

# Service Management
just setup-ssl                # Setup SSL certificates
just check-services           # Check Docker containers status
just get-jenkins-password     # Get Jenkins initial password
just get-nexus-password       # Get Nexus initial password

# Utilities
just ping-all                 # Test connectivity to all VMs
just show-inventory           # Display generated inventory
just clean                    # Clean generated files
```

## 🔐 Initial Credentials

### Jenkins
```bash
# Get initial admin password
just get-jenkins-password
# Or manually:
# ssh jenkins-vm
# sudo cat /var/lib/docker/volumes/jenkins_home/_data/secrets/initialAdminPassword
```

### SonarQube
- **Username**: `admin`
- **Password**: `admin` (change on first login)

### Nexus
```bash
# Get initial admin password
just get-nexus-password
# Or manually:
# ssh nexus-vm
# sudo cat /var/lib/docker/volumes/nexus-data/_data/admin.password
```

## 🌐 DNS Configuration

Before running SSL setup, configure DNS:

1. Get VM external IPs:
   ```bash
   gcloud compute instances list
   ```

2. Add A records in your DNS provider:
   ```
   A Record | jenkins    | YOUR_JENKINS_IP    | TTL: Auto
   A Record | sonarqube  | YOUR_SONARQUBE_IP  | TTL: Auto
   A Record | nexus      | YOUR_NEXUS_IP      | TTL: Auto
   ```

3. Wait 2-3 minutes for DNS propagation

4. Verify DNS:
   ```bash
   dig +short jenkins.yourdomain.com
   ```

## 🔧 Infrastructure Details

### VMs Created

| VM Name | Purpose | Machine Type | Disk Size | Services |
|---------|---------|--------------|-----------|----------|
| jenkins-vm | CI/CD Server | e2-standard-2 (2 vCPUs, 8GB RAM) | 50GB | Jenkins, Docker, Nginx |
| sonarqube-vm | Code Quality | e2-medium (2 vCPUs, 4GB RAM) | 50GB | SonarQube, PostgreSQL, Nginx |
| nexus-vm | Artifact Repository | e2-medium (2 vCPUs, 4GB RAM) | 50GB | Nexus, Docker, Nginx |

### Firewall Rules

- **allow-ssh**: Port 22 (SSH access)
- **allow-http**: Port 80 (HTTP)
- **allow-https**: Port 443 (HTTPS)

### Ports

| Service | Internal Port | External Port |
|---------|--------------|---------------|
| Jenkins | 8080 | 443 (via Nginx) |
| SonarQube | 9000 | 443 (via Nginx) |
| Nexus | 8081 | 443 (via Nginx) |

## 🔄 SSL Certificate Management

SSL certificates are automatically obtained using Let's Encrypt and renewed every 60 days.

### Auto-Renewal

Certificates are automatically renewed via cron job:
```
30 3 * * * certbot renew --quiet --post-hook 'systemctl reload nginx'
```

### Manual Renewal

```bash
# Test renewal (dry run)
ssh jenkins-vm
sudo certbot renew --dry-run

# Force renewal
sudo certbot renew --force-renewal
```

## 🐛 Troubleshooting

### Issue: SSL Certificate Not Obtained

**Solution:**
1. Verify DNS points to correct IP: `dig +short jenkins.yourdomain.com`
2. Ensure port 80 is accessible
3. Run manually: `sudo certbot --nginx -d jenkins.yourdomain.com --non-interactive --agree-tos -m your-email`

### Issue: Docker Permission Denied

**Solution:**
```bash
sudo usermod -aG docker $USER
sudo systemctl restart docker
```

### Issue: Service Not Accessible

**Solution:**
```bash
# Check service status
docker ps

# Check Nginx configuration
sudo nginx -t
sudo systemctl status nginx

# Check logs
docker logs jenkins
sudo tail -f /var/log/nginx/error.log
```

## 🧹 Cleanup

To remove all resources:

```bash
# Destroy all VMs and firewall rules
just destroy-infrastructure

# Confirm deletion
# Type 'yes' when prompted
```

## 📚 Project Architecture

```
                    Internet
                       │
                    DNS (yourdomain.com)
                       │
        ┌──────────────┼──────────────┐
        │              │              │
    jenkins-vm    sonarqube-vm    nexus-vm
        │              │              │
    ┌───┴───┐      ┌───┴───┐      ┌───┴───┐
    │ Nginx │      │ Nginx │      │ Nginx │
    │  :443 │      │  :443 │      │  :443 │
    └───┬───┘      └───┬───┘      └───┬───┘
        │              │              │
    ┌───┴────┐    ┌────┴─────┐   ┌───┴────┐
    │Jenkins │    │SonarQube │   │ Nexus  │
    │ :8080  │    │  :9000   │   │ :8081  │
    └────────┘    └──────────┘   └────────┘
```

## 🎓 Learning Outcomes

This project demonstrates:
- Infrastructure as Code (IaC) with Ansible
- Cloud resource management on GCP
- Container orchestration with Docker Compose
- Reverse proxy configuration with Nginx
- SSL/TLS certificate automation
- DevOps tool deployment and integration
- Role-based Ansible playbook organization

## 📄 License

This project is for educational purposes.

## 👤 Author

Student Project - DevOps Course

## 🙏 Acknowledgments

- Google Cloud Platform for cloud infrastructure
- Let's Encrypt for free SSL certificates
- Docker for containerization
- Ansible community for automation tools
