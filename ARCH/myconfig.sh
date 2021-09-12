#!/usr/bin/env bash

###########################################
# Only For Ext4 ROOT AND HOME PARTATION If Diffrent then modify script
# CREDITS:
# https://www.ubuntupit.com/best-linux-hardening-security-tips-a-comprehensive-checklist/
# https://github.com/ernw/hardening/blob/master/operating_system/linux/ERNW_Hardening_Linux.md#secure-ssh-mandatory
# https://github.com/Jsitech/JShielder/blob/master/UbuntuServer_18.04LTS/jshielder-CIS.sh

# Check root and internet
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root" && exit
    if : >/dev/tcp/8.8.8.8/53; then
        echo 'Welcome to script'
    else
        echo 'offline Please connect...' && exit
    fi
fi
export SUSER="${SUDO_USER:-${USER}}"
noroot(){
		sudo -H -u "$SUSER" bash -c "$1"
}

# Install Fav App's
pacman -Syyu --needed lm_sensors thermald papirus-icon-theme \
    libsecret cracklib man-db man-pages htop byobu aria2 youtube-dl xarchiver-gtk2

# VSCODIUM
paru -S vscodium-bin
# UCODE
paru -S intel-ucode
# NVIDIA
paru -S nvidia-390xx-utils nvidia-390xx-dkms optimus-manager
# INTEL
paru -S xf86-input-libinput xf86-video-intel mesa
# VAAPI
paru -S libva libva-utils libva-intel-driver-hybrid intel-hybrid-codec-driver
echo -e "export LIBVA_DRIVER_NAME='i965'" >>/etc/profile.d/graphic.sh
# VDPAU
paru -S libglvnd libvdpau-va-gl libva-vdpau-driver
echo -e "export VDPAU_DRIVER='va_gl'" >>/etc/profile.d/graphic.sh
# VULKAN
paru -S vulkan-intel vulkan-mesa-layers

# Install DPI TUNNEL
git clone --depth=1 -b master --single-branch https://github.com/zhenyolka/DPITunnel
cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release
make && make install

# Display manager and Windows manager tearing
xfconf-query -c xfwm4 -p /general/vblank_mode -t string -s 'xpresent' --create # Disable xfwm compositor OR set to off/glx/auto
xfconf-query -c xfwm4 -p /general/use_compositing -s false  # Disable xfce compositor
xfconf-query -c xfwm4 -p /general/mousewheel_rollup -s true # SHADE UP ON MOUSE SCROLL
xfconf-query -c xfwm4 -p /general/tile_on_move -s true      # XFCE TILING MODE
xfconf-query -c xfce4-session -p /shutdown/LockScreen -s true
xfconf-query -c xfce4-session -p /general/SaveOnExit -n -t bool -s false
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/lock-screen-suspend-hibernate -s true
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/logind-handle-suspend-key -n -t bool -s true

# Stop Junk service & Some tweaks
systemctl daemon-reload
systemctl --now disable pulseaudio.service pulseaudio.socket avahi-daemon systemd-resolved
systemctl --now enable pipewire pipewire-pulse pipewire-media-session bluetooth thermald tlp fstrim fstrim.timer lightdm preload
systemctl mask pulseaudio systemd-resolved

# Add/Remove Some Junk
pacman -Rcns xfce4-appfinder xterm rsh-server telnet-server
pacman -Rcns "$(pacman -Qtdq)"
paru -Scc
rm -rfv ~/.cache/sessions/* && chmod 500 ~/.cache/sessions
mkdir -p "$HOME"/{Git,Backup}

# Generate init and grub and sysctl
mkinitcpio -c /etc/mkinitcpio.conf -g /boot/initramfs-linux.img -k "$(uname -r)"
grub-mkconfig -o /boot/grub/grub.cfg
sysctl -p
fc-cache -fvr
