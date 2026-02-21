#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="$HOME/.config_backup_$(date +%Y-%m-%d_%H-%M-%S)"

echo "🔄 Updating Arch..."
sudo pacman -Syu --noconfirm

echo "📦 Installing git and base-devel..."
sudo pacman -S --needed --noconfirm git base-devel

if [ ! -d "$HOME/yay" ]; then
    echo "⬇️ Downloading yay..."
    git clone https://aur.archlinux.org/yay.git "$HOME/yay"
fi

echo "⚙️ Installing yay..."
cd "$HOME/yay"
makepkg -si --noconfirm
cd ~

echo "📦 Installing core packages..."
sudo pacman -S --needed --noconfirm \
  cpio cmake meson nodejs npm neovim \
  discord telegram-desktop fish tmux \
  kitty openvpn yazi fastfetch \
  openrgb rsync lazygit eza mc btop \
  bat gping steam ntfs-3g \
  clapper gst-libav gst-plugins-base \
  gst-plugins-good gst-plugins-bad \
  gst-plugins-ugly

echo "🐚 Setting default shell to fish..."
chsh -s "$(which fish)"

echo "📦 Installing AUR packages via yay..."
yay -S --needed --noconfirm \
  happ-desktop-bin google-chrome openvpn-update-systemd-resolved \
  systemd-resolvconf-git openvpn-update-resolv-conf-git \

echo "🔁 Updating hyprpm..."
hyprpm update || true

echo "✨ Installing Hyprspace..."
hyprpm add https://github.com/hyprwm/hyprland-plugins
hyprpm enable hyprexpo || true

echo "📁 Backing up existing ~/.config..."
if [ -d "$HOME/.config" ]; then
    mkdir -p "$BACKUP_DIR"
    cp -r "$HOME/.config"/* "$BACKUP_DIR"/
    echo "✅ Backup saved to: $BACKUP_DIR"
fi

echo "⬇️ Cloning omarchy-config..."
git clone https://github.com/the-simen/omarchy-config.git --depth 1

echo "🧩 Copying omarchy config (without deleting others)..."
rsync -av omarchy-config/ ~/.config/

echo "🎨 Installing catppuccin tmux theme..."
mkdir -p ~/.config/tmux/plugins/catppuccin
git clone -b v2.1.3 https://github.com/catppuccin/tmux.git ~/.config/tmux/plugins/catppuccin/tmux --depth 1

echo "🧠 Downloading tmux config..."
git clone https://github.com/the-simen/tmux-config.git --depth 1
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
rsync -av --exclude='.git' tmux-config/ ~/

echo "📝 Installing NvChad..."
rm -rf ~/.config/nvim ~/.local/share/nvim
git clone https://github.com/the-simen/nvchad-configs ~/.config/nvim --depth 1

echo "📸 Downloading wallpapers..."
rm -rf ~/.config/omarchy/current/theme/backgrounds/*
git clone https://github.com/orangci/walls-catppuccin-mocha.git ~/.config/omarchy/current/theme/backgrounds/ --depth 1

echo ""
notify-send "✅ Done!" "📦 Your old configs were backed up to: $BACKUP_DIR 🔁 Please reboot your system!"
