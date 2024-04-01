#!/bin/bash
# Time-zone
sudo timedatectl set-timezone Chile/Continental

# Deleting default folders
rm -rf ~/{Music,Pictures,Public,Templates,Videos}

# Update and upgrade
sudo apt update; sudo apt upgrade -y

# Install alacritty, sxhkd (dropdown bind f10), tmux, bat, lsd, flameshot 
sudo apt install alacritty sxhkd tmux bat lsd flameshot -y

# Install tdrop
git clone https://github.com/noctuid/tdrop && cd tdrop && sudo make install && cd ..

# sxhkd
mkdir ~/.config/sxhkd
mv sxhkdrc ~/.config/sxhkd/sxhkdrc


# Fonts
# wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip
# sudo unzip JetBrainsMono.zip -d /usr/share/fonts/
# fc-cache -fv

# Fonts - new
mkdir -p ~/.local/share/fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Iosevka.zip
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/RobotoMono.zip
unzip Iosevka.zip -d ~/.local/share/fonts/
unzip RobotoMono.zip -d ~/.local/share/fonts/
fc-cache -fv


# Alacritty
mv alacritty ~/.config/

# bash_aliases
mv bash_aliases ~/.bash_aliases

# zsh
mv zshrc ~/.zshrc

# Tmux
mv tmux ~/.tmux
mv tmux.conf ~/.tmux.conf
# prefix + i

# Wallpaper
sudo cp desktop.jpg /usr/share/backgrounds/kali-16x9/default
sudo cp desktop.jpg /usr/share/backgrounds/kali/kali-ferrofluid-16x9.jpg
sudo cp login.png /usr/share/backgrounds/kali/kali-aqua-16x9.jpg
sudo cp login.png /usr/share/backgrounds/kali-16x9/kali-aqua.jpg

# opt - Useful 
#sudo unzip opt_useful.zip -d /opt
#sudo chown kali:kali /opt/payloads /opt/things /opt/useful

# Desktop Enviroment
sudo apt install -y kali-desktop-kde
sudo update-alternatives --config x-session-manager
# Unistall 
# xfce sudo apt purge --autoremove kali-desktop-xfce

# Fix copy/paste, drag and drop with KDE desktop
kwriteconfig5 --file startkderc --group General --key systemdBoot false

# Config autostart
mkdir ~/.config/autostart/
mv *.desktop ~/.config/autostart/
mv mount-vmhgfs.sh ~/.config/autostart/
