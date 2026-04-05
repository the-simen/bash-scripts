
# Configs installation scripts

---

## Cachyos (niri + noctalia-shell)

> [!IMPORTANT]
> cachyos with niri and noctalia-shell required!

command to install my cachy configs 
``` 
git clone https://github.com/the-simen/bash-scripts/ ~/bash-scripts/ && sudo chmod +x ~/bash-scripts/cachyos/install.sh && ~/bash-scripts/cachyos/install.sh
```
It will install some apps, my config folder, my tmux config and my NvChad config (neovim distribution)


comand to update my cachy configs (.config and neovim)
```
cd ~/bash-scripts && git pull && sudo chmod +x ./cachy/update.sh && ./cachy/update.sh
```

---

## Omarchy

> [!WARNING]
> DEPRECATED

> [!IMPORTANT]
> omarchy required!

command to install my omarchy configs 
``` 
git clone https://github.com/the-simen/bash-scripts/ ~/bash-scripts/ && sudo chmod +x ~/bash-scripts/omarchy/install_config.sh && ~/bash-scripts/omarchy/install_config.sh
```

comand to update my omarchy configs (.config and neovim)
```
cd ~/bash-scripts && git pull && sudo chmod +x ./omarchy/update_config.sh && ./omarchy/update_config.sh
```
