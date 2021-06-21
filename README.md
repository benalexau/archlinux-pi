# archlinux-pi

Builds a Raspberry Pi 4 [Arch Linux ARM](https://archlinuxarm.org/) image ready
to boot and become managed by Ansible. The image includes:

* Resizing the root file system to consume the entire SD card
* Creating a user account with passwordless `sudo` access
* Adding SSH keys to that user account and enabling the daemon
* Securing the SSH daemon (rejecting passwords, denying root login)
* Removing the `alarm` user
* Disabling the `root` password
* Using DHCP assigned hostnames
* Setup of NTP and DNS resolution
* Installing packages used by Ansible

This repository configures the image with my username, SSH keys, timezone etc.
Please edit `build.sh` or fork the repository to define your own settings.

## Getting Started

[Download the latest image](https://github.com/benalexau/archlinux-pi/releases/tag/latest)
created by [GitHub Actions](https://github.com/benalexau/archlinux-pi/actions).

Alternately you can build the image locally by installing
[packer-builder-arm](https://github.com/mkaczanowski/packer-builder-arm) and
running `PACKER_LOG=1 sudo packer build archlinux-pi-rp4.json`.

Write the image file to an SD card using a command such as:

```
sudo dd if=archlinux-pi-rp4.img of=/dev/sdd bs=4M && sync
```

Put the SD card in a Raspberry Pi and boot it. The system will obtain a DHCP
address, after which you can SSH in as the created user.
