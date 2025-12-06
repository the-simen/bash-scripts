cd ~/.config
git stash push -q
git pull
git stash pop -q

cd ~/.config/nvim 
git stash push -q
git pull
git stash pop -q

cd
