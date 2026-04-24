#!/usr/bin/env bash
# GitHub.com/PiercingXX
# FreeBSD-Mod — Base system setup (step-1.sh)
# Run from the scripts/ directory via freebsd-mod.sh

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

username=${SUDO_USER:-$(id -un)}
builddir=$(cd .. && pwd)

# ── Create user directories ───────────────────────────────────────────────────
echo -e "${YELLOW}Creating necessary directories...${NC}"
for dir in \
    "$HOME/.fonts" \
    "$HOME/.icons" \
    "$HOME/.config" \
    "$HOME/Pictures/backgrounds" \
    "$HOME/Pictures/profile-image"; do
    [ ! -d "$dir" ] && mkdir -p "$dir"
done
chown -R "$username":"$username" \
    "$HOME/.fonts" \
    "$HOME/.icons" \
    "$HOME/.config" \
    "$HOME/Pictures"

# ── Update package database ───────────────────────────────────────────────────
echo -e "${YELLOW}Updating package database and upgrading installed packages...${NC}"
sudo pkg update
sudo pkg upgrade -y

# ── Core shell & utilities ────────────────────────────────────────────────────
echo -e "${YELLOW}Installing core shell tools and utilities...${NC}"
sudo pkg install -y \
    bash \
    bash-completion \
    gum \
    git \
    wget \
    curl \
    zip \
    unzip \
    gzip \
    gmake \
    fontconfig \
    tree \
    tmux \
    htop \
    nvtop \
    fzf \
    bat \
    eza \
    zoxide \
    starship \
    fastfetch \
    chafa \
    w3m \
    lnav \
    multitail \
    cpio \
    meson \
    cmake \
    sshpass \
    rsync

# ── Set bash as default login shell ──────────────────────────────────────────
echo -e "${YELLOW}Setting bash as default shell for ${username}...${NC}"
if ! grep -q "/usr/local/bin/bash" /etc/shells; then
    echo "/usr/local/bin/bash" | sudo tee -a /etc/shells
fi
sudo chsh -s /usr/local/bin/bash "$username"

# Minimal .bashrc if none exists
if [ ! -f "$HOME/.bashrc" ]; then
    cat > "$HOME/.bashrc" << 'EOF'
# FreeBSD-Mod .bashrc

# bash completion
[[ -r /usr/local/share/bash-completion/bash_completion ]] && \
    . /usr/local/share/bash-completion/bash_completion

# Starship prompt
command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"

# Zoxide (smarter cd)
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init bash)"

# Aliases
alias ls='eza --icons'
alias ll='eza -lah --icons'
alias lt='eza --tree --icons'
alias cat='bat --style=plain'
alias grep='grep --color=auto'
EOF
fi

# ── Languages & runtimes ──────────────────────────────────────────────────────
echo -e "${YELLOW}Installing Python, Node.js, and related tools...${NC}"
sudo pkg install -y \
    python3 \
    py311-pip \
    node \
    npm

# ── Neovim & dependencies ─────────────────────────────────────────────────────
echo -e "${YELLOW}Installing Neovim and editor dependencies...${NC}"
sudo pkg install -y \
    neovim \
    lua54 \
    ripgrep \
    fd-find \
    py311-pynvim
python3 -m pip install --user --upgrade pynvim

# ── Kitty terminal emulator ───────────────────────────────────────────────────
echo -e "${YELLOW}Installing Kitty terminal...${NC}"
sudo pkg install -y kitty

# ── VSCodium (open-source VS Code) ────────────────────────────────────────────
echo -e "${YELLOW}Installing VSCodium...${NC}"
sudo pkg install -y vscode

# ── Firewall: enable pf (FreeBSD's built-in packet filter) ───────────────────
echo -e "${YELLOW}Enabling pf firewall...${NC}"
sudo sysrc pf_enable="YES"
sudo sysrc pflog_enable="YES"
# Ensure SSH is allowed before loading any custom ruleset
if [ ! -f /etc/pf.conf ]; then
    cat << 'EOF' | sudo tee /etc/pf.conf
# FreeBSD-Mod default pf ruleset — permissive base; tighten as needed
set skip on lo
block in all
pass out all keep state
pass in proto tcp to port 22  # SSH
EOF
fi

# ── Enable core system services ───────────────────────────────────────────────
echo -e "${YELLOW}Enabling core services (dbus, avahi)...${NC}"
sudo sysrc dbus_enable="YES"
sudo sysrc avahi_daemon_enable="YES"
sudo service dbus start 2>/dev/null || true

# ── Media, archive & file tools ───────────────────────────────────────────────
echo -e "${YELLOW}Installing media, archive, and file tools...${NC}"
sudo pkg install -y \
    ffmpeg \
    7-zip \
    jq \
    poppler-utils \
    imagemagick7 \
    fwupd

# ── Yazi file manager ─────────────────────────────────────────────────────────
echo -e "${YELLOW}Installing Yazi file manager...${NC}"
sudo pkg install -y yazi

if command -v ya >/dev/null 2>&1; then
    echo -e "${YELLOW}Installing Yazi plugins...${NC}"
    ya pkg add dedukun/bookmarks
    ya pkg add yazi-rs/plugins:mount
    ya pkg add dedukun/relative-motions
    ya pkg add yazi-rs/plugins:chmod
    ya pkg add yazi-rs/plugins:smart-enter
    ya pkg add AnirudhG07/rich-preview
    ya pkg add Rolv-Apneseth/starship
    ya pkg add yazi-rs/plugins:full-border
    ya pkg add uhs-robert/recycle-bin
    ya pkg add yazi-rs/plugins:diff
fi

# ── Tailscale VPN ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}Installing Tailscale...${NC}"
sudo pkg install -y tailscale
sudo sysrc tailscaled_enable="YES"
sudo service tailscaled start 2>/dev/null || true
echo -e "${CYAN}Run 'sudo tailscale up' to authenticate with Tailscale.${NC}"

# ── Icons & themes ────────────────────────────────────────────────────────────
echo -e "${YELLOW}Installing Papirus icon theme...${NC}"
sudo pkg install -y papirus-icon-theme

# ── Fonts ─────────────────────────────────────────────────────────────────────
echo -e "${YELLOW}Installing Nerd Fonts...${NC}"
sudo pkg install -y nerd-fonts
fc-cache -fv "$HOME/.fonts" 2>/dev/null || true

echo -e "${GREEN}Base setup complete!${NC}"