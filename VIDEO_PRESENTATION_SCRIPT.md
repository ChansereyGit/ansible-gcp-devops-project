# Complete Video Presentation Script
## Automated DevOps Infrastructure on GCP using Ansible

**Total Duration:** 35-45 minutes
**Target Audience:** DevOps engineers, students, technical professionals
**Level:** Intermediate to Advanced

---

## 🎬 VIDEO STRUCTURE

### Timeline
- **00:00-02:00** - Introduction & Problem Statement
- **02:00-05:00** - DevOps Concepts & Theory
- **05:00-08:00** - Infrastructure as Code (IaC)
- **08:00-12:00** - Architecture Overview
- **12:00-15:00** - Technology Stack Explanation
- **15:00-18:00** - Project Structure & Organization
- **18:00-35:00** - Live Demo & Implementation
- **35:00-40:00** - Results & Best Practices
- **40:00-45:00** - Q&A & Conclusion

---

## 📝 DETAILED SCRIPT

### SEGMENT 1: Introduction (00:00-02:00)

**[SCREEN: Title slide with your name]**

**YOU:**
> "Hello everyone! Welcome to my presentation on Automated DevOps Infrastructure Deployment on Google Cloud Platform using Ansible. My name is [Your Name], and today I'll show you how to build a production-ready DevOps infrastructure that can be deployed with just one command."

**[SCREEN: Show the three service logos - Jenkins, SonarQube, Nexus]**

**YOU:**
> "In this project, we'll be deploying three critical DevOps tools: Jenkins for continuous integration and delivery, SonarQube for code quality analysis, and Nexus for artifact management. But more importantly, we'll be doing this using Infrastructure as Code principles, making the entire deployment fully automated and reproducible."

**[SCREEN: Show problem statement slide]**

**YOU:**
> "Let me start by explaining the problem we're solving."

---

### SEGMENT 2: Problem Statement & Motivation (02:00-05:00)

**[SCREEN: Traditional manual deployment diagram with sad face emoji]**

**YOU:**
> "In traditional IT operations, setting up a DevOps infrastructure is a time-consuming and error-prone process. Let me walk you through what this typically looks like."

**[SCREEN: Checklist of manual steps appearing one by one]**

**YOU:**
> "First, you need to manually provision virtual machines in your cloud provider. This alone can take 30-60 minutes, depending on how many machines you need and how familiar you are with the cloud console.

> Then, you SSH into each machine and start installing packages. You need to install Docker, Docker Compose, configure firewalls, set up networking, install web servers like Nginx, configure reverse proxies, generate SSL certificates, and finally deploy your applications.

> This process can easily take 2 to 3 hours for experienced engineers. For someone learning, it might take a full day or more."

**[SCREEN: Show problems appearing as red X marks]**

**YOU:**
> "But time isn't the only problem. Manual processes lead to:

> **Inconsistency** - Each deployment might be slightly different. Maybe you forgot to set a configuration parameter on one server. Maybe you installed a different version of software.

> **Human Error** - A single typo in a configuration file can break your entire system. Trust me, we've all been there at 2 AM debugging why nothing works.

> **Documentation Drift** - Your written documentation gets out of date. Six months later, when you need to deploy again, the steps don't match what's actually needed.

> **No Version Control** - You can't easily track what changed between deployments. Rolling back to a previous configuration? Good luck remembering what it was.

> **Knowledge Silos** - Only the person who set it up knows how everything works. If they leave the company, you're in trouble."

**[SCREEN: Show the solution - Infrastructure as Code concept]**

**YOU:**
> "This is where Infrastructure as Code comes in. And that's what we'll be implementing today."

---

### SEGMENT 3: DevOps Concepts & Theory (05:00-08:00)

**[SCREEN: DevOps infinity loop diagram]**

**YOU:**
> "Before we dive into the implementation, let's understand some fundamental DevOps concepts."

#### **The DevOps Philosophy**

**[SCREEN: Traditional Dev vs Ops with wall between them]**

**YOU:**
> "Traditionally, development teams and operations teams worked in silos. Developers would write code and 'throw it over the wall' to operations. Operations would then struggle to deploy and maintain it, often blaming developers for writing code that's hard to deploy."

**[SCREEN: DevOps breaking down the wall]**

**YOU:**
> "DevOps breaks down this wall. It's a cultural shift that emphasizes:

> **Collaboration** - Dev and Ops work together from day one
> **Automation** - Manual processes are automated wherever possible
> **Continuous Integration** - Code is integrated and tested frequently
> **Continuous Delivery** - Software can be released to production at any time
> **Monitoring & Feedback** - Systems are monitored, and feedback loops are short"

#### **Infrastructure as Code (IaC)**

**[SCREEN: Definition of IaC]**

**YOU:**
> "Infrastructure as Code is a key DevOps practice. The idea is simple but powerful: manage and provision infrastructure through code rather than through manual processes.

> Think of it like this - instead of clicking buttons in a web console to create a server, you write code that describes what you want. Then you run that code, and the infrastructure is created automatically.

> This code can be:
> - **Stored in version control** - just like application code
> - **Reviewed and tested** - catch errors before deployment
> - **Reused and shared** - deploy the same infrastructure multiple times
> - **Documented automatically** - the code IS the documentation"

**[SCREEN: IaC benefits diagram]**

**YOU:**
> "The benefits are enormous:

> **Speed** - Deploy in minutes instead of hours
> **Consistency** - Same code = same infrastructure every time
> **Repeatability** - Destroy and recreate identical environments
> **Scalability** - Deploy 1 server or 100 servers with the same effort
> **Cost Savings** - Less time spent on manual work
> **Disaster Recovery** - Rebuild entire infrastructure quickly"

#### **Declarative vs Imperative**

**[SCREEN: Side-by-side comparison]**

**YOU:**
> "There are two main approaches to IaC: Imperative and Declarative.

> **Imperative** is like giving step-by-step instructions:
> - First, create a server
> - Then, install Docker
> - Next, start a container
> - Finally, configure networking

> **Declarative** is like describing the desired end state:
> - I want a server with Docker installed
> - I want this container running
> - I want this network configuration

> Ansible, which we're using today, is primarily declarative with some imperative features. You describe what you want, and Ansible figures out how to make it happen.

> The beauty of declarative IaC is **idempotency** - you can run the same code multiple times, and it will always result in the same state. If something already exists, it won't create it again."

---

### SEGMENT 4: Architecture Overview (08:00-12:00)

**[SCREEN: High-level architecture diagram]**

**YOU:**
> "Now let's look at what we're building today. This is our target architecture."

**[SCREEN: Zoom into architecture diagram showing all components]**

**YOU:**
> "At a high level, we have three virtual machines running on Google Cloud Platform. Each VM runs a specific DevOps tool. Let me break this down:"

#### **Component 1: Jenkins**

**[SCREEN: Jenkins logo and description]**

**YOU:**
> "First, we have Jenkins - the most popular CI/CD tool in the industry.

> **What is Jenkins?**
> Jenkins is an automation server. It monitors your source code repository, and when you push new code, it automatically:
> - Pulls the latest code
> - Runs your build process
> - Executes automated tests
> - Packages your application
> - Deploys to various environments

> **Why Jenkins?**
> - Open source and free
> - Huge plugin ecosystem (1,800+ plugins)
> - Pipeline as Code with Jenkinsfile
> - Widely adopted in industry
> - Active community

> **Our Setup:**
> - Running Jenkins LTS (Long Term Support) version
> - Containerized using Docker
> - Accessible via jenkins.konpapa.online
> - Secured with HTTPS
> - Backed by persistent storage"

#### **Component 2: SonarQube**

**[SCREEN: SonarQube logo and description]**

**YOU:**
> "Second, we have SonarQube - for code quality and security analysis.

> **What is SonarQube?**
> SonarQube performs static code analysis. It scans your source code and detects:
> - Bugs and potential issues
> - Code smells and technical debt
> - Security vulnerabilities
> - Code coverage from tests
> - Complexity metrics

> **Why SonarQube?**
> - Supports 27+ programming languages
> - Integrates with Jenkins pipelines
> - Provides quality gates
> - Tracks technical debt over time
> - Security hotspot detection

> **Our Setup:**
> - Running SonarQube Community Edition
> - Backed by PostgreSQL 16 database
> - Both containerized using Docker Compose
> - Accessible via sonarqube.konpapa.online
> - Optimized for Elasticsearch (vm.max_map_count)
> - Persistent data storage"

#### **Component 3: Nexus**

**[SCREEN: Nexus logo and description]**

**YOU:**
> "Third, we have Nexus Repository Manager - for artifact management.

> **What is Nexus?**
> Nexus is an artifact repository manager. It stores and manages:
> - Maven artifacts (Java libraries)
> - Docker images
> - npm packages (Node.js)
> - Python packages (PyPI)
> - And many more formats

> **Why Nexus?**
> - Central storage for all build artifacts
> - Caching proxy for external repositories
> - Supports private repositories
> - Version management
> - Access control and permissions

> **Our Setup:**
> - Running Nexus Repository OSS (Open Source)
> - Containerized using Docker
> - Exposed on two ports: 8081 (UI) and 5000 (Docker registry)
> - Accessible via nexus.konpapa.online
> - Persistent data with correct permissions (UID 200)"

#### **Network Architecture**

**[SCREEN: Network flow diagram]**

**YOU:**
> "Now let's understand how traffic flows through our system.

> **External Access Flow:**
> 1. User types jenkins.konpapa.online in browser
> 2. DNS resolves to our Jenkins VM's public IP (34.x.x.x)
> 3. Request hits Nginx on port 443 (HTTPS)
> 4. Nginx validates SSL certificate
> 5. Nginx forwards request to Jenkins on port 8080
> 6. Jenkins processes request and returns response
> 7. Response flows back through Nginx to user

> **Why Nginx as Reverse Proxy?**
> - SSL/TLS termination (Nginx handles HTTPS)
> - Single entry point (port 443)
> - Load balancing capabilities
> - Request buffering
> - Static file serving
> - Security layer

> **Security Layers:**
> 1. GCP Firewall rules (port-level access control)
> 2. Nginx reverse proxy (SSL termination)
> 3. Application authentication (Jenkins/SonarQube/Nexus login)
> 4. Optional: Cloudflare WAF and DDoS protection"

**[SCREEN: Infrastructure components summary]**

**YOU:**
> "So in summary, each VM has:
> - Base OS: Ubuntu 24.04 LTS
> - Container runtime: Docker Engine
> - Orchestration: Docker Compose
> - Web server: Nginx (reverse proxy)
> - SSL: Let's Encrypt certificates or Cloudflare Origin
> - Monitoring: Systemd services for auto-start
> - Storage: Docker volumes for persistence"

---

### SEGMENT 5: Technology Stack Deep Dive (12:00-15:00)

**[SCREEN: Technology stack diagram with logos]**

**YOU:**
> "Let's dive deeper into the technologies we're using to build this infrastructure."

#### **Google Cloud Platform (GCP)**

**[SCREEN: GCP logo and services]**

**YOU:**
> "We're using Google Cloud Platform as our cloud provider.

> **Why GCP?**
> - Competitive pricing
> - Global network infrastructure
> - Easy to use API and CLI (gcloud)
> - Good free tier for learning
> - Integration with other Google services
> - Excellent documentation

> **GCP Services We Use:**
> - **Compute Engine** - Virtual machines (VMs)
> - **VPC Network** - Networking and firewall rules
> - **External IPs** - Public internet access
> - **Metadata service** - SSH key injection
> - **Startup scripts** - VM initialization

> **Machine Types:**
> - e2-medium: 2 vCPUs, 4GB RAM (for SonarQube and Nexus)
> - e2-standard-2: 2 vCPUs, 8GB RAM (for Jenkins)
> - These are cost-effective choices that provide good performance

> **Cost Estimate:** Approximately $50-80 per month if running 24/7"

#### **Ansible**

**[SCREEN: Ansible logo and architecture]**

**YOU:**
> "Ansible is our Infrastructure as Code tool. Let me explain why we chose Ansible.

> **What is Ansible?**
> Ansible is an open-source automation platform. It allows you to automate:
> - Provisioning (creating infrastructure)
> - Configuration management (installing and configuring software)
> - Application deployment (deploying applications)
> - Orchestration (coordinating multiple systems)

> **Why Ansible?**
> 1. **Agentless** - No software to install on managed nodes
>    - Uses SSH for Linux/Unix
>    - Uses WinRM for Windows
>    - Simple and secure
>
> 2. **Simple Syntax** - Uses YAML, easy to read and write
>    ```yaml
>    - name: Install Docker
>      apt:
>        name: docker.io
>        state: present
>    ```
>
> 3. **Idempotent** - Safe to run multiple times
>    - Won't create duplicates
>    - Only makes necessary changes
>    - Predictable results
>
> 4. **Powerful** - Despite simplicity, very capable
>    - Extensive module library (6,000+ modules)
>    - Supports all major platforms
>    - Can do anything via shell commands
>
> 5. **Popular** - Industry standard
>    - Used by Netflix, NASA, Apple, and more
>    - Large community
>    - Good documentation

> **Ansible Concepts We Use:**
> - **Playbooks** - YAML files that define automation tasks
> - **Roles** - Reusable collections of tasks
> - **Inventory** - List of hosts to manage
> - **Variables** - Configuration values
> - **Templates** - Jinja2 templates for config files
> - **Modules** - Built-in automation units"

#### **Docker & Docker Compose**

**[SCREEN: Docker logo and container diagram]**

**YOU:**
> "All our applications run in Docker containers. Let me explain why.

> **What is Docker?**
> Docker is a containerization platform. A container is like a lightweight virtual machine that:
> - Packages application + dependencies together
> - Runs isolated from the host system
> - Starts in seconds
> - Uses fewer resources than VMs

> **Why Docker?**
> 1. **Consistency** - "Works on my machine" problem solved
> 2. **Isolation** - Each app runs independently
> 3. **Portability** - Same container runs anywhere
> 4. **Version Control** - Different versions side by side
> 5. **Easy Updates** - Pull new image, restart container
> 6. **Resource Efficiency** - Share host kernel

> **Docker Compose:**
> Docker Compose is a tool for defining multi-container applications.

> Example for SonarQube:
> ```yaml
> services:
>   sonarqube:
>     image: sonarqube:community
>     ports:
>       - 9000:9000
>     depends_on:
>       - postgres
>   
>   postgres:
>     image: postgres:16
>     environment:
>       POSTGRES_DB: sonarqube
> ```

> With one command, Docker Compose:
> - Creates the network
> - Starts PostgreSQL
> - Waits for it to be ready
> - Starts SonarQube
> - Connects them together"

#### **Additional Technologies**

**[SCREEN: Logos of other technologies]**

**YOU:**
> "We also use several other important technologies:

> **Nginx:**
> - High-performance web server
> - Reverse proxy for our applications
> - Handles SSL termination
> - Used by 30% of websites globally

> **Let's Encrypt:**
> - Free SSL certificate authority
> - Automated certificate issuance
> - Certificates valid for 90 days
> - Auto-renewal with Certbot

> **Justfile:**
> - Command runner (like Make but simpler)
> - Provides convenient shortcuts
> - Documents common operations
> - Makes complex commands easy

> **Git & GitHub:**
> - Version control for our code
> - Collaboration and code review
> - CI/CD integration
> - Documentation with README"

---

### SEGMENT 6: Project Structure & Organization (15:00-18:00)

**[SCREEN: Project directory tree]**

**YOU:**
> "Now let's look at how our project is organized. Good organization is crucial for maintainability."

**[SCREEN: Show file tree expanding step by step]**

```
ansible-gcp-devops-project/
├── ansible/
├── docs/
├── scripts/
├── Justfile
└── README.md
```

**YOU:**
> "At the root level, we have four main directories and two key files. Let me walk through each."

#### **ansible/ Directory**

**[SCREEN: Expand ansible directory]**

```
ansible/
├── inventory/
│   ├── bootstrap.ini
│   └── hosts.ini
├── playbooks/
│   ├── 01-create-infrastructure.yaml
│   ├── 02-destroy-infrastructure.yaml
│   └── 03-configure-all.yaml
├── roles/
│   ├── common/
│   ├── docker/
│   ├── jenkins/
│   ├── sonarqube/
│   ├── nexus/
│   ├── nginx/
│   └── certbot/
├── templates/
│   └── inventory-template.j2
├── vars/
│   └── config.yaml
└── ansible.cfg
```

**YOU:**
> "The ansible directory contains all our Infrastructure as Code.

> **inventory/** - Defines what hosts to manage
> - bootstrap.ini: Used for first run (creates infrastructure)
> - hosts.ini: Generated automatically with VM IPs

> **playbooks/** - The main automation scripts
> - 01-create-infrastructure.yaml: Creates GCP VMs
> - 02-destroy-infrastructure.yaml: Deletes everything
> - 03-configure-all.yaml: Installs and configures services

> **roles/** - Modular, reusable components
> Each role handles one specific aspect:
> - common: Base system configuration (packages, limits, sysctl)
> - docker: Docker Engine installation
> - jenkins: Jenkins deployment
> - sonarqube: SonarQube + PostgreSQL deployment
> - nexus: Nexus deployment
> - nginx: Reverse proxy configuration
> - certbot: SSL certificate management

> **templates/** - Dynamic configuration files
> - Uses Jinja2 templating to generate configs
> - Variables are replaced at runtime

> **vars/** - Configuration values
> - config.yaml: Single source of truth
> - All settings in one place

> **ansible.cfg** - Ansible behavior settings
> - Defines defaults
> - SSH settings
> - Output format"

**[SCREEN: Show role structure zoomed in]**

**YOU:**
> "Each role follows a standard structure:

```
roles/jenkins/
├── tasks/
│   └── main.yaml       # Steps to perform
├── templates/
│   ├── docker-compose.yml.j2  # Jenkins compose file
│   ├── jenkins.env.j2         # Environment variables
│   └── jenkins.service.j2     # Systemd service
├── files/
│   └── jenkins-setup.md       # Documentation
└── vars/
    └── main.yaml       # Role-specific variables
```

> This structure makes roles:
> - Self-contained and portable
> - Easy to understand
> - Reusable across projects
> - Testable independently"

#### **docs/ Directory**

**[SCREEN: Show docs directory]**

**YOU:**
> "The docs directory contains comprehensive documentation:

> - **DEPLOYMENT_GUIDE.md**: Step-by-step deployment instructions
> - **NAMECHEAP_DNS_SETUP.md**: DNS configuration with screenshots
> - **CLOUDFLARE_SETUP.md**: Cloudflare CDN integration
> - **DNS_FLOW_DIAGRAM.md**: Visual diagrams and flow charts
> - **TROUBLESHOOTING.md**: Common issues and solutions

> Good documentation is critical. It helps:
> - New team members onboard faster
> - Troubleshoot issues quickly
> - Understand design decisions
> - Maintain the project long-term"

#### **Justfile**

**[SCREEN: Show Justfile excerpt]**

**YOU:**
> "The Justfile provides convenient command shortcuts:

```
# Create all infrastructure
just create-infrastructure

# Configure all services
just configure-all

# Get passwords
just get-jenkins-password

# Destroy everything
just destroy-infrastructure
```

> Without Justfile, you'd need to type:
```bash
cd ansible && ansible-playbook -i inventory/bootstrap.ini playbooks/01-create-infrastructure.yaml
```

> With Justfile, just type:
```bash
just create-infrastructure
```

> Much easier to remember and use!"

---

### SEGMENT 7: Live Demo & Implementation (18:00-35:00)

**[SCREEN: Terminal ready, split screen with GCP console]**

**YOU:**
> "Now, let's see this in action! I'm going to deploy the entire infrastructure from scratch."

#### **Demo Part 1: Pre-Flight Checks (18:00-19:00)**

**[SCREEN: Terminal showing commands]**

**YOU:**
> "First, let's verify our environment is ready."

```bash
# Check GCP authentication
gcloud auth list
```

**YOU (explaining output):**
> "Good! We're authenticated as [your email]. This means Ansible can interact with GCP APIs."

```bash
# Verify project
gcloud config get-value project
```

**YOU:**
> "We're working in project 'my-project-devops-504714'. All our VMs will be created here."

```bash
# Check current VMs (should be empty or show existing ones)
gcloud compute instances list
```

**YOU:**
> "Currently, we have [X VMs or none]. We'll be creating three new ones."

```bash
# Show our configuration
cat ansible/vars/config.yaml
```

**YOU:**
> "This is our single source of configuration. Notice:
> - GCP project and zone
> - SSH key paths  
> - Domain names for each service
> - Machine specifications
> - Service ports
> 
> Everything is defined here. To deploy this same infrastructure in a different project or region, we just change these values."

#### **Demo Part 2: Creating Infrastructure (19:00-23:00)**

**[SCREEN: Show command]**

**YOU:**
> "Now, let's create the infrastructure. One command:"

```bash
just create-infrastructure
```

**[SCREEN: Show output flowing]**

**YOU (explaining as it runs):**
> "Let me explain what's happening in real-time:

> **TASK: Display GCP Project Information**
> We're deploying to project 'my-project-devops-504714' in zone 'asia-southeast1-c'. We'll create three VMs: jenkins-vm, sonarqube-vm, and nexus-vm.

> **TASK: Check if gcloud is authenticated**
> Ansible is verifying we have active GCP credentials. This runs 'gcloud auth list' in the background.

> **TASK: Read SSH public key**
> Ansible is reading our SSH public key from ~/.ssh/id_ed25519.pub. This key will be injected into each VM's metadata, allowing us to SSH into them later.

> **TASK: Create GCP compute instances**
> This is the big one! Ansible is calling the GCP API to create three virtual machines. For each VM, it's:
> 1. Allocating resources (CPU, RAM, disk)
> 2. Attaching to the network
> 3. Assigning an external IP address
> 4. Injecting SSH keys
> 5. Running a startup script

> The startup script does initial configuration:
> - Updates system packages
> - Sets timezone to Asia/Bangkok
> - Disables swap (required for SonarQube's Elasticsearch)
> - Increases vm.max_map_count to 262144
> - Creates a marker file when complete

> This takes about 2-3 minutes. Notice we're not clicking anything in the GCP console - it's all automated!"

**[SCREEN: Switch to GCP Console browser tab]**

**YOU:**
> "Look at the GCP Console - you can see the VMs being created in real-time. Three green checkmarks appearing!"

**[SCREEN: Back to terminal showing completion]**

**YOU:**
> "Perfect! All three VMs created successfully. Look at the output:

```
✓ VMs Created Successfully!

jenkins-vm:
  - External IP: 34.142.147.236
  - Machine Type: e2-standard-2
  - Zone: asia-southeast1-c

sonarqube-vm:
  - External IP: 34.21.213.214
  - Machine Type: e2-medium
  - Zone: asia-southeast1-c

nexus-vm:
  - External IP: 34.21.132.214
  - Machine Type: e2-medium
  - Zone: asia-southeast1-c
```

> Ansible has automatically:
> - Generated the inventory file with these IPs
> - Waited for SSH to be ready
> - Verified connectivity

> Let's verify:"

```bash
cat ansible/inventory/hosts.ini
```

**YOU:**
> "See? The inventory file is populated with the actual IPs. Ansible will use this for subsequent operations."

#### **Demo Part 3: Testing Connectivity (23:00-24:00)**

**YOU:**
> "Before configuring, let's verify we can reach all VMs:"

```bash
just ping-all
```

**[SCREEN: Show successful ping responses]**

**YOU:**
> "Excellent! All three VMs respond with 'pong'. This confirms:
> - SSH is working
> - Firewall allows connection
> - Python is installed (Ansible requirement)
> - We can proceed with configuration"

#### **Demo Part 4: DNS Configuration (24:00-25:30)**

**[SCREEN: Show Namecheap dashboard screenshot or live]**

**YOU:**
> "Before we configure services, we need DNS records. I've already set up:

> In Namecheap's Advanced DNS panel:
> - A Record: jenkins → 34.142.147.236
> - A Record: sonarqube → 34.21.213.214
> - A Record: nexus → 34.21.132.214

> Important: I've disabled Cloudflare proxy (gray cloud, not orange) so DNS points directly to our VMs. This is necessary for Let's Encrypt."

**[SCREEN: Terminal]**

```bash
dig jenkins.konpapa.online +short
dig sonarqube.konpapa.online +short
dig nexus.konpapa.online +short
```

**YOU:**
> "Perfect! DNS is resolving to our actual VM IPs. We're ready to configure."

#### **Demo Part 5: Configuring Services (25:30-32:00)**

**YOU:**
> "Now for the main event - configuring all services with ONE command:"

```bash
just configure-all
```

**[SCREEN: Show playbook output]**

**YOU (narrating the phases as they execute):**

> "**Phase 1: Common Configuration - All VMs**
>
> TASK: Update apt cache - Refreshing package lists
> TASK: Upgrade all packages - Applying security updates
> - This ensures all VMs have latest security patches
> - Takes 1-2 minutes depending on updates available
>
> TASK: Install common packages - curl, wget, git, vim, htop, etc.
> - These are tools we'll need for troubleshooting
>
> TASK: Install Python packages - pyyaml, jmespath, netaddr
> - Using apt instead of pip for Ubuntu 24.04 compatibility
> - This was a challenge we solved during development
>
> TASK: Configure system limits - file descriptors, processes
> - Setting soft/hard limits to 65536
> - Required for high-traffic applications
>
> TASK: Set sysctl parameters - vm.max_map_count, fs.file-max
> - vm.max_map_count=262144 for SonarQube's Elasticsearch
> - Essential for proper operation
>
> TASK: Disable swap permanently
> - Kubernetes and Elasticsearch require swap to be off
> - Editing /etc/fstab to make it permanent"

> "**Phase 2: Docker Installation - All VMs**
>
> TASK: Remove old Docker packages - Clean slate
> TASK: Install Docker prerequisites - apt-transport-https, ca-certificates
> TASK: Add Docker GPG key - Verify package authenticity
> TASK: Add Docker repository - Official Docker packages
> TASK: Install Docker Engine - Latest stable version
>
> TASK: Install Docker Compose
> - Installing both plugin and standalone versions
> - Docker Compose V2 for compatibility
>
> TASK: Add user to docker group
> - Allows running docker without sudo
> - Security best practice
>
> TASK: Create Docker network
> - Custom network for inter-container communication
> - Better than default bridge network
>
> TASK: Start and enable Docker service
> - Systemd manages Docker daemon
> - Auto-start on boot"

> "**Phase 3: Jenkins Deployment**
>
> TASK: Create Jenkins directories
> - /home/samnangchanserey/jenkins
> - /home/samnangchanserey/jenkins/data
>
> TASK: Copy docker-compose.yml
> - Jenkins LTS image
> - Port mapping 8080:8080
> - Volume for persistent data
>
> TASK: Reset SSH connection
> - Refreshes docker group membership
> - Critical fix for permission issues
>
> TASK: Start Jenkins container
> - Docker Compose pulls image (if not cached)
> - Creates volume
> - Starts container
> - Takes ~30 seconds
>
> TASK: Wait for Jenkins to start
> - Checking port 8080
> - Additional 30 second wait for full initialization
>
> TASK: Read initial admin password
> - From /jenkins/data/secrets/initialAdminPassword
> - Using sudo for correct permissions
> - Password displayed in output"

> "**Phase 4: SonarQube Deployment**
>
> Similar process but with two containers:
> - PostgreSQL 16 database
> - SonarQube Community Edition
>
> Docker Compose orchestrates the dependency:
> 1. Starts PostgreSQL first
> 2. Waits for database to be ready
> 3. Starts SonarQube
> 4. Connects them via Docker network
>
> Health check confirms SonarQube API is responding"

> "**Phase 5: Nexus Deployment**
>
> TASK: Set ownership for Nexus data
> - Nexus container runs as UID 200
> - Permission fix before starting
>
> TASK: Start Nexus container
> - Takes longest to initialize (~60 seconds)
> - Generates admin password file
>
> Admin password retrieved from /nexus/data/admin.password"

> "**Phase 6: Nginx Configuration**
>
> For each VM:
> TASK: Install Nginx
> TASK: Configure reverse proxy
> - HTTP to HTTPS redirect
> - Proxy pass to localhost:8080 (or 9000, 8081)
> - WebSocket support for Jenkins
> TASK: Enable site and reload Nginx"

> "**Phase 7: SSL Certificates (if Certbot role runs)**
>
> TASK: Install Certbot
> TASK: Obtain certificates from Let's Encrypt
> - Validates domain ownership via HTTP challenge
> - Issues certificate valid for 90 days
> TASK: Update Nginx for HTTPS
> TASK: Setup auto-renewal cron job"

**[SCREEN: Show final output]**

**YOU:**
> "Complete! Look at this beautiful output:

```
✓ Configuration Complete!

Jenkins:    https://jenkins.konpapa.online
SonarQube:  https://sonarqube.konpapa.online
Nexus:      https://nexus.konpapa.online

Initial Admin Passwords:
- Jenkins: [password]
- Nexus: [password]
- SonarQube: admin/admin
```

> In just 5-8 minutes, we've:
> - Installed and configured Docker on 3 VMs
> - Deployed 4 containers (Jenkins, SonarQube, PostgreSQL, Nexus)
> - Configured 3 Nginx reverse proxies
> - Set up HTTPS with SSL certificates
> - Created systemd services for auto-start

> Manually, this would have taken 2-3 hours!"

#### **Demo Part 6: Accessing Services (32:00-35:00)**

**YOU:**
> "Let's verify everything is working by accessing each service."

**[SCREEN: Open browser to jenkins.konpapa.online]**

**YOU:**
> "Here's Jenkins! Notice:
> - HTTPS is working (green padlock)
> - Professional Jenkins login page
> - Let me enter the admin password...

**[SCREEN: Enter password, show Jenkins dashboard]**

> And we're in! Jenkins is fully operational. I can:
> - Install plugins
> - Create pipelines
> - Configure integrations
> - All ready to go!"

**[SCREEN: Open sonarqube.konpapa.online]**

**YOU:**
> "SonarQube is also up. Login with admin/admin...

> It's asking me to change the password - that's a security best practice. After changing:

**[SCREEN: Show SonarQube dashboard]**

> Here's the SonarQube dashboard. Ready to analyze code quality!"

**[SCREEN: Open nexus.konpapa.online]**

**YOU:**
> "And finally Nexus. Using the admin password we retrieved...

**[SCREEN: Show Nexus repository browser]**

> Perfect! Nexus Repository Manager is running. We can see:
> - Maven repositories
> - Docker registries
> - npm registries
> - All configured and ready!"

**[SCREEN: Terminal]**

**YOU:**
> "Let's verify with curl commands too:"

```bash
curl -I https://jenkins.konpapa.online
curl -I https://sonarqube.konpapa.online  
curl -I https://nexus.konpapa.online
```

**YOU:**
> "All returning HTTP 200 or 403 (which means they're working, just need auth). SSL certificates are valid. Everything is production-ready!"

---

### SEGMENT 8: Results & Best Practices (35:00-40:00)

**[SCREEN: Results summary slide]**

**YOU:**
> "Let's recap what we've accomplished and discuss best practices."

#### **Metrics & Results**

**[SCREEN: Comparison chart]**

**YOU:**
> "Here are the quantifiable results:

> **Time Comparison:**
> - Manual deployment: 2-3 hours
> - Automated deployment: 10-15 minutes
> - **Time saved: 85-90%**

> **Consistency:**
> - Manual: Different every time (human error)
> - Automated: Identical every time (code-driven)

> **Code Statistics:**
> - Total lines of code: ~2,000 lines
> - Ansible playbooks: 3 files
> - Ansible roles: 7 roles
> - Templates: 15+ configuration templates
> - Documentation: 6 comprehensive guides
> - Automation commands: 40+ Justfile recipes

> **Infrastructure Specs:**
> - Virtual Machines: 3 (jenkins, sonarqube, nexus)
> - Total vCPUs: 6
> - Total RAM: 16 GB
> - Total Disk: 150 GB
> - Containers: 4 (Jenkins, SonarQube, PostgreSQL, Nexus)
> - Services: 3 (+ 1 database)
> - Monthly cost: ~$50-80 (if running 24/7)"

#### **Key Features**

**[SCREEN: Features list]**

**YOU:**
> "Our infrastructure has these production-ready features:

> **1. Full Automation**
> - One command creates everything
> - One command destroys everything
> - No manual steps required

> **2. Security**
> - HTTPS everywhere with valid SSL certificates
> - Firewall rules at GCP level
> - Application-level authentication
> - SSH key-based access (no passwords)
> - Optional Cloudflare WAF integration

> **3. Reliability**
> - Systemd services for auto-restart
> - Docker containers for isolation
> - Persistent data storage
> - Health checks and monitoring

> **4. Maintainability**
> - Comprehensive documentation
> - Modular code organization
> - Version controlled in Git
> - Easy to update and modify

> **5. Scalability**
> - Add more VMs easily
> - Increase VM sizes in config
> - Deploy to multiple regions
> - Horizontal scaling ready"

#### **Best Practices Demonstrated**

**[SCREEN: Best practices checklist]**

**YOU:**
> "This project demonstrates industry best practices:

> **Infrastructure as Code:**
> ✓ All infrastructure defined in code
> ✓ Version controlled with Git
> ✓ Idempotent and repeatable
> ✓ Self-documenting

> **Ansible Practices:**
> ✓ Role-based organization
> ✓ Variable separation (vars/config.yaml)
> ✓ Template usage (Jinja2)
> ✓ Idempotent tasks
> ✓ Proper error handling

> **DevOps Practices:**
> ✓ Automation first
> ✓ Immutable infrastructure
> ✓ Configuration management
> ✓ Continuous improvement

> **Security Practices:**
> ✓ HTTPS by default
> ✓ Principle of least privilege
> ✓ Secrets management consideration
> ✓ Regular updates

> **Documentation:**
> ✓ Comprehensive README
> ✓ Deployment guides
> ✓ Architecture diagrams
> ✓ Troubleshooting guides
> ✓ Inline code comments"

#### **Lessons Learned**

**[SCREEN: Challenges and solutions]**

**YOU:**
> "During development, we encountered and solved several challenges:

> **Challenge 1: Ubuntu 24.04 PEP 668**
> - Problem: Python pip packages blocked by externally-managed-environment error
> - Root cause: Ubuntu 24.04 implements PEP 668 for system stability
> - Solution: Use apt packages (python3-yaml) instead of pip
> - Lesson: Always test on target OS version

> **Challenge 2: Docker Group Membership**
> - Problem: User added to docker group but permission denied
> - Root cause: Group membership not active in same SSH session
> - Solution: `meta: reset_connection` in Ansible
> - Lesson: Understand SSH session lifecycle

> **Challenge 3: Container File Permissions**
> - Problem: Can't read password files created by Docker containers
> - Root cause: Files owned by container's internal user (UID 1000 or 200)
> - Solution: Use `become: yes` (sudo) to read as root
> - Lesson: Container users differ from host users

> **Challenge 4: DNS Propagation Timing**
> - Problem: SSL setup fails if run too quickly after DNS changes
> - Root cause: DNS takes 10-30 minutes to propagate globally
> - Solution: Separate SSL setup step, document wait time
> - Lesson: Consider propagation delays in automation

> **Challenge 5: Let's Encrypt with Cloudflare**
> - Problem: Let's Encrypt validation fails with Cloudflare proxy enabled
> - Root cause: Let's Encrypt needs to reach origin server directly
> - Solution: Disable proxy OR use Cloudflare Origin Certificates
> - Lesson: Understand how different technologies interact"

---

### SEGMENT 9: Future Enhancements (40:00-42:00)

**[SCREEN: Future roadmap]**

**YOU:**
> "This project is production-ready, but there's always room for improvement. Here are potential enhancements:

> **Monitoring & Observability:**
> - Add Prometheus for metrics collection
> - Add Grafana for visualization
> - Implement log aggregation (ELK stack)
> - Set up alerting (PagerDuty, Slack)
> - Application Performance Monitoring (APM)

> **High Availability:**
> - Multiple instances of each service
> - Load balancer in front
> - Database replication
> - Automated failover
> - Health checks and auto-recovery

> **Backup & Disaster Recovery:**
> - Automated backup scripts
> - GCP snapshots scheduled
> - Backup to Cloud Storage
> - Tested restore procedures
> - RPO/RTO targets defined

> **Security Hardening:**
> - Secrets management (HashiCorp Vault)
> - Network segmentation
> - Intrusion detection
> - Security scanning (Trivy, Clair)
> - Compliance monitoring

> **Cost Optimization:**
> - Use preemptible VMs for dev
> - Auto-scaling based on load
> - Resource rightsizing
> - Cost monitoring and alerts
> - Reserved instances for prod

> **CI/CD Integration:**
> - GitHub Actions for Ansible testing
> - Automated infrastructure testing
> - Terraform for cloud resources
> - GitOps workflow (ArgoCD)
> - Environment promotion pipeline

> **Multi-Environment Support:**
> - Separate dev/staging/prod environments
> - Environment-specific configurations
> - Promotion workflows
> - Blue-green deployments

> **Kubernetes Migration:**
> - Migrate from Docker Compose to K8s
> - Use Helm charts
> - Implement service mesh (Istio)
> - Auto-scaling
> - Rolling updates"

---

### SEGMENT 10: Conclusion & Takeaways (42:00-45:00)

**[SCREEN: Key takeaways slide]**

**YOU:**
> "Let me summarize the key takeaways from this project:

> **Technical Takeaways:**
> 1. Infrastructure as Code is powerful and practical
> 2. Ansible is simple yet capable
> 3. Docker simplifies application deployment
> 4. Automation saves time and reduces errors
> 5. Good organization makes projects maintainable

> **Professional Skills Demonstrated:**
> - Cloud infrastructure (GCP)
> - Configuration management (Ansible)
> - Containerization (Docker)
> - DevOps tools (Jenkins, SonarQube, Nexus)
> - Networking and security
> - Documentation and communication

> **DevOps Principles Applied:**
> - Automation first
> - Infrastructure as Code
> - Immutable infrastructure
> - Continuous improvement
> - Collaboration through code

> **Project Management:**
> - Clear problem statement
> - Well-defined architecture
> - Iterative development
> - Comprehensive documentation
> - Lessons learned captured"

**[SCREEN: Final thoughts]**

**YOU:**
> "This project demonstrates that modern DevOps practices are accessible and practical. You don't need a massive team or budget to implement automation and Infrastructure as Code.

> What started as manual, error-prone processes lasting hours is now automated, consistent, and completed in minutes. That's the power of DevOps.

> The code is fully open source and available on GitHub. Feel free to:
> - Clone and use for your own projects
> - Modify and adapt to your needs
> - Learn from the code and documentation
> - Contribute improvements back

> Remember: The goal isn't just working code - it's maintainable, documented, automated code that solves real problems."

**[SCREEN: Thank you slide with contact info]**

**YOU:**
> "Thank you for watching! I hope this has been educational and inspiring. If you have questions, feel free to reach out:

> - GitHub: [Your GitHub URL]
> - LinkedIn: [Your LinkedIn]
> - Email: [Your email]

> I'm happy to discuss the project, answer technical questions, or collaborate on improvements.

> Remember: The best way to learn DevOps is to build projects like this. Start small, iterate, and keep improving.

> Good luck with your DevOps journey!"

---

## 🎥 VIDEO PRODUCTION TIPS

### Before Recording

1. **Prepare Demo Environment**
   - Clean GCP project (no existing VMs)
   - DNS records already configured
   - All code pushed to GitHub
   - Terminal with good font size
   - Test full workflow once

2. **Setup Recording Environment**
   - Quiet room
   - Good microphone
   - Clean desktop (close unnecessary apps)
   - Clear browser history/tabs
   - Disable notifications

3. **Prepare Visuals**
   - Slides ready (use Google Slides or PowerPoint)
   - Diagrams exported
   - Code snippets formatted
   - Terminal color scheme readable

### Recording Tips

1. **Audio Quality**
   - Speak clearly and at moderate pace
   - Pause between sentences
   - Use enthusiasm in voice
   - Record in a quiet space
   - Use a good microphone (not laptop built-in)

2. **Video Quality**
   - Record at 1080p minimum
   - Use screen recording software (OBS, Camtasia)
   - Zoom in on important text
   - Use annotations/highlights
   - Keep cursor movement smooth

3. **Presentation Style**
   - Look at camera when speaking
   - Smile (it shows in your voice)
   - Use hand gestures if showing yourself
   - Vary tone to maintain interest
   - Pause for emphasis

4. **Technical Execution**
   - Type commands slowly and clearly
   - Explain before executing
   - Show outputs fully
   - Handle errors gracefully
   - Have backup screenshots

### Post-Production

1. **Editing**
   - Cut long waits (compiling, downloading)
   - Add transitions between sections
   - Insert graphics/diagrams
   - Add captions for key points
   - Background music (soft, non-distracting)

2. **Polish**
   - Fix audio levels
   - Remove background noise
   - Color correction
   - Add intro/outro
   - Timestamps in description

3. **Accessibility**
   - Add subtitles/captions
   - Provide transcript
   - Clear visual design
   - High contrast
   - Large text size

---

## 📝 SCRIPT TIMING GUIDE

### For 30-minute video:
- Cut some theory sections shorter
- Speed through less critical tasks
- Pre-populate some config
- Use fast-forward for long operations

### For 45-minute detailed version:
- Follow script as written
- Show more code
- Explain more concepts
- Take questions from audience

### For 15-minute lightning talk:
- Skip all theory
- Jump straight to demo
- Show key commands only
- Focus on results

---

## ✅ PRE-RECORDING CHECKLIST

- [ ] All code committed and pushed
- [ ] Demo environment clean (no VMs)
- [ ] DNS records configured
- [ ] GCP authenticated
- [ ] SSH keys generated
- [ ] Terminal font large and readable
- [ ] Browser tabs organized
- [ ] Slides ready
- [ ] Backup environment ready (in case live demo fails)
- [ ] Microphone tested
- [ ] Screen recording software tested
- [ ] Notifications disabled
- [ ] Phone on silent
- [ ] Water nearby
- [ ] Full dry run completed
- [ ] Talking points memorized
- [ ] Energy level high!

---

## 🎯 CALL TO ACTION

End your video with:

> "If you found this helpful, please:
> - ⭐ Star the GitHub repository
> - 👍 Like this video
> - 📢 Share with your team
> - 💬 Comment with questions
> - 🔔 Subscribe for more DevOps content
>
> Your feedback helps me create better content. Thanks for watching!"

---

**Good luck with your recording! You've got this! 🚀**
