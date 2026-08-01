#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/packages/pacman.sh"
source "$SCRIPT_DIR/packages/aur.sh"
source "$SCRIPT_DIR/packages/flatpak.sh"

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
sudo pacman -S --needed --noconfirm git base-devel rust

echo "📦 Installing core packages..."
sudo pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}"

echo "adding input user"
sudo usermod -a -G input "$USER"

echo "🐚 Setting default shell to fish..."
if command -v fish &> /dev/null; then
    chsh -s "$(which fish)"
else
    echo "⚠️ fish not installed, skipping chsh."
fi

echo "🌐 Starting networkmanager service..."
sudo systemctl enable --now NetworkManager

echo "📦 Adding Flathub..."
flatpak remote-add --if-not-exists flathub \
  https://flathub.org/repo/flathub.flatpakrepo

echo "📦 Installing flatpack applications..."
flatpak install -y flathub "${FLATPAK_APPS[@]}"

if flatpak info com.spotify.Client &>/dev/null; then
    flatpak override --user --no-talk-name=org.freedesktop.ScreenSaver com.spotify.Client
fi

echo "📦 Installing AUR packages via paru..."
if ! command -v paru &> /dev/null; then
  echo "⚠️ paru not found. Installing..."
  rm -rf /tmp/paru
  git clone https://aur.archlinux.org/paru.git /tmp/paru
  cd /tmp/paru
  makepkg -si --noconfirm
  cd "$HOME"
fi

paru -S --needed "${AUR_PACKAGES[@]}"

echo "📁 Backing up existing $HOME/.config..."
if [ -d "$HOME/.config" ]; then
    mkdir -p "$BACKUP_DIR"
    rsync -a "$HOME/.config/" "$BACKUP_DIR/"
    echo "✅ Backup saved to: $BACKUP_DIR"
fi

echo "⬇️ Cloning cachy-config..."
if [ ! -d "$HOME/cachy-config" ]; then
  git clone --depth 1 https://github.com/the-simen/cachy-config.git "$HOME/cachy-config"
fi

echo "🔗 Creating simlinks for applications..."
mkdir -p "$HOME/.local/share"
rm -rf "$HOME/.local/share/applications"
ln -s "$HOME/.config/applications" "$HOME/.local/share/applications"

echo "🧩 Copying config (without deleting others)..."
rsync --progress -av "$HOME/cachy-config/" "$HOME/.config/"

systemctl --user daemon-reload
systemctl --user enable --now ssh-agent.service
systemctl --user enable --now cliphist.service

echo "📝 Fixing discord update issue..."
$HOME/.config/scripts/skip_dc_update.sh

echo "🧠 Installing tmux config..."
cd "$HOME"
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi
ln -sf "$HOME/.config/tmux/.tmux.conf" "$HOME/.tmux.conf"

echo "📝 Installing NvChad..."
rm -rf "$HOME/.config/nvim" "$HOME/.local/share/nvim"
git clone https://github.com/the-simen/nvchad-configs "$HOME/.config/nvim" --depth 1

echo ""
if command -v notify-send &> /dev/null; then
    notify-send "✅ Done!" "📦 Your old configs were backed up to: $BACKUP_DIR 🔁 Please reboot your system!"
fi

fish -c "fisher install IlanCosman/tide@v6"
