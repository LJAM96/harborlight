#!/bin/bash

set -ouex pipefail

echo "Installing Haborlight branding..."

# Create Plymouth theme directory
mkdir -p /usr/share/plymouth/themes/haborlight

# Install Plymouth theme files
cp /ctx/branding/plymouth/haborlight.plymouth /usr/share/plymouth/themes/haborlight/
cp /ctx/branding/plymouth/haborlight.script /usr/share/plymouth/themes/haborlight/
cp /ctx/branding/plymouth/logo.png /usr/share/plymouth/themes/haborlight/
cp /ctx/branding/plymouth/progress_bar.png /usr/share/plymouth/themes/haborlight/

# Set Plymouth theme with error handling
echo "Setting Plymouth theme to Haborlight..."
if plymouth-set-default-theme haborlight 2>/dev/null; then
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
cp /ctx/branding/logos/logo.png /usr/share/pixmaps/haborlight-logo.png
cp /ctx/branding/logos/logo.svg /usr/share/pixmaps/haborlight-logo.svg

# Install Anaconda branding (for ISO installer)
mkdir -p /usr/share/anaconda/pixmaps
cp /ctx/branding/logos/logo.png /usr/share/anaconda/pixmaps/sidebar-logo.png
cp /ctx/branding/logos/logo.png /usr/share/anaconda/pixmaps/topbar-logo.png

# Remove Bluefin branding if present
rm -f /usr/share/pixmaps/bluefin* || true
rm -f /usr/share/anaconda/pixmaps/sidebar-bg.png || true

# Create desktop file for system info
cat > /usr/share/applications/haborlight-info.desktop << EOF
[Desktop Entry]
Name=Haborlight System Info
Comment=Haborlight Operating System Information
Exec=gnome-control-center info
Icon=haborlight-logo
Type=Application
Categories=System;
NoDisplay=true
EOF

# Update hostname configuration
echo "haborlight" > /etc/hostname

# Create issue files for login screen
cat > /etc/issue << EOF
Haborlight \\r (\\l)

EOF

cat > /etc/issue.net << EOF
Haborlight

EOF

# Update motd
cat > /etc/motd << EOF

Welcome to Harborlight!

A custom bootc operating system based on Bluefin Nvidia
featuring LibreWolf browser and dual container support.

EOF

# Remove Bluefin wallpapers and restore GNOME defaults
rm -rf /usr/share/backgrounds/bluefin* || true
rm -rf /usr/share/backgrounds/ublue* || true
rm -rf /usr/share/gnome-background-properties/bluefin* || true
rm -rf /usr/share/gnome-background-properties/ublue* || true

# Reset wallpaper settings to GNOME defaults
gsettings reset org.gnome.desktop.background picture-uri || true
gsettings reset org.gnome.desktop.background picture-uri-dark || true

# Configure GDM branding
mkdir -p /etc/dconf/db/gdm.d
cp /ctx/branding/gdm/01-haborlight /etc/dconf/db/gdm.d/
dconf update

# Configure SDDM branding (if present)
if [ -d "/etc/sddm.conf.d" ]; then
    cp /ctx/branding/sddm/haborlight.conf /etc/sddm.conf.d/
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

echo "Haborlight branding installation complete!"