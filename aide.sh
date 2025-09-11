#!/bin/bash

set -e

echo "Detecting OS type..."
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Cannot detect OS type."
    exit 1
fi

echo "Installing AIDE..."
if [[ "$OS" == "ubuntu" ]]; then
    sudo apt update
    sudo apt install -y aide
elif [[ "$OS" == "ol" || "$OS" == "oracle" || "$OS" == "centos" || "$OS" == "rhel" ]]; then
    sudo yum install -y aide
else
    echo "Unsupported OS: $OS"
    exit 1
fi

echo "Initializing AIDE database..."
sudo aideinit

echo "Activating AIDE database..."
if [ -f /var/lib/aide/aide.db.new.gz ]; then
    sudo mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
else
    echo "AIDE database not found after initialization."
    exit 1
fi

echo "Configuring daily integrity check..."
sudo tee /etc/cron.daily/aide-check > /dev/null << 'EOF'
#!/bin/bash
/usr/bin/aide --check > /var/log/aide/aide-check.log
EOF
sudo chmod +x /etc/cron.daily/aide-check

echo "AIDE installation and configuration completed successfully."