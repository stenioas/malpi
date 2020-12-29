<h1 align="center">
  My <a href=https://www.archlinux.org/>Arch Linux</a> Personal Installer
</h1>
<p align="center"><strong>My Arch Linux Personal Installer</strong>, a simple and amateur shell script for installing Arch Linux on my personal computers. You can use and modify it as you prefer. The <strong>malpi</strong> script offers two steps when installing Arch Linux.</p>

<p align="center">
  <img src="https://img.shields.io/badge/Maintained%3F-Yes-green?style=for-the-badge">
  <img src="https://img.shields.io/github/license/stenioas/malpi?style=for-the-badge">
  <img src="https://img.shields.io/github/issues/stenioas/malpi?color=violet&style=for-the-badge">
  <img src="https://img.shields.io/github/stars/stenioas/malpi?style=for-the-badge">
</p>

## Note
* You can partition the disk before launching the script if you prefer.
* You can first try it in a **VirtualMachine**
* This script change the console font

## Prerequisites

- A working internet connection
- Logged in as 'root'

## Obtaining the script

### curl
	curl -L stenioas.github.io/malpi/malpi > malpi

### wget
	wget stenioas.github.io/malpi/malpi

### git
	git clone git://github.com/stenioas/malpi

## How to use

### First Step (*Base installation*) ###

> The first step offers the installation of the base system.

boot with the last [Arch Linux image](https://www.archlinux.org/download/) with a [bootable device](https://wiki.archlinux.org/index.php/USB_flash_installation_media).

Then make sure you have Internet connection on the Arch iso. If you have a wireless connection the [`iwctl`](https://wiki.archlinux.org/index.php/Iwd#iwctl) command might be useful to you. You can also read the [Network configuration](https://wiki.archlinux.org/index.php/Network_configuration) from the Arch Linux guide for more detailed instructions.

Finnaly, launch the script first step:

    sh malpi -i

Then follow the on-screen instructions to completion.

### Important informations: ###

1. This script supports [**UEFI**](https://wiki.archlinux.org/index.php/Unified_Extensible_Firmware_Interface) only.
2. This script will only consider [**ESP**](https://wiki.archlinux.org/index.php/EFI_system_partition) and **ROOT** partitions.
3. This script will format the root partition in [**BTRFS**](https://wiki.archlinux.org/index.php/btrfs) filesystem.
4. The ESP partition can be formatted in FAT32 if the user wants to.
5. This script does not support [**SWAP**](https://wiki.archlinux.org/index.php/swap).
6. This script will create three [**subvolumes**](https://wiki.archlinux.org/index.php/btrfs#Subvolumes "subvolumes"):
	- **@** for /
	- **@home** for /home
	- **@.snapshots** for /.snapshots
7. This script, for now, supports [**XORG**](https://wiki.archlinux.org/index.php/Xorg) only(*[**Wayland**](https://wiki.archlinux.org/index.php/wayland) will be available soon*).
8. This script, for now, installs the [**GRUB**](https://wiki.archlinux.org/index.php/GRUB) bootloader by default(*[**Systemd-boot**](https://wiki.archlinux.org/index.php/Systemd-boot) will be available soon*).
9. This script can be cancelled at any time with **CTRL+C**.
10. **THIS SCRIPT IS NOT YET COMPLETE!**

### Second Step (*Post installation*) ###

> Second step offers the post installation.

Launch the script second step after being successful in the first step.

	sh malpi -p

## Features
### First Step
- Set console font
- Timedatectl set ntp as true
- Updating archlinux-keyring
- Rank mirrors by country
- Select disk and partitioning
- Format and mount **EFI** and **ROOT** partitions
- Select kernel version (*You can enter the version of the kernel you want to install*)
- Select microcode version
- Install system base
- Configure fstab
- Configure timezone
- Configure hardware clock
- Configure localization
- Configure network(***hostname** file and **hosts** file*)
- Configure mkinitcpio
- Configure root password
- Install/Configure bootloader

### Second Step
- Create and Configure New User
- Enable Multilib Repository
- Install Essential Packages
	- dosfstools
	- mtools
	- udisks2
	- dialog
	- wget
	- git
	- nano
	- reflector
	- bash-completion
	- xdg-utils
	- xdg-user-dirs
- Install Xorg Packages
	- xorg
	- xorg-apps
	- xorg-xinit
	- xterm
- Install Video Driver (*Currently only intel and virtualbox available*)
- Install Desktop Environment or Window Manager
- Install Display Manager or Xinit
- Install Extra Packages
	- Utilities: `usbutils lsof dmidecode neofetch bashtop htop avahi nss-mdns logrotate sysfsutils mlocate`
	- Compression tools: `zip unzip unrar p7zip lzop`
	- Filesystem tools: `ntfs-3g autofs fuse fuse2 fuse3 fuseiso mtpfs`
	- Sound tools: `alsa-utils pulseaudio`
- Install Laptop Packages
	- `wpa_supplicant wireless_tools bluez bluez-utils pulseaudio-bluetooth xf86-input-synaptics`
- Install YAY
---

## References ##

- [**Archwiki**](https://wiki.archlinux.org/)
- [**archfi**](https://github.com/MatMoul/archfi) script by [***MatMoul***](https://github.com/MatMoul)
- [**aui**](https://github.com/helmuthdu/aui) script by [***Helmuthdu***](https://github.com/helmuthdu)
- [**pos-alpine**](https://terminalroot.com.br/2019/12/alpine-linux-com-awesomewm-nao-recomendado-para-usuarios-nutella.html) script by [***Terminal Root***](https://terminalroot.com.br/)

---
<h1 align="center" style="color:green">Btw, thanks for your time!</h1>