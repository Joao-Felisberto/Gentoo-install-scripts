#! /bin/bash
#1          2     3          4         5
#$root_pass $user $user_pass $hostname $boot_part

# make.conf
# rc.conf
# keymaps
# hwclock

source /etc/profile
export PS1="\n\[\033[36m\]\w \\$>\[\033[00m\] "

################
#	MOUNT BOOT #
################
mount $boot_part /boot

#######################
#	CONFIGURE PORTAGE #
#######################

# for poor networks only
# emerge-webrsync

emerge --sync --quiet

#############
#	PROFILE #
#############
# TODO: input validation
eselect profile list
read -p "Profile: " prof

eselect profile set "$prof"

############
#	UPDATE #
############

emerge --verbose --update --deep --newuse @world

###################
#	USE VARIABLES #
###################
# view all with less /var/db/repos/gentoo/profiles/use.desc

# For kde USE="-gtk -gnome qt4 qt5 kde dvd alsa cdr"
# nano /etc/portage/make.conf

###############
#	TIME ZONE #
###############

echo "Europe/Lisbon" > /etc/timezone
emerge --config sys-libs/timezone-data

############
#	LOCALE #
############

echo "en_US ISO-8859-1" > /etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen

locale-gen

echo "LANG=\"en_US.UTF-8\"" > /etc/env.d/02locale
echo "LC_COLLATE=\"C.UTF-8\"" >> /etc/env.d/02locale

env-update && source /etc/profile && export PS1="\n\[\033[36m\]\w \\$>\[\033[00m\] "

############
#	KERNEL #
############
# See https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Kernel#Activating_required_options

emerge sys-kernel/gentoo-sources

eselect kernel set 1

# to get system info, lspci, lsmod
# emerge sys-apps/pciutils

cd /usr/src/linux

# TODO: this uses a menu, make it automatic
# https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Kernel
make menuconfig

make && make modules_install
make install

###########
#	FSTAB #
###########
# TODO: automate
# see https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/System

nano /etc/fstab

#############
#	NETWORK #
#############
# see https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/System#Configuring_the_network

echo "hostname=\"$4\"" > /etc/conf.d/hostname

# nano /etc/conf.d/net
echo "dns_domain_lo=\"localhost\"" > /etc/conf.d/net

emerge --noreplace net-misc/netifrc

echo "config_eth0=\"dhcp\"" >> /etc/conf.d/net

cd /etc/init.d
ln -s net.lo net.eth0
rc-update add net.eth0 default

echo "127.0.0.1	$4.localdomain	$4 localhost" >> /etc/hosts

###########
# 	USERS #
###########

echo "root:$1" | chpasswd

useradd -m $2
echo "$2:$3" | chpasswd

##########
#	BOOT #
##########
# TODO: automate
# see https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/System#Init_and_boot_configuration

nano /etc/rc.conf

# keyboard layout
nano /etc/conf.d/keymaps

# clock
nano /etc/conf.d/hwclock

###########
#	TOOLS #
###########

# system logger
emerge app-admin/sysklogd
rc-update add sysklogd default

# scheduler
emerge sys-process/cronie
rc-update add cronie default

# for faster file location
emerge sys-apps/mlocate

# stuff to handle ext4 and fat32 file systems
# emerge sys-fs/e2fsprogs already installed
emerge sys-fs/dosfstools


################
#	BOOTLOADER #
################
# TODO: efibootmgr is maybe better for VMs

echo "GRUB_PLATFORMS=\"efi-64\"" >> /etc/portage/make.conf
emerge sys-boot/grub:2

grub-install --target=x86_64-efi --efi-directory=/boot
grub-mkconfig -o /boot/grub/grub.cfg
