#!/bin/bash

. ./errors.sh
. ./config.sh

arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Warsaw /etc/localtime
arch-chroot /mnt hwclock --systohc --utc

cat << 'EOF' > /mnt/etc/locale.gen
en_US.UTF-8 UTF-8
pl_PL.UTF-8 UTF-8
EOF

arch-chroot /mnt locale-gen

cat << 'EOF' > /mnt/etc/locale.conf
LANG=en_US.UTF-8
LC_CTYPE="pl_PL.UTF-8"
LC_NUMERIC="pl_PL.UTF-8"
LC_TIME="pl_PL.UTF-8"
LC_COLLATE="pl_PL.UTF-8"
LC_MONETARY="pl_PL.UTF-8"
LC_MESSAGES=
LC_PAPER="pl_PL.UTF-8"
LC_NAME="pl_PL.UTF-8"
LC_ADDRESS="pl_PL.UTF-8"
LC_TELEPHONE="pl_PL.UTF-8"
LC_MEASUREMENT="pl_PL.UTF-8"
LC_IDENTIFICATION="pl_PL.UTF-8"
LC_ALL=
EOF