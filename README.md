# Ansible GCP DevOps Project

Automated infrastructure setup for Jenkins, SonarQube, and Nexus on Google Cloud Platform.

## What This Does

- Creates 3 VMs on GCP (Jenkins, SonarQube, Nexus)
- Installs Docker on all servers
- Deploys services using Docker Compose
- Sets up Nginx as reverse proxy
- Configures SSL certificates with Let's Encrypt

## Requirements

- GCP account with project created
- Domain name
- Ubuntu VM or local machine with Ansible

## Setup

1. **Install dependencies**
```bash
./scripts/bootstrap-controller.sh
```

2. **Configure GCP**
```bash
gcloud auth login
gcloud auth application-default login
```

3. **Edit configuration**

Edit `ansible/vars/config.yaml`:
- Add your GCP project ID
- Add your domain names
- Add your email for SSL certificates

4. **Deploy**
```bash
just create-infrastructure
just configure-all
```

## DNS Setup

Before running `just configure-all`, configure your DNS:

1. Get VM IPs: `gcloud compute instances list`
2. Add A records pointing to your VMs:
   - jenkins.yourdomain.com → jenkins-vm IP
   - sonarqube.yourdomain.com → sonarqube-vm IP  
   - nexus.yourdomain.com → nexus-vm IP
3. Wait 2-3 minutes for DNS to propagate

## Available Commands

```bash
just create-infrastructure    # Create VMs
just configure-all           # Install everything
just destroy-infrastructure  # Delete all VMs
just check-services         # Check container status
just get-jenkins-password   # Get Jenkins password
just get-nexus-password     # Get Nexus password
```

## Access Services

After deployment:
- Jenkins: https://jenkins.yourdomain.com
- SonarQube: https://sonarqube.yourdomain.com (admin/admin)
- Nexus: https://nexus.yourdomain.com

## Project Structure

```
ansible-gcp-devops-project/
├── ansible/
│   ├── playbooks/          # Main playbooks
│   ├── roles/              # Ansible roles
│   ├── vars/               # Configuration
│   └── inventory/          # Host inventories
├── scripts/                # Setup scripts
└── Justfile               # Command shortcuts
```

## Troubleshooting

**SSL certificate fails:**
- Make sure DNS points to correct IPs
- Check port 80 is accessible
- Run manually: `sudo certbot --nginx -d yourdomain.com`

**Docker permission denied:**
```bash
sudo usermod -aG docker $USER
sudo systemctl restart docker
```

**Service not running:**
```bash
docker ps                    # Check containers
docker logs <container>      # Check logs
sudo systemctl status nginx  # Check nginx
```

## Cleanup

```bash
just destroy-infrastructure
```
