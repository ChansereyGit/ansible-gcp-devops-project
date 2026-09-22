# Scripts Directory

This directory contains helper scripts for the project.

## `bootstrap-controller.sh`

Bootstrap script to set up the Ansible controller VM with all required tools.

### What It Does

This script installs and configures:

1. **System Updates**
   - Updates all system packages
   - Installs security updates

2. **Basic Tools**
   - curl, wget, git, vim, htop, tree
   - Development tools and utilities

3. **Ansible**
   - Latest version from PPA
   - Python dependencies (google-auth, requests)
   - GCP modules

4. **Google Cloud SDK**
   - gcloud CLI
   - Configured for Ansible automation

5. **Just** 
   - Command runner for automation
   - Installed to `~/.local/bin`

6. **GitHub CLI** (`gh`)
   - For repository management
   - Authentication and workflows

7. **SSH Keys**
   - Generates ed25519 key pair
   - Displays public key for VM access

8. **Optional Tools**
   - Fish shell
   - Oh My Zsh (with Zsh)

9. **System Optimizations**
   - Increased file descriptors
   - Network performance tuning
   - Resource limits

10. **Ansible Collections**
    - google.cloud
    - community.docker

### Usage

#### Option 1: Direct Download and Run

```bash
# On the ansible-controller VM
wget https://raw.githubusercontent.com/YOUR_REPO/main/scripts/bootstrap-controller.sh
chmod +x bootstrap-controller.sh
./bootstrap-controller.sh
```

#### Option 2: Via Git

```bash
# Clone the project first
git clone YOUR_REPO_URL
cd ansible-gcp-devops-project/scripts
chmod +x bootstrap-controller.sh
./bootstrap-controller.sh
```

#### Option 3: Via SCP

```bash
# From your local machine
scp scripts/bootstrap-controller.sh user@controller-ip:~/
ssh user@controller-ip
chmod +x bootstrap-controller.sh
./bootstrap-controller.sh
```

### After Running the Script

1. **Reload Your Shell**
   ```bash
   exec bash
   # Or
   source ~/.bashrc
   ```

2. **Authenticate to GCP**
   ```bash
   gcloud auth login
   gcloud auth application-default login
   gcloud config set project my-project-devops-504714
   ```

3. **Clone Project (if not already done)**
   ```bash
   cd ~/projects
   git clone YOUR_REPO_URL
   cd ansible-gcp-devops-project
   ```

4. **Update Configuration**
   ```bash
   vim ansible/vars/config.yaml
   # Update with your settings
   ```

5. **Deploy Infrastructure**
   ```bash
   just deploy-all
   ```

### Manual Setup (Alternative)

If you prefer to set up manually without the script:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Ansible
sudo apt-add-repository ppa:ansible/ansible
sudo apt update
sudo apt install ansible -y

# Install Python packages
pip3 install google-auth requests

# Install gcloud
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
sudo apt update && sudo apt install google-cloud-cli -y

# Install just
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/.local/bin

# Generate SSH keys
ssh-keygen -t ed25519 -C "ansible-controller"

# Install Ansible collections
ansible-galaxy collection install google.cloud
ansible-galaxy collection install community.docker
```

### Troubleshooting

**Issue: Python package installation error (Ubuntu 24.04)**
```
error: externally-managed-environment
```

**Solution:**
The updated bootstrap script now handles this automatically. It tries to install via apt first, then falls back to pip if needed.

Manual fix:
```bash
# Use system packages (recommended)
sudo apt-get install -y python3-google-auth python3-requests python3-yaml

# Or use pip with flag (quick fix)
pip3 install --user --break-system-packages google-auth requests
```

**Issue: `just: command not found`**
```bash
# Add to PATH
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

**Issue: GCP authentication fails**
```bash
# Re-authenticate
gcloud auth revoke
gcloud auth login
gcloud auth application-default login
```

**Issue: Ansible module not found**
```bash
# Reinstall collections
ansible-galaxy collection install google.cloud --force
ansible-galaxy collection install community.docker --force
```

**Issue: Permission denied for SSH keys**
```bash
# Fix permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

### Script Output

The script will display:
- Installation progress for each component
- Your SSH public key (for adding to VMs)
- Next steps to complete setup
- Installed tool versions

### Requirements

- Ubuntu 24.04 LTS (or Ubuntu 22.04)
- Internet connection
- Non-root user with sudo privileges
- Minimum 2GB RAM, 20GB disk

### Security Notes

- Script does not run as root (will exit if run with sudo)
- SSH keys are generated securely with ed25519
- All packages verified with GPG signatures
- No secrets or credentials stored in script

### Customization

Edit the script to:
- Change SSH key type or size
- Skip optional tools (Fish, Oh My Zsh)
- Add additional packages
- Modify system optimization values
- Change default directories

### Support

If the script fails:
1. Check error messages
2. Ensure you're on Ubuntu 24.04
3. Verify internet connectivity
4. Run with verbose output: `bash -x bootstrap-controller.sh`
5. Check logs: `journalctl -xe`
