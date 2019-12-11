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
    dialog --title "Arch install" --yes-label "Continue" --no-label "Abort" --yesno "Options selected:\\n\\nDisk: \"$DISK\"\\nEncyption: \"$CRYPT\"\\n\\nPress <Continue> if you want to begin. Script will erase all data on disk \"$DISK\"!!!" 13 60 || { clear; exit; }
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
	dd bs=1M count=4 status=none if=/dev/zero of=${DISK} oflag=sync > ailog.txt 2>&1
	${CMD} mklabel gpt > ailog.txt 2>&1
	${CMD} unit MiB mkpart bios 1 2 name 1 "BIOS" set 1 bios_grub on > ailog.txt 2>&1
	${CMD} unit MiB mkpart boot 2 514 name 2 "Boot" set 2 boot on set 2 esp on > ailog.txt 2>&1
	${CMD} unit MiB mkpart system 514 -1 > ailog.txt 2>&1
	dd if=/dev/zero bs=1M count=1 of=${DISK}1 oflag=sync status=none > ailog.txt 2>&1
    dd if=/dev/zero bs=1M count=1 of=${DISK}2 oflag=sync status=none > ailog.txt 2>&1
    dd if=/dev/zero bs=1M count=16 of=${DISK}3 oflag=sync status=none > ailog.txt 2>&1
	mkfs.vfat -F 32 -n EFI ${DISK}2 > ailog.txt 2>&1
	systemctl start lvm2-lvmetad.service > ailog.txt 2>&1
    if [ "${CRYPT}" = "yes" ]; then
		echo $pass1 | cryptsetup --verbose --cipher aes-xts-plain64 \
			--key-size 512 --hash sha512 --iter-time 2500 --use-urandom \
			--force-password luksFormat ${DISK}3 > ailog.txt 2>&1
		echo $pass1 | cryptsetup luksOpen --allow-discards ${DISK}3 crypt > ailog.txt 2>&1
		pvcreate -ff -y --zero y /dev/mapper/crypt > ailog.txt 2>&1
		vgcreate system /dev/mapper/crypt > ailog.txt 2>&1
	else
		pvcreate -ff -y --zero y ${DISK}3 > ailog.txt 2>&1
		vgcreate system ${DISK}3 > ailog.txt 2>&1
	fi

	lvcreate -L 4G --wipesignatures y -n swap system > ailog.txt 2>&1
	lvcreate -l 100%FREE --wipesignatures y -n root system > ailog.txt 2>&1
	lvscan > ailog.txt 2>&1
	mkfs.ext4 -L root /dev/mapper/system-root > ailog.txt 2>&1
	mkswap -f /dev/mapper/system-swap > ailog.txt 2>&1
	sync > ailog.txt 2>&1
	unset pass1 pass2 ;}

mountsetup() { \
	dialog --title "Arch install" --infobox "Mounting partitions" 6 70
	mount -o defaults,discard,noatime /dev/mapper/system-root /mnt > ailog.txt 2>&1
    swapon /dev/mapper/system-swap > ailog.txt 2>&1
    mkdir -p /mnt/boot > ailog.txt 2>&1
    mount ${DISK}2 /mnt/boot > ailog.txt 2>&1
	}

basesystem() { \
	dialog --title "Arch install" --infobox "Installing reflector" 6 70
    pacman -Sy --noconfirm reflector > ailog.txt 2>&1

	dialog --title "Arch install" --infobox "Updating mirrorlist" 6 70
    reflector -c "Poland" -f 3 -l 3 --verbose --save /etc/pacman.d/mirrorlist > ailog.txt 2>&1

	dialog --title "Arch install" --infobox "Installing base system" 6 70
    pacstrap /mnt base base-devel efitools grub efibootmgr lvm2 cryptsetup parted mkinitcpio > ailog.txt 2>&1

    genfstab -U -p /mnt >> /mnt/etc/fstab > ailog.txt 2>&1
    cp /etc/resolv.conf /mnt/etc/resolv.conf > ailog.txt 2>&1
    cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist > ailog.txt 2>&1
    }

timezone() {\
	dialog --title "Arch install" --infobox "Setting up timezone" 6 70
    arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Warsaw /etc/localtime
    arch-chroot /mnt hwclock --systohc --utc

    cat << EOF > /mnt/etc/locale.gen
    en_US.UTF-8 UTF-8
    pl_PL.UTF-8 UTF-8
    EOF

    arch-chroot /mnt locale-gen

    cat << EOF > /mnt/etc/locale.conf
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
    }

confirmation

[ "$CRYPT" = "yes" ] && getcryptpass

partedsetup

mountsetup

basesystem

timezone

clear
