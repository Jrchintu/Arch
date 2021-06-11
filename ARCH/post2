#!/bin/bash

# Generate initramfs
mkinitcpio -P

#Install needed software
pacman -S networkmanager ufw lightdm-gtk-greeter xorg grub efibootmgr --noconfirm --needed

# Set locale to en_US.UTF-8 UTF-8
sed -i '/en_US.UTF-8 UTF-8/s/^#//g' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

# Set date time
timedatectl set-timezone Asia/Kolkata
timedatectl set-ntp true
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc

# Set hostname
echo "3542" >> /etc/hostname
echo "127.0.1.1 3542.localdomain 3542" >> /etc/hosts

# Install grub with efi
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=arch
grub-mkconfig -o /boot/grub/grub.cfg

# Firewall setup
ufw default deny incoming
ufw default allow outgoing
ufw enable

#install yay
git clone https://aur.archlinux.org/yay.git
cd yay/ || exit
makepkg -si PKGBUILD

# Enable service
systemctl enable lightdm.service
systemctl enable NetworkManager.service
systemctl enable ufw.service

# Set root password
echo "Set root password"
passwd

# add new user
useradd -m -G wheel,power,input,storage,uucp,network -s /usr/bin/zsh chintu
sed --in-place 's/^#\s*\(%wheel\s\+ALL=(ALL)\s\+NOPASSWD:\s\+ALL\)/\1/' /etc/sudoers
echo "Set password for new user chintu"
passwd chintu

#EXIT
echo "Configuration done. exiting chroot."
