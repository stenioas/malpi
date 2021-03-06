<h1 align="center">
  malpi
</h1>

<h3 align="center">
  <a href="https://www.archlinux.org">Arch Linux</a> + Btrfs + Luks
</h3>
<p align="center">A shell script, simple and amateur, to install Arch Linux on my personal computers. You can use and modify it as you like.</p>
<br>
<p align="center">
  <img src="https://img.shields.io/badge/Maintained%3F-Yes-green?style=for-the-badge">
  <img src="https://img.shields.io/github/license/stenioas/malpi?style=for-the-badge">
  <img src="https://img.shields.io/github/issues/stenioas/malpi?color=violet&style=for-the-badge">
  <img src="https://img.shields.io/github/stars/stenioas/malpi?style=for-the-badge">
</p>
<h4 align="center">Demo</h4>
<p align="center"><img src="./imgs/start-screen.png" alt="Start screen image" width="640px"></p>

<p align="center"><a href="https://youtu.be/plAaZUxDaeU" target="_blank">Watch the demo video.</a></p>

## Notes
* It is advisable that you already know how to install Arch in the traditional way, following the [**installation guide**](https://wiki.archlinux.org/index.php/Installation_guide) available on ArchWiki, the purpose of this script is to speed up my installations and not skip steps in learning.
* If you prefer you can partition your disk before launching this script.
* You can first try it in a **Virtual Machine** if you prefer.
* The console font will be changed while the script is running.
* I have intentions of migrating this script to the [**whiptail**](https://linux.die.net/man/1/whiptail) tool.
* The idea of ​​creating this script came from the desire to practice the shell language, nothing more.

## Prerequisites

- A working internet connection.
- Logged in as 'root' user.

## Obtaining the script

### curl
	curl -L stenioas.github.io/malpi/malpi > malpi

### wget
	wget stenioas.github.io/malpi/malpi

### git
	git clone https://github.com/stenioas/malpi

## How to use

### Important informations:

1. This script assumes that you know your keymap and it will already be loaded.
2. Only [**UEFI**](https://wiki.archlinux.org/index.php/Unified_Extensible_Firmware_Interface) mode is supported.
3. This script uses only two partitions, [**ESP**](https://wiki.archlinux.org/index.php/EFI_system_partition) and **ROOT**.
4. The root partition will be formatted with the [**BTRFS**](https://wiki.archlinux.org/index.php/btrfs) file system.
5. This script will create 4 [**subvolumes**](https://wiki.archlinux.org/index.php/btrfs#Subvolumes "subvolumes"):
	- **@** for /
	- **@home** for /home
	- **@pkgs** for /var/cache/pacman/pkgs
	- **@snapshots** for /.snapshots
6. The EFI partition can be formatted in FAT32 if the user wants to.
7. [**SWAP**](https://wiki.archlinux.org/index.php/swap) is not supported.
8. [**NetworkManager**](https://wiki.archlinux.org/index.php/NetworkManager) is installed by default.
9. Only [**Grub**](https://wiki.archlinux.org/index.php/GRUB) and [**Systemd-boot**](https://wiki.archlinux.org/index.php/Systemd-boot) are available.
10. This script can be cancelled at any time with **CTRL+C**.
11. **THIS SCRIPT IS NOT YET COMPLETE!**

##### Tips:
  - A SWAP partition or SWAP file can be created after installing the system.
  - The home partition can be migrated to another disk or partition after installing the system.

### First Step (*Base installation*)

Boot with the last [Arch Linux image](https://www.archlinux.org/download/) on a [bootable device](https://wiki.archlinux.org/index.php/USB_flash_installation_media).

Then make sure you have Internet connection on the Arch iso. If you have a wireless connection the [`iwctl`](https://wiki.archlinux.org/index.php/Iwd#iwctl) command might be useful to you. You can also read the [Network configuration](https://wiki.archlinux.org/index.php/Network_configuration) from the Arch Linux guide for more detailed instructions.

Finnaly, launch the script first step with the command below:

    sh malpi -i
or

	sh malpi --install

Then follow the on-screen instructions to completion.
##### Features
- Set console font
- Timedatectl set ntp as true `timedatectl set-ntp true`
- Rank mirrors (*by country*)
- Select disk and partitioning
- Format and mount **EFI** and **ROOT** partitions
- Select kernel version
- Select microcode version
- Install system base
- Configure fstab
- Configure timezone
- Configure localization
- Configure network(***hostname** file and **hosts** file*)
- Configure initramfs
- Configure root password
- Install bootloader

### Second Step (*Post installation*) ###

> Second step offers the post installation.

Launch the second script step, after succeeding in the first step, with the command below:

	sh malpi -p

or

	sh malpi --post

##### Features
- Create and configure a new user
- Enable multilib mepository
- Install Xorg
- Install video driver (*Currently only intel and virtualbox available*)
- Install Desktop Environment or Window Manager ***(Optional)***
- Install Display Manager or Xinit ***(Optional)***
- Install extra packages ***(Optional)***
- Install Laptop Packages ***(Optional)***
- Install YAY ***(Optional)***
- Cleanup orphan packages

---

## References

- [**Archwiki**](https://wiki.archlinux.org/)
- [**archfi**](https://github.com/MatMoul/archfi) script (by [***MatMoul***](https://github.com/MatMoul))
- [**aui**](https://github.com/helmuthdu/aui) script (by [***Helmuthdu***](https://github.com/helmuthdu))
- [**pos-alpine**](https://terminalroot.com.br/2019/12/alpine-linux-com-awesomewm-nao-recomendado-para-usuarios-nutella.html) script (by [***Terminal Root***](https://terminalroot.com.br/))

---
<h2 align="center">Btw, thank you for taking the time to get to know my project.!</h2>