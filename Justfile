#!/usr/bin/env just --justfile

# ============================================================================
# Justfile - Automation Commands for GCP DevOps Infrastructure
# ============================================================================
# This Justfile provides convenient shortcuts for common operations.
# Based on course patterns from devoops12-shortcourse-weekend/5.Ansible/iac-prod
#
# Prerequisites:
# - Install just: https://github.com/casey/just
# - Authenticate to GCP: gcloud auth application-default login
# - Configure SSH keys: ssh-keygen -t ed25519
#
# Usage: just <command>
# Example: just create-infrastructure
# ============================================================================

# Set working directory to ansible folder
set positional-arguments
ansible_dir := "ansible"

# Default recipe (shows help)
default:
    @just --list

# ============================================================================
# Infrastructure Management
# ============================================================================

# Create all GCP infrastructure (VMs and generate inventory)
create-infrastructure:
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @echo "Creating GCP Infrastructure..."
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cd {{ansible_dir}} && ansible-playbook -i inventory/bootstrap.ini playbooks/01-create-infrastructure.yaml

# Destroy all GCP infrastructure (with confirmation)
destroy-infrastructure:
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @echo "⚠️  WARNING: This will destroy all infrastructure!"
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cd {{ansible_dir}} && ansible-playbook playbooks/02-destroy-infrastructure.yaml

# Configure all VMs (install Docker, apps, setup SSL)
configure-all:
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @echo "Configuring All VMs..."
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cd {{ansible_dir}} && ansible-playbook playbooks/03-configure-all.yaml

# Complete workflow: create infrastructure and configure everything
deploy-all: create-infrastructure
    @echo ""
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @echo "Waiting 30 seconds for VMs to stabilize..."
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    sleep 30
    just configure-all

# ============================================================================
# Connectivity Testing
# ============================================================================

# Test connectivity to all hosts
ping-all:
    @echo "Testing connectivity to all hosts..."
    cd {{ansible_dir}} && ansible -m ping all

# Test connectivity to Jenkins VM
ping-jenkins:
    @echo "Testing connectivity to Jenkins..."
    cd {{ansible_dir}} && ansible -m ping jenkins

# Test connectivity to SonarQube VM
ping-sonarqube:
    @echo "Testing connectivity to SonarQube..."
    cd {{ansible_dir}} && ansible -m ping sonarqube

# Test connectivity to Nexus VM
ping-nexus:
    @echo "Testing connectivity to Nexus..."
    cd {{ansible_dir}} && ansible -m ping nexus

# ============================================================================
# Service Management
# ============================================================================

# Check status of all Docker containers on all VMs
check-services:
    @echo "Checking Docker services on all VMs..."
    cd {{ansible_dir}} && ansible app_servers -m shell -a "docker ps --format 'table {{{{.Names}}}}\t{{{{.Status}}}}\t{{{{.Ports}}}}'" -b

# Restart Jenkins service
restart-jenkins:
    @echo "Restarting Jenkins..."
    cd {{ansible_dir}} && ansible jenkins -m shell -a "cd ~/jenkins && docker compose restart" -b

# Restart SonarQube service
restart-sonarqube:
    @echo "Restarting SonarQube..."
    cd {{ansible_dir}} && ansible sonarqube -m shell -a "cd ~/sonarqube && docker compose restart" -b

# Restart Nexus service
restart-nexus:
    @echo "Restarting Nexus..."
    cd {{ansible_dir}} && ansible nexus -m shell -a "cd ~/nexus && docker compose restart" -b

# ============================================================================
# SSL Certificate Management
# ============================================================================

# Setup SSL certificates for all services (requires DNS to be configured)
setup-ssl:
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @echo "⚠️  Ensure DNS records are configured before running this!"
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @echo ""
    @echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
    sleep 5
    cd {{ansible_dir}} && ansible-playbook playbooks/03-configure-all.yaml --tags certbot

# Renew SSL certificates manually
renew-ssl:
    @echo "Renewing SSL certificates..."
    cd {{ansible_dir}} && ansible app_servers -m shell -a "certbot renew" -b

# Test SSL certificate renewal (dry run)
test-ssl-renewal:
    @echo "Testing SSL certificate renewal (dry run)..."
    cd {{ansible_dir}} && ansible app_servers -m shell -a "certbot renew --dry-run" -b

# ============================================================================
# Information & Debugging
# ============================================================================

# Show inventory information
show-inventory:
    @echo "Current Ansible Inventory:"
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cd {{ansible_dir}} && ansible-inventory --list

# Show inventory graph
show-inventory-graph:
    @echo "Inventory Graph:"
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cd {{ansible_dir}} && ansible-inventory --graph

# Display Jenkins initial password
get-jenkins-password:
    @echo "Fetching Jenkins initial password..."
    cd {{ansible_dir}} && ansible jenkins -m shell -a "sudo cat /home/samnangchanserey/jenkins/data/secrets/initialAdminPassword"

# Display Nexus initial password
get-nexus-password:
    @echo "Fetching Nexus initial password..."
    cd {{ansible_dir}} && ansible nexus -m shell -a "sudo cat /home/samnangchanserey/nexus/data/admin.password"

# Show all service URLs
show-urls:
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @echo "Service URLs:"
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @echo ""
    @echo "Jenkins:    https://jenkins.konpapa.online"
    @echo "SonarQube:  https://sonarqube.konpapa.online"
    @echo "Nexus:      https://nexus.konpapa.online"
    @echo ""
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check system resources on all VMs
check-resources:
    @echo "Checking system resources..."
    cd {{ansible_dir}} && ansible all -m shell -a "echo '=== Disk Usage ===' && df -h / && echo '' && echo '=== Memory Usage ===' && free -h && echo '' && echo '=== CPU Info ===' && top -bn1 | head -5" -b

# View logs from a specific service
view-logs service:
    @echo "Viewing logs for {{service}}..."
    cd {{ansible_dir}} && ansible {{service}} -m shell -a "docker logs {{service}} --tail 50" -b

# ============================================================================
# Configuration Management
# ============================================================================

# Validate Ansible playbook syntax
validate:
    @echo "Validating Ansible playbooks..."
    cd {{ansible_dir}} && ansible-playbook playbooks/01-create-infrastructure.yaml --syntax-check
    cd {{ansible_dir}} && ansible-playbook playbooks/02-destroy-infrastructure.yaml --syntax-check
    cd {{ansible_dir}} && ansible-playbook playbooks/03-configure-all.yaml --syntax-check
    @echo "✓ All playbooks are valid!"

# Check Ansible configuration
check-config:
    @echo "Ansible Configuration:"
    cd {{ansible_dir}} && ansible-config dump --only-changed

# ============================================================================
# Backup & Maintenance
# ============================================================================

# Backup all service data
backup-all:
    @echo "Backing up all service data..."
    @echo "This will create backups in ~/backups/ on each VM"
    cd {{ansible_dir}} && ansible app_servers -m shell -a "mkdir -p ~/backups && tar czf ~/backups/backup-$(date +%Y%m%d-%H%M%S).tar.gz ~/jenkins/data ~/sonarqube ~/nexus/data 2>/dev/null || true" -b

# Update all system packages
update-systems:
    @echo "Updating all systems..."
    cd {{ansible_dir}} && ansible all -m apt -a "update_cache=yes upgrade=dist autoremove=yes" -b

# ============================================================================
# GCP Specific Commands
# ============================================================================

# List all GCP instances in the project
list-gcp-instances:
    @echo "GCP Instances:"
    gcloud compute instances list --project=my-project-devops-504714

# Show GCP instance details
show-gcp-details:
    @echo "GCP Instance Details:"
    gcloud compute instances describe ansible-controller --zone=asia-southeast1-c --project=my-project-devops-504714
    gcloud compute instances describe jenkins-vm --zone=asia-southeast1-c --project=my-project-devops-504714
    gcloud compute instances describe sonarqube-vm --zone=asia-southeast1-c --project=my-project-devops-504714
    gcloud compute instances describe nexus-vm --zone=asia-southeast1-c --project=my-project-devops-504714

# SSH into a specific VM
ssh-jenkins:
    gcloud compute ssh jenkins-vm --zone=asia-southeast1-c --project=my-project-devops-504714

ssh-sonarqube:
    gcloud compute ssh sonarqube-vm --zone=asia-southeast1-c --project=my-project-devops-504714

ssh-nexus:
    gcloud compute ssh nexus-vm --zone=asia-southeast1-c --project=my-project-devops-504714

ssh-controller:
    gcloud compute ssh ansible-controller --zone=asia-southeast1-c --project=my-project-devops-504714

# ============================================================================
# Troubleshooting
# ============================================================================

# Run Ansible in verbose mode for debugging
debug-infrastructure:
    cd {{ansible_dir}} && ansible-playbook playbooks/01-create-infrastructure.yaml -vvv

debug-configuration:
    cd {{ansible_dir}} && ansible-playbook playbooks/03-configure-all.yaml -vvv

# Check firewall rules
check-firewall:
    gcloud compute firewall-rules list --project=my-project-devops-504714

# Test HTTP connectivity to services
test-connectivity:
    @echo "Testing HTTP connectivity..."
    @echo "Jenkins:"
    curl -I http://jenkins.konpapa.online || true
    @echo ""
    @echo "SonarQube:"
    curl -I http://sonarqube.konpapa.online || true
    @echo ""
    @echo "Nexus:"
    curl -I http://nexus.konpapa.online || true

# ============================================================================
# Quick Start Guide
# ============================================================================

# Show quick start instructions
help:
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @echo "GCP DevOps Infrastructure - Quick Start"
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @echo ""
    @echo "Prerequisites:"
    @echo "  1. Authenticate to GCP: gcloud auth application-default login"
    @echo "  2. Generate SSH keys: ssh-keygen -t ed25519"
    @echo "  3. Update ansible/vars/config.yaml with your settings"
    @echo ""
    @echo "Complete Deployment:"
    @echo "  just deploy-all              # Create & configure everything"
    @echo ""
    @echo "Step-by-Step Deployment:"
    @echo "  just create-infrastructure   # Create GCP VMs"
    @echo "  just ping-all                # Test connectivity"
    @echo "  just configure-all           # Install & configure services"
    @echo ""
    @echo "After Configuration:"
    @echo "  1. Configure DNS A records (see README.md)"
    @echo "  2. Run: just setup-ssl       # Setup HTTPS"
    @echo "  3. Access services:"
    @echo "     - https://jenkins.konpapa.online"
    @echo "     - https://sonarqube.konpapa.online"
    @echo "     - https://nexus.konpapa.online"
    @echo ""
    @echo "Useful Commands:"
    @echo "  just show-urls               # Display all service URLs"
    @echo "  just get-jenkins-password    # Get Jenkins admin password"
    @echo "  just get-nexus-password      # Get Nexus admin password"
    @echo "  just check-services          # Check all Docker containers"
    @echo ""
    @echo "Cleanup:"
    @echo "  just destroy-infrastructure  # Delete all VMs"
    @echo ""
    @echo "For full command list: just --list"
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
