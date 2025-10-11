#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
dnf5 install -y tmux libldm docker freerdp

# Remove Firefox and Thunderbird flatpaks, install LibreWolf
flatpak remove -y org.mozilla.firefox org.mozilla.Thunderbird || true
flatpak install -y flathub io.gitlab.librewolf-community

### Install Fluent icon theme
# Try to clone and install from GitHub, with fallback if unavailable
ICON_THEME_URL="https://github.com/vinceliuice/Fluent-icon-theme.git"
ICON_THEME_DIR="/tmp/fluent-icon-theme"

if git clone --depth 1 "$ICON_THEME_URL" "$ICON_THEME_DIR" 2>/dev/null; then
    echo "Installing Fluent icon theme from GitHub..."
    cd "$ICON_THEME_DIR"
    ./install.sh -a || echo "Warning: Fluent icon theme installation encountered issues"
    cd -
    rm -rf "$ICON_THEME_DIR"
else
    echo "Warning: Could not clone Fluent icon theme from GitHub. Keeping default icons."
fi

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket
