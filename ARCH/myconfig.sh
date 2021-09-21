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
noroot() {
	sudo -H -u "$SUSER" bash -c "$1"
}

# Make my fav dirs
mkdir -p "$SUSER"/{Git,Backup}

# Install Fav App's
pacman -Sy --needed lm_sensors thermald papirus-icon-theme gnome-keyring x86_energy_perf_policy \
	libsecret cracklib man-db man-pages alacritty ttf-hack ttf-lato aria2 youtube-dl xarchiver-gtk2
# EXTRA FAV
paru -S usbip vscodium-bin preload && systemctl --now enable preload

# INTEL
paru -S intel-ucode mesa
# NVIDIA [Need reboot]
paru -S nvidia-390xx-utils nvidia-390xx-dkms optimus-manager nvidia-settings acpi_call-dkms #bbswitch-dkms
systemctl enable optimus-manager
# XORG-DRIVERS
pacman -S --needed xf86-video-{fbdev,vesa,intel,libinput}
# VAAPI [check with vainfo in libva-utils package]
paru -S libva libva-intel-driver-hybrid intel-hybrid-codec-driver
echo -e "export LIBVA_DRIVER_NAME='i965'" >>/etc/profile.d/env.sh && chmod a+x /etc/profile.d/env.sh
# VDPAU [check with vdpauinfo]
paru -S libglvnd libvdpau-va-gl libva-vdpau-driver mesa-vdpau
echo -e "export VDPAU_DRIVER='va_gl'" >>/etc/profile.d/env.sh && chmod a+x /etc/profile.d/env.sh
# VULKAN
paru -S vulkan-intel vulkan-mesa-layers
# XORG CONFIG [Need Xorg video drivers]
echo -e 'Section "Device"
  Identifier  "Intel Graphics"
  Driver      "intel"
  Option      "DRI" "3"            # Default
  #Option      "DRI" "2"            # Fallback
  Option      "AccelMethod"  "sna" # Default
  #Option      "AccelMethod"  "uxa" # Fallback
  Option      "TearFree" "true" # Dont wrk with uxa
EndSection' >/etc/X11/xorg.conf.d/20-intel.conf
# Enabling Early KMS
sed -i 's|MODULES=()|MODULES=(i915)|g' /etc/mkinitcpio.conf
# Enable framebuffer compression [For intel gpu >6-gen]
echo -e 'options i915 enable_fbc=1' >>/etc/modprobe.d/i915.conf
# Enable Fastboot
echo -e 'options i915 fastboot=1' >>/etc/modprobe.d/i915.conf
# TLP
paru -S tlp ethtool x86_energy_perf_policy && systemctl enable --now tlp

# Fancontrol
pacman -S --needed --noconfirm lm_sensors && systemctl enable --now fancontrol
curl -L https://raw.githubusercontent.com/Jrchintu/CDN/main/ARCH/XTRA/fancontrol >/etc/fancontrol

# Thermald [Need /etc/thermald/thermald-config.xml]
pacman -S --needed --noconfirm thermald && systemctl enable --now thermald

# Display manager and Windows manager tearing
xfconf-query -c xfwm4 -p /general/vblank_mode -t string -s 'off' --create # Disable xfwm compositor OR set to off/glx/auto
xfconf-query -c xfwm4 -p /general/use_compositing -s false                # Disable xfce compositor
xfconf-query -c xfwm4 -p /general/mousewheel_rollup -s true               # SHADE UP ON MOUSE SCROLL
xfconf-query -c xfwm4 -p /general/tile_on_move -s true                    # XFCE TILING MODE
xfconf-query -c xfce4-session -p /shutdown/LockScreen -n -t bool -s true --create
xfconf-query -c xfce4-session -p /general/SaveOnExit -n -t bool -s false --create
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/lock-screen-suspend-hibernate -n -t bool -s true --create
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/logind-handle-suspend-key -n -t bool -s true --create

# Use new systemd-swap
sudo pacman -S systemd-swap
sudo bash -c 'echo -e "zswap_enabled=0\nzram_enabled=0\nswapfc_enabled=1" > /etc/systemd/swap.conf.d/myswap.conf'
systemd-swap start

# Generate init and grub and sysctl
mkinitcpio -P
grub-mkconfig -o /boot/grub/grub.cfg
sysctl -p
fc-cache -fvr
