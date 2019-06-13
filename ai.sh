#!/bin/sh

while getopts ":d:c:h" o; do case "${o}" in
	h) printf "Arguments:\\n  -d: Target disk (default: /dev/sda)\\n  -c: Encrypt volumes (default: no)\\n  -h: Show this message\\n" && exit ;;
	d) DISK=${OPTARG} ;;
	c) CRYPT=${OPTARG} ;;
	*) printf "Invalid option: -%s\\n" "$OPTARG" && exit ;;
esac done

# DEFAULTS:
[ -z "$DISK" ] && DISK="/dev/sda"
[ -z "$CRYPT" ] && CRYPT="no"

error() { clear; printf "ERROR:\\n%s\\n" "$1"; exit;}

confirmation() {\
    dialog --title "Arch install" --yes-label "Continue" --no-label "Abort" --yesno "Options selected:\\n\\nDisk: \"$DISK\"\\nEncyption: \"$CRYPT\"\\n\\nPress <Continue> if you want to begin!" 13 60 || { clear; exit; }
	}

getcryptpass() { \
	pass1=$(dialog --title "Arch install" --no-cancel --passwordbox "Enter encryption password" 10 60 3>&1 1>&2 2>&3 3>&1)
	pass2=$(dialog --title "Arch install" --no-cancel --passwordbox "Retype password." 10 60 3>&1 1>&2 2>&3 3>&1)
	while ! [ "$pass1" = "$pass2" ]; do
		unset pass2
		pass1=$(dialog --title "Arch install" --no-cancel --passwordbox "Passwords do not match.\\n\\nEnter password again." 10 60 3>&1 1>&2 2>&3 3>&1)
		pass2=$(dialog --title "Arch install" --no-cancel --passwordbox "Retype password." 10 60 3>&1 1>&2 2>&3 3>&1)
	done ;}

partedsetup() { \
	dialog --title "Arch install" --infobox "Preparing partitions" 6 70
	CMD="parted ${DISK} --align optimal --script --machine --"
	dd bs=1M count=4 status=none if=/dev/zero of=${DISK} oflag=sync >/dev/null 2>&1
	${CMD} mklabel gpt >/dev/null 2>&1
	${CMD} unit MiB mkpart bios 1 2 name 1 "BIOS" set 1 bios_grub on >/dev/null 2>&1
	${CMD} unit MiB mkpart boot 2 514 name 2 "Boot" set 2 boot on set 2 esp on >/dev/null 2>&1
	${CMD} unit MiB mkpart system 514 -1 >/dev/null 2>&1
	dd if=/dev/zero bs=1M count=1 of=${DISK}1 oflag=sync status=none >/dev/null 2>&1
    dd if=/dev/zero bs=1M count=1 of=${DISK}2 oflag=sync status=none >/dev/null 2>&1
    dd if=/dev/zero bs=1M count=16 of=${DISK}3 oflag=sync status=none >/dev/null 2>&1
	mkfs.vfat -F 32 -n EFI ${DISK}2 >/dev/null 2>&1
	systemctl start lvm2-lvmetad.service >/dev/null 2>&1
    if [ "${CRYPT}" = "yes" ]; then
		echo $pass1 | cryptsetup --verbose --cipher aes-xts-plain64 \
			--key-size 512 --hash sha512 --iter-time 2500 --use-urandom \
			--force-password luksFormat ${DISK}3 >/dev/null 2>&1
		echo $pass1 | cryptsetup luksOpen --allow-discards ${DISK}3 crypt >/dev/null 2>&1
		pvcreate -ff -y --zero y /dev/mapper/crypt >/dev/null 2>&1
		vgcreate system /dev/mapper/crypt >/dev/null 2>&1
	else
		pvcreate -ff -y --zero y ${DISK}3 >/dev/null 2>&1
		vgcreate system ${DISK}3 >/dev/null 2>&1
	fi

	lvcreate -L 4G --wipesignatures y -n swap system >/dev/null 2>&1
	lvcreate -l 100%FREE --wipesignatures y -n root system >/dev/null 2>&1
	lvscan >/dev/null 2>&1
	mkfs.ext4 -L root /dev/mapper/system-root >/dev/null 2>&1
	mkswap -f /dev/mapper/system-swap >/dev/null 2>&1
	sync >/dev/null 2>&1
	unset pass1 pass2 ;}

confirmation

[ "$CRYPT" = "yes" ] && getcryptpass

partedsetup

clear
