#!/usr/bin/env bash
# Some variables/Functions
clear && LC_ALL=C && LANG=C
br() {
    for ((i = 1; i <= $(tput cols); i++)); do echo -n -; done
}

# QnA
read -rep 'Do you want to skip password/Hostname/Timezone-stuff incase of error last time? [Y/N]: ' SKIPJUNK
if [ "$SKIPJUNK" = 'y' ] || [ "$SKIPJUNK" = 'Y' ]; then
	echo 'Skipping Password-stuff/Hosname/Region etc' && br
else
read -rep "Enter the username for new user [Only small character without symbol]: " USER1
read -rep "Enter the hostname/Machine-Name: " HNAME
read -rep "Enter Region/Zone Eg.Asia/Kolkata: " RNAME
br && echo -e "USERNAME = $USER1\nHOSTNAME = $HNAME\nREGION/ZONE = $RNAME"
read -rep "Is above data correct? [Y/N]: " DATAYN
if [[ "$DATAYN" = 'y' ]] || [[ "$DATAYN" = 'Y' ]]; then
	echo ''
else
	read -rep "Enter the username for new user [Only small character without symbol]: " USER1
	read -rep "Enter the hostname/Machine-name: " HNAME
	read -rep "Enter Region/Zone Eg.Asia/Kolkata: " RNAME
	br && echo -e "USERNAME = $USER1\nHOSTNAME = $HNAME\nREGION/ZONE = $RNAME" 
	read -rep "Is above data correct? [Y/N]: " DATANY
	if [[ "$DATANY" = 'n' ]] || [[ "$DATANY" = 'N' ]]; then exit; fi
fi
# Time & Locale
ln -sf /usr/share/zoneinfo/"$RNAME" /etc/localtime   && hwclock --systohc
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && locale-gen
echo 'LANG=en_US.UTF-8' >/etc/locale.conf
# HOSTNAME
echo "$HNAME" >/etc/hostname
echo -e "127.0.0.1 $HNAME\n::1 $HNAME\n127.0.1.1 $HNAME.localdomain $HNAME" >/etc/hosts

# ROOT-PASSWORD
br && echo "Setting new Root/Sudo/Admin password [Keep powerfull password in mind]"
if compgen -g | grep &>/dev/null; then true; else groupadd sudo; fi
passwd
# NEWUSER-&-PASSWORD
br && echo "Enter powerfull password for new user \"$USER1\" [Keep powerfull password in mind]"
if compgen -u | grep "$USER1" &>/dev/null; then true; else
	useradd -m -G wheel,power,input,storage,uucp,network -s /usr/bin/bash -N "$USER1" || exit
fi
passwd "$USER1"
EDITOR=nano sed -i 's/^#\s*\(%wheel\s\+ALL=(ALL)\s\+ALL\)/\1/' /etc/sudoers
fi

# INSTALL PARU
read -rep 'Do you want to install paru [Aur helper][Y/N]: ' PARUYN
if [ "$PARUYN" = 'Y' ] || [ "$PARUYN" = 'y' ]; then
if [ -z "$USER1" ]; then read -rep 'Tell username you setted back [This is due to error last time] : ' USER1; else true; fi
sudo -H -u "$USER1" bash -c 'if [[ -f "/home/$USER1/paru" ]]; then true; else git clone --depth=1 https://aur.archlinux.org/paru-bin.git /home/$USER1/paru; fi'
sudo -H -u "$USER1" bash -c 'chmod -R 777 /home/$USER1/paru && cd /home/$USER1/paru && makepkg -s -i -c --noconfirm'
sudo -H -u "$USER1" bash -c 'rm -rf /home/$USER1/paru'
fi

# Add chromium pacman config
curl -s 'https://download.opensuse.org/repositories/home:/ungoogled_chromium/Arch/x86_64/home_ungoogled_chromium_Arch.key' | pacman-key -a -
if grep home_ungoogled_chromium_Arch /etc/pacman.conf &>/dev/null; then
	echo 'Chromium already exist in pacman.conf'
else
	echo -e '\n[home_ungoogled_chromium_Arch]\nSigLevel = Required TrustAll' | tee -a /etc/pacman.conf
	echo -e 'Server = https://download.opensuse.org/repositories/home:/ungoogled_chromium/Arch/$arch' | tee -a /etc/pacman.conf
fi

# Enabling multilib in pacman
sed -i '93s/#\[/\[/' /etc/pacman.conf
sed -i '94s/#I/I/' /etc/pacman.conf
# Tweaking pacman
sed -i 's/#Color/Color/g' /etc/pacman.conf
sed -i 's/#VerbosePkgLists/VerbosePkgLists/g' /etc/pacman.conf

# GRUB-CONFIG
sed -i 's/#GRUB_DISABLE_SUBMENU=y/GRUB_DISABLE_SUBMENU=y/g' /etc/default/grub
sed -i 's/GRUB_DISABLE_RECOVERY=true/#GRUB_DISABLE_RECOVERY=true/g' /etc/default/grub

# Enable Hibernation
br && read -rep "Do you want to enable hibernation support? [Y/N]: " HIBERYN
if [ "${HIBERYN}" = "y" ]; then
	lsblk && br
	read -rep 'Please write name of swap partation [E.g /dev/sda2]: ' SWAPID
	read -rep "SWAP is in $SWAPID. Is it correct? [Y/N]: " SWAPCONFIRM
	if [ "${SWAPCONFIRM}" = "y" ] || [ "${SWAPCONFIRM}" = "Y" ]; then
		SWAP_GRUB="$(blkid "$SWAPID" | cut -d '"' -f2)"
		TEMP2="GRUB_CMDLINE_LINUX_DEFAULT=\"i8042.nopnp udev.log_priority=3 loglevel=3 resume=UUID=$SWAP_GRUB\""
		sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=.*/$TEMP2/g" /etc/default/grub
		sed -i "s/HOOKS=(base.*/HOOKS=(base udev autodetect modconf block filesystems keyboard resume fsck)/g" /etc/mkinitcpio.conf
	else
		exit
	fi
fi		
	
# Networkmanager & disable systemd-resolved
pacman -Sy --needed --noconfirm networkmanager
cat > /etc/NetworkManager/NetworkManager.conf << "EOF"
[main]
#dns=none # need to fix from some linkdin site
systemd-resolved=false
EOF
systemctl enable --now NetworkManager

# Fancontrol
pacman -S --needed --noconfirm lm_sensors
curl -L https://raw.githubusercontent.com/Jrchintu/CDN/main/ARCH/XTRA/fancontrol >/etc/fancontrol
systemctl enable --now fancontrol

# Thermald
pacman -S --needed --noconfirm
systemctl enable --now thermald

# Firewall
pacman -S --needed --noconfirm ufw
systemctl enable --now ufw
ufw default deny incoming
ufw default allow outgoing
ufw enable

# Bluetooth
pacman -S --needed --noconfirm bluez bluez-utils blueman
systemctl enable --now bluetooth

# Pipewire
pacman -S --needed --noconfirm pipewire pipewire-pulse pipewire-media-session pavucontrol
systemctl --now pipewire pipewire-pulse pipewire-media-session

# XFCE Tweaks/WIP
#sed -i 's|#lock-memory=true|lock-memory=true|g' /etc/lightdm/lightdm.conf
#sed -i 's|#greeter-hide-users=false|greeter-hide-users=true|g' /etc/lightdm/lightdm.conf
#sed -i 's|#cache-directory=/var/cache/lightdm|cache-directory=/var/cache/lightdm|g' /etc/lightdm/lightdm.conf

# Fixup Systemd
systemctl daemon-reload
systemctl --now disable avahi-daemon systemd-resolved &>/dev/null
systemctl mask systemd-resolved avahi-daemon
