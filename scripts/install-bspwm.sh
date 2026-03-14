#!/usr/bin/env bash
# GitHub.com/PiercingXX
# FreeBSD-Mod — BSPWM Window Manager installer (X11)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

username=${SUDO_USER:-$(id -un)}

echo -e "${YELLOW}Installing BSPWM and X11 stack...${NC}"

# ── Xorg display server ───────────────────────────────────────────────────────
sudo pkg install -y \
    xorg \
    xrandr \
    xinit \
    xterm \
    xset \
    xsetroot

# ── BSPWM + hotkey daemon ─────────────────────────────────────────────────────
sudo pkg install -y \
    bspwm \
    sxhkd

# ── X11 companion tools ───────────────────────────────────────────────────────
sudo pkg install -y \
    polybar \
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

sudo pw groupmod video -m "$username" 2>/dev/null || true

# ── .xinitrc fallback ─────────────────────────────────────────────────────────
if [ ! -f "$HOME/.xinitrc" ]; then
    cat > "$HOME/.xinitrc" << 'EOF'
#!/bin/sh
exec bspwm
EOF
    chmod +x "$HOME/.xinitrc"
fi

# ── BSPWM config ─────────────────────────────────────────────────────────────
mkdir -p "$HOME/.config/bspwm" "$HOME/.config/sxhkd"

if [ ! -f "$HOME/.config/bspwm/bspwmrc" ]; then
    cat > "$HOME/.config/bspwm/bspwmrc" << 'EOF'
#!/bin/sh
# FreeBSD-Mod — minimal bspwmrc

sxhkd &
picom -b &
dunst &
feh --bg-scale ~/.config/wallpaper.png 2>/dev/null || xsetroot -solid "#1e1e2e" &
polybar main &

bspc monitor -d 1 2 3 4 5 6 7 8 9 10

bspc config border_width         2
bspc config window_gap           10
bspc config split_ratio          0.52
bspc config borderless_monocle   true
bspc config gapless_monocle      true

# Colors
bspc config focused_border_color  "#89b4fa"
bspc config normal_border_color   "#313244"
EOF
    chmod +x "$HOME/.config/bspwm/bspwmrc"
fi

# ── sxhkd keybindings ────────────────────────────────────────────────────────
if [ ! -f "$HOME/.config/sxhkd/sxhkdrc" ]; then
    cat > "$HOME/.config/sxhkd/sxhkdrc" << 'EOF'
# FreeBSD-Mod — sxhkdrc

# Terminal
super + Return
    kitty

# Launcher
super + d
    rofi -show drun

# Close focused node
super + shift + q
    bspc node -c

# Quit / restart bspwm
super + alt + {q,r}
    bspc {quit,wm -r}

# Toggle fullscreen
super + f
    bspc node -t fullscreen

# Toggle floating
super + shift + space
    bspc node -t floating

# Focus node in direction
super + {Left,Down,Up,Right}
    bspc node -f {west,south,north,east}

# Move node
super + shift + {Left,Down,Up,Right}
    bspc node -s {west,south,north,east}

# Switch workspace
super + {1-9,0}
    bspc desktop -f '^{1-9,10}'

# Move node to workspace
super + shift + {1-9,0}
    bspc node -d '^{1-9,10}'
EOF
fi

echo -e "${GREEN}BSPWM install complete!${NC}"
echo -e "${CYAN}GDM display manager is enabled. Reboot to enter the graphical session.${NC}"
echo -e "${CYAN}Configs: ~/.config/bspwm/bspwmrc and ~/.config/sxhkd/sxhkdrc${NC}"
