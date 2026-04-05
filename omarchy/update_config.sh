echo "🔄 Updating config..."
cd ~/.config
git stash push -q
git pull --ff-only || exit 1
git stash pop -q

echo "🔄 Updating nvim..."
cd ~/.config/nvim 
git stash push -q
git pull --ff-only || exit 1
git stash pop -q

echo "🔄 Updating tmux..."
TMUX_REPO_DIR="$HOME/tmux-config"
if [ ! -d "$TMUX_REPO_DIR" ]; then
  echo "⬇️ Downloading tmux..."
  git clone --depth 1 https://github.com/the-simen/tmux-config.git "$TMUX_REPO_DIR" || exit 1
else
  cd "$TMUX_REPO_DIR" || exit 1
  git pull --ff-only || exit 1
fi
rm -f ~/.tmux.conf
rsync -av --exclude='.git' ~/tmux-config/ ~/

echo "🔄 Updating hyprpm..."
hyprpm update || true

cd ~
