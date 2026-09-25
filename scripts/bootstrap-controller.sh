#!/bin/bash

# ============================================================================
# Bootstrap Script for Ansible Controller VM
# ============================================================================
# This script sets up the Ansible controller VM with all required tools
# Run this script on the ansible-controller VM after creation
#
# IMPORTANT: This script requires sudo access
#
# Two options to avoid password prompts:
#
# Option 1: Run setup-passwordless-sudo.sh first (RECOMMENDED)
#   wget https://raw.githubusercontent.com/YOUR_REPO/main/scripts/setup-passwordless-sudo.sh
#   chmod +x setup-passwordless-sudo.sh
#   ./setup-passwordless-sudo.sh  (enter password once)
#   ./bootstrap-controller.sh     (no password needed!)
#
# Option 2: This script will ask for password once at the start
#   ./bootstrap-controller.sh
#   (enter password once, it will be cached)
#
# Usage:
#   wget https://raw.githubusercontent.com/YOUR_REPO/main/scripts/bootstrap-controller.sh
#   chmod +x bootstrap-controller.sh
#   ./bootstrap-controller.sh
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    log_error "Please do not run this script as root"
    exit 1
fi

# Request sudo password upfront and cache it
log_info "This script requires sudo access for package installation"
log_info "Please enter your password once (it will be cached for the script duration)"
sudo -v

# Keep sudo alive in background
while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Ansible Controller Bootstrap Script"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ============================================================================
# 1. Update System
# ============================================================================
log_info "Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y
log_success "System updated"

# ============================================================================
# 2. Install Basic Tools
# ============================================================================
log_info "Installing basic tools..."
sudo apt-get install -y \
    curl \
    wget \
    git \
    vim \
    htop \
    tree \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    python3-pip \
    python3-venv \
    jq \
    tmux

log_success "Basic tools installed"

# ============================================================================
# 3. Install Ansible
# ============================================================================
log_info "Installing Ansible..."
sudo apt-add-repository -y ppa:ansible/ansible || true
sudo apt-get update -y
sudo apt-get install -y ansible

# Install required Python packages for GCP
log_info "Installing Ansible GCP dependencies..."

# Ubuntu 24.04 uses externally-managed Python environment
# Install via apt instead of pip for system packages
sudo apt-get install -y \
    python3-google-auth \
    python3-requests \
    python3-yaml \
    python3-jmespath \
    python3-netaddr

# If some packages aren't available via apt, use pipx or venv
if ! python3 -c "import google.auth" 2>/dev/null; then
    log_warning "google-auth not found in apt, installing via pip with --break-system-packages"
    pip3 install --user --break-system-packages google-auth requests
fi

log_success "Ansible installed: $(ansible --version | head -1)"

# ============================================================================
# 4. Install Google Cloud SDK
# ============================================================================
log_info "Installing Google Cloud SDK..."

# Add gcloud repository
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
    sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

# Import Google Cloud public key
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg

# Install gcloud CLI
sudo apt-get update -y
sudo apt-get install -y google-cloud-cli

log_success "Google Cloud SDK installed: $(gcloud --version | head -1)"

# ============================================================================
# 5. Install Just Command Runner
# ============================================================================
log_info "Installing Just command runner..."

# Download and install just
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | \
    bash -s -- --to ~/.local/bin

# Add to PATH if not already there
if ! grep -q '.local/bin' ~/.bashrc; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi

# Source bashrc to update PATH
export PATH="$HOME/.local/bin:$PATH"

log_success "Just installed: $(~/.local/bin/just --version)"

# ============================================================================
# 6. Install GitHub CLI
# ============================================================================
log_info "Installing GitHub CLI..."

# Add GitHub CLI repository
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
    sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y gh

log_success "GitHub CLI installed: $(gh --version | head -1)"

# ============================================================================
# 7. Generate SSH Keys
# ============================================================================
if [ ! -f ~/.ssh/id_ed25519 ]; then
    log_info "Generating SSH key pair..."
    ssh-keygen -t ed25519 -C "ansible-controller@gcp" -f ~/.ssh/id_ed25519 -N ""
    log_success "SSH key generated"
    echo ""
    log_warning "Your SSH public key (add this to other VMs):"
    cat ~/.ssh/id_ed25519.pub
    echo ""
else
    log_info "SSH key already exists"
fi

# ============================================================================
# 8. Configure Git
# ============================================================================
log_info "Configuring Git..."
git config --global init.defaultBranch main
git config --global core.editor vim
log_success "Git configured"

# ============================================================================
# 9. Install Fish Shell (Optional)
# ============================================================================
log_info "Installing Fish shell..."
sudo apt-get install -y fish

log_success "Fish shell installed"

# ============================================================================
# 10. Install Oh My Zsh (Optional)
# ============================================================================
if [ ! -d ~/.oh-my-zsh ]; then
    log_info "Installing Oh My Zsh..."
    sudo apt-get install -y zsh
    
    # Install Oh My Zsh non-interactively
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || true
    
    log_success "Oh My Zsh installed"
else
    log_info "Oh My Zsh already installed"
fi

# ============================================================================
# 11. Create Project Directory Structure
# ============================================================================
log_info "Creating project directory..."
mkdir -p ~/projects
mkdir -p ~/backups
mkdir -p ~/tools

log_success "Project directories created"

# ============================================================================
# 12. System Optimizations
# ============================================================================
log_info "Applying system optimizations..."

# Increase file descriptors
sudo tee -a /etc/security/limits.conf > /dev/null <<EOF
*    soft nofile 65536
*    hard nofile 65536
*    soft nproc  65536
*    hard nproc  65536
EOF

# Optimize sysctl for network performance
sudo tee -a /etc/sysctl.conf > /dev/null <<EOF
# Network optimizations
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
EOF

sudo sysctl -p > /dev/null 2>&1

log_success "System optimizations applied"

# ============================================================================
# 13. Setup GCP Authentication
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_warning "IMPORTANT: GCP Authentication Required"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Run the following commands to authenticate:"
echo ""
echo "  1. Login to GCP:"
echo "     gcloud auth login"
echo ""
echo "  2. Set application default credentials (for Ansible):"
echo "     gcloud auth application-default login"
echo ""
echo "  3. Set your project:"
echo "     gcloud config set project my-project-devops-504714"
echo ""

# ============================================================================
# 14. Clone Project Repository
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_warning "Project Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "To clone your project:"
echo ""
echo "  cd ~/projects"
echo "  git clone YOUR_REPO_URL"
echo "  cd ansible-gcp-devops-project"
echo ""
echo "Or upload via SCP:"
echo ""
echo "  # From your local machine:"
echo "  scp -r ansible-gcp-devops-project/ user@controller-ip:~/projects/"
echo ""

# ============================================================================
# 15. Install Ansible Collections
# ============================================================================
log_info "Installing Ansible collections..."
ansible-galaxy collection install google.cloud || true
ansible-galaxy collection install community.docker || true
log_success "Ansible collections installed"

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Bootstrap Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
log_success "Ansible Controller setup complete!"
echo ""
echo "Installed Tools:"
echo "  ✓ Ansible $(ansible --version | head -1 | awk '{print $2}')"
echo "  ✓ gcloud $(gcloud --version | head -1 | awk '{print $4}')"
echo "  ✓ just $(~/.local/bin/just --version 2>/dev/null || echo 'installed')"
echo "  ✓ gh $(gh --version | head -1 | awk '{print $3}')"
echo "  ✓ git $(git --version | awk '{print $3}')"
echo "  ✓ Python $(python3 --version | awk '{print $2}')"
echo ""
echo "Next Steps:"
echo "  1. Reload shell: exec bash"
echo "  2. Authenticate to GCP"
echo "  3. Clone/upload your project"
echo "  4. Update ansible/vars/config.yaml"
echo "  5. Run: just deploy-all"
echo ""
echo "Your SSH public key (copy this to add to VMs):"
cat ~/.ssh/id_ed25519.pub || true
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
