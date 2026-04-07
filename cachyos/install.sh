#!/usr/bin/env bash
set -euo pipefail

if ! sudo -v; then
    echo "❌ Sudo authentication failed"
    exit 1
fi

while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
done 2>/dev/null &

BACKUP_DIR="$HOME/.config_backup_$(date +%Y-%m-%d_%H-%M-%S)"

echo "🔄 Updating Arch..."
sudo pacman -Syu --noconfirm

echo "📦 Installing git and base-devel..."
sudo pacman -S --needed --noconfirm git base-devel

echo "📦 Installing core packages..."
sudo pacman -S --needed --noconfirm \
  cpio cmake meson nodejs npm neovim \
  discord telegram-desktop fish tmux \
  openvpn yazi fastfetch \
  openrgb rsync lazygit eza mc btop \
  bat gping steam ntfs-3g \
  clapper gst-libav gst-plugins-base \
  gst-plugins-good gst-plugins-bad \
  gst-plugins-ugly \
  networkmanager network-manager-applet \
  networkmanager-openvpn \
  7zip file-roller ghostty

echo "🐚 Setting default shell to fish..."
if command -v fish &> /dev/null; then
    chsh -s "$(which fish)"
else
    echo "⚠️ fish not installed, skipping chsh."
fi

echo "🌐 Starting networkmanager service..."
sudo systemctl enable --now NetworkManager

echo "📦 Installing AUR packages via paru..."
if ! command -v paru &> /dev/null; then
  echo "⚠️ paru not found. Installing..."
  git clone https://aur.archlinux.org/paru.git /tmp/paru
  cd /tmp/paru
  makepkg -si --noconfirm
  cd "$HOME"
fi
paru -S --needed --noconfirm \
  happ-desktop-bin openvpn-update-systemd-resolved \
  systemd-resolvconf-git openvpn-update-resolv-conf-git \

echo "📁 Backing up existing $HOME/.config..."
if [ -d "$HOME/.config" ]; then
    mkdir -p "$BACKUP_DIR"
    rsync -a "$HOME/.config/" "$BACKUP_DIR/"
    echo "✅ Backup saved to: $BACKUP_DIR"
fi

echo "⬇️ Cloning cachy-config..."
[ ! -d "$HOME/cachy-config" ] && git clone https://github.com/the-simen/cachy-config.git --depth 1

echo "🔗 Creating simlinks for applications..."
ln -sf "$HOME/.config/applications" "$HOME/.local/share/applications"

echo "🧩 Copying config (without deleting others)..."
rsync --progress -av cachy-config/ "$HOME/.config/"

systemctl --user daemon-reload
systemctl --user enable --now ssh-agent.service
systemctl --user enable quickshell.service

echo "🎨 Installing catppuccin tmux theme..."
mkdir -p "$HOME/.config/tmux/plugins/catppuccin"
[ ! -d "$HOME/.config/tmux/plugins/catppuccin/tmux" ] && git clone -b v2.1.3 https://github.com/catppuccin/tmux.git "$HOME/.config/tmux/plugins/catppuccin/tmux" --depth 1

echo "🧠 Installing tmux config..."
cd "$HOME"
[ ! -d "$HOME/.tmux/plugins/tpm" ] && git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
ln -sf "$HOME/.config/tmux/.tmux.conf" "$HOME/.tmux.conf"

echo "📝 Installing NvChad..."
rm -rf "$HOME/.config/nvim" "$HOME/.local/share/nvim"
git clone https://github.com/the-simen/nvchad-configs "$HOME/.config/nvim" --depth 1

echo ""
if command -v notify-send &> /dev/null; then
    notify-send "✅ Done!" "📦 Your old configs were backed up to: $BACKUP_DIR 🔁 Please reboot your system!"
fi
