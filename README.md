
# FreeBSD-Mod

A post-install desktop setup script for FreeBSD.  
Designed for headless-to-desktop installs on tablets, mini-PCs, and low-powered hardware.  
Automates essential package installation, window manager setup, GPU drivers, and base configuration for a streamlined desktop experience.



## 📦 Features

- Base install: core CLI tools, Neovim, Kitty, Yazi, VSCodium, Tailscale, PipeWire, fonts
- Choice of window manager: **i3**, **BSPWM**, **Awesome WM**, **Hyprland**, **Sway**, or **GNOME**
- GPU driver setup: Intel, AMD (GCN+ and legacy), NVIDIA proprietary
- Touchscreen support via libinput + evdev passthrough
- Bluetooth service configuration
- Starter configs for every WM so you're never dropped into a blank desktop
- `pf` firewall enabled with a sane default ruleset
- Lightweight and tablet-friendly — tested on mini-PCs and touch devices



## 🖥️ Window Managers

| WM | Protocol | Display Manager | Notes |
|---|---|---|---|
| **i3** | X11 | GDM | Minimal, keyboard-driven tiling |
| **BSPWM** | X11 | GDM | Binary space partitioning; pairs with sxhkd |
| **Awesome WM** | X11 | GDM | Lua-configurable; very extensible |
| **Hyprland** | Wayland | GDM | Animated, modern Wayland compositor |
| **Sway** | Wayland | GDM | i3-compatible Wayland compositor |
| **GNOME** | Wayland/X11 | GDM | Full desktop environment |

Multiple WMs can be installed simultaneously and selected at the GDM login screen.



## 🚀 Quick Start

> **Prerequisites:** A fresh FreeBSD install with network access and `sudo` configured for your user.
> If `sudo` is not yet installed: `pkg install sudo` as root, then add yourself to the `wheel` group.

```bash
git clone https://github.com/PiercingXX/freebsd-mod
cd freebsd-mod
chmod -R u+x scripts/
./freebsd-mod.sh
```



## 🛠️ Usage

Run `./freebsd-mod.sh` and follow the interactive menu.

**Recommended first-run order:**
1. **Install FreeBSD Mini Mod (Base Setup)** — installs core tools, shell, fonts, firewall
2. **Install GPU Drivers** — pick your GPU before starting X/Wayland
3. **Install Window Manager** — choose one or more; starter configs are generated automatically
4. **Configure Touchscreen Support** *(optional)* — enables evdev passthrough for libinput
5. **Configure Bluetooth** *(optional)*
6. **Reboot**



## 🔧 What Gets Installed (Base Setup)

| Category | Packages |
|---|---|
| Shell | bash, bash-completion, starship, zoxide |
| Files | eza, bat, fzf, tree, yazi, fd-find |
| Editors | neovim (+ lua, pynvim), vscode (VSCodium) |
| Terminal | kitty |
| Media | ffmpeg, imagemagick7, cava |
| Network | tailscale |
| Dev tools | git, python3, node/npm, meson, cmake |
| Misc | tmux, htop, nvtop, lnav, multitail, jq |
| Fonts | nerd-fonts |
| Icons | papirus-icon-theme |
| Firewall | pf (built-in FreeBSD) |



## 🗒️ FreeBSD Notes

- **Package manager:** `pkg` — no AUR or Flatpak; everything comes from the official FreeBSD ports tree.
- **Service management:** `sysrc` and `service` replace `systemctl`. Enabled services are written to `/etc/rc.conf`.
- **GPU drivers:** Intel and AMD use `drm-kmod` (loaded via `kld_list` in rc.conf). NVIDIA uses the proprietary `nvidia-driver`.
- **Audio:** PipeWire is installed. On FreeBSD, PipeWire is started per-session via the WM autostart (not as a system service).
- **Firewall:** `pf` is enabled with a minimal default ruleset. Customise `/etc/pf.conf` as needed.
- **Wayland on FreeBSD:** Fully supported in FreeBSD 13+. Hyprland and Sway are both available in the official ports tree.



## 📋 Compatibility

| Hardware | Status |
|---|---|
| Generic x86-64 desktop/laptop | ✅ Works |
| Intel-GPU tablet / mini-PC | ✅ Works (use `drm-kmod` + `i915kms`) |
| AMD-GPU device | ✅ Works (use `drm-kmod` + `amdgpu`/`radeonkms`) |
| NVIDIA device | ⚠️ Works with proprietary driver; Wayland support limited |
| Touchscreen device | ✅ Supported via libinput + evdev passthrough |

---

## 📄 License

MIT © PiercingXX  
See the LICENSE file for details.

---

## 🤝 Contributing

Fork, branch, and PR welcome.  

---

## 📞 Support & Contact

    Email: Don’t

    Open an issue in the relevant repo instead. If it’s a rant make it entertaining.