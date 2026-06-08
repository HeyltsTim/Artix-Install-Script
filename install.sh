#!/bin/bash


countdown() {
for i in {5..0}; do
echo -ne "\r$i"
sleep 1
done
echo -ne "\r"
}


# setup
clear
echo "please run as root.\nyou are $USER"
umount -R /mnt
lsblk
echo "which drive would you like to partition?\n"
read -p " drive name > /dev/" DRVNM
clear


# erase disk
echo "!WARNING! this action will wipe all data on drive $DRVNM"
read -p "enter to continue ctrl+c to cancel > "
DRV="/dev/$DRVNM"
clear
echo "wiping drive..."
countdown
wipefs -fa $DRV


# partition disk
echo "partitioning..."
sfdisk -q --force --no-reread "$DRV" <<EOF
label: gpt
type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B, size=512MiB
type=0FC63DAF-8483-4772-8E79-3D69D8477DE4
EOF
echo "refreshing..."
partprobe -s $DRV
echo
fdisk -l $DRV
echo "partition number ex: sda# or nvme0n1p#"
read -p "boot(fat32) > $DRV" BTPT
read -p "root(btrfs) > $DRV" RTPT
BT="$DRV$BTPT"
RT="$DRV$RTPT"
mkfs.vfat -F32 -n "boot" $BT
mkfs.btrfs -L artix -f -M -O quota $RT
mount $RT /mnt
echo "building subvolumes..."
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


echo "unmounting btrfs filesystem..."
umount -R /mnt


echo "mounting btrfs subvolumes..."

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

echo "mounting boot..."
mount $BT /mnt/boot
echo
findmnt -R /mnt
read -p "enter to continue to package install > "
echo "installing packages..."
basestrap -Ki /mnt base sudo vim linux-rt seatd-dinit mkinitcpio amd-ucode linux-firmware-mediatek linux-firmware-amdgpu linux-firmware-realtek turnstile-dinit bash-completion iptables-dinit dhcpcd-dinit btrfs-progs grub-btrfs efibootmgr dosfstools
echo "generating fstab..."
fstabgen -U /mnt >> /mnt/etc/fstab
echo "fstab done."
cat /mnt/etc/fstab
CHRT="artix-chroot /mnt /bin/bash -c"
echo "setting region and time..."
echo "region"
#read -p "ex: America > " RGN
RGN="America"
echo "$RGN"
echo "city"
#read -p "ex: New_York >  " CTY
CTY="New_York"
echo "$CTY"
ln -sf /mnt/usr/share/zoneinfo/$RGN/$CTY /mnt/etc/localtime
$CHRT hwclock --systohc
echo "setting locale..."
LCCODE="en_US.UTF-8"
echo "$LCCODE UTF-8" > /mnt/etc/locale.gen
echo "LANG=$LCCODE" > /mnt/etc/locale.conf
echo "KEYMAP=us" > /mnt/etc/vconsole.conf
$CHRT locale-gen
echo "configuring sudo..."
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /mnt/etc/sudoers
$CHRT EDITOR=vim visudo -c
echo "configuration complete."
echo "set hostname"
read -p "hostname > " HN
echo "$HN" > /mnt/etc/hostname
echo "set root password"
$CHRT passwd
echo "add privilaged user"
read -p "username > " USRNM
$CHRT useradd --btrfs-subvolume-home -m -g users -G wheel ${USRNM}
$CHRT passwd $USRNM
echo "installing grub"
$CHRT grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
$CHRT grub-mkconfig -o /boot/grub/grub.cfg
echo "setting up basic networking"
$CHRT ln -s /etc/dinit.d/dhcpcd /etc/dinit.d/boot.d/
echo "installation completed"
echo "unmounting filesystem"
umount -R /mnt
read -p "enter to reboot > "
countdown
#reboot
