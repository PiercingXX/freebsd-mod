#!/usr/bin/env bash
# GitHub.com/PiercingXX
# FreeBSD-Mod — GNOME Desktop installer

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

username=${SUDO_USER:-$(id -un)}

echo -e "${YELLOW}Installing GNOME Desktop...${NC}"
echo -e "${CYAN}This is a large install and may take several minutes.${NC}"

# ── GNOME metapackage ─────────────────────────────────────────────────────────
sudo pkg install -y gnome

# ── Optional GNOME extras ─────────────────────────────────────────────────────
sudo pkg install -y \
    gnome-tweaks \
    dconf \
    gnome-shell-extension-manager \
    nautilus \
    gedit

# ── Audio (PipeWire — GNOME 44+ prefers PipeWire) ────────────────────────────
sudo pkg install -y \
    pipewire \
    wireplumber

# ── Enable required services ──────────────────────────────────────────────────
echo -e "${YELLOW}Enabling GNOME services in /etc/rc.conf...${NC}"

sudo sysrc dbus_enable="YES"
sudo sysrc gdm_enable="YES"
sudo sysrc sddm_enable="NO"
sudo sysrc avahi_daemon_enable="YES"
sudo sysrc moused_nondefault_enable="YES"

# evdev passthrough for libinput (touch events in GNOME on Wayland)
if ! grep -q "kern.evdev.rcpt_mask" /etc/sysctl.conf; then
    echo 'kern.evdev.rcpt_mask=12' | sudo tee -a /etc/sysctl.conf
fi
sudo sysctl kern.evdev.rcpt_mask=12 2>/dev/null || true

# Start dbus now so the rest of the session can use it
sudo service dbus start 2>/dev/null || true

# ── Add user to required groups ───────────────────────────────────────────────
sudo pw groupmod video  -m "$username" 2>/dev/null || true
sudo pw groupmod wheel  -m "$username" 2>/dev/null || true

# ── PiercingXX GNOME customizations (from piercing-dots) ────────────────────
builddir=$(cd .. && pwd)
if gum confirm "Apply PiercingXX GNOME customizations from piercing-dots?"; then
    echo -e "${YELLOW}Cloning piercing-dots for GNOME customizations...${NC}"
    rm -rf "$builddir/piercing-dots"
    git clone --depth 1 https://github.com/Piercingxx/piercing-dots.git "$builddir/piercing-dots" && {
        if [ -f "$builddir/piercing-dots/scripts/gnome-customizations.sh" ]; then
            chmod u+x "$builddir/piercing-dots/scripts/gnome-customizations.sh"
            bash "$builddir/piercing-dots/scripts/gnome-customizations.sh"
            wait
            echo -e "${GREEN}GNOME customizations applied!${NC}"
        else
            echo -e "${YELLOW}gnome-customizations.sh not found in piercing-dots — skipping.${NC}"
        fi
        rm -rf "$builddir/piercing-dots"
    } || echo -e "${RED}Failed to clone piercing-dots. Skipping GNOME customizations.${NC}"
fi

echo -e "${GREEN}GNOME install complete!${NC}"
echo -e "${CYAN}GDM (GNOME Display Manager) is enabled as the login screen.${NC}"
echo -e "${CYAN}Reboot to start GNOME. On first boot it may take a moment to initialize.${NC}"
echo -e "${CYAN}Post-login: use GNOME Tweaks to fine-tune fonts, themes, and extensions.${NC}"
