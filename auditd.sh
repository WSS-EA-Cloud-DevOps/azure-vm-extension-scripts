#!/bin/bash

set -e

echo "🔍 Detecting Linux distribution..."

# Detect distro
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "❌ Cannot detect Linux distribution."
    exit 1
fi

echo "📦 Installing auditd on $DISTRO..."

case "$DISTRO" in
    ubuntu|debian)
        sudo apt update
        sudo apt install -y auditd audispd-plugins
        ;;
    rhel|centos|rocky|almalinux|fedora)
        sudo yum install -y audit
        ;;
    suse|opensuse-leap)
        sudo zypper install -y audit
        ;;
    *)
        echo "❌ Unsupported Linux distribution: $DISTRO"
        exit 1
        ;;
esac

echo "⚙️ Configuring auditd..."

# Enable and start auditd
sudo systemctl enable auditd
sudo systemctl start auditd

# Create basic audit rules
cat <<EOF | sudo tee /etc/audit/rules.d/basic.rules
# Watch for changes to sensitive files
-w /etc/passwd -p wa -k passwd_changes
-w /etc/shadow -p wa -k shadow_changes

# Monitor sudo usage
-w /usr/bin/sudo -p x -k sudo_usage

# Monitor login/authentication logs
-w /var/log/auth.log -p r -k auth_events
-w /var/log/secure -p r -k login_events

# Monitor audit config changes
-w /etc/audit/ -p wa -k audit_config

# Monitor execution of binaries
-a always,exit -F arch=b64 -S execve -k exec_monitor
-a always,exit -F arch=b32 -S execve -k exec_monitor
EOF

# Apply rules
sudo augenrules --load

echo "✅ auditd installation and configuration complete on $DISTRO."