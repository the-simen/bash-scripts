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

echo "Updating Arch..."
sudo pacman -Syu --noconfirm

echo "Installing git and base-devel..."
sudo pacman -S --needed --noconfirm git base-devel rust

echo "Installing core packages..."
sudo pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}"

echo "Installing kitty as default terminal in Nemo..."
gsettings set org.cinnamon.desktop.default-applications.terminal exec kitty \
  || echo "⚠️ Could not set Nemo terminal (no D-Bus session?), continuing."

echo "adding input user"
sudo usermod -a -G input "$USER"

echo "Setting default shell to fish..."
if command -v fish &> /dev/null; then
    chsh -s "$(command -v fish)" || echo "⚠️ chsh failed, set fish as your shell manually."
else
    echo "⚠️ fish not installed, skipping chsh."
fi

echo "Starting networkmanager service..."
sudo systemctl enable --now NetworkManager

echo "Adding Flathub..."
# System remote needs root on a fresh machine; fall back to sudo.
flatpak remote-add --if-not-exists flathub \
  https://flathub.org/repo/flathub.flatpakrepo \
  || sudo flatpak remote-add --if-not-exists flathub \
  https://flathub.org/repo/flathub.flatpakrepo

echo "Installing flatpack applications..."
flatpak install -y flathub "${FLATPAK_APPS[@]}"

if flatpak info com.spotify.Client &>/dev/null; then
    flatpak override --user --no-talk-name=org.freedesktop.ScreenSaver com.spotify.Client
fi

echo "Installing AUR packages via paru..."
if ! command -v paru &> /dev/null; then
  echo "⚠️ paru not found. Installing..."
  rm -rf /tmp/paru
  git clone https://aur.archlinux.org/paru.git /tmp/paru
  cd /tmp/paru
  makepkg -si --noconfirm
  cd "$HOME"
fi

paru -S --needed --noconfirm "${AUR_PACKAGES[@]}"

echo "Backing up existing $HOME/.config..."
if [ -d "$HOME/.config" ]; then
    mkdir -p "$BACKUP_DIR"
    rsync -a "$HOME/.config/" "$BACKUP_DIR/"
    echo "✅ Backup saved to: $BACKUP_DIR"
fi

echo "Cloning cachy-config..."
if [ ! -d "$HOME/cachy-config" ]; then
  git clone --depth 1 -b main https://github.com/the-simen/cachy-config.git "$HOME/cachy-config"
else
  echo "cachy-config already cloned, pulling latest..."
  git -C "$HOME/cachy-config" pull --ff-only || echo "⚠️ Could not update ~/cachy-config, using existing copy."
fi

echo "Creating simlinks for applications..."
if [ -d "$HOME/.local/share/applications" ] && [ ! -L "$HOME/.local/share/applications" ]; then
    APP_BACKUP="$HOME/.local_share_applications_backup_$(date +%Y-%m-%d_%H-%M-%S)"
    cp -a "$HOME/.local/share/applications" "$APP_BACKUP"
    echo "✅ Existing launchers backed up to: $APP_BACKUP"
fi
mkdir -p "$HOME/.local/share"
rm -rf "$HOME/.local/share/applications"
ln -s "$HOME/.config/applications" "$HOME/.local/share/applications"

echo "Copying config (without deleting others)..."
rsync --progress -av "$HOME/cachy-config/" "$HOME/.config/"

chmod +x "$HOME/.config/scripts/install_noctalia_conf.sh" \
  "$HOME/.config/scripts/ensure-noctalia-palettes.sh" \
  "$HOME/.config/scripts/skip_dc_update.sh"

echo "Restoring Noctalia palette fallbacks (fresh clone)..."
"$HOME/.config/scripts/ensure-noctalia-palettes.sh" \
  || echo "⚠️ Palette restore failed, continuing."

"$HOME/.config/scripts/install_noctalia_conf.sh" "$HOME/.config/noctalia/config.toml.full"

systemctl --user daemon-reload
systemctl --user enable --now ssh-agent.service \
  || echo "⚠️ Could not enable ssh-agent.service, continuing."
systemctl --user enable --now cliphist.service \
  || echo "⚠️ Could not enable cliphist.service, continuing."

echo "Refreshing desktop database..."
update-desktop-database "$HOME/.local/share/applications" \
  || echo "⚠️ update-desktop-database failed, launchers appear after relogin."

echo "Fixing discord update issue..."
"$HOME/.config/scripts/skip_dc_update.sh" \
  || echo "⚠️ Discord fix failed, continuing."

echo "Installing tmux config..."
cd "$HOME"
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi
ln -sf "$HOME/.config/tmux/.tmux.conf" "$HOME/.tmux.conf"

echo "Installing NvChad..."
rm -rf "$HOME/.config/nvim" "$HOME/.local/share/nvim"
git clone https://github.com/the-simen/nvchad-configs "$HOME/.config/nvim" --depth 1

echo ""
if command -v notify-send &> /dev/null; then
    notify-send "✅ Done!" "📦 Your old configs were backed up to: $BACKUP_DIR 🔁 Please reboot your system!"
fi

fish -c "fisher install IlanCosman/tide@v6" \
  || echo "⚠️ Tide install failed (is fisher set up?). Run manually: fisher install IlanCosman/tide@v6"
