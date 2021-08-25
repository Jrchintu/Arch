#!/usr/bin/env bash

# Q/A
read -rep "Enter the username: " USER1
read -rep "Enter the hostname: " HNAME
read -rep "Enter Region/Zone Eg.Asia/Kolkata:" RNAME

#TIME
ln -sf /usr/share/zoneinfo/"$RNAME" /etc/localtime && hwclock --systohc
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && locale-gen && echo 'LANG=en_US.UTF-8' >/etc/locale.conf

# HOSTNAME
echo "$HNAME" >/etc/hostname
echo -e "127.0.0.1 $HNAME\n::1 $HNAME\n127.0.1.1 $HNAME.localdomain $HNAME" >>/etc/hosts

# ROOT-PASSWORD
br && echo "Setting new Root password [Keep powerfull password in mind]"
passwd

# NEW-USER
br && echo "Setting new user $USER1 [Keep powerfull password in mind]"
groupadd sudo && useradd -mG wheel,sudo -s /usr/bin/bash "$USER1"
passwd "$USER1"
sed -i 's/^#\s*\(%wheel\s\+ALL=(ALL)\s\+ALL\)/\1/' /etc/sudoers

# ENABLE SYSTEM SERVICE
systemctl enable NetworkManager.service
systemctl enable ufw.service

# GRUB CONFIG
sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"i8042.nopnp\"/g" /etc/default/grub

# INSTALL PARU
git clone --depth=1 https://aur.archlinux.org/paru-bin.git paru
cd paru && sudo -u "$USER1" makepkg -si && rm -rf /paru

# PACMAN CONFIG
# Add chromium pacman config
curl -s 'https://download.opensuse.org/repositories/home:/ungoogled_chromium/Arch/x86_64/home_ungoogled_chromium_Arch.key' | pacman-key -a -
echo -e '\n[home_ungoogled_chromium_Arch]\nSigLevel = Required TrustAll' | tee -a /etc/pacman.conf
echo -e 'Server = https://download.opensuse.org/repositories/home:/ungoogled_chromium/Arch/$arch' | tee -a /etc/pacman.conf
# Enabling multilib in pacman
sed -i '93s/#\[/\[/' /etc/pacman.conf && sed -i '94s/#I/I/' /etc/pacman.conf
# Tweaking pacman, uncomment options Color, TotalDownload and VerbosePkgList
sed -i '34s/#C/C/' /etc/pacman.conf && sed -i '35s/#T/T/' /etc/pacman.conf && sed -i '37s/#V/V/' /etc/pacman.conf

# FIREWALL
ufw default deny incoming
ufw default allow outgoing
ufw enable

# PROFILE.D [WIP]
rm -rf /etc/profile.d/*alias* /etc/profile.d/*ps1*
curl -L https://github.com/Jrchintu/CDN/raw/main/DOT/.bashrc -o /etc/profile.d/.bashrc
chmod a+x /etc/profile.d/*

# Install intel related stuff
pacman -S --noconfirm --needed libva-utils vulkan-intel intel-ucode
