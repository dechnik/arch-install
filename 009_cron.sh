#!/bin/bash

. ./errors.sh
. ./config.sh

arch-chroot /mnt pacman -Sy --noconfirm cronie
arch-chroot /mnt systemctl enable cronie