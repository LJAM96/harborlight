#!/bin/bash

set -ouex pipefail

### Install packages

# Ensure COPR plugin and RPM Fusion repositories are available
dnf5 install -y dnf5-plugins
fedora_version="$(rpm -E %fedora)"
dnf5 install -y \
    "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_version}.noarch.rpm" \
    "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_version}.noarch.rpm"

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs packages from fedora repos
dnf5 install -y \
    tmux \
    git \
    libldm \
    moby-engine \
    docker-compose \
    virt-install \
    libvirt-daemon-config-network \
    libvirt-daemon-kvm \
    qemu-kvm \
    virt-manager \
    virt-viewer \
    libguestfs-tools \
    python3-libguestfs \
    virt-top \
    freerdp \
    curl

### Remove unwanted RPM packages

dnf5 remove -y \
    gnome-shell-extension-logo-menu \
    bluefin-backgrounds \
    bluefin-cli-logos \
    bluefin-faces \
    bluefin-fastfetch \
    bluefin-logos \
    bluefin-plymouth \
    bluefin-schemas || true

### Apply Harborlight branding assets

if [[ -d /ctx/branding ]]; then
    find /ctx/branding -name '.DS_Store' -delete

    if [[ -d /ctx/branding/usr/share ]]; then
        cp -a /ctx/branding/usr/share/. /usr/share/
    fi

    if [[ -d /ctx/branding/usr/lib/systemd/system ]]; then
        for unit in /ctx/branding/usr/lib/systemd/system/*.service; do
            [[ -f "${unit}" ]] || continue
            if grep -q '^\[Unit\]' "${unit}"; then
                cp -a "${unit}" /usr/lib/systemd/system/
            else
                echo "Skipping invalid systemd unit template: ${unit}" >&2
            fi
        done
    fi
fi

### Install Docker Compose plugin (CLI v2)

mkdir -p /usr/libexec/docker/cli-plugins
curl -L "https://github.com/docker/compose/releases/download/v2.29.7/docker-compose-linux-x86_64" -o /usr/libexec/docker/cli-plugins/docker-compose
chmod +x /usr/libexec/docker/cli-plugins/docker-compose

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
systemctl enable docker.service
systemctl enable docker.socket
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

### Ensure newly created users can access Docker

install -d /usr/libexec/harborlight

cat <<'EOF' > /usr/libexec/harborlight/add-docker-group.sh
#!/bin/bash
set -euo pipefail

awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd | while read -r username; do
    if ! id -nG "${username}" | grep -qw docker; then
        usermod -aG docker "${username}"
    fi
done
EOF

chmod 0755 /usr/libexec/harborlight/add-docker-group.sh

cat <<'EOF' > /etc/systemd/system/docker-user-group.service
[Unit]
Description=Ensure all users belong to the docker group
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/libexec/harborlight/add-docker-group.sh

[Install]
WantedBy=multi-user.target
EOF

cat <<'EOF' > /etc/systemd/system/docker-user-group.path
[Unit]
Description=Watch for new users to add them to the docker group

[Path]
PathChanged=/etc/passwd
Unit=docker-user-group.service

[Install]
WantedBy=multi-user.target
EOF

systemctl enable docker-user-group.service
systemctl enable docker-user-group.path