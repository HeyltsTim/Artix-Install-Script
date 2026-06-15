#!/bin/bash

countdown_() {
for i in {5..0}; do
echo -ne "\r$i"
sleep 1
done
echo -ne "\r"
}

done_msg() {
COLOR='\e[32m'
BOLD='\e[1m'
BLINK='\e[5m'
RESET='\e[0m'
echo -e "${BOLD}${BLINK}${COLOR}[done]${RESET}"
}

flush_pt() {
fuser -k "/dev/$1" 2>/dev/null || true
partprobe "/dev/$1" 2>/dev/null || true
sync
blockdev --flushbufs "/dev/$1" 2>/dev/null || true
}

flush_dv() {
echo "flushing ${1}..."
for PART in "${1}"p[0-9]*; do
if [ -b "$PART" ]; then
flush_pt $PART
fi
done
for PART in "${1}"[0-9]*; do
if [ -b "$PART" ]; then
flush_pt $PART
fi
done
echo "flushing..."
done_msg
}

wipe_fs() {
clear
echo "!WARNING! this action will wipe all data on drive $1"
read -p "enter to continue ctrl+c to cancel ~ "
clear
echo "wiping drive..."
countdown_
flush_dv $1
wipefs -fa "/dev/$1"
partprobe "/dev/$1"
echo "wiping drive..."
done_msg
}

partition_drv() { 
wipe_fs ${1}
echo "partitioning ${1}..."
sfdisk --force --no-reread "/dev/${1}" <<EOF
label: gpt
type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B, size=512MiB
type=0FC63DAF-8483-4772-8E79-3D69D8477DE4
EOF
echo "partitioning ${1}..."
done_msg
}

#start of script
echo "if you are not please run as root.\nyou are $USER"
lsblk -dn

echo "what is the name of your drive? ex: sd<a-z> or nvme#n# etc. and not sda# or nvme#n#p#"
read -p "name of device you would like to use ~ " DRV
echo "using $DRV"
partition_drv $DRV

lsblk -ln $DRV
echo "partition number ex: sda# or nvme0n1p#"
read -p "boot(fat32) > $DRV" BOOTPT
read -p "root(btrfs) > $DRV" ROOTPT
BOOT="$DRV$BOOTPT"
ROOT="$DRV$ROOTPT"
echo "formating ${BOOT} as boot & ${ROOT} as root..."
mkfs.vfat -F32 -n "boot" $BOOT
mkfs.btrfs -L artix -f -M -O quota $ROOT
echo "formating ${BOOT} as boot & ${ROOT} as root..."
done_msg

echo "build subvolumes..."
mount $RT /mnt
VLCT="btrfs subvolume create /mnt/"
${VLCT}root
${VLCT}users
${VLCT}containers
${VLCT}virtualmachines
${VLCT}packages
${VLCT}snapshots
${VLCT}logs
${VLCT}cache
${VLCT}temp
${VLCT}swap
echo "build subvolumes..."
done_msg

echo "unmount filesystems..."
umount -R /mnt
echo "unmount filesystems..."
done_msg

echo "mount btrfs subvolumes..."
OPS="compress=zstd:5,noatime"
OPS2="nodatacow,noatime"
MNTO="mount -o subvol"
${MNTO}root,$OPS $RT /mnt
mkdir -p /mnt/{home,boot,var/log,var/cache,var/swap,var/snapshots,ops/containers,ops/vmachines,var/tmp}
${MNTO}cache,$OPS $RT /mnt/var/cache
mkdir -p /mnt/var/cache/pacman/pkg
${MNTO}=logs,$OPS $RT /mnt/var/log
${MNTO}=users,$OPS $RT /mnt/home
${MNTO}=packages,$OPS $RT /mnt/var/cache/pacman/pkg
${MNTO}=temp,$OPS $RT /mnt/var/tmp
${MNTO}=snapshots,$OPS $RT /mnt/var/snapshots
${MNTO}=containers,$OPS2 $RT /mnt/ops/containers
${MNTO}=virtualmachines,$OPS2 $RT /mnt/ops/vmachines
${MNTO}=swap,$OPS2 $RT /mnt/var/swap
echo "mount btrfs subvolumes..."
done_msg

echo "mount boot..."
mount $BT /mnt/boot
echo "mount boot..."
done_msg

echo
echo "intended output: 2 partitions and 10 subvolumes"
findmnt -R /mnt
read -p "enter to continue to package install > "

echo "package install..."
basestrap -Ki /mnt base sudo vim linux-rt seatd-dinit mkinitcpio \
amd-ucode linux-firmware-mediatek linux-firmware-amdgpu \
linux-firmware-realtek turnstile-dinit bash-completion iptables-dinit \
dhcpcd-dinit btrfs-progs grub-btrfs snapper efibootmgr dosfstools
echo "package install..."
done_msg

echo "fstab..."
fstabgen -U /mnt >> /mnt/etc/fstab
echo "fstab..."
done_msg

CHRT="artix-chroot /mnt /bin/bash -c"

echo "region and time..."
echo "region"
RGN="America"
#read -p "ex: America > " RGN
echo "$RGN"
echo "city"
CTY="New_York"
#read -p "ex: New_York >  " CTY
echo "$CTY"
ln -sf /mnt/usr/share/zoneinfo/$RGN/$CTY /mnt/etc/localtime
$CHRT hwclock --systohc
echo "region and time..."
done_msg

echo "locale..."
LCCODE="en_US.UTF-8"
echo "$LCCODE UTF-8" > /mnt/etc/locale.gen
echo "LANG=$LCCODE" > /mnt/etc/locale.conf
echo "KEYMAP=us" > /mnt/etc/vconsole.conf
$CHRT locale-gen
echo "locale..."
done_msg

echo "sudo..."
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /mnt/etc/sudoers
$CHRT EDITOR=vim visudo -c
echo "sudo..."
done_msg

echo "hostname..."
read -p "hostname > " HN
echo "$HN" > /mnt/etc/hostname
echo "hostname..."
done_msg

echo "credentials..."
$CHRT passwd
echo "add privilaged user"
read -p "username > " USRNM
$CHRT useradd --btrfs-subvolume-home -m -g users -G wheel ${USRNM}
$CHRT passwd $USRNM
echo "credentials..."
done_msg

echo "grub..."
$CHRT grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
$CHRT grub-mkconfig -o /boot/grub/grub.cfg
echo "grub..."
done_msg

echo "networking..."
$CHRT ln -s /etc/dinit.d/dhcpcd /etc/dinit.d/boot.d/
echo "networking..."
done_msg

echo -e "\e[1;5;32m[installation completed]\e[0m"
echo "unmounting filesystems"
umount -R /mnt
echo "unmounting filesystems"
done_msg

while true; do
  read -rp "type \"YES\" to reboot > " RBTYN
  case "$RBTYN" in
    [Yy][Ee][Ss]) return 1 ;;
    "") echo "ctrl+c to exit"; return 0 ;;
    *) echo "ctrl+c to exit"; return 0 ;;
  esac
done

read -p "are you sure you would like to reboot? > "
countdown_
reboot
