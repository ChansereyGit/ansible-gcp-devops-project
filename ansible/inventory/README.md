# Ansible Inventory

This directory contains the Ansible inventory files.

## Files

- **`hosts.ini`** - Auto-generated inventory file (created by `01-create-infrastructure.yaml`)
  - **DO NOT EDIT MANUALLY!** This file is regenerated each time you create infrastructure
  - Contains actual IP addresses of created VMs
  - Excluded from git (see `.gitignore`)

- **`hosts.ini.example`** - Example inventory structure
  - Shows what the inventory looks like
  - Safe to commit to git

## Inventory Structure

The inventory is organized into the following groups:

### Host Groups

- **`[jenkins]`** - Jenkins CI/CD server
- **`[sonarqube]`** - SonarQube code quality server
- **`[nexus]`** - Nexus repository manager
- **`[controller]`** - Ansible controller VM (optional)
- **`[localhost]`** - Local connection to controller

### Parent Groups

- **`[app_servers]`** - All application servers (jenkins + sonarqube + nexus)
- **`[gcp_vms]`** - All GCP VMs

## Usage

Test connectivity to all hosts:
```bash
ansible -m ping all
```

Test specific group:
```bash
ansible -m ping jenkins
ansible -m ping sonarqube
ansible -m ping nexus
```

List all hosts in inventory:
```bash
ansible-inventory --list
```

Show inventory graph:
```bash
ansible-inventory --graph
```

## Variables

Common variables set for all hosts:

- `ansible_user` - SSH user (from config.yaml)
- `ansible_python_interpreter` - Python interpreter path
- `ansible_ssh_private_key_file` - SSH private key location
- `ansible_ssh_extra_args` - Additional SSH arguments

## Regenerating Inventory

The inventory is automatically regenerated when you create infrastructure:

```bash
just create-infrastructure
```

Or manually run the playbook:
```bash
cd ansible
ansible-playbook playbooks/01-create-infrastructure.yaml
```
