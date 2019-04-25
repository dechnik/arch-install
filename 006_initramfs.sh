#!/bin/bash

. ./errors.sh
. ./config.sh

arch-chroot /mnt systemctl start lvm2-lvmetad.service

cat << 'EOF' > /mnt/etc/mkinitcpio.conf
MODULES=()
BINARIES=()
FILES=()
HOOKS=(base udev autodetect modconf block keyboard encrypt lvm2 filesystems fsck)
EOF

arch-chroot /mnt mkinitcpio -p linux