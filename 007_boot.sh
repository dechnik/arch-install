#!/bin/bash

. ./errors.sh
. ./config.sh

cat << EOF > /mnt/etc/default/grub
GRUB_DEFAULT=0
GRUB_TIMEOUT=2
GRUB_DISTRIBUTOR="Arch"
GRUB_PRELOAD_MODULES="part_gpt part_msdos"
GRUB_TERMINAL_INPUT=console
GRUB_GFXMODE=auto

GRUB_DISABLE_LINUX_UUID=false
GRUB_DISABLE_RECOVERY=true
GRUB_DISABLE_SUBMENU=y
EOF

if [ "${CRYPT}" = "yes" ]; then
    echo 'GRUB_CMDLINE_LINUX_DEFAULT="cryptdevice='${DISK}'3:system"' >> /mnt/etc/default/grub
    echo 'GRUB_ENABLE_CRYPTODISK=y' >> /mnt/etc/default/grub
else
    echo 'GRUB_CMDLINE_LINUX_DEFAULT=""' >> /mnt/etc/default/grub
fi

arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --removable
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg