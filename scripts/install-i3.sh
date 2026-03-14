#!/usr/bin/env bash
# GitHub.com/PiercingXX
# FreeBSD-Mod — i3 Window Manager installer (X11)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

username=${SUDO_USER:-$(id -un)}

echo -e "${YELLOW}Installing i3 and X11 stack...${NC}"

# ── Xorg display server ───────────────────────────────────────────────────────
sudo pkg install -y \
    xorg \
    xrandr \
    xinit \
    xterm \
    xset \
    xsetroot

# ── i3 window manager suite ───────────────────────────────────────────────────
sudo pkg install -y \
    i3 \
    i3status \
    i3lock \
    i3blocks

# ── X11 companion tools ───────────────────────────────────────────────────────
sudo pkg install -y \
    rofi \
    picom \
    dunst \
    feh \
    nitrogen \
    lxappearance \
    xclip \
    xdotool \
    arandr \
    pavucontrol \
    playerctl \
    brightnessctl \
    libnotify

# ── Display manager (GDM) ─────────────────────────────────────────────────────
sudo pkg install -y gdm
sudo sysrc gdm_enable="YES"
sudo sysrc sddm_enable="NO"

# ── System services ───────────────────────────────────────────────────────────
sudo sysrc dbus_enable="YES"
sudo sysrc moused_enable="YES"
sudo sysrc moused_nondefault_enable="YES"

# Add user to video group for DRI/GPU access
sudo pw groupmod video -m "$username" 2>/dev/null || true

# ── Minimal .xinitrc fallback (used when launching via startx) ────────────────
if [ ! -f "$HOME/.xinitrc" ]; then
    cat > "$HOME/.xinitrc" << 'EOF'
#!/bin/sh
exec i3
EOF
    chmod +x "$HOME/.xinitrc"
fi

# ── Minimal i3 config stub ────────────────────────────────────────────────────
mkdir -p "$HOME/.config/i3"
if [ ! -f "$HOME/.config/i3/config" ]; then
    cp /usr/local/etc/i3/config "$HOME/.config/i3/config" 2>/dev/null || \
    cat > "$HOME/.config/i3/config" << 'EOF'
# FreeBSD-Mod — minimal i3 config
set $mod Mod4

font pango:FiraCode Nerd Font 10

# Terminal
bindsym $mod+Return exec kitty

# Launcher
bindsym $mod+d exec rofi -show drun

# Kill window
bindsym $mod+Shift+q kill

# Reload / restart / exit
bindsym $mod+Shift+c reload
bindsym $mod+Shift+r restart
bindsym $mod+Shift+e exec i3-nagbar -t warning -m 'Exit i3?' \
    -B 'Yes' 'i3-msg exit'

# Focus
bindsym $mod+Left  focus left
bindsym $mod+Down  focus down
bindsym $mod+Up    focus up
bindsym $mod+Right focus right

# Move
bindsym $mod+Shift+Left  move left
bindsym $mod+Shift+Down  move down
bindsym $mod+Shift+Up    move up
bindsym $mod+Shift+Right move right

# Workspaces
bindsym $mod+1 workspace number 1
bindsym $mod+2 workspace number 2
bindsym $mod+3 workspace number 3
bindsym $mod+4 workspace number 4
bindsym $mod+5 workspace number 5
bindsym $mod+Shift+1 move container to workspace number 1
bindsym $mod+Shift+2 move container to workspace number 2
bindsym $mod+Shift+3 move container to workspace number 3
bindsym $mod+Shift+4 move container to workspace number 4
bindsym $mod+Shift+5 move container to workspace number 5

# Layout
bindsym $mod+f fullscreen toggle
bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+e layout toggle split
bindsym $mod+Shift+space floating toggle

floating_modifier $mod

# Autostart
exec --no-startup-id picom -b
exec --no-startup-id dunst
exec --no-startup-id feh --bg-scale ~/.config/wallpaper.png 2>/dev/null || \
    exec --no-startup-id xsetroot -solid "#1e1e2e"

bar {
    status_command i3status
}
EOF
fi

echo -e "${GREEN}i3 install complete!${NC}"
echo -e "${CYAN}GDM display manager is enabled. Reboot to enter the graphical session.${NC}"
echo -e "${CYAN}Config: ~/.config/i3/config${NC}"
