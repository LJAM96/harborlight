#!/bin/bash

set -ouex pipefail

echo "Installing Harborlight branding..."

# Create Plymouth theme directory
mkdir -p /usr/share/plymouth/themes/harborlight

# Install Plymouth theme files
cp /ctx/branding/plymouth/harborlight.plymouth /usr/share/plymouth/themes/harborlight/
cp /ctx/branding/plymouth/harborlight.script /usr/share/plymouth/themes/harborlight/
cp /ctx/branding/plymouth/logo.png /usr/share/plymouth/themes/harborlight/
cp /ctx/branding/plymouth/progress_bar.png /usr/share/plymouth/themes/harborlight/

# Set Plymouth theme with error handling
echo "Setting Plymouth theme to Harborlight..."
if plymouth-set-default-theme harborlight 2>/dev/null; then
    echo "✓ Plymouth theme set successfully"
else
    echo "⚠ Warning: Could not set Plymouth theme, checking script module..."
    if [ ! -f "/usr/lib64/plymouth/script.so" ]; then
        echo "✗ Plymouth script module missing, theme may not work properly"
    else
        echo "? Plymouth theme setting failed for unknown reason"
    fi
fi

# Update system identification
cp /ctx/branding/os-release /etc/os-release
cp /ctx/branding/os-release /usr/lib/os-release

# Install system logos
mkdir -p /usr/share/pixmaps
cp /ctx/branding/logos/logo.png /usr/share/pixmaps/harborlight-logo.png
cp /ctx/branding/logos/logo.svg /usr/share/pixmaps/harborlight-logo.svg

# Install Anaconda branding (for ISO installer)
mkdir -p /usr/share/anaconda/pixmaps
cp /ctx/branding/logos/logo.png /usr/share/anaconda/pixmaps/sidebar-logo.png
cp /ctx/branding/logos/logo.png /usr/share/anaconda/pixmaps/topbar-logo.png

# Remove Bluefin branding if present
rm -f /usr/share/pixmaps/bluefin* || true
rm -f /usr/share/anaconda/pixmaps/sidebar-bg.png || true

# Remove additional Bluefin logos that might appear in About page
rm -f /usr/share/pixmaps/fedora-logo* || true
rm -f /usr/share/pixmaps/system-logo-white.png || true
rm -f /etc/fedora-release || true

# Override any vendor logos
ln -sf /usr/share/pixmaps/harborlight-logo.png /usr/share/pixmaps/fedora-logo.png || true
ln -sf /usr/share/pixmaps/harborlight-logo.png /usr/share/pixmaps/system-logo-white.png || true

# Create desktop file for system info
cat > /usr/share/applications/harborlight-info.desktop << EOF
[Desktop Entry]
Name=Harborlight System Info
Comment=Harborlight Operating System Information
Exec=gnome-control-center info
Icon=harborlight-logo
Type=Application
Categories=System;
NoDisplay=true
EOF

# Update hostname configuration
echo "harborlight" > /etc/hostname

# Create issue files for login screen
cat > /etc/issue << EOF
Harborlight \\r (\\l)

EOF

cat > /etc/issue.net << EOF
Harborlight

EOF

# Update motd
cat /ctx/branding/logo_ascii.txt > /etc/motd
cat >> /etc/motd << 'EOF'

  ╔══════════════════════════════════════════════════════════════════════════╗
  ║                        Welcome to Harborlight!                           ║
  ╚══════════════════════════════════════════════════════════════════════════╝

  A custom bootc operating system based on Bluefin Nvidia
  • LibreWolf browser for enhanced privacy
  • Docker & Podman dual container engine support
  • Enhanced development tools

  Documentation: https://github.com/LJAM96/harborlight
  Report issues: https://github.com/LJAM96/harborlight/issues

EOF

# Ensure MOTD is displayed in shell sessions
mkdir -p /etc/profile.d
cat > /etc/profile.d/harborlight-motd.sh << 'EOF'
# Display MOTD for interactive shells
if [ -f /etc/motd ] && [ -n "$PS1" ]; then
    cat /etc/motd
fi
EOF
chmod +x /etc/profile.d/harborlight-motd.sh

# Remove any Bluefin MOTD scripts
rm -f /etc/profile.d/bluefin* || true

# Install Fluent icon theme
echo "Installing Fluent icon theme..."
cd /tmp
if git clone --depth=1 https://github.com/vinceliuice/Fluent-icon-theme.git 2>/dev/null; then
    cd Fluent-icon-theme
    if ./install.sh -d /usr/share/icons; then
        echo "✓ Fluent icon theme installed"
    else
        echo "⚠ Warning: Fluent icon theme installation failed, falling back to Adwaita"
    fi
    cd /tmp
    rm -rf Fluent-icon-theme
else
    echo "⚠ Warning: Could not clone Fluent icon theme repository, falling back to Adwaita"
fi

# Remove Bluefin wallpapers and restore GNOME defaults
rm -rf /usr/share/backgrounds/bluefin* || true
rm -rf /usr/share/backgrounds/ublue* || true
rm -rf /usr/share/gnome-background-properties/bluefin* || true
rm -rf /usr/share/gnome-background-properties/ublue* || true

# Remove any Bluefin GDM backgrounds
rm -f /usr/share/backgrounds/default.png || true
rm -f /usr/share/backgrounds/default.jpg || true

# Reset wallpaper settings to GNOME defaults
gsettings reset org.gnome.desktop.background picture-uri || true
gsettings reset org.gnome.desktop.background picture-uri-dark || true

# Configure GDM branding
mkdir -p /etc/dconf/db/gdm.d
cp /ctx/branding/gdm/01-harborlight /etc/dconf/db/gdm.d/
dconf update

# Configure user defaults for icon theme
mkdir -p /etc/dconf/db/local.d
cat > /etc/dconf/db/local.d/01-harborlight-defaults << EOF
[org/gnome/desktop/interface]
icon-theme='Fluent'
EOF
dconf update

# Configure SDDM branding (if present)
if [ -d "/etc/sddm.conf.d" ]; then
    cp /ctx/branding/sddm/harborlight.conf /etc/sddm.conf.d/
fi

# Remove existing Plymouth themes that might conflict
rm -rf /usr/share/plymouth/themes/bluefin* || true
rm -rf /usr/share/plymouth/themes/spinner || true

# Rebuild Plymouth initrd
echo "Rebuilding Plymouth initrd..."
if dracut -f 2>/dev/null; then
    echo "✓ Plymouth initrd rebuilt successfully"
else
    echo "⚠ Warning: Could not rebuild Plymouth initrd"
fi

echo "Harborlight branding installation complete!"