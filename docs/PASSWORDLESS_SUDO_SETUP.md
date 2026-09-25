# Passwordless Sudo Setup Guide

## Why Passwordless Sudo?

When running automation scripts like `bootstrap-controller.sh`, you need to install packages which requires `sudo`. Without configuration, you'll be prompted for password multiple times, which:
- Interrupts automation
- Requires you to watch the script
- Breaks unattended execution
- Annoying for repeated runs

**Solution:** Configure passwordless sudo for your user account.

---

## ⚠️ Security Considerations

### Is This Safe?

**On Cloud VMs:** ✅ Generally safe because:
- VMs are isolated
- SSH key authentication required
- Firewall protected
- Short-lived (can be destroyed/recreated)
- GCP has additional security layers

**On Production Servers:** ⚠️ Use with caution
- Consider restricting to specific commands
- Use for service accounts only
- Audit logs carefully
- Consider alternatives (Ansible vault, etc.)

**On Personal Machines:** ❌ NOT recommended
- Use standard sudo with password
- More secure

### Our Use Case

For this DevOps learning project:
- ✅ Running on isolated GCP VMs
- ✅ Short-lived infrastructure
- ✅ SSH key protected
- ✅ Can destroy and recreate anytime
- ✅ **Safe to use passwordless sudo**

---

## 🚀 Quick Setup (Recommended)

### Step 1: Download the script

```bash
# On your controller VM (jenkins-server)
cd ~
wget https://raw.githubusercontent.com/YOUR_REPO/main/scripts/setup-passwordless-sudo.sh
chmod +x setup-passwordless-sudo.sh
```

### Step 2: Run the script

```bash
./setup-passwordless-sudo.sh
```

**You'll see:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Setup Passwordless Sudo
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[INFO] Setting up passwordless sudo for user: samnangchanserey

[IMPORTANT] You will be prompted for your password ONE TIME.
[IMPORTANT] After this, sudo will work without password.

[sudo] password for samnangchanserey: ████████

[SUCCESS] Sudoers file created and validated
[SUCCESS] Passwordless sudo is now active!

✓ You can now run commands with sudo without entering a password
✓ Run the bootstrap script: ./bootstrap-controller.sh

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Done!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 3: Test it

```bash
# This should work without password prompt
sudo whoami
# Output: root

sudo apt update
# No password prompt!
```

### Step 4: Run bootstrap script

```bash
./bootstrap-controller.sh
# No password prompts! 🎉
```

---

## 🔧 What the Script Does

The script creates a file in `/etc/sudoers.d/` with the following content:

```bash
# /etc/sudoers.d/90-samnangchanserey-nopasswd
samnangchanserey ALL=(ALL) NOPASSWD: ALL
```

**Breakdown:**
- `samnangchanserey`: Your username
- `ALL=(ALL)`: Can run commands as any user
- `NOPASSWD:`: No password required
- `ALL`: Can run all commands

**File permissions:** `0440` (read-only, required for sudo)

**Validation:** Script validates syntax with `visudo -c` before applying

---

## 🛠️ Manual Setup (Alternative)

If you prefer to do it manually:

### Method 1: Using visudo (Safest)

```bash
# Open sudoers file
sudo visudo

# Add this line at the end:
samnangchanserey ALL=(ALL) NOPASSWD: ALL

# Save and exit (Ctrl+X, Y, Enter)
```

**Advantages:**
- Validates syntax automatically
- Prevents breaking sudo
- Standard method

### Method 2: Create sudoers.d file

```bash
# Create file
sudo bash -c 'echo "samnangchanserey ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/90-samnangchanserey-nopasswd'

# Set permissions
sudo chmod 0440 /etc/sudoers.d/90-samnangchanserey-nopasswd

# Validate
sudo visudo -c -f /etc/sudoers.d/90-samnangchanserey-nopasswd
```

---

## ✅ Verification

### Test 1: Simple Command

```bash
sudo whoami
# Expected: root (no password prompt)
```

### Test 2: Non-Interactive Check

```bash
sudo -n true && echo "Passwordless sudo works!" || echo "Password required"
# Expected: "Passwordless sudo works!"
```

### Test 3: Check Configuration

```bash
sudo cat /etc/sudoers.d/90-*-nopasswd
# Shows your configuration file
```

### Test 4: Validate Syntax

```bash
sudo visudo -c
# Expected: parsed OK
```

---

## 🔄 Reverting (Removing Passwordless Sudo)

If you want to go back to password-required sudo:

```bash
# Remove the configuration file
sudo rm /etc/sudoers.d/90-${USER}-nopasswd

# Test - should now require password
sudo whoami
[sudo] password for samnangchanserey: ████████
```

---

## 🐛 Troubleshooting

### Issue 1: "sudo: ... is not in the sudoers file"

**Cause:** User not in sudo group

**Fix:**
```bash
# On Ubuntu, add user to sudo group
sudo usermod -aG sudo $USER

# Logout and login again
exit
# SSH back in

# Verify
groups
# Should show: ... sudo ...
```

### Issue 2: Still prompts for password

**Cause:** Configuration file not created or wrong permissions

**Check:**
```bash
ls -la /etc/sudoers.d/
# Should show: -r--r----- 1 root root ... 90-yourname-nopasswd
```

**Fix permissions:**
```bash
sudo chmod 0440 /etc/sudoers.d/90-*-nopasswd
```

### Issue 3: "sudo: syntax error"

**Cause:** Typo in sudoers file

**Fix:**
```bash
# Remove broken file
sudo rm /etc/sudoers.d/90-*-nopasswd

# Try again with correct syntax
```

### Issue 4: Works for some commands, not others

**Cause:** You might have multiple sudoers entries with different rules

**Check:**
```bash
sudo cat /etc/sudoers
sudo cat /etc/sudoers.d/*
```

**Fix:** Ensure `NOPASSWD: ALL` comes last (overrides previous rules)

---

## 📊 Different Sudo Configurations

### 1. No Password for All Commands (Our Setup)
```
user ALL=(ALL) NOPASSWD: ALL
```
✅ No password for any sudo command
⚠️ Most permissive

### 2. No Password for Specific Commands Only
```
user ALL=(ALL) NOPASSWD: /usr/bin/apt, /usr/bin/systemctl
```
✅ More secure
❌ Password required for other commands

### 3. Normal Sudo (Default)
```
user ALL=(ALL) ALL
```
⚠️ Password required every time
⚠️ Cached for 15 minutes after first use

### 4. No Sudo Access
```
# User not in sudoers file
```
❌ Cannot use sudo at all

---

## 🎯 Best Practices

### For Learning/Development VMs ✅
```bash
# Passwordless sudo is fine
user ALL=(ALL) NOPASSWD: ALL
```

### For Production Servers ⚠️
```bash
# Service accounts with specific commands only
serviceuser ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart myapp, \
                                /usr/bin/systemctl status myapp
```

### For Shared Systems ❌
```bash
# Always require password
# Don't use NOPASSWD
```

---

## 🔐 Security Best Practices

1. **Use on Isolated VMs Only**
   - Don't use on shared systems
   - Don't use on production with sensitive data

2. **Audit Regularly**
   ```bash
   # Check who has passwordless sudo
   sudo grep -r NOPASSWD /etc/sudoers.d/
   ```

3. **Limit to Specific Commands (Production)**
   ```bash
   user ALL=(ALL) NOPASSWD: /path/to/specific/command
   ```

4. **Use Service Accounts**
   - Create dedicated user for automation
   - Don't use personal account

5. **Monitor Sudo Usage**
   ```bash
   # View sudo logs
   sudo cat /var/log/auth.log | grep sudo
   ```

6. **Remove When Done**
   - After project, delete the VM
   - Or remove passwordless config

---

## 📝 Summary

### Quick Reference

**Setup:**
```bash
# Download and run
wget https://raw.githubusercontent.com/YOUR_REPO/main/scripts/setup-passwordless-sudo.sh
chmod +x setup-passwordless-sudo.sh
./setup-passwordless-sudo.sh
```

**Test:**
```bash
sudo -n true && echo "Works!" || echo "Doesn't work"
```

**Remove:**
```bash
sudo rm /etc/sudoers.d/90-${USER}-nopasswd
```

### When to Use

✅ **Use when:**
- Learning environment
- Isolated cloud VMs
- Short-lived infrastructure
- Running automation scripts
- Development/testing

❌ **Don't use when:**
- Production servers
- Shared systems
- Sensitive data present
- Compliance requirements
- Personal computers

---

## 🎓 Understanding Sudoers File

### File Locations

```
/etc/sudoers              # Main config (edit with visudo)
/etc/sudoers.d/*         # Drop-in configs (easier to manage)
```

### Syntax

```
user_or_group HOST=(USER:GROUP) [NOPASSWD:] COMMANDS
```

**Examples:**

```bash
# User john can run all commands as any user, no password
john ALL=(ALL) NOPASSWD: ALL

# User jane can run specific commands as root
jane ALL=(root) NOPASSWD: /usr/bin/systemctl, /usr/bin/apt

# Group admin can run all commands
%admin ALL=(ALL) ALL

# User bob can run commands as user www-data
bob ALL=(www-data) /usr/bin/php
```

### Priority

Files are processed in this order:
1. `/etc/sudoers`
2. `/etc/sudoers.d/*` (alphabetically)

**Last rule wins!** That's why our file is named `90-*` (high number = processed late)

---

**Your bootstrap script will now run smoothly without password interruptions! 🚀**
