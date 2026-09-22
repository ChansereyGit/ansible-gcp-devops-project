#!/bin/bash

# ============================================================================
# Project Validation Script
# ============================================================================
# This script validates YAML syntax and project structure
# Run this on the ansible-controller VM after bootstrap
#
# Usage:
#   ./scripts/validate-project.sh
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
    ((WARNINGS++))
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
    ((ERRORS++))
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Project Validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ============================================================================
# 1. Check Required Tools
# ============================================================================
log_info "Checking required tools..."

if command -v ansible &> /dev/null; then
    log_success "Ansible installed: $(ansible --version | head -1)"
else
    log_error "Ansible not found"
fi

if command -v python3 &> /dev/null; then
    log_success "Python3 installed: $(python3 --version)"
else
    log_error "Python3 not found"
fi

if command -v just &> /dev/null; then
    log_success "Just installed: $(just --version)"
else
    log_warning "Just not found (optional)"
fi

if command -v gcloud &> /dev/null; then
    log_success "gcloud installed: $(gcloud --version | head -1)"
else
    log_error "gcloud not found"
fi

echo ""

# ============================================================================
# 2. Validate Ansible Playbook Syntax
# ============================================================================
log_info "Validating Ansible playbooks..."

cd ansible

for playbook in playbooks/*.yaml; do
    if [ -f "$playbook" ]; then
        if ansible-playbook "$playbook" --syntax-check &> /dev/null; then
            log_success "$(basename $playbook) - syntax OK"
        else
            log_error "$(basename $playbook) - syntax error"
            ansible-playbook "$playbook" --syntax-check
        fi
    fi
done

echo ""

# ============================================================================
# 3. Validate YAML Files
# ============================================================================
log_info "Validating YAML files..."

validate_yaml() {
    local file=$1
    if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
        log_success "$(basename $file) - valid YAML"
    else
        log_error "$(basename $file) - invalid YAML"
    fi
}

# Validate role files
for file in roles/*/tasks/*.yaml roles/*/defaults/*.yaml roles/*/handlers/*.yaml; do
    if [ -f "$file" ]; then
        validate_yaml "$file"
    fi
done

# Validate vars
for file in vars/*.yaml; do
    if [ -f "$file" ]; then
        validate_yaml "$file"
    fi
done

echo ""

# ============================================================================
# 4. Check Required Files
# ============================================================================
log_info "Checking required files..."

cd ..

required_files=(
    "Justfile"
    "README.md"
    ".gitignore"
    "ansible/ansible.cfg"
    "ansible/vars/config.yaml"
    "ansible/playbooks/01-create-infrastructure.yaml"
    "ansible/playbooks/02-destroy-infrastructure.yaml"
    "ansible/playbooks/03-configure-all.yaml"
    "ansible/templates/inventory-template.j2"
    "scripts/bootstrap-controller.sh"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        log_success "$file exists"
    else
        log_error "$file missing"
    fi
done

echo ""

# ============================================================================
# 5. Check Role Structure
# ============================================================================
log_info "Checking role structure..."

roles=(
    "common"
    "docker"
    "jenkins"
    "sonarqube"
    "nexus"
    "nginx"
    "certbot"
)

for role in "${roles[@]}"; do
    if [ -d "ansible/roles/$role" ]; then
        log_success "Role '$role' exists"
        
        if [ -f "ansible/roles/$role/tasks/main.yaml" ]; then
            log_success "  - tasks/main.yaml exists"
        else
            log_error "  - tasks/main.yaml missing"
        fi
    else
        log_error "Role '$role' missing"
    fi
done

echo ""

# ============================================================================
# 6. Check Configuration
# ============================================================================
log_info "Checking configuration..."

if [ -f "ansible/vars/config.yaml" ]; then
    # Check for placeholder values
    if grep -q "your-gcp-project-id" ansible/vars/config.yaml 2>/dev/null; then
        log_warning "config.yaml contains placeholder 'your-gcp-project-id'"
    fi
    
    if grep -q "yourdomain.com" ansible/vars/config.yaml 2>/dev/null; then
        log_warning "config.yaml contains placeholder 'yourdomain.com'"
    fi
    
    if grep -q "YOUR_USERNAME" ansible/vars/config.yaml 2>/dev/null; then
        log_warning "config.yaml contains placeholder 'YOUR_USERNAME'"
    fi
    
    log_success "config.yaml file checked"
else
    log_error "config.yaml not found"
fi

echo ""

# ============================================================================
# 7. Check SSH Keys
# ============================================================================
log_info "Checking SSH keys..."

if [ -f ~/.ssh/id_ed25519 ]; then
    log_success "SSH private key exists"
else
    log_warning "SSH private key not found at ~/.ssh/id_ed25519"
fi

if [ -f ~/.ssh/id_ed25519.pub ]; then
    log_success "SSH public key exists"
else
    log_warning "SSH public key not found at ~/.ssh/id_ed25519.pub"
fi

echo ""

# ============================================================================
# 8. Check GCP Authentication
# ============================================================================
log_info "Checking GCP authentication..."

if gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q "@"; then
    log_success "GCP authenticated: $(gcloud auth list --filter=status:ACTIVE --format='value(account)')"
else
    log_warning "GCP not authenticated - run: gcloud auth login"
fi

if [ -f ~/.config/gcloud/application_default_credentials.json ]; then
    log_success "Application Default Credentials exist"
else
    log_warning "Application Default Credentials not found - run: gcloud auth application-default login"
fi

echo ""

# ============================================================================
# 9. Check Ansible Collections
# ============================================================================
log_info "Checking Ansible collections..."

if ansible-galaxy collection list | grep -q "google.cloud"; then
    log_success "google.cloud collection installed"
else
    log_warning "google.cloud collection not found - run: ansible-galaxy collection install google.cloud"
fi

if ansible-galaxy collection list | grep -q "community.docker"; then
    log_success "community.docker collection installed"
else
    log_warning "community.docker collection not found - run: ansible-galaxy collection install community.docker"
fi

echo ""

# ============================================================================
# 10. Validate Docker Compose Files
# ============================================================================
log_info "Checking Docker Compose template files..."

compose_templates=(
    "ansible/roles/jenkins/templates/docker-compose.yml.j2"
    "ansible/roles/sonarqube/templates/docker-compose.yml.j2"
    "ansible/roles/nexus/templates/docker-compose.yml.j2"
)

for template in "${compose_templates[@]}"; do
    if [ -f "$template" ]; then
        log_success "$(basename $(dirname $(dirname $template)))/docker-compose.yml.j2 exists"
    else
        log_error "$(basename $(dirname $(dirname $template)))/docker-compose.yml.j2 missing"
    fi
done

echo ""

# ============================================================================
# Summary
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Validation Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    log_success "All checks passed! Project is ready to deploy."
    echo ""
    echo "Next steps:"
    echo "  1. Update ansible/vars/config.yaml if not already done"
    echo "  2. Authenticate to GCP if not already done"
    echo "  3. Run: just deploy-all"
elif [ $ERRORS -eq 0 ]; then
    log_warning "Validation completed with $WARNINGS warnings"
    echo ""
    echo "You can proceed but address warnings for best results."
else
    log_error "Validation failed with $ERRORS errors and $WARNINGS warnings"
    echo ""
    echo "Please fix errors before proceeding."
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
