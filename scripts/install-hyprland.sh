#!/usr/bin/env bash
# GitHub.com/PiercingXX
# FreeBSD-Mod — Hyprland installer (Wayland)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

username=${SUDO_USER:-$(id -un)}

echo -e "${YELLOW}Installing Hyprland and Wayland stack...${NC}"

# ── Hyprland core ─────────────────────────────────────────────────────────────
sudo pkg install -y \
    hyprland \
    xwayland \
    wayland \
    wayland-protocols \
    wlroots

# ── Wayland companion tools ───────────────────────────────────────────────────
sudo pkg install -y \
    waybar \
    fuzzel \
    mako \
    wl-clipboard \
    wlr-randr \
    grim \
    slurp \
    swaylock \
    swayidle \
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

# ── XDG desktop portals (screensharing, file pickers) ────────────────────────
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

# ── Hyprland config ───────────────────────────────────────────────────────────
mkdir -p "$HOME/.config/hypr"

if [ ! -f "$HOME/.config/hypr/hyprland.conf" ]; then
    cat > "$HOME/.config/hypr/hyprland.conf" << 'EOF'
# FreeBSD-Mod — Hyprland config
# See https://wiki.hyprland.org/Configuring/

monitor = , preferred, auto, 1

$terminal = kitty
$menu     = fuzzel

env = XCURSOR_SIZE, 24
env = QT_QPA_PLATFORM, wayland
env = XDG_CURRENT_DESKTOP, Hyprland
env = XDG_SESSION_TYPE, wayland
env = XDG_SESSION_DESKTOP, Hyprland

input {
    kb_layout  = us
    touchpad {
        natural_scroll = true
        tap-to-click   = true
        drag_lock      = true
    }
    sensitivity = 0
}

general {
    gaps_in             = 5
    gaps_out            = 10
    border_size         = 2
    col.active_border   = rgba(89b4faee) rgba(cba6f7ee) 45deg
    col.inactive_border = rgba(313244aa)
    layout              = dwindle
}

decoration {
    rounding = 8
    blur {
        enabled           = true
        size              = 4
        passes            = 2
        new_optimizations = true
    }
    drop_shadow   = true
    shadow_range  = 8
    shadow_render_power = 3
}

animations {
    enabled = true
    bezier  = ease, 0.4, 0, 0.2, 1
    animation = windows,     1, 4,  ease
    animation = windowsOut,  1, 4,  ease, popin 80%
    animation = border,      1, 10, default
    animation = fade,        1, 6,  ease
    animation = workspaces,  1, 4,  ease
}

dwindle {
    pseudotile      = true
    preserve_split  = true
}

gestures {
    workspace_swipe           = true
    workspace_swipe_fingers   = 3
}

misc {
    force_default_wallpaper = 0
}

# ── Keybinds ──────────────────────────────────────────────────────────────────
$mod = SUPER

bind  = $mod,       Return,      exec,            $terminal
bind  = $mod,       D,           exec,            $menu
bind  = $mod,       Q,           killactive,
bind  = $mod SHIFT, E,           exit,
bind  = $mod,       F,           fullscreen,      0
bind  = $mod,       Space,       togglefloating,
bind  = $mod,       P,           pseudo,
bind  = $mod,       J,           togglesplit,

# Focus
bind  = $mod, Left,  movefocus, l
bind  = $mod, Right, movefocus, r
bind  = $mod, Up,    movefocus, u
bind  = $mod, Down,  movefocus, d

# Move
bind  = $mod SHIFT, Left,  movewindow, l
bind  = $mod SHIFT, Right, movewindow, r
bind  = $mod SHIFT, Up,    movewindow, u
bind  = $mod SHIFT, Down,  movewindow, d

# Resize (hold mod + right-click drag)
bindm = $mod, mouse:272, movewindow
bindm = $mod, mouse:273, resizewindow

# Workspaces 1–10
bind  = $mod,       1, workspace, 1
bind  = $mod,       2, workspace, 2
bind  = $mod,       3, workspace, 3
bind  = $mod,       4, workspace, 4
bind  = $mod,       5, workspace, 5
bind  = $mod,       6, workspace, 6
bind  = $mod,       7, workspace, 7
bind  = $mod,       8, workspace, 8
bind  = $mod,       9, workspace, 9
bind  = $mod,       0, workspace, 10

bind  = $mod SHIFT, 1, movetoworkspace, 1
bind  = $mod SHIFT, 2, movetoworkspace, 2
bind  = $mod SHIFT, 3, movetoworkspace, 3
bind  = $mod SHIFT, 4, movetoworkspace, 4
bind  = $mod SHIFT, 5, movetoworkspace, 5
bind  = $mod SHIFT, 6, movetoworkspace, 6
bind  = $mod SHIFT, 7, movetoworkspace, 7
bind  = $mod SHIFT, 8, movetoworkspace, 8
bind  = $mod SHIFT, 9, movetoworkspace, 9
bind  = $mod SHIFT, 0, movetoworkspace, 10

# Swipe workspaces on touchpad
bind  = $mod, mouse_down, workspace, e+1
bind  = $mod, mouse_up,   workspace, e-1

# Screenshot
bind  = , Print, exec, grim ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png
bind  = $mod SHIFT, S, exec, grim -g "$(slurp)" ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png

# Audio
bind  = , XF86AudioRaiseVolume,  exec, pamixer -i 5
bind  = , XF86AudioLowerVolume,  exec, pamixer -d 5
bind  = , XF86AudioMute,         exec, pamixer -t
bind  = , XF86AudioPlay,         exec, playerctl play-pause
bind  = , XF86AudioNext,         exec, playerctl next
bind  = , XF86AudioPrev,         exec, playerctl previous

# Brightness
bind  = , XF86MonBrightnessUp,   exec, brightnessctl set 5%+
bind  = , XF86MonBrightnessDown, exec, brightnessctl set 5%-

# ── Autostart ─────────────────────────────────────────────────────────────────
exec-once = waybar
exec-once = mako
exec-once = pipewire
exec-once = pipewire-pulse
exec-once = wireplumber
exec-once = /usr/local/libexec/polkit-gnome-authentication-agent-1
exec-once = cliphist wipe
exec-once = wl-paste --type text  --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
EOF
fi

echo -e "${GREEN}Hyprland install complete!${NC}"
echo -e "${CYAN}GDM display manager is enabled. Reboot to enter the graphical session.${NC}"
echo -e "${CYAN}Config: ~/.config/hypr/hyprland.conf${NC}"
echo -e "${CYAN}Tip: Run 'Hyprland' from a TTY to test before relying on GDM login.${NC}"
