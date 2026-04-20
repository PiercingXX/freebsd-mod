#!/usr/bin/env bash
# GitHub.com/PiercingXX
# FreeBSD-Mod — Post-install desktop setup script
# Designed for FreeBSD on tablets, low-powered hardware, and headless-to-desktop installs.

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ── Root check ────────────────────────────────────────────────────────────────
if [[ $EUID -eq 0 ]]; then
    echo "This script should not be executed as root! Exiting..."
    exit 1
fi

# ── Helper: check if a command exists ────────────────────────────────────────
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ── Cache sudo credentials ────────────────────────────────────────────────────
cache_sudo_credentials() {
    echo "Caching sudo credentials for script execution..."
    sudo -v
    (while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &)
}

# ── Network check ─────────────────────────────────────────────────────────────
if command_exists nmcli; then
    state=$(nmcli -t -f STATE g)
    if [[ "$state" != connected ]]; then
        echo "Network connectivity is required to continue."
        exit 1
    fi
else
    # FreeBSD fallback: check for non-loopback inet address
    if ! ifconfig | grep "inet " | grep -qv "127.0.0.1"; then
        echo "Network connectivity is required to continue."
        exit 1
    fi
fi

if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    echo "Network connectivity is required to continue."
    exit 1
fi

# ── Bootstrap pkg if needed ───────────────────────────────────────────────────
if ! command_exists pkg; then
    echo -e "${YELLOW}Bootstrapping pkg...${NC}"
    env ASSUME_ALWAYS_YES=YES /usr/sbin/pkg bootstrap
fi

# ── Ensure gum is installed ───────────────────────────────────────────────────
if ! command_exists gum; then
    echo -e "${YELLOW}gum not found. Installing via pkg...${NC}"
    sudo pkg install -y gum || {
        echo "Failed to install gum. Please run: sudo pkg install gum"
        exit 1
    }
fi

# ── Ensure bash is installed (required for subscripts) ───────────────────────
if ! command_exists bash; then
    echo -e "${YELLOW}bash not found. Installing...${NC}"
    sudo pkg install -y bash
fi

# ── Variables ─────────────────────────────────────────────────────────────────
# Prefer the original user when invoked via sudo
username=${SUDO_USER:-$(id -un)}
builddir=$(pwd)

cache_sudo_credentials

# ── Apply piercing-dots dotfiles ──────────────────────────────────────────────
apply_piercing_dots() {
    echo -e "${YELLOW}Cloning PiercingXX dotfiles (piercing-dots)...${NC}"
    rm -rf "$builddir/piercing-dots"
    git clone --depth 1 https://github.com/Piercingxx/piercing-dots.git "$builddir/piercing-dots" || {
        echo -e "${RED}Failed to clone piercing-dots. Check your internet connection.${NC}"
        return 1
    }
    cd "$builddir/piercing-dots" || return 1

    # Run the main dotfiles installer
    if [ -f install.sh ]; then
        chmod u+x install.sh
        ./install.sh
        wait
    fi

    # Copy .bashrc
    if [ -f resources/bash/.bashrc ]; then
        cp -f resources/bash/.bashrc "/home/${username}/.bashrc"
        # shellcheck source=/dev/null
        source "/home/${username}/.bashrc" 2>/dev/null || true
        echo -e "${GREEN}.bashrc applied from piercing-dots.${NC}"
    fi

    cd "$builddir" || return 1
    rm -rf "$builddir/piercing-dots"
    echo -e "${GREEN}PiercingXX dotfiles applied successfully!${NC}"
}

# ── Helper functions ──────────────────────────────────────────────────────────
msg_box() {
    gum style \
        --border double \
        --margin "1 2" \
        --padding "1 2" \
        --foreground 212 \
        "$1" | gum pager
}

menu() {
    gum choose \
        "Install FreeBSD Mini Mod (Base Setup)" \
        "Apply PiercingXX Dotfiles" \
        "Install Window Manager" \
        "Install GPU Drivers" \
        "Configure Touchscreen Support" \
        "Configure Bluetooth" \
    "Rotate TTY Clockwise" \
        "Reboot System" \
        "Exit"
}

wm_menu() {
    # --no-limit allows selecting multiple WMs (Space toggles, Enter confirms)
    gum choose --no-limit \
        "i3 (X11)" \
        "BSPWM (X11)" \
        "Awesome WM (X11)" \
        "Hyprland (Wayland)" \
        "Sway (Wayland)" \
        "GNOME"
}

gpu_menu() {
    gum choose \
        "Intel (drm-kmod / i915kms)" \
        "AMD GCN+ (drm-kmod / amdgpu)" \
        "AMD Legacy (drm-kmod / radeonkms)" \
        "NVIDIA (proprietary nvidia-driver)" \
        "Back"
}

run_wm_install_script() {
    local label="$1"
    local script_name="$2"

    echo -e "${YELLOW}Installing ${label}...${NC}"
    chmod u+x "$script_name"
    if ! ./"$script_name"; then
        echo -e "${RED}${label} install encountered errors. Check output above.${NC}"
        return 1
    fi
    echo -e "${GREEN}${label} installed successfully.${NC}"
}

# ── Main loop ─────────────────────────────────────────────────────────────────
while true; do
    clear
    echo -e "${BLUE}PiercingXX's FreeBSD-Mod Script${NC}"
    echo -e "${CYAN}FreeBSD Desktop Setup — Tablets & Low-Power Hardware${NC}"
    echo -e "${GREEN}Welcome, ${username}${NC}\n"

    choice=$(menu)

    case $choice in

        "Install FreeBSD Mini Mod (Base Setup)")
            echo -e "${YELLOW}Installing base packages and essentials...${NC}"
            cd scripts || exit 1
            chmod u+x step-1.sh
            ./step-1.sh
            wait
            cd "$builddir" || exit 1
            echo -e "${GREEN}Base setup complete!${NC}"
            echo -e "${YELLOW}Applying PiercingXX dotfiles...${NC}"
            apply_piercing_dots
            msg_box "Base install and dotfiles complete. Select 'Install Window Manager' next."
            ;;

        "Apply PiercingXX Dotfiles")
            apply_piercing_dots
            ;;

        "Install Window Manager")
            echo -e "${CYAN}Select one or more window managers (Space = toggle, Enter = confirm):${NC}\n"
            wm_choices=$(wm_menu)

            if [[ -z "$wm_choices" ]]; then
                echo -e "${YELLOW}No selection made.${NC}"
            else
                cd scripts || exit 1
                while IFS= read -r wm; do
                    case "$wm" in
                        "i3 (X11)")
                            run_wm_install_script "i3" "install-i3.sh"
                            ;;
                        "BSPWM (X11)")
                            run_wm_install_script "BSPWM" "install-bspwm.sh"
                            ;;
                        "Awesome WM (X11)")
                            run_wm_install_script "Awesome WM" "install-awesome.sh"
                            ;;
                        "Hyprland (Wayland)")
                            run_wm_install_script "Hyprland" "install-hyprland.sh"
                            ;;
                        "Sway (Wayland)")
                            run_wm_install_script "Sway" "install-sway.sh"
                            ;;
                        "GNOME")
                            run_wm_install_script "GNOME" "install-gnome.sh"
                            ;;
                    esac
                done <<< "$wm_choices"
                cd "$builddir" || exit 1
                msg_box "Window manager installation complete. Reboot to enter your desktop."
            fi
            ;;

        "Install GPU Drivers")
            echo -e "${CYAN}Select your GPU type:${NC}\n"
            gpu_choice=$(gpu_menu)

            case "$gpu_choice" in
                "Intel (drm-kmod / i915kms)")
                    echo -e "${YELLOW}Installing Intel GPU driver (drm-kmod)...${NC}"
                    sudo pkg install -y drm-kmod
                    sudo sysrc kld_list+=" i915kms"
                    sudo pw groupmod video -m "$username" 2>/dev/null || true
                    echo -e "${GREEN}Intel driver configured. Reboot to activate.${NC}"
                    ;;
                "AMD GCN+ (drm-kmod / amdgpu)")
                    echo -e "${YELLOW}Installing AMD GCN+ GPU driver (drm-kmod / amdgpu)...${NC}"
                    sudo pkg install -y drm-kmod
                    sudo sysrc kld_list+=" amdgpu"
                    sudo pw groupmod video -m "$username" 2>/dev/null || true
                    echo -e "${GREEN}AMD GCN+ driver configured. Reboot to activate.${NC}"
                    ;;
                "AMD Legacy (drm-kmod / radeonkms)")
                    echo -e "${YELLOW}Installing AMD Legacy GPU driver (drm-kmod / radeonkms)...${NC}"
                    sudo pkg install -y drm-kmod
                    sudo sysrc kld_list+=" radeonkms"
                    sudo pw groupmod video -m "$username" 2>/dev/null || true
                    echo -e "${GREEN}AMD Legacy driver configured. Reboot to activate.${NC}"
                    ;;
                "NVIDIA (proprietary nvidia-driver)")
                    echo -e "${YELLOW}Installing NVIDIA proprietary driver...${NC}"
                    sudo pkg install -y nvidia-driver nvidia-settings nvidia-xconfig
                    sudo sysrc kld_list+=" nvidia-modeset"
                    sudo nvidia-xconfig 2>/dev/null || true
                    echo -e "${GREEN}NVIDIA driver configured. Reboot to activate.${NC}"
                    ;;
                "Back")
                    ;;
            esac
            ;;

        "Configure Touchscreen Support")
            echo -e "${YELLOW}Configuring touchscreen support...${NC}"
            sudo pkg install -y xf86-input-evdev xf86-input-libinput
            sudo sysrc moused_enable="YES"
            sudo sysrc moused_nondefault_enable="YES"
            sudo sysrc devd_enable="YES"
            # evdev passthrough lets libinput see raw touch events
            if ! grep -q "kern.evdev.rcpt_mask" /etc/sysctl.conf; then
                echo 'kern.evdev.rcpt_mask=12' | sudo tee -a /etc/sysctl.conf
            fi
            sudo sysctl kern.evdev.rcpt_mask=12
            echo -e "${GREEN}Touchscreen support configured.${NC}"
            echo -e "${CYAN}Note: libinput tap-to-click and natural scroll are enabled by default in WM configs.${NC}"
            ;;

        "Configure Bluetooth")
            echo -e "${YELLOW}Configuring Bluetooth services...${NC}"
            sudo sysrc bluetooth_enable="YES"
            sudo sysrc hcsecd_enable="YES"
            sudo sysrc sdpd_enable="YES"
            sudo sysrc bthidd_enable="YES"
            sudo service bluetooth start 2>/dev/null || true
            sudo service hcsecd start 2>/dev/null || true
            sudo service sdpd start 2>/dev/null || true
            echo -e "${GREEN}Bluetooth services enabled and started.${NC}"
            echo -e "${CYAN}Tip: Use 'hccontrol -n ubt0hci inquiry' to discover nearby devices.${NC}"
            echo -e "${CYAN}For GUI Bluetooth management install 'bluetuith' (pkg install bluetuith).${NC}"
            ;;

        "Rotate TTY Clockwise")
            echo -e "${YELLOW}Rotating TTY 90 degrees clockwise and attempting persistence update...${NC}"
            chmod u+x scripts/rotate-tty-clockwise.sh
            sudo ./scripts/rotate-tty-clockwise.sh
            echo -e "${GREEN}TTY rotation command executed. Reboot for full effect.${NC}"
            ;;

        "Reboot System")
            echo -e "${YELLOW}Rebooting in 3 seconds...${NC}"
            sleep 3
            sudo reboot
            ;;

        "Exit")
            clear
            echo -e "${BLUE}Thanks! Enjoy your FreeBSD setup.${NC}"
            exit 0
            ;;
    esac

    gum confirm "Return to main menu?" || break
done
