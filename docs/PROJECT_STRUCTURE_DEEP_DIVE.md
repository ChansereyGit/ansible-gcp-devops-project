# Project Structure Deep Dive
## Complete Directory and File Explanation

---

## 📁 Root Directory Overview

```
ansible-gcp-devops-project/
├── ansible/                 # All Ansible code (IaC)
├── docs/                    # Documentation
├── scripts/                 # Helper scripts
├── .git/                    # Git version control
├── .gitignore              # Files to ignore in git
├── Justfile                # Command automation
├── README.md               # Project overview
├── PRESENTATION.md         # Presentation script
└── VIDEO_PRESENTATION_SCRIPT.md  # Video recording script
```

---

## 📂 ansible/ Directory - The Heart of Infrastructure as Code

```
ansible/
├── inventory/              # Where are our servers?
├── playbooks/             # What do we want to do?
├── roles/                 # How do we do it?
├── templates/             # Dynamic configuration files
├── vars/                  # Configuration values
└── ansible.cfg           # Ansible behavior settings
```

### Purpose
This directory contains **all** Infrastructure as Code. Everything needed to deploy and manage infrastructure is here.

---

## 📋 ansible/inventory/ - Server Lists

```
inventory/
├── bootstrap.ini          # Initial inventory for infrastructure creation
└── hosts.ini             # Auto-generated inventory with VM IPs
```

### bootstrap.ini

**Purpose:** Used for the FIRST playbook run when no VMs exist yet

**Content:**
```ini
# Bootstrap inventory for creating infrastructure
[localhost]
127.0.0.1 ansible_connection=local
```

**Why needed?**
- First run: No VMs exist yet, can't list their IPs
- We need to run Ansible on localhost to CREATE the VMs
- After VMs created, we generate hosts.ini with actual IPs

**Analogy:** Like a chicken-and-egg problem - need inventory to create VMs, but VMs don't exist yet to put in inventory. Bootstrap.ini solves this by running on local machine first.

### hosts.ini

**Purpose:** Dynamic inventory with actual VM IP addresses (auto-generated)

**Content Example:**
```ini
[all:vars]
ansible_user=samnangchanserey
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_private_key_file=/home/samnangchanserey/.ssh/id_ed25519

[localhost]
localhost ansible_connection=local

[jenkins]
jenkins-vm ansible_host=34.142.147.236

[sonarqube]
sonarqube-vm ansible_host=34.21.213.214

[nexus]
nexus-vm ansible_host=34.21.132.214

[app_servers:children]
jenkins
sonarqube
nexus
```

**How it's generated:**
1. Playbook `01-create-infrastructure.yaml` creates VMs
2. GCP returns VM details including external IPs
3. Ansible uses template `templates/inventory-template.j2`
4. Variables (IPs) inserted into template
5. Result saved as `inventory/hosts.ini`

**Inventory Groups Explained:**

**[all:vars]** - Variables applied to ALL hosts
- `ansible_user`: SSH username
- `ansible_python_interpreter`: Which Python to use
- `ansible_ssh_private_key_file`: SSH key for authentication

**[jenkins], [sonarqube], [nexus]** - Individual VM groups
- Each group contains one VM
- Can run playbooks on specific groups
- Example: `ansible-playbook -l jenkins playbook.yaml`

**[app_servers:children]** - Group of groups
- Contains: jenkins, sonarqube, nexus
- Run commands on all app servers at once
- Example: `ansible app_servers -m ping`

---

## 📖 ansible/playbooks/ - Automation Scripts

```
playbooks/
├── 01-create-infrastructure.yaml     # Creates GCP VMs
├── 02-destroy-infrastructure.yaml    # Deletes all VMs
└── 03-configure-all.yaml            # Installs and configures services
```

### Why Numbered?
- **Execution order** - Clear workflow
- **01** → **03** is the deployment flow
- **02** is for cleanup (destroy)

### 01-create-infrastructure.yaml

**Purpose:** Create virtual machines on Google Cloud Platform

**What it does:**
1. ✅ Verifies GCP authentication
2. ✅ Reads SSH public key
3. ✅ Creates 3 VMs via GCP API
4. ✅ Injects startup scripts
5. ✅ Waits for VMs to be SSH-ready
6. ✅ Generates dynamic inventory

**Key sections:**

```yaml
- name: Create GCP Virtual Machines
  hosts: localhost          # Runs on controller
  connection: local         # Not over SSH
  gather_facts: false       # Don't need system info
  
  vars_files:
    - ../vars/config.yaml   # Load configuration
```

**Tasks breakdown:**

1. **Authentication Check**
```yaml
- name: Check if gcloud is authenticated
  command: gcloud auth list --filter=status:ACTIVE
```
- Runs `gcloud` command
- Verifies active credentials
- Prevents errors later

2. **Read SSH Key**
```yaml
- name: Read SSH public key
  slurp:
    src: "{{ ssh_public_key_path }}"
  register: ssh_pub_key
```
- `slurp` module reads file and base64 encodes it
- Stores in variable `ssh_pub_key`
- Will inject into VM metadata

3. **Create VMs**
```yaml
- name: Create GCP compute instances
  google.cloud.gcp_compute_instance:
    name: "{{ item.name }}"
    machine_type: "{{ item.machine_type }}"
    zone: "{{ item.zone }}"
    project: "{{ google_project_id }}"
    auth_kind: application
    state: present
    metadata:
      ssh-keys: "{{ ssh_username }}:{{ ssh_public_key_content }}"
      startup-script: |
        #!/bin/bash
        # Startup script content here
```
- `google.cloud.gcp_compute_instance` module (from google.cloud collection)
- `state: present` = create if doesn't exist (idempotent)
- `metadata`: Extra data attached to VM
- `startup-script`: Bash script that runs on first boot

4. **Generate Inventory**
```yaml
- name: Generate dynamic inventory
  template:
    src: ../templates/inventory-template.j2
    dest: ../inventory/hosts.ini
  vars:
    instances: "{{ gcp_instances.results }}"
```
- Takes Jinja2 template
- Fills in variables (VM IPs)
- Writes to hosts.ini

### 02-destroy-infrastructure.yaml

**Purpose:** Delete all VMs and clean up

**What it does:**
1. ⚠️ Prompts for confirmation ("type 'yes'")
2. 🗑️ Deletes all VMs via GCP API
3. 🧹 Removes generated inventory file
4. 🧹 Cleans up local state files

**Safety features:**

```yaml
vars_prompt:
  - name: confirm_destroy
    prompt: |
      ⚠️ WARNING: You are about to DESTROY all infrastructure!
      Type 'yes' to confirm
```
- Interactive prompt
- Must type exactly "yes"
- Prevents accidental deletion

**Idempotency:**
```yaml
ignore_errors: true
```
- If VM doesn't exist, don't fail
- Safe to run multiple times

### 03-configure-all.yaml

**Purpose:** Configure VMs and deploy services

**What it does:**
1. 🔧 Base system configuration (common role)
2. 🐳 Install Docker (docker role)
3. 🛠️ Deploy Jenkins (jenkins role)
4. 📊 Deploy SonarQube (sonarqube role)
5. 📦 Deploy Nexus (nexus role)
6. 🌐 Configure Nginx (nginx role)
7. 🔒 Setup SSL (certbot role)

**Structure:**

```yaml
# Phase 1: Common configuration for ALL VMs
- name: Configure All Virtual Machines
  hosts: all:!localhost     # All hosts except localhost
  become: true              # Run as root
  roles:
    - common                # Base config
    - docker                # Docker Engine

# Phase 2: Configure Jenkins specifically
- name: Configure Jenkins Server
  hosts: jenkins
  become: true
  roles:
    - jenkins               # Jenkins deployment
    - nginx                 # Reverse proxy

# Phase 3: SonarQube (similar structure)
# Phase 4: Nexus (similar structure)
# Phase 5: SSL for all
```

**Why separate plays?**
- Different hosts (jenkins vs sonarqube vs nexus)
- Different roles per service
- Clear organization

---

## 🎭 ansible/roles/ - Modular Components

```
roles/
├── common/                # Base system configuration
├── docker/               # Docker Engine installation
├── jenkins/              # Jenkins deployment
├── sonarqube/           # SonarQube + PostgreSQL
├── nexus/               # Nexus Repository Manager
├── nginx/               # Nginx reverse proxy
└── certbot/             # SSL certificates
```

### What is a Role?

**Think of a role as a LEGO brick:**
- Self-contained functionality
- Reusable across projects
- Combinable with other roles
- Standardized structure

### Standard Role Structure

```
role_name/
├── tasks/               # WHAT to do (main logic)
│   └── main.yaml
├── templates/           # Config files with variables
│   ├── template1.j2
│   └── template2.j2
├── files/              # Static files to copy
│   └── staticfile.txt
├── vars/               # Role-specific variables
│   └── main.yaml
├── defaults/           # Default variable values
│   └── main.yaml
├── handlers/           # Triggered actions (restart services)
│   └── main.yaml
└── meta/              # Role dependencies
    └── main.yaml
```

---

### Role: common/

**Purpose:** Base system configuration applied to ALL VMs

**Location:** `roles/common/tasks/main.yaml`

**What it configures:**

1. **Package Management**
```yaml
- name: Update apt cache
  apt:
    update_cache: yes
    cache_valid_time: 3600

- name: Upgrade all packages
  apt:
    upgrade: dist
```
- Updates package lists
- Upgrades all installed packages
- Ensures security patches applied

2. **Install Common Tools**
```yaml
- name: Install common packages
  apt:
    name: "{{ common_packages }}"
    state: present
```
- Installs utilities: curl, wget, git, vim, htop
- Tools needed for troubleshooting

3. **System Limits**
```yaml
- name: Configure system limits
  pam_limits:
    domain: '*'
    limit_type: soft
    limit_item: nofile
    value: 65536
```
- Increases file descriptor limits
- Required for high-performance applications
- Prevents "too many open files" errors

4. **Kernel Parameters (sysctl)**
```yaml
- name: Set sysctl parameters
  sysctl:
    name: vm.max_map_count
    value: 262144
```
- `vm.max_map_count`: Required for Elasticsearch (used by SonarQube)
- Without this, SonarQube won't start

5. **Disable Swap**
```yaml
- name: Disable swap permanently
  shell: |
    swapoff -a
    sed -i '/ swap / s/^/#/' /etc/fstab
```
- Turns off swap memory
- Required for Kubernetes and some databases
- Improves performance

**Why this role?**
- Every server needs basic configuration
- DRY principle: Don't Repeat Yourself
- Run once on all VMs

---

### Role: docker/

**Purpose:** Install Docker Engine and Docker Compose

**Location:** `roles/docker/tasks/main.yaml`

**Installation steps:**

1. **Remove Old Versions**
```yaml
- name: Remove old Docker packages
  apt:
    name:
      - docker
      - docker-engine
      - docker.io
    state: absent
```
- Cleans up conflicting packages
- Fresh start

2. **Add Docker Repository**
```yaml
- name: Add Docker GPG key
  apt_key:
    url: https://download.docker.com/linux/ubuntu/gpg

- name: Add Docker repository
  apt_repository:
    repo: "deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable"
```
- Adds official Docker repository
- Ensures we get latest version

3. **Install Docker**
```yaml
- name: Install Docker Engine
  apt:
    name:
      - docker-ce
      - docker-ce-cli
      - containerd.io
    state: present
```
- Installs Docker daemon
- Installs Docker CLI
- Installs container runtime

4. **Install Docker Compose**
```yaml
- name: Install Docker Compose plugin
  apt:
    name: docker-compose-plugin
```
- Docker Compose V2 (plugin)
- Manages multi-container applications

5. **Configure User**
```yaml
- name: Add user to docker group
  user:
    name: "{{ ansible_user }}"
    groups: docker
    append: yes
```
- Allows running docker without sudo
- Security best practice

6. **Create Docker Network**
```yaml
- name: Create docker network
  docker_network:
    name: devops-network
```
- Custom network for containers
- Better than default bridge

**Why Docker?**
- Consistent environments
- Easy deployment
- Isolation
- Version management

---

### Role: jenkins/

**Purpose:** Deploy Jenkins CI/CD server

**Location:** `roles/jenkins/`

**Structure:**
```
jenkins/
├── tasks/
│   └── main.yaml              # Deployment tasks
├── templates/
│   ├── docker-compose.yml.j2  # Jenkins compose file
│   ├── jenkins.env.j2         # Environment variables
│   └── jenkins.service.j2     # Systemd service
└── files/
    └── jenkins-setup.md       # Setup documentation
```

**Deployment Process:**

1. **Create Directories**
```yaml
- name: Create Jenkins directories
  file:
    path: "{{ item }}"
    state: directory
    owner: "{{ ansible_user }}"
    mode: '0755'
  loop:
    - "/home/{{ ansible_user }}/jenkins"
    - "/home/{{ ansible_user }}/jenkins/data"
```
- Creates folder structure
- Sets correct permissions

2. **Deploy Docker Compose File**

**Template:** `templates/docker-compose.yml.j2`
```yaml
version: '3.8'

services:
  jenkins:
    image: jenkins/jenkins:lts
    container_name: jenkins
    restart: unless-stopped
    ports:
      - "{{ jenkins_port }}:8080"
      - "50000:50000"
    volumes:
      - jenkins_data:/var/jenkins_home
    environment:
      - JAVA_OPTS=-Djenkins.install.runSetupWizard=false

volumes:
  jenkins_data:
    driver: local
```

**Explanation:**
- `image: jenkins/jenkins:lts`: Official Jenkins long-term support image
- `container_name: jenkins`: Easy to reference
- `restart: unless-stopped`: Auto-start on boot
- `ports: 8080:8080`: Expose Jenkins UI
- `ports: 50000:50000`: For Jenkins agents
- `volumes: jenkins_data`: Persistent storage
- `JAVA_OPTS`: Java settings for Jenkins

3. **Start Container**
```yaml
- name: Reset SSH connection
  meta: reset_connection

- name: Start Jenkins container
  community.docker.docker_compose_v2:
    project_src: "/home/{{ ansible_user }}/jenkins"
    state: present
    pull: always
```
- `reset_connection`: Refreshes docker group
- `docker_compose_v2`: Uses new Compose
- `pull: always`: Gets latest image
- `state: present`: Creates/starts if not running

4. **Wait for Startup**
```yaml
- name: Wait for Jenkins to start
  wait_for:
    host: localhost
    port: "{{ jenkins_port }}"
    delay: 10
    timeout: 300
```
- Waits for port 8080 to accept connections
- Delays 10 seconds first
- Timeout after 5 minutes

5. **Read Admin Password**
```yaml
- name: Read Jenkins initial admin password
  slurp:
    src: "/home/{{ ansible_user }}/jenkins/data/secrets/initialAdminPassword"
  register: jenkins_password_content
  become: yes
```
- Jenkins generates random password
- Stored in secrets/initialAdminPassword
- Need sudo to read

6. **Create Systemd Service**

**Template:** `templates/jenkins.service.j2`
```ini
[Unit]
Description=Jenkins Docker Container
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/{{ ansible_user }}/jenkins
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
User={{ ansible_user }}

[Install]
WantedBy=multi-user.target
```

**Purpose:** Auto-start Jenkins on system boot

**Explanation:**
- `Requires=docker.service`: Needs Docker running first
- `Type=oneshot`: Command runs once
- `RemainAfterExit=yes`: Stays "active" after starting
- `ExecStart`: Command to start
- `ExecStop`: Command to stop
- `WantedBy=multi-user.target`: Start at boot

---

### Role: sonarqube/

**Purpose:** Deploy SonarQube code quality analysis + PostgreSQL database

**Special considerations:**
- SonarQube requires PostgreSQL
- Two containers working together
- Special kernel parameters needed

**docker-compose.yml structure:**

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_DB: sonarqube
      POSTGRES_USER: sonar
      POSTGRES_PASSWORD: "{{ sonarqube_db_password }}"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  sonarqube:
    image: sonarqube:community
    depends_on:
      - postgres
    ports:
      - "{{ sonarqube_port }}:9000"
    environment:
      SONAR_JDBC_URL: jdbc:postgresql://postgres:5432/sonarqube
      SONAR_JDBC_USERNAME: sonar
      SONAR_JDBC_PASSWORD: "{{ sonarqube_db_password }}"
    volumes:
      - sonarqube_data:/opt/sonarqube/data
```

**Key features:**
- `depends_on`: SonarQube waits for PostgreSQL
- Database connection via Docker network
- Persistent volumes for both

**System requirements:**
```yaml
- name: Verify vm.max_map_count
  sysctl:
    name: vm.max_map_count
    value: 262144
```
- Elasticsearch (inside SonarQube) requires this
- Without it, SonarQube crashes

---

### Role: nexus/

**Purpose:** Deploy Nexus Repository Manager

**Special challenge: File permissions**

```yaml
- name: Set ownership for Nexus data directory
  file:
    path: "/home/{{ ansible_user }}/nexus/data"
    owner: "200"
    group: "200"
    recurse: yes
```

**Why UID 200?**
- Nexus container runs as user ID 200
- Docker volumes inherit host permissions
- Must match or Nexus can't write

**Exposed ports:**
- `8081`: Web UI
- `5000`: Docker registry

Can push/pull Docker images to/from Nexus!

---

### Role: nginx/

**Purpose:** Reverse proxy and SSL termination

**What is a reverse proxy?**

```
User → Nginx (443) → Jenkins (8080)
     ↑ HTTPS       ↑ HTTP (internal)
```

**Benefits:**
1. Single entry point (port 443)
2. SSL handled by Nginx
3. Can serve multiple apps
4. Load balancing capable

**Nginx configuration structure:**

```nginx
# HTTP server (redirects to HTTPS)
server {
    listen 80;
    server_name jenkins.konpapa.online;
    return 301 https://$host$request_uri;
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name jenkins.konpapa.online;
    
    # SSL certificates (added by certbot later)
    
    # Reverse proxy
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

**Why separate Nginx for each service?**
- Each VM runs one service
- Nginx on same VM as service
- Simpler than one Nginx for all

---

### Role: certbot/

**Purpose:** Obtain and manage SSL certificates from Let's Encrypt

**Process:**
1. Install certbot + nginx plugin
2. Check if certificate exists (don't request duplicates)
3. Request certificate from Let's Encrypt
4. Let's Encrypt validates domain ownership
5. Certificate installed in Nginx
6. Setup auto-renewal cron job

**Auto-renewal:**
```yaml
- name: Setup auto-renewal with cron
  cron:
    name: "Certbot automatic renewal"
    minute: "30"
    hour: "3"
    job: "certbot renew --quiet --post-hook 'systemctl reload nginx'"
```

Runs at 3:30 AM daily, renews 30 days before expiration

**See:** `docs/SSL_CERTBOT_EXPLAINED.md` for full details

---

## 🗂️ ansible/templates/ - Dynamic Configuration

```
templates/
└── inventory-template.j2      # Inventory file generator
```

### What are Jinja2 Templates?

**Jinja2** is a templating language. Think of it as:
- A text file with placeholders
- Variables get replaced with actual values
- Logic and loops supported

**Example:**

**Template:**
```jinja2
Hello {{ name }}!
You have {{ count }} messages.
```

**Variables:**
```yaml
name: "John"
count: 5
```

**Result:**
```
Hello John!
You have 5 messages.
```

### inventory-template.j2

**Purpose:** Generate inventory file with actual VM IPs

**Template snippet:**
```jinja2
[jenkins]
{% for instance in instances %}
{% if 'jenkins' in instance.name %}
{{ instance.name }} ansible_host={{ instance.networkInterfaces[0].accessConfigs[0].natIP }}
{% endif %}
{% endfor %}
```

**How it works:**
1. Loop through all created instances
2. Check if instance name contains 'jenkins'
3. If yes, output: `jenkins-vm ansible_host=34.142.147.236`

**Other templates in roles:**
- `docker-compose.yml.j2`: Docker Compose files with variables
- `nginx.conf.j2`: Nginx configs with domain names
- `*.service.j2`: Systemd service files

---

## 📊 ansible/vars/ - Configuration Values

```
vars/
└── config.yaml               # Single source of truth
```

### config.yaml - The Master Configuration

**Purpose:** ALL configuration in ONE place

**Structure:**

```yaml
# GCP Settings
google_project_id: "my-project-devops-504714"
google_zone: "asia-southeast1-c"

# SSH Settings
ssh_username: "samnangchanserey"
ssh_public_key_path: "/home/samnangchanserey/.ssh/id_ed25519.pub"

# Domain Settings
jenkins_domain: "jenkins.konpapa.online"
sonarqube_domain: "sonarqube.konpapa.online"
nexus_domain: "nexus.konpapa.online"
letsencrypt_email: "admin@konpapa.online"

# Machine Specs
machine_specs:
  medium:
    machine_type: "e2-medium"
    disk_size: 30
  large:
    machine_type: "e2-standard-2"
    disk_size: 50

# VMs to Create
vms:
  - name: "jenkins-vm"
    machine_type: "{{ machine_specs.large.machine_type }}"
    zone: "{{ google_zone }}"
    ...
```

**Why centralized config?**
- Change value once, affects everywhere
- Easy to deploy to different projects/regions
- Clear overview of all settings
- No hardcoded values scattered in code

**To deploy to different environment:**
1. Copy config.yaml to config-prod.yaml
2. Change values (different project, domain, etc.)
3. Run: `ansible-playbook ... --extra-vars "@vars/config-prod.yaml"`

---

## ⚙️ ansible.cfg - Ansible Behavior

```
[defaults]
inventory = inventory/hosts.ini
host_key_checking = False
retry_files_enabled = False
result_format = yaml
```

**What it controls:**

**`inventory`**: Default inventory file location
- Don't need `-i inventory/hosts.ini` every time

**`host_key_checking = False`**: Skip SSH fingerprint confirmation
- Useful for automation
- Slightly less secure (acceptable for our case)

**`retry_files_enabled = False`**: Don't create .retry files
- Cleaner directory

**`result_format = yaml`**: Output format
- More readable than default JSON

**`[privilege_escalation]`**: Sudo settings
```ini
become = False
become_method = sudo
become_ask_pass = False
```
- Don't become root by default
- Use sudo when needed
- Don't prompt for password

---

## 📚 docs/ - Documentation

```
docs/
├── DEPLOYMENT_GUIDE.md              # Complete deployment walkthrough
├── NAMECHEAP_DNS_SETUP.md          # DNS configuration steps
├── CLOUDFLARE_SETUP.md             # Cloudflare integration
├── DNS_FLOW_DIAGRAM.md             # Visual DNS explanations
├── SSL_CERTBOT_EXPLAINED.md        # SSL/TLS deep dive
├── TROUBLESHOOTING.md              # Common issues
└── PROJECT_STRUCTURE_DEEP_DIVE.md  # This file!
```

**Purpose:** Comprehensive documentation for:
- New users
- Future maintenance
- Troubleshooting
- Learning

---

## 🔧 scripts/ - Helper Scripts

```
scripts/
└── bootstrap-controller.sh         # Setup Ansible controller
```

### bootstrap-controller.sh

**Purpose:** Prepare a fresh VM to be Ansible controller

**What it installs:**
1. Ansible + collections
2. Google Cloud SDK (gcloud CLI)
3. Python packages
4. Just command runner
5. GitHub CLI
6. SSH keys generation

**Usage:**
```bash
# On fresh GCP VM
wget https://raw.githubusercontent.com/YOUR_REPO/main/scripts/bootstrap-controller.sh
chmod +x bootstrap-controller.sh
./bootstrap-controller.sh
```

**Why needed?**
- Automates controller setup
- Ensures all dependencies installed
- One-command preparation

---

## 🎯 Justfile - Command Automation

```
Justfile                    # Make-like command runner
```

**Purpose:** Convenient shortcuts for complex commands

**Example:**

**Without Justfile:**
```bash
cd ansible && ansible-playbook -i inventory/bootstrap.ini playbooks/01-create-infrastructure.yaml
```

**With Justfile:**
```bash
just create-infrastructure
```

**Common commands:**
```bash
just create-infrastructure    # Create VMs
just configure-all           # Deploy services
just destroy-infrastructure  # Delete everything
just ping-all               # Test connectivity
just check-services         # Show Docker containers
just get-jenkins-password   # Retrieve password
just show-urls              # Display service URLs
```

**Benefit:** Easy to remember, document, and share

---

## 📖 README.md - Project Overview

**Purpose:** Entry point for anyone viewing the project

**Contains:**
- Quick start guide
- Prerequisites
- Installation steps
- Usage examples
- Architecture diagram
- Link to detailed docs

**Target audience:**
- Developers wanting to use the project
- Recruiters reviewing your portfolio
- Future you (6 months later)

---

## 🎬 Presentation Files

```
PRESENTATION.md                  # Live presentation script
VIDEO_PRESENTATION_SCRIPT.md     # Video recording script
```

**Purpose:** Scripts for explaining the project

**PRESENTATION.MD:** For live demos
- Talking points
- Command cheatsheet
- Q&A preparation

**VIDEO_PRESENTATION_SCRIPT.MD:** For recordings
- Complete narration
- Theory explanations
- Production tips

---

## 🔐 .gitignore - Excluded Files

```
.gitignore                      # Files NOT tracked by git
```

**Example content:**
```
# Ansible
*.retry
.vault_pass
*.log

# Secrets
*secret*
*password*
*.pem
*.key

# Generated
inventory/hosts.ini
gcp_instances.json

# OS
.DS_Store
Thumbs.db
```

**Why?**
- Don't commit secrets
- Don't commit generated files
- Don't commit OS-specific files

---

## 📊 Summary: How It All Fits Together

```
1. USER runs: just create-infrastructure

2. JUSTFILE executes: ansible-playbook ... 01-create-infrastructure.yaml

3. PLAYBOOK loads: vars/config.yaml

4. PLAYBOOK uses: inventory/bootstrap.ini (localhost)

5. PLAYBOOK calls: google.cloud.gcp_compute_instance module

6. GCP API creates: 3 virtual machines

7. PLAYBOOK generates: inventory/hosts.ini (with IPs)

8. USER runs: just configure-all

9. PLAYBOOK: 03-configure-all.yaml

10. PLAYBOOK applies ROLES: common, docker, jenkins, sonarqube, nexus, nginx, certbot

11. ROLES use TEMPLATES: docker-compose.yml.j2, nginx.conf.j2, etc.

12. SERVICES deployed: Jenkins, SonarQube, Nexus all running!

13. USER accesses: https://jenkins.konpapa.online ✨
```

---

## 🎓 Key Concepts Demonstrated

**Infrastructure as Code:**
- Everything defined in code
- Version controlled
- Repeatable

**Modularity:**
- Roles are independent
- Reusable components
- Clear separation of concerns

**Idempotency:**
- Safe to run multiple times
- Only makes necessary changes
- Predictable results

**Configuration Management:**
- Single source of truth (config.yaml)
- Templates for dynamic configs
- Clear variable hierarchy

**Automation:**
- One command deployment
- No manual steps
- Consistent results

---

**This structure represents professional DevOps practices used in industry! 🚀**
