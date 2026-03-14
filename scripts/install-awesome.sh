#!/usr/bin/env bash
# GitHub.com/PiercingXX
# FreeBSD-Mod — Awesome WM installer (X11)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

username=${SUDO_USER:-$(id -un)}

echo -e "${YELLOW}Installing Awesome WM and X11 stack...${NC}"

# ── Xorg display server ───────────────────────────────────────────────────────
sudo pkg install -y \
    xorg \
    xrandr \
    xinit \
    xterm \
    xset \
    xsetroot

# ── Awesome WM ────────────────────────────────────────────────────────────────
sudo pkg install -y \
    awesome \
    lua54 \
    lua54-lgi

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

sudo pw groupmod video -m "$username" 2>/dev/null || true

# ── .xinitrc fallback ─────────────────────────────────────────────────────────
if [ ! -f "$HOME/.xinitrc" ]; then
    cat > "$HOME/.xinitrc" << 'EOF'
#!/bin/sh
exec awesome
EOF
    chmod +x "$HOME/.xinitrc"
fi

# ── Awesome config ────────────────────────────────────────────────────────────
mkdir -p "$HOME/.config/awesome"
if [ ! -f "$HOME/.config/awesome/rc.lua" ]; then
    # Copy the default config from the installed location
    for candidate in \
        /usr/local/share/awesome/lib/awful/rc.lua \
        /usr/local/etc/xdg/awesome/rc.lua \
        /usr/local/share/doc/awesome/rc.lua.gz; do
        if [ -f "$candidate" ]; then
            cp "$candidate" "$HOME/.config/awesome/rc.lua" 2>/dev/null && break
        elif [[ "$candidate" == *.gz ]] && [ -f "$candidate" ]; then
            gzip -dc "$candidate" > "$HOME/.config/awesome/rc.lua" 2>/dev/null && break
        fi
    done

    # If still missing, write a minimal stub
    if [ ! -f "$HOME/.config/awesome/rc.lua" ]; then
        cat > "$HOME/.config/awesome/rc.lua" << 'EOF_LUA'
-- FreeBSD-Mod minimal rc.lua — replace with a full config
-- See https://awesomewm.org/doc/api/documentation/05-awesomerc.md.html
pcall(require, "luarocks.loader")
local awful = require("awful")
require("awful.autofocus")

-- Default terminal and editor
terminal = "kitty"
editor   = os.getenv("EDITOR") or "nvim"
modkey   = "Mod4"

-- Layouts
awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.floating,
    awful.layout.suit.max,
}

-- Key bindings
local globalkeys = require("awful.key")
globalkeys = awful.util.table.join(
    awful.key({ modkey }, "Return", function() awful.spawn(terminal) end),
    awful.key({ modkey }, "d",      function() awful.spawn("rofi -show drun") end),
    awful.key({ modkey, "Shift" }, "r", awesome.restart),
    awful.key({ modkey, "Shift" }, "q", awesome.quit)
)
root.keys(globalkeys)
EOF_LUA
    fi
fi

echo -e "${GREEN}Awesome WM install complete!${NC}"
echo -e "${CYAN}GDM display manager is enabled. Reboot to enter the graphical session.${NC}"
echo -e "${CYAN}Config: ~/.config/awesome/rc.lua${NC}"
echo -e "${CYAN}Tip: Consider bling, beautiful, or a community rc.lua for a richer setup.${NC}"
