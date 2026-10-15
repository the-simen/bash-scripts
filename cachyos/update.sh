#!/usr/bin/env bash
set -uo pipefail

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

update_repo "$HOME/.config" "config"
update_repo "$HOME/.config/nvim" "nvim"

# Re-apply what a plain `git pull` does not refresh on its own.
if [ -f "$HOME/.config/scripts/ensure-noctalia-palettes.sh" ]; then
    echo "🎨 Restoring missing Noctalia palettes..."
    "$HOME/.config/scripts/ensure-noctalia-palettes.sh" || true
fi

if [ -f "$HOME/.config/noctalia/config.toml.full" ]; then
    echo "🌙 Refreshing live Noctalia config..."
    "$HOME/.config/scripts/install_noctalia_conf.sh" "$HOME/.config/noctalia/config.toml.full" \
        && echo "ℹ️ Restart the Noctalia shell to apply it." \
        || echo "⚠️ Noctalia config refresh failed."
fi

if [ -L "$HOME/.local/share/applications" ]; then
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
fi

cd ~
