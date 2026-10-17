
# Configs installation scripts

---

## Cachyos (niri + noctalia-shell)

> [!IMPORTANT]
> cachyos with niri and noctalia required!

command to install my cachy configs 
```sh 
git clone https://github.com/the-simen/install-scripts/ ~/install-scripts/ && sudo chmod +x ~/install-scripts/cachyos/install.sh && ~/install-scripts/cachyos/install.sh
```
It will install some apps, my config folder, my tmux config and my NvChad config (neovim distribution)

use this command if you want to modify application list, it will only clone the repo in ```$HOME/install-scripts```
```sh
git clone https://github.com/the-simen/install-scripts/ ~/install-scripts/ && sudo chmod +x ~/install-scripts/cachyos/install.sh
```

lists of apps are located in ```$HOME/install-scripts/cachyos/packages```

comand to update my cachy configs (.config and neovim) or use my ```Config manager```, you can find it in app list after installation
```sh
cd ~/install-scripts && git pull && sudo chmod +x ./cachyos/update.sh && ./cachyos/update.sh
```

---
