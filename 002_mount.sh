#!/bin/bash

. ./errors.sh
. ./config.sh

systemctl start lvm2-lvmetad.service

if [ "${CRYPT}" = "yes" ]; then
  if [ ! -b /dev/mapper/crypt ]; then
      cryptsetup luksOpen --allow-discards ${DISK}3 crypt
  fi

  sleep 1

  pvscan
  lvscan
fi

if lvscan | grep system | grep -q inactive &> /dev/null; then
  vgchange --activate y system
fi

mount -o defaults,discard,noatime /dev/mapper/system-root /mnt
swapon /dev/mapper/system-swap
mkdir -p /mnt/boot
mount ${DISK}2 /mnt/boot
