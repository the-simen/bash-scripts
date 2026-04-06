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

cd ~
