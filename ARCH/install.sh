#!/usr/bin/env bash
clear && LC_ALL=C && LANG=C
# CREDITS == https://github.com/prmsrswt/arch-install.sh\

# Some Default Variables
export BOOT1="+512M"
export SWAP1="+6G"
export ROOT1="+50G"
export BIOS1="+1M"
export HOME1="0" # Remaining space

ascii() {
    echo ' $$$$$$\                      $$\             $$$$$$\                       $$\               $$\ $$\ '
    echo '$$  __$$\                     $$ |            \_$$  _|                      $$ |              $$ |$$ |'
    echo '$$ /  $$ | $$$$$$\   $$$$$$$\ $$$$$$$\          $$ |  $$$$$$$\   $$$$$$$\ $$$$$$\    $$$$$$\  $$ |$$ |'
    echo '$$$$$$$$ |$$  __$$\ $$  _____|$$  __$$\         $$ |  $$  __$$\ $$  _____|\_$$  _|   \____$$\ $$ |$$ |'
    echo '$$  __$$ |$$ |  \__|$$ /      $$ |  $$ |        $$ |  $$ |  $$ |\$$$$$$\    $$ |     $$$$$$$ |$$ |$$ |'
    echo '$$ |  $$ |$$ |      $$ |      $$ |  $$ |        $$ |  $$ |  $$ | \____$$\   $$ |$$\ $$  __$$ |$$ |$$ |'
    echo '$$ |  $$ |$$ |      \$$$$$$$\ $$ |  $$ |      $$$$$$\ $$ |  $$ |$$$$$$$  |  \$$$$  |\$$$$$$$ |$$ |$$ |'
    echo '\__|  \__|\__|       \_______|\__|  \__|      \______|\__|  \__|\_______/    \____/  \_______|\__|\__|'
    echo '                                                                                                      '
    echo '                                                                                                      '
}

br() {
    for ((i = 1; i <= $(tput cols); i++)); do echo -n -; done
}

tablegpt() {
    echo '' && echo """$DRIVE2EDIT""1 [efi] = $BOOT1"
    echo """$DRIVE2EDIT""2 [swap] = $SWAP1"
    echo """$DRIVE2EDIT""3 [root] = $ROOT1"
    echo """$DRIVE2EDIT""4 [home] = $HOME1 [0=All remaining space]" && echo ''
}

updatestuff() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root" && exit
        if : >/dev/tcp/8.8.8.8/53; then
            echo ''
        else echo 'Offline Please connect...[Use iwctl command then type help]' && exit; fi
    fi
    pacman -Syyy --noconfirm
}

partationing() {
    clear && echo -e '1. Create New Partation table [Recommended for new installs]'
    echo -e '2. Edit Old Partation table with cgdisk [Recommended for Pro user]'
    echo -e '3. Skip partationing [Choose only if you know partition is correct]'
    read -rep ':> ' OLDNEW
    if [[ "$OLDNEW" = '1' ]]; then
        read -rep "Which drive you want to partition (example /dev/sda)?: " DRIVE2EDIT
        clear && br && echo "We will create and format the partitions as follows:" && tablegpt && br
        read -rep 'Want to edit ? [Y/N]: ' FSOK
        if [[ "$FSOK" = 'y' ]] || [[ "$FSOK" = 'Y' ]]; then
            clear
            echo "Enter Size For   /Boot    [Default= $BOOT1][Use 0 For All Free Space & G=Gb;M=Mb & ctrl+c For Default]"
            read -re -i "$BOOT1" BOOT1
            clear
            echo "Enter Size For   /Swap    [Default= $SWAP1][Use 0 For All Free Space & G=Gb;M=Mb & ctrl+c For Default]"
            read -re -i "$SWAP1" SWAP1
            clear
            echo "Enter Size For   /Root    [Default= $ROOT1][Use 0 For All Free Space & G=Gb;M=Mb & ctrl+c For Default]"
            read -re -i "$ROOT1" ROOT1
            clear
            echo "Enter Size For   /Bios    [Default= $ROOT1][Use 0 For All Free Space & G=Gb;M=Mb & ctrl+c For Default]"
            read -re -i "$BIOS1" BIOS1
            clear
            echo "Enter Size For   /Home    [Default= $HOME1][Use 0 For All Free Space & G=Gb;M=Mb & ctrl+c For Default]"
            read -re -i "$HOME1" HOME1
        fi
        clear && br && tablegpt && lsblk && br
        read -rep 'All Good, shall i write table to disk? [Y/N]: ' FSOK
        if [[ "$FSOK" = 'y' ]] || [[ "$FSOK" = 'Y' ]]; then
            # Make partation table {x:x:x}=={partation_no:starting_block:desired_size}
            sgdisk -Z "$DRIVE2EDIT"                                    # Destroy existing mbr or gpt structures on disk
            sgdisk -a 2048 -o                                          # New gpt disk 2048 alignment
            sgdisk -n 1:0:"$ROOT1" -t 1:8300 -c 1:"ROOT" "$DRIVE2EDIT" # Part 1 (ROOT), default start, 60GB
            sgdisk -n 3:0:"$SWAP1" -t 3:8200 -c 3:"SWAP" "$DRIVE2EDIT" # Part 3 (SWAP), default start, 6GB
            sgdisk -n 4:0:"$BOOT1" -t 4:ef00 -c 4:"BOOT" "$DRIVE2EDIT" # Part 4 (BOOT), default start, 512MB
            sgdisk -n 5:0:"$BIOS1" -t 5:ef02 -c 5:"BIOS" "$DRIVE2EDIT" # Part 5 (BIOS), default start, 1MB
            sgdisk -n 2:0:"$HOME1" -t 2:8300 -c 2:"HOME" "$DRIVE2EDIT" # Part 2 (HOME), default start, Remaning space

            # Inform the OS of partition table changes
            sgdisk -p "$DRIVE2EDIT"
            clear && br && echo "Press any key to write partation table to disk or ctrl+c to exit" && br
            read -r TMPVAR
            partprobe "$DRIVE2EDIT"
        else
            clear && lsblk && br
            read -rep "Which drive you want to partition [Exit with ctrl+c] (example /dev/sda) ? " DRIVE2EDIT
            # Using cgdisk for GPT, for mbr use cfdisk
            cgdisk "$DRIVE2EDIT"
        fi
    elif [ "$OLDNEW" = '2' ]; then
        clear && lsblk && br
        read -rep "Which drive you want to partition [Exit with ctrl+c] (example /dev/sda) ? " DRIVE2EDIT
        # Using cgdisk for GPT, for mbr use cfdisk
        cgdisk "$DRIVE2EDIT"
    else
        true
    fi
}

mounting() {
    clear && lsblk && br
    read -r -p "Which is your root partition [Eg. /dev/sda3]?: " ROOTP
    mkfs.ext4 "$ROOTP"
    mount -o "defaults,noatime" "$ROOTP" /mnt
    mkdir -pv /mnt/{boot/efi,home}

    clear && lsblk && br
    read -r -p "Which is your boot partition [Eg. /dev/sda1]?: " BOOTP
    read -r -p "Do you want to format your boot partition? [y/N] " RESPB
    case "$RESPB" in
    [yY][eE][sS] | [yY])
        mkfs.fat -F32 "$BOOTP"
        ;;
    *) ;;

    esac
    mount -o "defaults,noatime,nosuid,nodev" "$BOOTP" /mnt/boot/efi

    clear && lsblk && br
    read -r -p "Do you want to use a seperate home partition? [y/N]: " RESPH
    case "$RESPH" in
    [yY][eE][sS] | [yY])
        read -rep "which is your home partition? [Eg. /dev/sda4]: " HOMEP
        read -rep "Do you want to ***FORMAT*** your /home partition?[Y/N]: " TMPVAR
        read -rep 'Literally, do you want to **FORMAT** /home partation?[Y/N]: ' RESPRMH
        case "$RESPRMH" in
        [yY][eE][sS] | [yY])
            mkfs.ext4 "$HOMEP"
            ;;
        *) ;;

        esac
        mount -o "defaults,noatime,nosuid,nodev" "$HOMEP" /mnt/home
        ;;
    *) ;;

    esac

    clear && lsblk && br
    read -r -p "Do you want to use a seperate SWAP partition? [y/N] " RESPS
    case "$RESPS" in
    [yY][eE][sS] | [yY])
        read -r -p "Which Is Your Swap Partition [Eg. /dev/sda2]? " SWAPP && export SWAPP
        mkswap "$SWAPP"
        swapon "$SWAPP"
        ;;
    *) ;;

    esac
}

base() {
    br && echo "Starting installation of packages in selected root drive..."
    read -rep "Do you want to use your old saved packages directory [Y/N]: " PACBDIR
    if [ "$PACBDIR" = 'y' ] || [ "$PACBDIR" = 'Y' ]; then
        arch-chroot /mnt bash -c "sed -i 's|#CacheDir    = /var/cache/pacman/pkg/|CacheDir    = /home/SAFE/pkg/|g' /etc/pacman.conf"
    fi
    pacstrap /mnt base linux-firmware linux-zen linux-zen-headers \
		base-devel grub efibootmgr nano sudo git
    genfstab -U /mnt >/mnt/etc/fstab
}

chrootstuff() {
    br && echo -e "Entering Chroot...\n"
    arch-chroot /mnt bash -c "curl -LO https://github.com/Jrchintu/CDN/raw/main/ARCH/chroot.sh && exit"
    arch-chroot /mnt bash -c "chmod a+x /chroot.sh && exit"
    arch-chroot /mnt bash -c "bash /chroot.sh && exit"
}

de() {
    br && echo -e "Choose a Desktop Environment to install: \n"
    echo -e "1. GNOME \n2. DEEPIN \n3. KDE \n4. XFCE"
    read -rep "DE[1-4]: " DESKTOPE
    case "$DESKTOPE" in
    1)
        pacstrap /mnt gnome gnome-tweaks papirus-icon-theme
        arch-chroot /mnt bash -c "systemctl enable gdm && exit"
        # Editing gdm's config for disabling Wayland as it does not play nicely with Nvidia
        arch-chroot /mnt bash -c "sed -i 's/#W/W/' /etc/gdm/custom.conf && exit"
        ;;
    2)
        pacstrap /mnt deepin lightdm gedit
        arch-chroot /mnt bash -c "systemctl enable lightdm && exit"
        ;;
    3)
        pacstrap /mnt xorg-server plasma sddm
        arch-chroot /mnt bash -c "systemctl enable sddm && exit"
        ;;
    4)
        pacstrap /mnt xfce4 xorg-server lightdm lightdm-gtk-greeter \
        gtk-engine-murrine gtk-engines xfce4-screenshooter xfce4-power-manager \
        xfce4-whiskermenu-plugin xfce4-pulseaudio-plugin xfce4-battery-plugin network-manager-applet \
        gvfs gvfs-mtp mtpfs thunar-media-tags-plugin accountsservice
        arch-chroot /mnt bash -c "systemctl enable lightdm && exit"
        ;;
    *) ;;

    esac
}

installgrub() {
    br && echo -e "Installing GRUB.."
    arch-chroot /mnt bash -c "grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Arch && exit"
    arch-chroot /mnt bash -c "grub-mkconfig -o /boot/grub/grub.cfg && exit"
}

browser() {
    br && read -r -p "Install Ungoogled-Chromium Browser? [y/N]: " chrom
    case "$chrom" in
    [yY][eE][sS] | [yY])
        arch-chroot /mnt bash -c "pacman -Sy ungoogled-chromium gnome-keyring && exit"
        ;;
    *) ;;

    esac
    read -r -p "Install FireFox Browser? [y/N] " ff
    case "$ff" in
    [yY][eE][sS] | [yY])
        pacstrap /mnt firefox
        ;;
    *) ;;

    esac
}

extrastuff() {
    br
    read -r -p "Do you want to install any Extra packages? [y/N] " extrayes
    case "$extrayes" in
    [yY][eE][sS] | [yY])
        read -r -p "You can name some apps also [Ex. byobu <space> tmux <space> screen]: " xtraa
        pacstrap /mnt neofetch "$xtraa"
        ;;
    *) ;;

    esac
}

main() {
    echo "These Steps Are Available For Installion Usually choose 1."
    echo ""
    echo "1.  Update Pacman"
    echo "2.  Create/Edit Partation Table"
    echo "3.  Mount Partations"
    echo "4.  Base Arch install"
    echo "5.  Chroot Stuff"
    echo "6.  DesktopEnv"
    echo "7.  Grub"
    echo "8.  Browser"
    echo "9.  Extra packages"
    br && read -rep "Enter the number of step [1-9]: " stepno && clear

    array=(updatestuff partationing mounting base chrootstuff de installgrub browser extrastuff)
    stepno=$((stepno - 1))
    while [ $stepno -lt ${#array[*]} ]; do
        ${array[$stepno]}
        stepno=$((stepno + 1))
    done
}

clear
ascii
br
main

# EXIT
umount -f /mnt
umount -f /mnt/home
umount -f /mnt/boot/efi
swapoff -a
read -rep 'Do you want to reboot?[Y/N]: ' REBOOTYN
if [ "$REBOOTYN" = 'y' ] || [ "$REBOOTYN" = 'Y' ]; then
    echo 'Rebooting, remember to say "I use arch BTW"'
    reboot
fi
