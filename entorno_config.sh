#!/bin/bash
# Time-zone
sudo timedatectl set-timezone Chile/Continental

# Deleting default folders
rm -rf ~/{Music,Pictures,Public,Templates,Videos}

# Update and upgrade
sudo apt update; sudo apt upgrade -y

# Install alacritty, sxhkd (dropdown bind ctrl+enter), tmux, bat, lsd 
sudo apt install alacritty sxhkd tmux bat lsd golang neo4j -y

# Install tdrop
git clone https://github.com/noctuid/tdrop && cd tdrop && sudo make install && cd ..

# sxhkd
mkdir -p ~/.config/sxhkd
mv sxhkdrc ~/.config/sxhkd

# Fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip
sudo unzip JetBrainsMono.zip -d /usr/share/fonts/
# fc-cache -fv

# Fonts - new
mkdir -p ~/.local/share/fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Iosevka.zip
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/RobotoMono.zip
unzip Iosevka.zip -d ~/.local/share/fonts/
unzip RobotoMono.zip -d ~/.local/share/fonts/
fc-cache -fv


# Alacritty
cp alacritty ~/.config/

# bash_aliases
cp bash_aliases ~/.bash_aliases

# zsh
cp zshrc ~/.zshrc

# Tmux
mkdir ~/.tmux
cp tmux ~/.tmux
rm ~/.tmux.conf
cp tmux.conf ~/.tmux.conf
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
# prefix + i
# chmod +x tmux_start_logging.sh
# mv tmux_start_logging.sh ~/.local/share/

# Wallpaper
sudo cp desktop.jpg /usr/share/backgrounds/kali-16x9/default
sudo cp desktop.jpg /usr/share/backgrounds/kali/kali-ferrofluid-16x9.jpg
sudo cp login.png /usr/share/backgrounds/kali/kali-aqua-16x9.jpg
sudo cp login.png /usr/share/backgrounds/kali-16x9/kali-aqua.jpg


# Config autostart
mkdir -p ~/.config/autostart/
cp *.desktop ~/.config/autostart/



# opt - Useful 
#sudo unzip opt_useful.zip -d /opt
#sudo chown kali:kali /opt/payloads /opt/things /opt/useful

# Desktop Enviroment
# sudo apt install -y kali-desktop-kde
# sudo update-alternatives --config x-session-manager
# Unistall 
# xfce sudo apt purge --autoremove kali-desktop-xfce



# Fix copy/paste, drag and drop with KDE desktop
# kwriteconfig5 --file startkderc --group General --key systemdBoot false
