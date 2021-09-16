#!/usr/bin/env bash

# Some Default Variables
clear && LC_ALL=C && LANG=C
export BOOTSZ="+512M"
export SWAPSZ="+6G"
export ROOTSZ="+50G"
export BIOSSZ="+1M"
export HOMESZ="0" # Remaining space

ascii() {
    echo ' $$$$$$\                      $$\             $$$$$$\                       $$\               $$\ $$\ '
    echo '$$  __$$\                     $$ |            \_$$  _|                      $$ |              $$ |$$ |'
    echo '$$ /  $$ | $$$$$$\   $$$$$$$\ $$$$$$$\          $$ |  $$$$$$$\   $$$$$$$\ $$$$$$\    $$$$$$\  $$ |$$ |'
    echo '$$$$$$$$ |$$  __$$\ $$  _____|$$  __$$\         $$ |  $$  __$$\ $$  _____|\_$$  _|   \____$$\ $$ |$$ |'
    echo '$$  __$$ |$$ |  \__|$$ /      $$ |  $$ |        $$ |  $$ |  $$ |\$$$$$$\    $$ |     $$$$$$$ |$$ |$$ |'
    echo '$$ |  $$ |$$ |      $$ |      $$ |  $$ |        $$ |  $$ |  $$ | \____$$\   $$ |$$\ $$  __$$ |$$ |$$ |'
    echo '$$ |  $$ |$$ |      \$$$$$$$\ $$ |  $$ |      $$$$$$\ $$ |  $$ |$$$$$$$  |  \$$$$  |\$$$$$$$ |$$ |$$ |'
    echo '\__|  \__|\__|       \_______|\__|  \__|      \______|\__|  \__|\_______/    \____/  \_______|\__|\__|'
    echo '# EDIT BEFORE USING. NO ONE WILL BE RESPONSIBLE IF ANYTHING WENT WRONG.                                '
    echo '# CREDITS == https://github.com/prmsrswt/arch-install                                                 '
    echo '# PRO USER MEANS WHO KNOW WHATS HAPPENING IN BACKGROUND OF SCRIPT.                                    '
}

br() {
    for ((i = 1; i <= $(tput cols); i++)); do echo -n -; done
}

tablegpt() {
	echo ""$DRIVE2EDIT"1 ROOT = $ROOTSZ"
	echo ""$DRIVE2EDIT"2 HOME = $HOMESZ"
    echo ""$DRIVE2EDIT"3 SWAP = $SWAPSZ"
    echo ""$DRIVE2EDIT"4 ROOT = $BOOTSZ"
    echo ""$DRIVE2EDIT"5 BIOS = $BIOSSZ"
}

updates() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root" && exit
        if : >/dev/tcp/8.8.8.8/53; then
            echo ''
        else echo 'Offline Please connect...[Use iwctl command then type help]' && exit; fi
    fi
    timedatectl set-ntp true
    pacman -Syyy --noconfirm
}

partition() {
    clear && echo -e '1. Create New partition table [Recommended for new installs]'
    echo -e '2. Edit Old partition table with cgdisk [Only for Pro user]'
    echo -e '3. Skip partition [Only for Pro user]'
    read -rp ': ' OLDNEW
    if [[ "$OLDNEW" = '1' ]]; then
        read -rp "Which drive you want to partition (example /dev/sda)?: " DRIVE2EDIT
        clear && br && echo "We will create and format the partitions as follows:" && tablegpt && br
        read -rp 'Want to edit ? [Y/N]: ' FSOK
        if [[ "$FSOK" = 'y' ]] || [[ "$FSOK" = 'Y' ]]; then
            clear
            echo "Enter Size For   /Boot    [Default= $BOOTSZ][Use 0 For All Free Space & G=Gb;M=Mb & ctrl+c For Default]"
            read -re -i "$BOOTSZ" BOOTSZ
            clear
            echo "Enter Size For   /Swap    [Default= $SWAPSZ][Use 0 For All Free Space & G=Gb;M=Mb & ctrl+c For Default]"
            read -re -i "$SWAPSZ" SWAPSZ
            clear
            echo "Enter Size For   /Root    [Default= $ROOTSZ][Use 0 For All Free Space & G=Gb;M=Mb & ctrl+c For Default]"
            read -re -i "$ROOTSZ" ROOTSZ
            clear
            echo "Enter Size For   /Bios    [Default= $ROOTSZ][Use 0 For All Free Space & G=Gb;M=Mb & ctrl+c For Default]"
            read -re -i "$BIOSSZ" BIOSSZ
            clear
            echo "Enter Size For   /Home    [Default= $HOMESZ][Use 0 For All Free Space & G=Gb;M=Mb & ctrl+c For Default]"
            read -re -i "$HOMESZ" HOMESZ
        fi
        clear && br && tablegpt && lsblk -af && br
        read -rp 'All Good ? [Y/N]: ' FSOK
        if [[ "$FSOK" = 'y' ]] || [[ "$FSOK" = 'Y' ]]; then
            # Make partition table {x:x:x}=={partition_no:starting_block:desired_size}
            sgdisk -Z "$DRIVE2EDIT"                                    # Destroy existing mbr or gpt structures on disk
            sgdisk -a 4096 -o                                          # New gpt disk 4096 alignment
            sgdisk -n 1:0:"$ROOTSZ" -t 1:8300 -c 1:"ROOT" "$DRIVE2EDIT" # Part 1 (ROOT), default start, 60GB
            sgdisk -n 3:0:"$SWAPSZ" -t 3:8200 -c 3:"SWAP" "$DRIVE2EDIT" # Part 3 (SWAP), default start, 6GB
            sgdisk -n 4:0:"$BOOTSZ" -t 4:ef00 -c 4:"BOOT" "$DRIVE2EDIT" # Part 4 (BOOT), default start, 512MB
            sgdisk -n 5:0:"$BIOSSZ" -t 5:ef02 -c 5:"BIOS" "$DRIVE2EDIT" # Part 5 (BIOS), default start, 1MB
            sgdisk -n 2:0:"$HOMESZ" -t 2:8300 -c 2:"HOME" "$DRIVE2EDIT" # Part 2 (HOME), default start, Remaning space

            # Inform the OS of partition table changes
            sgdisk -p "$DRIVE2EDIT"
            clear && br && echo "Press any key to write partition table to disk or ctrl+c to exit" && br
            read -r TMPVAR
            partprobe "$DRIVE2EDIT"
        else
            clear && lsblk -af && br
            read -rp "Which drive you want to partition [Exit with ctrl+c] (example /dev/sda) ? " DRIVE2EDIT
            # Using cgdisk for GPT, for mbr use cfdisk
            cgdisk "$DRIVE2EDIT"
        fi
    elif [ "$OLDNEW" = '2' ]; then
        clear && lsblk -af && br
        read -rp "Which drive you want to partition [Exit with ctrl+c] (example /dev/sda) ? " DRIVE2EDIT
        # Using cgdisk for GPT, for mbr use cfdisk
        cgdisk "$DRIVE2EDIT"
    elif [ "$OLDNEW" = '3' ]; then
        true
    else
        exit
    fi
}

mounting() {
    clear && lsblk -af && br
    read -rp "Which is your root partition [Eg. /dev/sda3]?: " ROOTP
    mkfs.ext4 "$ROOTP"
    mount -o "defaults,noatime" "$ROOTP" /mnt
    mkdir -pv /mnt/{boot/efi,home}

    clear && lsblk -af && br
    read -rp "Which is your boot partition [Eg. /dev/sda1]?: " BOOTP
    read -rp "Do you want to format your boot partition? [y/N]: " RESPB
    case "$RESPB" in
    [yY][eE][sS] | [yY])
        mkfs.fat -F32 "$BOOTP"
        ;;
    *) ;;

    esac
    mount -o "defaults,noatime,nosuid,nodev" "$BOOTP" /mnt/boot/efi

    clear && lsblk -af && br
    read -rp "Do you want to use a seperate home partition? [y/N]: " RESPH
    case "$RESPH" in
    [yY][eE][sS] | [yY])
    read -rp "Which is your home partition? [Eg. /dev/sda4]: " HOMEP
    read -rp "Do you want to ***FORMAT*** your /home partition?[Y/N]: " TMPVAR
    read -rp 'Literally, do you want to **FORMAT** /home partition?[Y/N]: ' RESPRMH
    case "$RESPRMH" in
    [yY][eE][sS] | [yY])
        mkfs.ext4 "$HOMEP"
        mount -o "defaults,noatime,nosuid,nodev" "$HOMEP" /mnt/home
        ;;
    *) ;;

    esac

    clear && lsblk -af && br
    read -rp "Do you want to use a seperate SWAP partition? [Y/N]: " RESPS
    case "$RESPS" in
    [yY][eE][sS] | [yY])
        read -r -p "Which Is Your Swap Partition [Eg. /dev/sda2]?: " SWAPP
        mkswap -c "$SWAPP"
        swapon "$SWAPP"
        ;;
    *) ;;

    esac
}

base() {
    br && echo "Starting installation of packages in selected root drive..."
    read -rp "Do you want to use your old saved packages directory?[FOR PRO USER ONLY][Y/N]: " PACBDIR
    if [ "$PACBDIR" = 'y' ] || [ "$PACBDIR" = 'Y' ]; then
        sed -i 's|#CacheDir    = /var/cache/pacman/pkg/|CacheDir    = /home/me/PKG/|g' /mnt/etc/pacman.conf
        sed -i 's|#CacheDir    = /var/cache/pacman/pkg/|CacheDir    = /mnt/home/me/PKG/|g' /etc/pacman.conf
    fi
    pacstrap /mnt base linux-firmware linux-zen linux-zen-headers base-devel grub efibootmgr nano sudo git
    genfstab -U /mnt >/mnt/etc/fstab
}

chroots() {
    br && echo -e "Entering Chroot...\n"
    arch-chroot /mnt bash -c "curl -LO https://github.com/Jrchintu/CDN/raw/main/ARCH/chroot.sh && exit"
    arch-chroot /mnt bash -c "chmod a+x /chroot.sh && bash /chroot.sh && exit"
}

de() {
    br && echo -e "Choose a Desktop Environment to install: \n"
    echo -e "1. GNOME \n2. DEEPIN \n3. KDE \n4. XFCE"
    read -rp "DE[1-4]: " DESKTOPE
    case "$DESKTOPE" in
    1)
        pacstrap /mnt gnome gnome-tweaks papirus-icon-theme
        arch-chroot /mnt bash -c "systemctl enable --now gdm && exit"
        # Editing gdm's config for disabling Wayland as it does not play nicely with Nvidia
        sed -i 's/#W/W/' /mnt/etc/gdm/custom.conf
        ;;
    2)
        pacstrap /mnt deepin lightdm
        arch-chroot /mnt bash -c "systemctl enable --now lightdm && exit"
        ;;
    3)
        pacstrap /mnt xorg-server plasma sddm
        arch-chroot /mnt bash -c "systemctl enable --now sddm && exit"
        ;;
    4)
        pacstrap /mnt xfce4 xorg-server lightdm lightdm-gtk-greeter gtk-engine-murrine gtk-engines \
        xfce4-whiskermenu-plugin xfce4-pulseaudio-plugin xfce4-battery-plugin network-manager-applet \
        gvfs gvfs-mtp mtpfs thunar-media-tags-plugin thunar-archive-plugin accountsservice xfce4-screenshooter
        arch-chroot /mnt bash -c "systemctl enable --now lightdm && exit"
        sed -i 's|#greeter-hide-users=false|greeter-hide-users=true|g' /mnt/etc/lightdm/lightdm.conf
        ;;
    *) ;;

    esac
}

igrub() {
	sed -i 's|CacheDir|#CacheDir|g' /mnt/etc/pacman.conf # Dont use our pkg dir for other junk now
    br && echo -e "Installing GRUB.."
    arch-chroot /mnt bash -c "grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Arch && exit"
    arch-chroot /mnt bash -c "grub-mkconfig -o /boot/grub/grub.cfg && exit"
}

main() {
    echo -e "These Steps Are Available For Installion [Usually choose 1].\n"
    echo "1.  Update Pacman"
    echo "2.  Create/Edit partition Table"
    echo "3.  Mount partition"
    echo "4.  Install Base Arch"
    echo "5.  Chroot Stuff"
    echo "6.  DesktopEnv"
    echo "7.  Grub"
    br && read -rp "Enter the number of step [1-7]: " stepno && clear

    array=(updates partition mounting base chroots de igrub)
    stepno=$((stepno - 1))
    while [ $stepno -lt ${#array[*]} ]; do
        ${array[$stepno]}
        stepno=$((stepno + 1))
    done
}

# STEPS
clear
ascii
br
main
sed -i 's|CacheDir|#CacheDir|g' /mnt/etc/pacman.conf
umount -fvR /mnt
umount -fvR /mnt/home
umount -fvR /mnt/boot/efi
swapoff -av
read -rp 'Do you want to reboot?[Y/N]: ' REBOOTYN
if [ "$REBOOTYN" = 'y' ] || [ "$REBOOTYN" = 'Y' ]; then
    echo 'Rebooting, remember to say "I use arch BTW"'
    reboot
fi
