#!/usr/bin/env bash
# GitHub.com/PiercingXX
# FreeBSD-Mod — Sway installer (Wayland)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

username=${SUDO_USER:-$(id -un)}

echo -e "${YELLOW}Installing Sway and Wayland stack...${NC}"

# ── Sway core ─────────────────────────────────────────────────────────────────
sudo pkg install -y \
    sway \
    swaybg \
    swaylock \
    swayidle \
    xwayland \
    wayland \
    wayland-protocols

# ── Wayland companion tools ───────────────────────────────────────────────────
sudo pkg install -y \
    waybar \
    wofi \
    mako \
    wl-clipboard \
    wlr-randr \
    grim \
    slurp \
    cliphist \
    brightnessctl \
    pamixer \
    playerctl \
    pavucontrol \
    libnotify \
    wf-recorder \
    nwg-look

# ── Policy kit authentication agent ──────────────────────────────────────────
sudo pkg install -y polkit polkit-gnome

# ── Audio (PipeWire) ──────────────────────────────────────────────────────────
sudo pkg install -y \
    pipewire \
    wireplumber

# ── XDG desktop portals ───────────────────────────────────────────────────────
sudo pkg install -y \
    xdg-desktop-portal \
    xdg-desktop-portal-wlr

# ── Display manager (GDM) ─────────────────────────────────────────────────────
sudo pkg install -y gdm
sudo sysrc gdm_enable="YES"
sudo sysrc sddm_enable="NO"

# ── System services ───────────────────────────────────────────────────────────
sudo sysrc dbus_enable="YES"

# evdev passthrough for libinput touch/stylus support
if ! grep -q "kern.evdev.rcpt_mask" /etc/sysctl.conf; then
    echo 'kern.evdev.rcpt_mask=12' | sudo tee -a /etc/sysctl.conf
fi
sudo sysctl kern.evdev.rcpt_mask=12 2>/dev/null || true

sudo pw groupmod video -m "$username" 2>/dev/null || true

# ── Sway config ───────────────────────────────────────────────────────────────
mkdir -p "$HOME/.config/sway"

if [ ! -f "$HOME/.config/sway/config" ]; then
    # Try to copy the system default first, fall back to our stub
    cp /usr/local/etc/sway/config "$HOME/.config/sway/config" 2>/dev/null || \
    cat > "$HOME/.config/sway/config" << 'EOF'
# FreeBSD-Mod — Sway config
# See https://swaywm.org/

set $mod     Mod4
set $term    kitty
set $menu    wofi --show drun

# Wallpaper
output * bg #1e1e2e solid_color

# Font
font pango:FiraCode Nerd Font 10

# Touchpad / tablet input
input "type:touchpad" {
    tap             enabled
    natural_scroll  enabled
    drag_lock       enabled
}
input "type:touch" {
    events enabled
}

# Key bindings
bindsym $mod+Return      exec $term
bindsym $mod+d           exec $menu
bindsym $mod+Shift+q     kill
bindsym $mod+Shift+c     reload
bindsym $mod+Shift+e     exec swaynag -t warning -m 'Exit Sway?' \
    -B 'Yes' 'swaymsg exit'

# Focus
bindsym $mod+Left   focus left
bindsym $mod+Down   focus down
bindsym $mod+Up     focus up
bindsym $mod+Right  focus right

# Move
bindsym $mod+Shift+Left   move left
bindsym $mod+Shift+Down   move down
bindsym $mod+Shift+Up     move up
bindsym $mod+Shift+Right  move right

# Fullscreen / floating
bindsym $mod+f       fullscreen toggle
bindsym $mod+Space   floating toggle

# Layout
bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+e layout toggle split

# Workspaces 1–10
bindsym $mod+1 workspace number 1
bindsym $mod+2 workspace number 2
bindsym $mod+3 workspace number 3
bindsym $mod+4 workspace number 4
bindsym $mod+5 workspace number 5
bindsym $mod+6 workspace number 6
bindsym $mod+7 workspace number 7
bindsym $mod+8 workspace number 8
bindsym $mod+9 workspace number 9
bindsym $mod+0 workspace number 10

bindsym $mod+Shift+1 move container to workspace number 1
bindsym $mod+Shift+2 move container to workspace number 2
bindsym $mod+Shift+3 move container to workspace number 3
bindsym $mod+Shift+4 move container to workspace number 4
bindsym $mod+Shift+5 move container to workspace number 5
bindsym $mod+Shift+6 move container to workspace number 6
bindsym $mod+Shift+7 move container to workspace number 7
bindsym $mod+Shift+8 move container to workspace number 8
bindsym $mod+Shift+9 move container to workspace number 9
bindsym $mod+Shift+0 move container to workspace number 10

# Resize mode
mode "resize" {
    bindsym Left  resize shrink width  10px
    bindsym Down  resize grow   height 10px
    bindsym Up    resize shrink height 10px
    bindsym Right resize grow   width  10px
    bindsym Return mode "default"
    bindsym Escape mode "default"
}
bindsym $mod+r mode "resize"

# Screenshot
bindsym Print            exec grim ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png
bindsym $mod+Shift+s     exec grim -g "$(slurp)" ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png

# Audio
bindsym XF86AudioRaiseVolume  exec pamixer -i 5
bindsym XF86AudioLowerVolume  exec pamixer -d 5
bindsym XF86AudioMute         exec pamixer -t
bindsym XF86AudioPlay         exec playerctl play-pause
bindsym XF86AudioNext         exec playerctl next
bindsym XF86AudioPrev         exec playerctl previous

# Brightness
bindsym XF86MonBrightnessUp   exec brightnessctl set 5%+
bindsym XF86MonBrightnessDown exec brightnessctl set 5%-

# Drag floating windows
floating_modifier $mod normal

# Autostart
exec mako
exec pipewire
exec pipewire-pulse
exec wireplumber
exec /usr/local/libexec/polkit-gnome-authentication-agent-1
exec wl-paste --type text  --watch cliphist store
exec wl-paste --type image --watch cliphist store

bar {
    swaybar_command waybar
}
EOF
fi

echo -e "${GREEN}Sway install complete!${NC}"
echo -e "${CYAN}GDM display manager is enabled. Reboot to enter the graphical session.${NC}"
echo -e "${CYAN}Config: ~/.config/sway/config${NC}"
echo -e "${CYAN}Tip: Run 'sway' from a TTY to test before relying on GDM login.${NC}"
