#!/usr/bin/env bash
clear
LC_ALL=C
LANG=C

# ORIGINAL == https://github.com/prmsrswt/arch-install.sh
# Some Default Variables
export BOOT1="+512M"
export SWAP1="+6G"
export ROOT1="+60G"
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
    echo '' && echo """$pdrive""1 [efi] = $BOOT1"
    echo """$pdrive""2 [swap] = $SWAP1"
    echo """$pdrive""3 [root] = $ROOT1"
    echo """$pdrive""4 [home] = $HOME1 [0=All remaining space]" && echo ''
}

cont() {
    clear && read -rep "[SUCCESS] Continue to next step? [Y/n] " continue
    case $continue in
    [Nn][oO] | [nN])
        exit
        ;;
    *) ;;

    esac
}

updatestuff() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root" && exit
        if : >/dev/tcp/8.8.8.8/53; then
            echo ''
        else echo 'offline Please connect...' && exit; fi
    fi
    br && read -r -p "Do you want to update pacman source? [y/N] " resp
    case "$resp" in
    [yY][eE][sS] | [yY])
        echo "Setting time...."
        timedatectl set-local-rtc 1 --adjust-system-clock
        echo "Please wait updating source...."
        pacman -Syy --noconfirm
        ;;
    *) ;;
    esac
    cont
}

partationing() {
    read -rep 'Type Y for new Partation table or N for Editing old table with cgdisk: ' oldnew
    if [[ "$oldnew" = 'y' ]] || [[ "$oldnew" = 'Y' ]]; then
        read -rep "Which drive you want to partition (example /dev/sda)? " pdrive
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
            echo "Enter Size For   /Home    [Default= $HOME1][Use 0 For All Free Space & G=Gb;M=Mb & ctrl+c For Default]"
            read -re -i "$HOME1" HOME1
        fi
        clear && br && tablegpt && lsblk && br
        read -rep 'All Good, Shall i write table to disk ? [Y/N]: ' FSOK
        if [[ "$FSOK" = 'y' ]] || [[ "$FSOK" = 'Y' ]]; then
            # Make partation table {x:x:x}=={partation_no:starting_block:desired_size}
            sgdisk -Z "$pdrive"                                    # destroy existing mbr or gpt structures on disk
            sgdisk -a 2048 -o                                      # new gpt disk 2048 alignment
            sgdisk -n 1:0:"$ROOT1" -t 1:8300 -c 1:"root" "$pdrive" # partition 1 (ROOT), default start, 60GB
            sgdisk -n 3:0:"$SWAP1" -t 3:8200 -c 3:"swap" "$pdrive" # partition 3 (SWAP), default start, 6GB
            sgdisk -n 4:0:"$BOOT1" -t 4:ef00 -c 4:"boot" "$pdrive" # partition 4 (BOOT), default start, 512MB
            sgdisk -n 2:0:"$HOME1" -t 2:8300 -c 2:"home" "$pdrive" # partition 2 (HOME), default start, Remaning space

            # Inform the OS of partition table changes
            sgdisk -p "$pdrive"
            clear && br && echo "Press any key to write partation table to disk or ctrl+c to exit" && br
            read -r tmpvar
            partprobe "$pdrive"
        else
            clear && lsblk && br
            read -rep "Which drive you want to partition [Exit with ctrl+c] (example /dev/sda) ? " pdrive
            # Using cgdisk for GPT, for mbr use cfdisk
            cgdisk "$pdrive"
        fi
    else
        clear && lsblk && br
        read -rep "Which drive you want to partition [Exit with ctrl+c] (example /dev/sda) ? " pdrive
        # Using cgdisk for GPT, for mbr use cfdisk
        cgdisk "$pdrive"
    fi
    cont
}

mounting() {
    clear && lsblk && br
    read -r -p "Which is your root partition [Eg. /dev/sda3]? " rootp
    mkfs.ext4 "$rootp"
    mount -o "defaults,noatime" "$rootp" /mnt
    mkdir -pv /mnt/{boot/efi,home}

    clear && lsblk && br
    read -r -p "Which is your boot partition [Eg. /dev/sda1]? " bootp
    read -r -p "Do you want to format your boot partition? [y/N] " response
    case "$response" in
    [yY][eE][sS] | [yY])
        mkfs.fat -F32 "$bootp"
        ;;
    *) ;;

    esac
    mount -o "defaults,noatime" "$bootp" /mnt/boot/efi

    clear && lsblk && br
    read -r -p "Do you want to use a seperate home partition? [y/N] " responsehome
    case "$responsehome" in
    [yY][eE][sS] | [yY])
        read -r -p "which is your home partition [Eg. /dev/sda4]? " homep
        read -r -p "Do you want to ***FORMAT*** your home partition? [y/N] " rhome
        case "$rhome" in
        [yY][eE][sS] | [yY])
            mkfs.ext4 "$homep"
            ;;
        *) ;;

        esac
        mount -o "defaults,noatime" "$homep" /mnt/home
        ;;
    *) ;;

    esac

    clear && lsblk && br
    read -r -p "Do you want to use a seperate SWAP partition? [y/N] " responseswap
    case "$responseswap" in
    [yY][eE][sS] | [yY])
        read -r -p "Which Is Your Swap Partition [Eg. /dev/sda2]? " swapp
        mkswap "$swapp"
        swapon "$swapp"
        ;;
    *) ;;

    esac
    cont
}

base() {
    br
    echo "Starting installation of packages in selected root drive..."
    sleep 1
    pacstrap /mnt base linux-firmware linux-zen linux-zen-headers \
        nano sudo git xf86-video-intel intel-ucode mesa \
        base-devel ttf-liberation geany \
        networkmanager ufw \
        grub efibootmgr
    genfstab -U /mnt >>/mnt/etc/fstab
    cont
}

chrootstuff() {
    br && echo 'Chrooting Into Installed Archlinux'
    read -rep "Enter the username: " USER1
    read -rep "Enter the hostname: " HNAME
    read -rep "Enter Region/Zone Eg.Asia/Kolkata:" RNAME

    clear && echo -e "Entering Chroot...\n"
    arch-chroot /mnt bash -c "curl -LO https://github.com/Jrchintu/CDN/raw/main/ARCH/chroot.sh && exit"
    arch-chroot /mnt bash -c "sudo chmod -R 777 /chroot.sh && exit"
    arch-chroot /mnt bash -c "bash /chroot.sh && exit"    

    cont
}

install-gnome() {
    pacstrap /mnt gnome gnome-tweaks papirus-icon-theme
    arch-chroot /mnt bash -c "systemctl enable gdm && exit"
    # Editing gdm's config for disabling Wayland as it does not play nicely with Nvidia
    arch-chroot /mnt bash -c "sed -i 's/#W/W/' /etc/gdm/custom.conf && exit"
}
install-deepin() {
    pacstrap /mnt deepin lightdm gedit
    arch-chroot /mnt bash -c "systemctl enable lightdm && exit"
}
install-kde() {
    pacstrap /mnt xorg-server plasma sddm
    arch-chroot /mnt bash -c "systemctl enable sddm && exit"
    pacstrap /mnt ark dolphin ffmpegthumbs gwenview kaccounts-integration kate kdialog kio-extras konsole ksystemlog okular
}
install-xfce() {
    pacstrap /mnt xfce4 xorg-server lightdm lightdm-gtk-greeter
    arch-chroot /mnt bash -c "systemctl enable lightdm && exit"
    arch-chroot /mnt bash -c "xfconf-query -c xfwm4 -p /general/use_compositing -s false && exit"
}

de() {
    br
    echo -e "Choose a Desktop Environment to install: \n"
    echo -e "1. GNOME \n2. DEEPIN \n3. KDE \n4. XFCE"
    read -r -p "DE: " desktope
    case "$desktope" in
    1)
        install-gnome
        ;;
    2)
        install-deepin
        ;;
    3)
        install-kde
        ;;
    4)
        install-xfce
        ;;
    *) ;;

    esac
    cont
}

installgrub() {
    read -r -p "Install GRUB bootloader? [y/N] " igrub
    case "$igrub" in
    [yY][eE][sS] | [yY])
        echo -e "Installing GRUB.."
        arch-chroot /mnt bash -c "grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Arch && grub-mkconfig -o /boot/grub/grub.cfg && exit"
        ;;
    *) ;;

    esac
    cont
}

browser() {
    br
    read -r -p "Install Ungoogled-Chromium? [y/N] " chrom
    case "$chrom" in
    [yY][eE][sS] | [yY])
        arch-chroot /mnt bash -c "pacman -Sy ungoogled-chromium && exit"
        ;;
    *) ;;

    esac
    read -r -p "Install FireFox? [y/N] " ff
    case "$ff" in
    [yY][eE][sS] | [yY])
        pacstrap /mnt firefox
        ;;
    *) ;;

    esac

    cont
}

invidia() {
    br
    read -r -p "Do you want proprietary nvidia-390xx-dkms drivers? [y/N] " grapigs
    case "$grapigs" in
    [yY][eE][sS] | [yY])
        arch-chroot /mnt bash -c "sudo -u $USER1 paru -S --noconfirm nvidia-390xx-dkms nvidia-390xx-utils"
        ;;
    *) ;;

    esac
    cont
}

extrastuff() {
    br
    read -r -p "Do you want to install Extra packages? [y/N] " extrayes
    case "$extrayes" in
    [yY][eE][sS] | [yY])
        read -r -p "You can name some apps also [Ex byobu <seperate with space> tmux]: " xtraa
        pacstrap /mnt neofetch cmatrix $xtraa
        ;;
    *) ;;

    esac
}

full-installation() {
    updatestuff
    partationing
    mounting
    base
    chrootstuff
    de
    installgrub
    browser
    invidia
    extrastuff
    echo "Installation complete. Reboot you lazy bastard."
}

step-installation() {
    clear && br
    echo "These Steps Are Available For Installion"
    echo ""
    echo "1.  Set Time And Update Pacman Source"
    echo "2.  Create/Edit Partation Table"
    echo "3.  Mount Partations"
    echo "4.  Install Base ArchLinux"
    echo "5.  Chroot Stuff"
    echo "6.  Install DesktopEnv"
    echo "7.  Install Grub"
    echo "8.  Install Browser"
    echo "9.  Install Nvidia Graphic Drivers"
    echo "10. Extra package stuff"
    br && read -rep "Enter the number of step[1-11]: " stepno && clear

    array=(updatestuff partationing mounting base chrootstuff de installgrub browser invidia extrastuff)
    stepno=$((stepno - 1))
    while [ $stepno -lt ${#array[*]} ]; do
        ${array[$stepno]}
        stepno=$((stepno + 1))
    done
}

main() {
    br && echo "1. Start From Specific Step [Recommended]"
    echo "2. Start Full Auto Installer [Use Only if u Know what it do]" && br
    read -r -p "What would you like to do? [1/2] " what
    case "$what" in
    2)
        full-installation
        ;;
    *)
        step-installation
        ;;
    esac
}

ascii
read -r -p "Start Installation? [Y/n] " starti
case "$starti" in
[nN][oO] | [nN]) ;;

*)
    clear && main
    ;;
esac
