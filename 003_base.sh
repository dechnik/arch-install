#!/bin/bash

. ./errors.sh
. ./config.sh

pacman -Sy --noconfirm reflector

reflector -c "Poland" -f 3 -l 3 --verbose --save /etc/pacman.d/mirrorlist

pacstrap /mnt base base-devel efitools grub efibootmgr lvm2 cryptsetup parted mkinitcpio

genfstab -U -p /mnt >> /mnt/etc/fstab
cp /etc/resolv.conf /mnt/etc/resolv.conf
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
