#!/bin/bash

set -ouex pipefail

### Remove unwanted Flatpaks
# Remove Firefox and Thunderbird Flatpaks that come with Bluefin
flatpak remove --system -y org.mozilla.firefox || true
flatpak remove --system -y org.mozilla.Thunderbird || true

### Install LibreWolf Flatpak
flatpak install --system -y flathub io.gitlab.librewolf-community

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
dnf5 install -y tmux

# Install libldm and Docker
dnf5 install -y libldm docker docker-compose

# Install Plymouth scripts for custom themes
dnf5 install -y plymouth-scripts

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Enable Container Services

# Enable Docker daemon and socket
systemctl enable docker.service
systemctl enable docker.socket

# Enable Podman socket (for rootless and system use)
systemctl enable podman.socket

# Add docker group (users will be added to this group at runtime)
groupadd -f docker

# Ensure podman and docker can coexist
# Podman is already included in Bluefin, just enabling services

### Install Haborlight Branding
# Replace all Bluefin branding with Haborlight branding
/ctx/branding/install-branding.sh

### Install and Enable libldm Service
# Install libldm systemd service for Local Data Manager
echo "Installing libldm service..."
if cp /ctx/services/libldm.service /etc/systemd/system/; then
    echo "✓ libldm service file installed"
    if systemctl enable libldm.service; then
        echo "✓ libldm service enabled"
    else
        echo "⚠ Warning: Could not enable libldm service"
    fi
else
    echo "✗ Error: Could not install libldm service file"
fi
