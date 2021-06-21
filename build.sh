#!/bin/bash

#### RESIZE ROOT FILE SYSTEM ####

cat <<EOM >>/etc/systemd/system/resizerootfs.service
[Unit]
Description=resize root file system
Before=local-fs-pre.target
DefaultDependencies=no

[Service]
Type=oneshot
TimeoutSec=infinity
ExecStart=/usr/sbin/resizerootfs
ExecStart=/bin/systemctl --no-reload disable %n

[Install]
RequiredBy=local-fs-pre.target
EOM

mv /tmp/resizerootfs /usr/sbin
chmod 770 /usr/sbin/resizerootfs

systemctl enable resizerootfs.service

#### NTP AND DNS ####

timedatectl set-ntp true

# Temporary DNS for image build (restored at end of script)
mv /etc/resolv.conf /etc/resolv.conf.orig
echo 'nameserver 1.1.1.1' > /etc/resolv.conf

#### LOCALE AND TIMEZONE ####
sed -i 's/#en_AU.UTF-8/en_AU.UTF-8/' /etc/locale.gen
echo 'LANG=en_AU.UTF-8' > /etc/locale.conf
locale-gen

ln -fs /usr/share/zoneinfo/Australia/NSW /etc/localtime

#### PACKAGES ####

pacman-key --init
pacman-key --populate archlinuxarm
sed -i 's/#ParallelDownloads/ParallelDownloads/g' /etc/pacman.conf
pacman -Syu --noconfirm
pacman -S --noconfirm sudo python polkit python parted

#### HOSTNAME ####

# Hostname is set via DHCP so we do not ever require /etc/hostname
rm -f /etc/hostname

# polkit is required to work around https://bugs.archlinux.org/task/41761
# (required for hostname via DHCP)
ls -l /etc/polkit-1 || true
cp -v /usr/share/polkit-1/rules.d/systemd-networkd.rules /etc/polkit-1/rules.d

#### USERS AND SUDO ####

userdel -r -f alarm
passwd --lock root

USERNAME="bpa"
# use mkpasswd --method=sha-512 --rounds=10000000 for a new password
useradd --create-home --user-group --groups wheel -K PASS_MAX_DAYS=-1 $USERNAME --password '$6$rounds=10000000$Hh721pROaFkw0Qxf$MS8.oDuqjzy8I7BXp7oWu8zsDL66lxA0fY/5bex9w0TG1Ppy4OL1vr8jal/1ScRDhz73M8BC1sFurMxIBbFAx1'

echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel
/usr/sbin/visudo --check

#### SSH ####

echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config
echo 'PermitRootLogin no' >> /etc/ssh/sshd_config

mkdir -p /home/${USERNAME}/.ssh
chmod 700 /home/${USERNAME}/.ssh
curl -k https://github.com/benalexau.keys -o /home/${USERNAME}/.ssh/authorized_keys
chmod 600 /home/${USERNAME}/.ssh/authorized_keys
chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}

sed -i 's/-account   \[success=1 default=ignore\]  pam_systemd_home.so/# -account   \[success=1 default=ignore\]  pam_systemd_home.so  as per https:\/\/github.com\/systemd\/systemd\/issues\/17266/' /etc/pam.d/system-auth

systemctl enable sshd.service

#### CLEAN UP ####

# Restore original resolver
rm /etc/resolv.conf
mv /etc/resolv.conf.orig /etc/resolv.conf

# Recover space
rm /var/cache/pacman/pkg/*.xz
