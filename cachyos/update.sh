#!/usr/bin/env bash
set -uo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

update_repo() {
    local dir="$1"
    local label="$2"

    if [ ! -d "$dir/.git" ]; then
        echo "⚠️ $label: $dir is not a git repo, skipping."
        return 0
    fi

    echo "🔄 Updating $label..."
    if [ -n "$(git -C "$dir" status --porcelain)" ]; then
        git -C "$dir" stash push -q -m "auto-stash by update.sh" \
            || { echo "❌ $label: stash failed"; return 1; }
        local stashed=1
    else
        local stashed=0
    fi

    if ! git -C "$dir" pull --ff-only; then
        echo "❌ $label: pull failed"
        [ "$stashed" -eq 1 ] && git -C "$dir" stash pop -q
        return 1
    fi

    if [ "$stashed" -eq 1 ]; then
        git -C "$dir" stash pop -q \
            || echo "⚠️ $label: stash pop failed, your changes are in 'git stash list'."
    fi
}

# Pull this repo first so the package lists below are fresh,
# even if update.sh was run without a manual `git pull`.
if SCRIPT_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null)"; then
    update_repo "$SCRIPT_ROOT" "bash-scripts"
fi

update_repo "$HOME/.config" "config"
update_repo "$HOME/.config/nvim" "nvim"

# Install anything missing from the package lists (no full system upgrade).
source "$SCRIPT_DIR/packages/pacman.sh"
source "$SCRIPT_DIR/packages/aur.sh"
source "$SCRIPT_DIR/packages/flatpak.sh"

echo "📦 Installing missing pacman packages..."
sudo pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}" \
    || echo "⚠️ pacman install failed."

if command -v paru &> /dev/null; then
    echo "📦 Installing missing AUR packages..."
    paru -S --needed --noconfirm "${AUR_PACKAGES[@]}" \
        || echo "⚠️ AUR install failed."
else
    echo "⚠️ paru not found, skipping AUR packages."
fi

if command -v flatpak &> /dev/null; then
    echo "📦 Installing missing Flatpak apps..."
    flatpak install -y flathub "${FLATPAK_APPS[@]}" \
        || echo "⚠️ Flatpak install failed."
else
    echo "⚠️ flatpak not found, skipping Flatpak apps."
fi

# Re-apply what a plain `git pull` does not refresh on its own.
if [ -f "$HOME/.config/scripts/ensure-noctalia-palettes.sh" ]; then
    echo "🎨 Restoring missing Noctalia palettes..."
    "$HOME/.config/scripts/ensure-noctalia-palettes.sh" || true
fi

# NOTE: live Noctalia settings (~/.local/state/noctalia/settings.toml) are
# deliberately NOT touched here. Overwriting them resets the user's current
# theme and generated assets (e.g. Telegram theme). Apply a repo config
# explicitly via install_noctalia_conf.sh (it keeps a timestamped backup).
if [ -L "$HOME/.local/share/applications" ]; then
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
fi

cd ~
