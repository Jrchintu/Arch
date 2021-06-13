#!/bin/bash
# Set up network connection
nc -z 8.8.8.8 53  >/dev/null 2>&1
online=$?
if [ $online -eq 0 ]; then
    echo "Online"
else
    echo "Offline"
    exit
fi

# Partationing
export EFI1="+512M"
export SWAP1="+8G"
export ROOT1="+40G"
export HOME1="0"
clear
echo "This script will create and format the partitions as follows:"
echo ""
echo "/dev/sda1 - $EFI1 of /boot/efi"
echo "/dev/sda2 - $SWAP1 of swap"
echo "/dev/sda3 - $ROOT1 of root"
echo "/dev/sda4 - $HOME1 of /home"
echo ""
read -rp 'Continue? [Y/N]: ' FSOK
if [[ "$FSOK" = 'y' ]] || [[ "$FSOK" = 'Y' ]]
  then clear
  echo "Enter Size For   /Efi     [Default= $EFI1][Use 0 For All Free Space & G=Gb;M=Mb & ctrl+c For Default]"
  read -re -i "$EFI1" EFI1
  clear
  echo "Enter Size For   /Swap    [Default= $SWAP1][Use 0 For All Free Space & G=Gb;M=Mb & ctrl+c For Default]"
  read -re -i "$SWAP1" SWAP1
  clear
  echo "Enter Size For   /Root    [Default= $ROOT1][Use 0 For All Free Space & G=Gb;M=Mb & ctrl+c For Default]"
  read -re -i "$ROOT1" ROOT1
  clear
  echo "Enter Size For   /Home    [Default= $HOME1][Use 0 For All Free Space & G=Gb;M=Mb & ctrl+c For Default]"
  read -re -i "$HOME1" HOME1
  clear
  echo "[Root] = $ROOT1"
  echo "[HOME] = $HOME1"
  echo "[Swap] = $SWAP1"
  echo "[/Efi] = $EFI1"
  read -rp 'Continue? [Y/N]: ' FSOK
  if [[ "$FSOK" = 'n' ]] || [[ "$FSOK" = 'N' ]]
  then exit; else :; fi
else
  echo ""
fi

# Make partation table {x:x:x}=={partation_no:starting_block:desired_size}
sgdisk -Z /dev/sda                                    # destroy existing mbr or gpt structures on disk
sgdisk -a 2048 -o                                     # new gpt disk 2048 alignment
sgdisk -n 1:0:"$ROOT1" -t 1:8300 -c 1:"root" /dev/sda # partition 1 (ROOT), default start, 40GB
sgdisk -n 3:0:"$SWAP1" -t 3:8200 -c 3:"swap" /dev/sda # partition 3 (SWAP), default start, 8GB
sgdisk -n 4:0:"$EFI1" -t 4:ef00 -c 4:"efi" /dev/sda   # partition 4 (ESP), default start, 512MB
sgdisk -n 2:0:"$HOME1" -t 2:8300 -c 2:"home" /dev/sda # partition 2 (HOME), default start, Remaning space

# Inform the OS of partition table changes
sgdisk -p /dev/sda
echo "Press any key to write partation continue or ctrl+c to exit"
read -r tmpvar
partprobe /dev/sda
gdisk -l /dev/sda

# Make filesystem
echo "making filesystem efi->fat32 root&home->ext4 swap->swap"
mkfs.fat -F32 /dev/sda3
mkfs.ext4 /dev/sda1
mkfs.ext4 /dev/sda2

# Make directory before mount
echo "Making directory before mount"
mkdir -pv /mnt/boot/efi
mkdir -pv /mnt/home

# Mount filesystem and enable swap
echo "Mounting filesystems"
mount /dev/sda1 /mnt
mount /dev/sda3 /mnt/boot/efi
mount /dev/sda2 /mnt/home
mkswap /dev/sda3
swapon /dev/sda3

# Sync time and package database
timedatectl set-timezone Asia/Kolkata
timedatectl set-ntp true
pacman -Syy

# Install Arch Linux
clear
echo "Installing Arch Linux Base"
pacstrap /mnt base \
              linux-firmware \
              linux-hardened \
              linux-hardened-headers nano git --noconfirm
              #linux linux-headers[stable] or linux-lts linux-lts-headers[lts]

#Generate fstab
clear
echo "Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab

# Copy chroot.sh to /root
clear
echo "Downloading chroot script"
curl https://raw.githubusercontent.com/Jrchintu/CDN/main/ARCH/chroot.sh >>./chroot.sh
cp -rfv chroot.sh /mnt/root
chmod a+x /mnt/root/chroot.sh

# Chroot into new system
clear
echo "Base archlinux is installed chroot into system and type [ bash chroot.sh ]"
echo "Press any key to chroot or ctrl+c to exit"
read -r tmpvar
arch-chroot /mnt/root

# Finish
clear
echo "If Chroot is sucessfull then installation sucessfull"
echo "Press any key to reboot or Ctrl+C to cancel..."
read -r tmpvar
umount -far
reboot
