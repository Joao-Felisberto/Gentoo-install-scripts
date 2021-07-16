#! /bin/bash

# make.conf

#############################
#	READ CONFIGS/USER INPUT #
########################### #
declare -a pkg
while read ln
do
  pkg+="$ln "
done < "packages.install"

read -p "Boot partition name: " boot_part
read -p "Root partition name: " root_part
read -sp "Root password: " root_pass
echo " "
read -p "User name: " user
read -sp "Password for $user: " user_pass
echo " "
read -p "Hostname: " hostname

########
# TIME #
########
# timedatectl set-ntp true
ntpd -qg

################
#	PARTITIONS #
################
mkfs.ext4 "$root_part"
#mkfs.ext4 "$home_part"
mkfs.vfat -F 32 "$boot_part"

mount "$root_part" /mnt/gentoo

#####################
#	STAGE 3 TARBALL #
#####################

cd /mnt/gentoo

# TODO: make this download the latest automatically, simple string editing with the output of `date`
wget https://bouncer.gentoo.org/fetch/root/all/releases/amd64/autobuilds/20210711T170538Z/stage3-amd64-openrc-20210711T170538Z.tar.xz

tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner

#####################
#	COMPILE OPTIONS #
#####################
# advanced - https://wiki.gentoo.org/wiki/GCC_optimization
# beginner - https://wiki.gentoo.org/wiki/Safe_CFLAGS

# TODO: use sed to edit this automatically
# COMMON_FLAGS
# 	-march / -mtune=native
# 	-O2 for gcc speed optimization
# 	-pipe to comunicate between files with pipes and not temp files. More ram
# CFLAGS="${COMMON_FLAGS}"
# CXXLAGS="${COMMON_FLAGS}"
# MAKEOPTS="-j${nproc}" # number of cores plus one OR 1 per 2Gb of ram. See lscpu: sockets * cores per socket

#nano /mnt/gentoo/etc/portage/make.conf.example

# nano /mnt/gentoo/etc/portage/make.conf
mv make.conf /mnt/gentoo/etc/portage/make.conf

#############
#	MIRRORS #
#############
# TODO: select mirrors automatically
mirrorselect -io >> /mnt/gentoo/etc/portage/make.conf

mkdir --parents /mnt/gentoo/etc/portage/repos.conf
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf

#####################
#	COPY DNS INFO	#
#####################

cp --dereference /etc/resolv.conf /mnt/gentoo/etc/

############
#	CHROOT #
############

mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev

chroot /mnt/gentoo /bin/bash /install.sh $root_pass $user $user_pass $hostname $boot_part

###########
#	CLEAN #
###########
cd

rm /mnt/install.sh
rm /mnt/services.install

rm /stage3-*.tar.*

umount -l /mnt/gentoo/dev{/shm,/pts,}
umount -R /mnt/gentoo

#reboot
