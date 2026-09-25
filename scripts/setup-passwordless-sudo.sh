#!/bin/bash

# ============================================================================
# Setup Passwordless Sudo for Current User
# ============================================================================
# This script configures the current user to use sudo without password
# Run this ONCE on a new VM before running bootstrap-controller.sh
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/YOUR_REPO/main/scripts/setup-passwordless-sudo.sh | bash
#
# OR:
#   wget https://raw.githubusercontent.com/YOUR_REPO/main/scripts/setup-passwordless-sudo.sh
#   chmod +x setup-passwordless-sudo.sh
#   ./setup-passwordless-sudo.sh
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Setup Passwordless Sudo${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Get current username
CURRENT_USER=$(whoami)

echo -e "${BLUE}[INFO]${NC} Setting up passwordless sudo for user: ${YELLOW}${CURRENT_USER}${NC}"
echo ""

# Check if already configured
if sudo -n true 2>/dev/null; then
    echo -e "${GREEN}[SUCCESS]${NC} Passwordless sudo already configured!"
    exit 0
fi

echo -e "${YELLOW}[IMPORTANT]${NC} You will be prompted for your password ONE TIME."
echo -e "${YELLOW}[IMPORTANT]${NC} After this, sudo will work without password."
echo ""

# Create sudoers file for current user
SUDOERS_FILE="/etc/sudoers.d/90-${CURRENT_USER}-nopasswd"

# This command requires password
sudo bash -c "cat > ${SUDOERS_FILE} << EOF
# Allow ${CURRENT_USER} to use sudo without password
# Created by setup-passwordless-sudo.sh on $(date)
${CURRENT_USER} ALL=(ALL) NOPASSWD: ALL
EOF"

# Set correct permissions
sudo chmod 0440 "${SUDOERS_FILE}"

# Validate sudoers file
if sudo visudo -c -f "${SUDOERS_FILE}" > /dev/null 2>&1; then
    echo -e "${GREEN}[SUCCESS]${NC} Sudoers file created and validated"
else
    echo -e "${RED}[ERROR]${NC} Sudoers file validation failed!"
    sudo rm -f "${SUDOERS_FILE}"
    exit 1
fi

# Test passwordless sudo
if sudo -n true 2>/dev/null; then
    echo -e "${GREEN}[SUCCESS]${NC} Passwordless sudo is now active!"
    echo ""
    echo -e "${GREEN}✓${NC} You can now run commands with sudo without entering a password"
    echo -e "${GREEN}✓${NC} Run the bootstrap script: ./bootstrap-controller.sh"
else
    echo -e "${RED}[ERROR]${NC} Something went wrong. Please check configuration."
    exit 1
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Done!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
