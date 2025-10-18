#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs packages from fedora repos
dnf5 install -y \
    tmux \
    git \
    libldm \
    docker \
    virt-install \
    libvirt-daemon-config-network \
    libvirt-daemon-kvm \
    qemu-kvm \
    virt-manager \
    virt-viewer \
    libguestfs-tools \
    python3-libguestfs \
    virt-top \
    freerdp

### Install Fluent icon theme system-wide

FLUENT_TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${FLUENT_TMP_DIR}"' EXIT

git clone --depth 1 https://github.com/vinceliuice/Fluent-icon-theme.git "${FLUENT_TMP_DIR}/Fluent-icon-theme"

# Install all variants into /usr/share/icons so they are available system-wide
"${FLUENT_TMP_DIR}/Fluent-icon-theme/install.sh" -a -d /usr/share/icons

### Set GNOME default icon theme

mkdir -p /etc/dconf/profile
if [[ -f /etc/dconf/profile/user ]]; then
    if ! grep -q '^system-db:local$' /etc/dconf/profile/user; then
        printf '\n%s\n' "system-db:local" >> /etc/dconf/profile/user
    fi
else
    cat <<'EOF' > /etc/dconf/profile/user
user-db:user
system-db:local
EOF
fi

mkdir -p /etc/dconf/db/local.d
cat <<'EOF' > /etc/dconf/db/local.d/00-harborlight-theme
[org/gnome/desktop/interface]
icon-theme='Fluent'
EOF

dconf update

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket
systemctl enable docker
systemctl enable libvirtd

### Local Data Manager service

cat <<'EOF' > /etc/systemd/system/ldm.service
[Unit]
Description=Local Data Manager
Before=local-fs-pre.target

[Service]
Type=forking
User=root
ExecStart=/usr/bin/ldmtool create all
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl enable ldm.service
