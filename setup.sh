#!/bin/sh
#
# pali: My Personal Arch Linux Installer - Install and Configure Archlinux
#
# ----------------------------------------------------------------------#
#
# References:
#   Archfi script by Matmaoul - github.com/Matmoul
#   Aui script by Helmuthdu - github.com/helmuthdu
#   pos-alpine script by terminalroot - github.com/terroo
#
# ----------------------------------------------------------------------#
#
# The MIT License (MIT)
#
# Copyright (c) 2020 Stenio Silveira
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# ----------------------------------------------------------------------#

### VARS

    # --- COLORS
      BOLD=$(tput bold)
      UNDERLINE=$(tput sgr 0 1)
      RESET=$(tput sgr0)

      # Regular Colors
      BLACK=$(tput setaf 0)
      RED=$(tput setaf 1)
      GREEN=$(tput setaf 2)
      YELLOW=$(tput setaf 3)
      BLUE=$(tput setaf 4)
      PURPLE=$(tput setaf 5)
      CYAN=$(tput setaf 6)
      WHITE=$(tput setaf 7)

      # Bold Colors
      BBLACK=${BOLD}${BLACK}
      BRED=${BOLD}${RED}
      BGREEN=${BOLD}${GREEN}
      BYELLOW=${BOLD}${YELLOW}
      BBLUE=${BOLD}${BLUE}
      BPURPLE=${BOLD}${PURPLE}
      BCYAN=${BOLD}${CYAN}
      BWHITE=${BOLD}${WHITE}

      # Background Colors
      BG_BLACK=$(tput setab 0)
      BG_RED=$(tput setab 1)
      BG_GREEN=$(tput setab 2)
      BG_YELLOW=$(tput setab 3)
      BG_BLUE=$(tput setab 4)
      BG_PURPLE=$(tput setab 5)
      BG_CYAN=$(tput setab 6)
      BG_WHITE=$(tput setab 7)

    # --- ESSENTIALS
      APP_TITLE="pali 0.1"
      NEW_LANGUAGE="pt_BR"
      NEW_ZONE="America"
      NEW_SUBZONE="Fortaleza"
      NEW_GRUB_NAME="Archlinux"
      T_COLS=$(tput cols)
      T_LINES=$(tput lines)
      TRIM=0

    # --- MOUNTPOINTS
      EFI_PARTITION="/dev/sda1"
      EFI_MOUNTPOINT="/boot/efi"
      ROOT_PARTITION="/dev/sda3"
      ROOT_MOUNTPOINT="/mnt"

    # --- PROMPT
      PROMPT1="${BGREEN}→ ${RESET}"

# ----------------------------------------------------------------------#

### TESTS

_check_connection() {
    _connection_test() {
      ping -q -w 1 -c 1 "$(ip r | grep default | awk 'NR==1 {print $3}')" &> /dev/null && return 0 || return 1
    }
    if ! _connection_test; then
      _print_title_alert "CONNECTION"
      _print_warning "You are not connected. Solve this problem and run this script again."
      _print_bye
      exit 1
    fi
}

# ----------------------------------------------------------------------#

### CORE FUNCTIONS

_setup_install(){
    [[ $(id -u) != 0 ]] && {
      _print_warning "Only for 'root'.\n"
      exit 1
    }
    _initial_info
    _rank_mirrors
    _select_disk
    _format_partitions
    _install_base
    _install_kernel
    _fstab_generate
    _set_timezone_and_clock
    _set_localization
    _set_network
    _mkinitcpio_generate
    _root_passwd
    _grub_generate
    _finish_install
    exit 0
}

_setup_config(){
    [[ $(id -u) != 0 ]] && {
      _print_warning "Only for 'root'.\n"
      exit 1
    }
    _create_new_user
    _enable_multilib
    _install_essential_pkgs
    _install_xorg
    _install_vga
    _install_extra_pkgs
    _install_laptop_pkgs
    _finish_config
    exit 0
}

_setup_desktop(){
    [[ $(id -u) != 0 ]] && {
      _print_warning "Only for 'root'.\n"
      exit 1
    }
    _install_desktop
    _install_display_manager
    _finish_desktop
    exit 0
}

_setup_user(){
    [[ $(id -u) != 1000 ]] && {
      _print_warning "Only for 'normal user'.\n"
      exit 1
    }
    _install_apps
    _install_pamac
    exit 0
}

# ----------------------------------------------------------------------#

### BASE FUNCTIONS

# --- INSTALL SECTION --- >

_initial_info() {
  _print_title_alert "IMPORTANT"
  timedatectl set-ntp true
  cat <<EOF

${CYAN}  * This script supports ${RESET}${BYELLOW}UEFI only${RESET}.
${CYAN}  * This script, for now, will install ${RESET}${BYELLOW}GRUB${RESET}${CYAN} as default bootloader.${RESET}
${CYAN}  * This script will only consider two partitions, ${RESET}${BYELLOW}ESP${RESET}${CYAN} and${RESET}${BYELLOW} ROOT.${RESET}
${CYAN}  * This script will format the root partition in ${RESET}${BYELLOW}BTRFS${RESET}${CYAN} format.${RESET}
${CYAN}  * The ESP partition can be formatted if the user wants to.${RESET}
${CYAN}  * This script does not support ${BYELLOW}SWAP${RESET}.
${CYAN}  * This script will create three subvolumes:${RESET}
${CYAN}      - ${BYELLOW}@${RESET}${CYAN} for /${RESET}
${CYAN}      - ${BYELLOW}@home${RESET}${CYAN} for /home${RESET}
${CYAN}      - ${BYELLOW}@.snapshots${RESET}${CYAN} for /.snapshots${RESET}
${CYAN}  * This script, for now, sets zoneinfo as America/Fortaleza.${RESET}
${CYAN}  * This script sets hwclock as UTC.${RESET}
  
${BYELLOW}  * This script is not yet complete!${RESET}
  
${BWHITE}  * Btw, thank's for your time!${RESET}
EOF
  _pause_function
}

_rank_mirrors() {
  _print_title "MIRRORS"
  if [[ ! -f /etc/pacman.d/mirrorlist.backup ]]; then
    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
  fi
  echo
  _print_action "Running" "reflector -c Brazil --sort score --save /etc/pacman.d/mirrorlist"
  reflector -c Brazil --sort score --save /etc/pacman.d/mirrorlist && _print_ok
  _print_action "Running" "pacman -Syy"
  pacman -Syy &> /dev/null && _print_ok
  echo
  _print_line_bblack
  _read_input_option "Edit your mirrorlist file? [y/N]: "
  if [[ $OPTION == y || $OPTION == Y ]]; then
    nano /etc/pacman.d/mirrorlist
  fi
}

_select_disk() {
  _print_title "PARTITION THE DISKS"
  PS3="$PROMPT1"
  DEVICES_LIST=($(lsblk -d | awk '{print "/dev/" $1}' | grep 'sd\|hd\|vd\|nvme\|mmcblk'))
  _print_subtitle "SELECT DISK:"
  select DEVICE in "${DEVICES_LIST[@]}"; do
    if _contains_element "${DEVICE}" "${DEVICES_LIST[@]}"; then
      break
    else
      _invalid_option
    fi
  done
  INSTALL_DISK=${DEVICE}
  echo
  _print_line_bblack
  _read_input_option "Edit disk partitions? [y/N]: "
  if [[ $OPTION == y || $OPTION == Y ]]; then
    cfdisk ${INSTALL_DISK}
  fi
}

_format_partitions() {
  _print_title "FORMAT THE PARTITIONS / MOUNT THE FILE SYSTEMS"
  BLOCK_LIST=($(lsblk | grep 'part\|lvm' | awk '{print substr($1,3)}'))

  PARTITIONS_LIST=()
  for OPT in "${BLOCK_LIST[@]}"; do
    PARTITIONS_LIST+=("/dev/${OPT}")
  done

  if [[ ${#BLOCK_LIST[@]} -eq 0 ]]; then
    _print_warning "No partition found."
    exit 0
  fi

  _format_root_partition() {
    _print_select_partition "ROOT"
    _print_danger "All data on the partition will be LOST!"
    PS3="$PROMPT1"
    select PARTITION in "${PARTITIONS_LIST[@]}"; do
      if _contains_element "${PARTITION}" "${PARTITIONS_LIST[@]}"; then
        PARTITION_NUMBER=$((REPLY -1))
        ROOT_PARTITION="$PARTITION"
        break;
      else
        _invalid_option
      fi
    done
    if mount | grep "${ROOT_PARTITION}" &> /dev/null; then
      umount -R ${ROOT_MOUNTPOINT}
    fi
    echo
    _print_action "Format" "${ROOT_PARTITION}"
    mkfs.btrfs -f -L Archlinux ${ROOT_PARTITION} &> /dev/null && _print_ok
    mount ${ROOT_PARTITION} ${ROOT_MOUNTPOINT} &> /dev/null
    _print_action "Create subvolume" "@"
    btrfs su cr ${ROOT_MOUNTPOINT}/@ &> /dev/null && _print_ok
    _print_action "Create subvolume" "@home"
    btrfs su cr ${ROOT_MOUNTPOINT}/@home &> /dev/null && _print_ok
    _print_action "Create subvolume" "@.snapshots"
    btrfs su cr ${ROOT_MOUNTPOINT}/@.snapshots &> /dev/null && _print_ok
    umount -R ${ROOT_MOUNTPOINT} &> /dev/null
    _print_action "Mount" "@"
    mount -o noatime,compress=lzo,space_cache,commit=120,subvol=@ ${ROOT_PARTITION} ${ROOT_MOUNTPOINT} &> /dev/null && _print_ok
    mkdir -p ${ROOT_MOUNTPOINT}/{home,.snapshots} &> /dev/null
    _print_action "Mount" "@home"
    mount -o noatime,compress=lzo,space_cache,commit=120,subvol=@home ${ROOT_PARTITION} ${ROOT_MOUNTPOINT}/home &> /dev/null && _print_ok
    _print_action "Mount" "@.snapshots"
    mount -o noatime,compress=lzo,space_cache,commit=120,subvol=@.snapshots ${ROOT_PARTITION} ${ROOT_MOUNTPOINT}/.snapshots &> /dev/null && _print_ok
    _check_mountpoint "${ROOT_PARTITION}" "${ROOT_MOUNTPOINT}"
    _pause_function
  }

  _format_efi_partition() {
    _print_title "FORMAT THE PARTITIONS / MOUNT THE FILE SYSTEMS"
    _print_select_partition "EFI"
    PS3="$PROMPT1"
    select PARTITION in "${PARTITIONS_LIST[@]}"; do
      if _contains_element "${PARTITION}" "${PARTITIONS_LIST[@]}"; then
        EFI_PARTITION="${PARTITION}"
        break;
      else
        _invalid_option
      fi
    done
    _read_input_option "Format EFI partition? [y/N]: "
    if [[ $OPTION == y || $OPTION == Y ]]; then
      _read_input_option "${BRED}All data will be LOST! Confirm format EFI partition? [y/N]: ${RESET}"
      if [[ $OPTION == y || $OPTION == Y ]]; then
        echo
        _print_action "Format" "${EFI_PARTITION}"
        mkfs.fat -F32 ${EFI_PARTITION} &> /dev/null && _print_ok
        mkdir -p ${ROOT_MOUNTPOINT}${EFI_MOUNTPOINT} &> /dev/null
        _print_action "Mount" "${EFI_PARTITION}"
        mount -t vfat ${EFI_PARTITION} ${ROOT_MOUNTPOINT}${EFI_MOUNTPOINT} &> /dev/null && _print_ok
      else
        echo
        mkdir -p ${ROOT_MOUNTPOINT}${EFI_MOUNTPOINT} &> /dev/null
        _print_action "Mount" "${EFI_PARTITION}"
        mount -t vfat ${EFI_PARTITION} ${ROOT_MOUNTPOINT}${EFI_MOUNTPOINT} &> /dev/null && _print_ok
      fi
    else
      echo
      mkdir -p ${ROOT_MOUNTPOINT}${EFI_MOUNTPOINT} &> /dev/null
      _print_action "Mount" "${EFI_PARTITION}"
      mount -t vfat ${EFI_PARTITION} ${ROOT_MOUNTPOINT}${EFI_MOUNTPOINT} &> /dev/null && _print_ok
    fi
    _check_mountpoint "${EFI_PARTITION}" "${ROOT_MOUNTPOINT}${EFI_MOUNTPOINT}"
  }

  _disable_partition() {
    unset PARTITIONS_LIST["${PARTITION_NUMBER}"]
    PARTITIONS_LIST=("${PARTITIONS_LIST[@]}")
  }

  _check_mountpoint() {
    if mount | grep "$2" &> /dev/null; then
      echo
      _print_info "Partition(s) successfully mounted!"
      _disable_partition "$1"
    else
      echo
      _print_warning "Partition(s) not successfully mounted!"
    fi
  }
  _format_root_partition
  _format_efi_partition
  _pause_function
}

_install_base() {
  _print_title "BASE"
  _print_subtitle "PACKAGES"
  _pacstrap_install "base base-devel"
  _pacstrap_install "intel-ucode"
  _pacstrap_install "btrfs-progs"
  _pacstrap_install "networkmanager"
  _print_subtitle "SERVICES"
  _print_action "Enabling" "NetworkManager"
  arch-chroot ${ROOT_MOUNTPOINT} systemctl enable NetworkManager &> /dev/null && _print_ok
  _pause_function
}

_install_kernel() {
  _print_title "KERNEL"
  _print_subtitle "SELECT KERNEL VERSION:"
  KERNEL_LIST=("linux" "linux-lts" "Other")
  select KERNEL_VERSION in "${KERNEL_LIST[@]}"; do
    if _contains_element "${KERNEL_VERSION}" "${KERNEL_LIST[@]}"; then
      KERNEL_VERSION="${KERNEL_VERSION}"
      break;
    else
      _invalid_option
    fi
  done
  if [[ "${KERNEL_VERSION}" = "linux" || "${KERNEL_VERSION}" = "linux-lts" ]]; then
    _print_subtitle "PACKAGES"
    _pacstrap_install "${KERNEL_VERSION}"
    _pacstrap_install "${KERNEL_VERSION}-headers"
    _pacstrap_install "linux-firmware"
  elif [[ "${KERNEL_VERSION}" = "Other" ]]; then
    _read_input_text "Type kernel do you want install: "
    echo -ne "${BGREEN}"
    read -r KERNEL_VERSION
    echo -ne "${RESET}"
    echo
    _print_subtitle "PACKAGES"
    _pacstrap_install "${KERNEL_VERSION}"
    _pacstrap_install "${KERNEL_VERSION}-headers"
    _pacstrap_install "linux-firmware"
  else
    _print_warning "You have not installed a kernel, remember this."
  fi
  _pause_function
}

_fstab_generate() {
  _print_title "FSTAB"
  echo
  _print_action "Running" "genfstab -U ${ROOT_MOUNTPOINT} > ${ROOT_MOUNTPOINT}/etc/fstab"
  genfstab -U ${ROOT_MOUNTPOINT} > ${ROOT_MOUNTPOINT}/etc/fstab && _print_ok
  echo
  _print_line_bblack
  _read_input_option "Edit your fstab file? [y/N]: "
  if [[ $OPTION == y || $OPTION == Y ]]; then
    nano ${ROOT_MOUNTPOINT}/etc/fstab
  fi
}

_set_timezone_and_clock() {
  _print_title "TIME ZONE AND SYSTEM CLOCK"
  echo
  _print_action "Running" "timedatectl set-ntp true"
  arch-chroot ${ROOT_MOUNTPOINT} timedatectl set-ntp true &> /dev/null && _print_ok
  _print_action "Running" "ln -sf /usr/share/zoneinfo/${NEW_ZONE}/${NEW_SUBZONE} /etc/localtime"
  arch-chroot ${ROOT_MOUNTPOINT} ln -sf /usr/share/zoneinfo/${NEW_ZONE}/${NEW_SUBZONE} /etc/localtime &> /dev/null && _print_ok
  arch-chroot ${ROOT_MOUNTPOINT} sed -i '/#NTP=/d' /etc/systemd/timesyncd.conf
  arch-chroot ${ROOT_MOUNTPOINT} sed -i 's/#Fallback//' /etc/systemd/timesyncd.conf
  arch-chroot ${ROOT_MOUNTPOINT} echo \"FallbackNTP=a.st1.ntp.br b.st1.ntp.br 0.br.pool.ntp.org\" >> /etc/systemd/timesyncd.conf 
  arch-chroot ${ROOT_MOUNTPOINT} systemctl enable systemd-timesyncd.service &> /dev/null
  _print_action "Running" "hwclock --systohc --utc"
  arch-chroot ${ROOT_MOUNTPOINT} hwclock --systohc --utc &> /dev/null && _print_ok
  sed -i 's/#\('pt_BR'\)/\1/' ${ROOT_MOUNTPOINT}/etc/locale.gen
  _pause_function
}

_set_localization() {
  _print_title "LOCALIZATION"
  echo
  _print_action "Running" "locale-gen"
  arch-chroot ${ROOT_MOUNTPOINT} locale-gen &> /dev/null && _print_ok
  _print_action "Running" "echo LANG=pt_BR.UTF-8 > ${ROOT_MOUNTPOINT}/etc/locale.conf"
  echo "LANG=pt_BR.UTF-8" > ${ROOT_MOUNTPOINT}/etc/locale.conf && _print_ok
  _print_action "Running" "echo KEYMAP=br-abnt2 > ${ROOT_MOUNTPOINT}/etc/vconsole.conf"
  echo "KEYMAP=br-abnt2" > ${ROOT_MOUNTPOINT}/etc/vconsole.conf && _print_ok
  _pause_function  
}

_set_network() {
  _print_title "NETWORK CONFIGURATION"
  echo
  _read_input_text "Type a hostname: "
  echo -ne "${BGREEN}"
  read -r NEW_HOSTNAME
  echo -ne "${RESET}"
  echo
  while [[ "${NEW_HOSTNAME}" == "" ]]; do
    _print_title "NETWORK CONFIGURATION"
    echo
    _print_warning "You must be type a hostname!"
    _read_input_text "Type a hostname: "
    echo -ne "${BGREEN}"
    read -r NEW_HOSTNAME
    echo -ne "${RESET}"
    echo
  done
  NEW_HOSTNAME=$(echo "$NEW_HOSTNAME" | tr '[:upper:]' '[:lower:]')
  _print_action "Setting" "hostname file"
  echo ${NEW_HOSTNAME} > ${ROOT_MOUNTPOINT}/etc/hostname && _print_ok
  _print_action "Setting" "hosts file"
  echo -e "127.0.0.1 localhost.localdomain localhost" > ${ROOT_MOUNTPOINT}/etc/hosts
  echo -e "::1 localhost.localdomain localhost" >> ${ROOT_MOUNTPOINT}/etc/hosts
  echo -e "127.0.1.1 ${NEW_HOSTNAME}.localdomain ${NEW_HOSTNAME}" >> ${ROOT_MOUNTPOINT}/etc/hosts && _print_ok
  _pause_function  
}

_mkinitcpio_generate() {
  _print_title "INITRAMFS"
  echo
  arch-chroot ${ROOT_MOUNTPOINT} mkinitcpio -P
  _pause_function
}

_root_passwd() {
  PASSWD_CHECK=0
  _print_title "ROOT PASSWORD"
  _print_subtitle "TYPE A NEW ROOT PASSWORD:"
  echo -ne "${CYAN}"
  arch-chroot ${ROOT_MOUNTPOINT} passwd && PASSWD_CHECK=1;
  echo -ne "${RESET}"
  while [[ $PASSWD_CHECK == 0 ]]; do
    _print_title "ROOT PASSWORD"
    _print_warning "The password does not match!"
    _print_subtitle "TYPE A NEW ROOT PASSWORD:"
    echo -ne "${CYAN}"
    arch-chroot ${ROOT_MOUNTPOINT} passwd && PASSWD_CHECK=1;
    echo -ne "${RESET}"
  done
  _pause_function
}

_grub_generate() {
  _print_title "BOOTLOADER"
  echo
  _read_input_text "Type a grub name entry: "
  echo -ne "${BGREEN}"
  read -r NEW_GRUB_NAME
  echo -ne "${RESET}"
  while [[ "${NEW_GRUB_NAME}" == "" ]]; do
    _print_title "BOOTLOADER"
    echo
    _print_warning "YOU MUST BE TYPE A GRUB NAME ENTRY!"
    _read_input_text "Type a grub name entry: "
    echo -ne "${BGREEN}"
    read -r NEW_GRUB_NAME
    echo -ne "${RESET}"
  done
  _print_subtitle "PACKAGES"
  _pacstrap_install "grub grub-btrfs efibootmgr"
  _print_subtitle "GRUB INSTALL"
  echo -ne "${CYAN}"
  arch-chroot ${ROOT_MOUNTPOINT} grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=${NEW_GRUB_NAME} --recheck
  echo -ne "${RESET}"
  _print_subtitle "GRUB CONFIGURATION FILE"
  echo -ne "${CYAN}"
  arch-chroot ${ROOT_MOUNTPOINT} grub-mkconfig -o /boot/grub/grub.cfg
  echo -ne "${RESET}"
  _pause_function  
}

_finish_install() {
  _print_title "FIRST STEP FINISHED"
  _print_subtitle "CONFIGS"
  echo -e "Root partition: ${ROOT_PARTITION}"
  echo -e "EFI partition: ${EFI_PARTITION}"
  echo -e "Kernel: ${KERNEL_VERSION}"
  echo -e "Hostname: ${NEW_HOSTNAME}"
  echo -e "Grubname: ${NEW_GRUB_NAME}"
  echo -e "-----------------------------------"
  echo
  _print_info "Your new system has been installed!"
  _read_input_option "Save a copy of this script in root directory? [y/N]: "
  if [[ $OPTION == y || $OPTION == Y ]]; then
    if ! _is_package_installed "wget"; then
      _package_install "wget"
    fi
    _print_action "Downloading" "setup.sh"
    wget -O ${ROOT_MOUNTPOINT}/root/setup.sh "stenioas.github.io/myarch/setup.sh" &> /dev/null && _print_ok
  fi
  cp /etc/pacman.d/mirrorlist.backup ${ROOT_MOUNTPOINT}/etc/pacman.d/mirrorlist.backup
  _read_input_option "${BRED}Reboot system now? [y/N]: ${RESET}"
  if [[ $OPTION == y || $OPTION == Y ]]; then
    _umount_partitions
    reboot
  fi
  _print_bye
  exit 0
}

# --- END INSTALL SECTION --- >

# --- CONFIG SECTION --- >

_create_new_user() {
  _print_title "NEW USER"
  _read_input_text "Type your username: "
  echo -ne "${BGREEN}"
  read -r NEW_USER
  echo -ne "${RESET}"
  echo
  while [[ "${NEW_USER}" == "" ]]; do
    _print_title "NEW USER"
    _print_warning "You must be type a username!"
    _read_input_text "Type your username: "
    echo -ne "${BGREEN}"
    read -r NEW_USER
    echo -ne "${RESET}"
    echo
  done
  NEW_USER=$(echo "$NEW_USER" | tr '[:upper:]' '[:lower:]')
  if [[ "$(grep ${NEW_USER} /etc/passwd)" == "" ]]; then
    _print_action "Create user" "${NEW_USER}"
    useradd -m -g users -G wheel ${NEW_USER} && _print_ok
    _print_subtitle "TYPE A NEW USER PASSWORD:"
    passwd ${NEW_USER}
    _print_info "Privileges added."
    sed -i '/%wheel ALL=(ALL) ALL/s/^# //' /etc/sudoers
  else
    _print_info "User ${NEW_USER} already exists!"
  fi
  _pause_function
}

_enable_multilib(){
  _print_title "MULTILIB"
  ARCHI=$(uname -m)
  if [[ $ARCHI == x86_64 ]]; then
    local _has_multilib=$(grep -n "\[multilib\]" /etc/pacman.conf | cut -f1 -d:)
    if [[ -z $_has_multilib ]]; then
      _print_action "Enabling" "Multilib"
      echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf && _print_ok
    else
      _print_action "Enabling" "Multilib"
      sed -i "${_has_multilib}s/^#//" /etc/pacman.conf
      local _has_multilib=$(( _has_multilib + 1 ))
      sed -i "${_has_multilib}s/^#//" /etc/pacman.conf && _print_ok
    fi
  fi
  _print_action "Updating mirrors..."
  pacman -Syy
  _pause_function
}

_install_essential_pkgs() {
  _print_title "ESSENTIAL PACKAGES"
  _package_install "dosfstools mtools udisks2 dialog wget git nano reflector bash-completion xdg-utils xdg-user-dirs"
  _pause_function
}

_install_xorg() {
  _print_title "XORG"
  _group_package_install "xorg"
  _group_package_install "xorg-apps"
  _package_install "xorg-xinit xterm"
  _pause_function
}

_install_vga() {
  _print_title "VIDEO DRIVER"
  PS3="$PROMPT1"
  VIDEO_CARD_LIST=("Intel" "Virtualbox");
  _print_subtitle "SELECT VIDEO DRIVER:"
  select VIDEO_CARD in "${VIDEO_CARD_LIST[@]}"; do
    if _contains_element "${VIDEO_CARD}" "${VIDEO_CARD_LIST[@]}"; then
      break
    else
      _invalid_option
    fi
  done
  if [[ "$VIDEO_CARD" == "Intel" ]]; then
    _package_install "xf86-video-intel mesa mesa-libgl libvdpau-va-gl"
  elif [[ "$VIDEO_CARD" == "AMD" ]]; then
    _print_warning "It's not working yet..."
  elif [[ "$VIDEO_CARD" == "Nvidia" ]]; then
    _print_warning "It's not working yet..."
  elif [[ "$VIDEO_CARD" == "Virtualbox" ]]; then
    _package_install "xf86-video-vmware virtualbox-guest-utils virtualbox-guest-dkms mesa mesa-libgl libvdpau-va-gl"

  else
    _invalid_option
    exit 0
  fi
  _pause_function
}

_install_extra_pkgs() {
  _print_title "EXTRA PACKAGES"
  _print_subtitle "UTILITIES"
  _package_install "usbutils lsof dmidecode neofetch bashtop htop avahi nss-mdns logrotate sysfsutils mlocate"
  _print_subtitle "COMPRESSION TOOLS"
  _package_install "zip unzip unrar p7zip lzop"
  _print_subtitle "FILESYSTEM TOOLS"
  _package_install "ntfs-3g autofs fuse fuse2 fuse3 fuseiso mtpfs"
  _print_subtitle "SOUND TOOLS"
  _package_install "alsa-utils pulseaudio"
  _pause_function
}

_install_laptop_pkgs() {
  _print_title "LAPTOP PACKAGES"
  PS3="$PROMPT1"
  echo
  _read_input_option "Install laptop packages? [y/N]: "
  if [[ $OPTION == y || $OPTION == Y ]]; then
    _print_subtitle "PACKAGES"
    _package_install "wpa_supplicant wireless_tools bluez bluez-utils pulseaudio-bluetooth xf86-input-synaptics"
    _print_subtitle "SERVICES"
    _print_action "Enabling" "Bluetooth"
    systemctl enable bluetooth &> /dev/null && _print_ok
  else
    -_print_info "Nothing to do!"
  fi
  _pause_function
}

_finish_config() {
  _print_title "SECOND STEP FINISHED"
  _pause_function
  exit 0
}

# --- END CONFIG SECTION --- >

# --- DESKTOP SECTION --- >

_install_desktop() {
  _print_title "DESKTOP OR WINDOW MANAGER"
  PS3="$PROMPT1"
  DESKTOP_LIST=("Gnome" "Plasma" "Xfce" "i3-gaps" "Bspwm" "Awesome" "Openbox" "Qtile" "None");
  _print_subtitle "SELECT YOUR DESKTOP:"
  select DESKTOP in "${DESKTOP_LIST[@]}"; do
    if _contains_element "${DESKTOP}" "${DESKTOP_LIST[@]}"; then
      break
    else
      _invalid_option
    fi
  done
  _print_title "DESKTOP OR WINDOW MANAGER"
  DESKTOP_CHOICE=$(echo "${DESKTOP}" | tr '[:lower:]' '[:upper:]')
  echo -e " ${PURPLE}${DESKTOP_CHOICE}${RESET}"
  echo
  
  if [[ "${DESKTOP}" == "Gnome" ]]; then
    _print_title "GNOME DESKTOP"
    _print_subtitle "PACKAGES"
    _group_package_install "gnome"
    _group_package_install "gnome-extra"
    _package_install "gnome-tweaks"

  elif [[ "${DESKTOP}" == "Plasma" ]]; then
    _print_title "PLASMA DESKTOP"
    _print_subtitle "PACKAGES"
    _package_install "plasma kde-applications packagekit-qt5"

  elif [[ "${DESKTOP}" == "Xfce" ]]; then
    _print_title "XFCE DESKTOP"
    _print_subtitle "PACKAGES"
    _package_install "xfce4 xfce4-goodies xarchiver network-manager-applet"

  elif [[ "${DESKTOP}" == "i3-gaps" ]]; then
    _print_title "I3-GAPS"
    _print_subtitle "PACKAGES"
    _package_install "i3-gaps i3status i3blocks i3lock dmenu rofi arandr feh nitrogen picom lxappearance xfce4-terminal xarchiver network-manager-applet"

  elif [[ "${DESKTOP}" == "Bspwm" ]]; then
    _print_title "BSPWM"
    _print_subtitle "PACKAGES"
    _print_warning "It's not working yet..."

  elif [[ "${DESKTOP}" == "Awesome" ]]; then
    _print_title "AWESOME WM"
    _print_subtitle "PACKAGES"
    _print_warning "It's not working yet..."

  elif [[ "${DESKTOP}" == "Openbox" ]]; then
    _print_title "OPENBOX"
    _print_subtitle "PACKAGES"
    _package_install "openbox obconf dmenu rofi arandr feh nitrogen picom lxappearance xfce4-terminal xarchiver network-manager-applet"

  elif [[ "${DESKTOP}" == "Qtile" ]]; then
    _print_title "QTILE"
    _print_subtitle "PACKAGES"
    _package_install "qtile dmenu rofi arandr feh nitrogen picom lxappearance xfce4-terminal xarchiver network-manager-applet"

  elif [[ "${DESKTOP}" == "None" ]]; then
    _print_info "Nothing to do!"

  else
    _invalid_option
    exit 0
  fi
  localectl set-x11-keymap br
  _pause_function
}

_install_display_manager() {
  _print_title "DISPLAY MANAGER"
  PS3="$PROMPT1"
  DMANAGER_LIST=("Lightdm" "Lxdm" "Slim" "GDM" "SDDM" "Xinit" "None");
  _print_warning " * Select your option:\n"
  select DMANAGER in "${DMANAGER_LIST[@]}"; do
    if _contains_element "${DMANAGER}" "${DMANAGER_LIST[@]}"; then
      break
    else
      _invalid_option
    fi
  done
  _print_title "DISPLAY MANAGER"
  DMANAGER_CHOICE=$(echo "${DMANAGER}" | tr '[:lower:]' '[:upper:]')
  echo -e " ${PURPLE}${DMANAGER_CHOICE}${RESET}\n"

  if [[ "${DMANAGER}" == "Lightdm" ]]; then
    _package_install "lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings"
    _print_action "Enabling" "LightDM"
    sudo systemctl enable lightdm &> /dev/null && _print_ok

  elif [[ "${DMANAGER}" == "Lxdm" ]]; then
    _print_warning "It's not working yet..."

  elif [[ "${DMANAGER}" == "Slim" ]]; then
    _print_warning "It's not working yet..."

  elif [[ "${DMANAGER}" == "GDM" ]]; then
    _package_install "gdm"
    _print_action "Enabling" "GDM"
    sudo systemctl enable gdm &> /dev/null && _print_ok

  elif [[ "${DMANAGER}" == "SDDM" ]]; then
    _package_install "sddm"
    _print_action "Enabling" "SDDM"
    sudo systemctl enable sddm &> /dev/null && _print_ok

  elif [[ "${DMANAGER}" == "Xinit" ]]; then
    _print_warning "It's not working yet..."

  elif [[ "${DMANAGER}" == "None" ]]; then
    _print_info "Nothing to do!"

  else
    _invalid_option
    exit 0
  fi
  _pause_function
}

_finish_desktop() {
  _print_title "THIRD STEP FINISHED"
  _print_info "[ OPTIONAL ] Proceed to the last step for install apps. Use ${BYELLOW}-u${RESET} ${BWHITE}option.${RESET}"
  _pause_function
  exit 0
}

# --- END DESKTOP SECTION --- >

# --- USER SECTION --- >

_install_apps() {
  _print_title "CUSTOM APPS"
  PS3="$PROMPT1"
  _read_input_option "Install custom apps? [y/N]: "
  if [[ $OPTION == y || $OPTION == Y ]]; then
    _package_install "libreoffice-fresh libreoffice-fresh-pt-br"
    _package_install "firefox firefox-i18n-pt-br"
    _package_install "steam"
    _package_install "gimp"
    _package_install "inkscape"
    _package_install "vlc"
    _package_install "telegram-desktop"
    if ${DESKTOP} == "Plasma" ; then
      _package_install "transmission-qt"
    else
      _package_install "transmission-gtk"
    fi
    _package_install "simplescreenrecorder"
    _package_install "redshift"
    _package_install "ranger"
    _package_install "cmatrix"
    _package_install "adapta-gtk-theme"
    _package_install "arc-gtk-theme"
    _package_install "papirus-icon-theme"
    _package_install "capitaine-cursors"
    _package_install "ttf-dejavu"
  else
    echo -e " ${BYELLOW}* Nothing to do!${RESET}"
  fi
  _pause_function
}

_install_pamac() {
  _print_title "PAMAC"
  PS3="$PROMPT1"
  _read_input_option "Install pamac? [y/N]: "
  _print_subtitle "Installing PAMAC..."
  if [[ "${OPTION}" == "y" || "${OPTION}" == "Y" ]]; then
    if ! _is_package_installed "pamac"; then
      [[ -d pamac ]] && rm -rf pamac
      git clone https://aur.archlinux.org/pamac-aur.git pamac
      cd pamac
      makepkg -csi --noconfirm
    else
      echo -e " ${BCYAN}Pamac${RESET} - ${BYELLOW}Is already installed!${RESET}"
    fi
  else
    echo -e " ${BYELLOW}* Nothing to do!${RESET}"
  fi
  _pause_function
}

# --- END USER SECTION --- >

### OTHER FUNCTIONS

_print_line() {
  echo -e "${BWHITE}`seq -s '─' $(( T_COLS + 1 )) | tr -d [:digit:]`${RESET}"
}

_print_dline() {
  T_COLS=$(tput cols)
  echo -e "${BWHITE}`seq -s '═' $(( T_COLS + 1 )) | tr -d [:digit:]`${RESET}"
}

_print_line_red() {
  echo -e "${RED}`seq -s '─' $(( T_COLS + 1 )) | tr -d [:digit:]`${RESET}"
}

_print_dline_red() {
  T_COLS=$(tput cols)
  echo -e "${RED}`seq -s '═' $(( T_COLS + 1 )) | tr -d [:digit:]`${RESET}"
}

_print_line_bblack() {
  echo -e "${BBLACK}`seq -s '─' $(( T_COLS + 1 )) | tr -d [:digit:]`${RESET}"
}

_print_dline_bblack() {
  T_COLS=$(tput cols)
  echo -e "${BBLACK}`seq -s '═' $(( T_COLS + 1 )) | tr -d [:digit:]`${RESET}"
}

_print_title() {
  clear
  T_COLS=$(tput cols)
  T_APP_TITLE=${#APP_TITLE}
  T_TITLE=${#1}
  T_LEFT="${BBLACK}║ ${RESET}${BGREEN} $1${RESET}"
  T_RIGHT="${BBLACK} ${APP_TITLE} ${RESET}"
  echo -ne "${BBLACK}╔${RESET}"; echo -ne "${BBLACK}`seq -s '═' $(( T_COLS - T_APP_TITLE - 4 )) | tr -d [:digit:]`${BBLACK}"
  echo -ne "${T_RIGHT}"; echo -e "${BBLACK}═╗${RESET}"
  echo -ne "${T_LEFT}"; echo -ne "`seq -s ' ' $(( T_COLS - T_TITLE - 3 )) | tr -d [:digit:]`"; echo -e "${BBLACK}║${RESET}"
  echo -ne "${BBLACK}╚${RESET}"; echo -ne "${BBLACK}`seq -s '═' $(( T_COLS - 1 )) | tr -d [:digit:]`${BBLACK}"; echo -e "${BBLACK}╝${RESET}"
}

_print_title_alert() {
  clear
  T_COLS=$(tput cols)
  T_APP_TITLE=${#APP_TITLE}
  T_TITLE=${#1}
  T_LEFT="${BBLACK}║${RESET}${BRED}   $1   ${RESET}${BBLACK}╠${RESET}"
  T_RIGHT="${BBLACK} ${APP_TITLE}${RESET}"
  echo -ne "`seq -s ' ' $(( T_COLS - T_APP_TITLE )) | tr -d [:digit:]`"
  echo -e "${T_RIGHT}"
  echo -ne "${T_LEFT}"
  echo -e "${BBLACK}`seq -s '═' $(( T_COLS - T_TITLE - 7 )) | tr -d [:digit:]`${RESET}"
}

_print_subtitle() {
  COLS_SUBTITLE=${#1}
  echo -e "\n${BWHITE} $1${RESET}"
  echo -ne "${BBWHITE}└${RESET}"; echo -ne "${BWHITE}`seq -s '─' $(( COLS_SUBTITLE + 2 )) | tr -d [:digit:]`${RESET}"; echo -e "${BBWHITE}┘${RESET}"
  echo
}

_print_select_partition() {
  COLS_SUBTITLE=${#1}
  echo -e "\n${BWHITE} SELECT${RESET}${BYELLOW} $1${RESET}${BWHITE} PARTITION:${RESET}"
  echo -ne "${BBWHITE}└${RESET}"; echo -ne "${BWHITE}`seq -s '─' $(( COLS_SUBTITLE + 20 )) | tr -d [:digit:]`${RESET}"; echo -e "${BWHITE}┘${RESET}"
  echo
}

_print_info() {
  T_COLS=$(tput cols)
  echo -e "${BBLUE}INFO:${RESET}${BWHITE} $1${RESET}" | fold -sw $(( T_COLS - 1 ))
}

_print_warning() {
  T_COLS=$(tput cols)
  echo -e "${BYELLOW}WARNING:${RESET}${BWHITE} $1${RESET}" | fold -sw $(( T_COLS - 1 ))
}

_print_danger() {
  T_COLS=$(tput cols)
  echo -e "${BRED}DANGER:${RESET}${BWHITE} $1${RESET}" | fold -sw $(( T_COLS - 1 ))
}

_print_action() {
  REM_COLS=$(( ${#1} + ${#2} ))
  REM_DOTS=$(( T_COLS - 22 - REM_COLS ))
  echo -ne "${BBLACK}$1${RESET}${WHITE} $2${RESET} "
  echo -ne "${BBLACK}`seq -s '.' $(( REM_DOTS )) | tr -d [:digit:]`${RESET}"
  echo -ne "${BBLACK} [      ]${RESET}"
}

_print_ok() {
  tput cub 5
  echo -e "${BGREEN}OK${RESET}"
}

_print_fail() {
  tput cub 5
  echo -e "${BRED}FAIL${RESET}"
}

_print_bye() {
  echo
  _print_line_bblack
  echo -e "${BGREEN} Bye!${RESET}\n"
}

_read_input_text() {
  printf "%s" "${BWHITE}$1${RESET}"
}

_read_input_option() {
  printf "%s" "${YELLOW}$1${RESET}"
  read -r OPTION
}

_contains_element() {
    for e in "${@:2}"; do [[ "$e" == "$1" ]] && break; done;
}

_invalid_option() {
    _print_warning "Invalid option. Try again..."
}

_pause_function() {
  echo
  _print_dline_bblack
  read -e -sn 1 -p "${BGREEN}Press any key to continue...${RESET}"
}

_umount_partitions() {
  _print_info "UMOUNTING PARTITIONS"
  umount -R ${ROOT_MOUNTPOINT}
}

_is_package_installed() {
  for PKG in $1; do
    pacman -Q "$PKG" &> /dev/null && return 0;
  done
  return 1
}

_package_install() { # install pacman package
  _package_was_installed() {
    for PKG in $1; do
      if [[ $(id -u) == 0 ]]; then
        pacman -S --noconfirm --needed "${PKG}" &> /dev/null && return 0;
      else
        sudo pacman -S --noconfirm --needed "${PKG}" &> /dev/null && return 0;
      fi
    done
    return 1
  }
  for PKG in $1; do
    if ! _is_package_installed "${PKG}"; then
      _print_action "Installing" "${PKG}"
      if _package_was_installed "${PKG}"; then
        _print_ok
      else
        _print_fail
      fi
    else
      _print_action "Installing" "${PKG}"
      _print_ok
    fi
  done
}

_group_package_install() { # install a package group
  _package_install "$(pacman -Sqg ${1})"
}

_pacstrap_install() { # install pacstrap package
  _pacstrap_was_installed() {
    for PKG in $1; do
      pacstrap "${ROOT_MOUNTPOINT}" "${PKG}" &> /dev/null && return 0;
    done
    return 1
  }
  for PKG in $1; do
    _print_action "Installing" "${PKG}"
    if _pacstrap_was_installed "${PKG}"; then
      _print_ok
    else
      _print_fail
    fi
  done
}

usage() {
  cat <<EOF

usage: ${0##*/} [flags]

  Flag options:

    --install | -i         First step, only root user.
    --config  | -c         Second step, only root user.
    --desktop | -d         Third step, only root user.
    --user    | -u         Last step, only normal user.

arch-setup 0.1

EOF
}

# ----------------------------------------------------------------------#

### EXECUTION

[[ -z $1 ]] && {
    usage
    exit 1
}
clear
setfont

cat <<EOF

${BYELLOW}                 -@                ${RESET}
${BYELLOW}                .##@               ${RESET}${CYAN}  ██████╗  █████╗    ██╗        ██╗           ${RESET}
${BYELLOW}               .####@              ${RESET}${CYAN}  ██╔══██╗██╔══██╗   ██║        ██║           ${RESET}
${BYELLOW}               @#####@             ${RESET}${CYAN}  ██████╔╝███████║   ██║        ██║           ${RESET}
${BYELLOW}             . *######@            ${RESET}${CYAN}  ██╔═══╝ ██╔══██║   ██║        ██║           ${RESET}
${BYELLOW}            .##@o@#####@           ${RESET}${CYAN}  ██║██╗  ██║  ██║██╗███████╗██╗██║██╗        ${RESET}
${BYELLOW}           /############@          ${RESET}${CYAN}  ╚═╝╚═╝  ╚═╝  ╚═╝╚═╝╚══════╝╚═╝╚═╝╚═╝        ${RESET}
${BYELLOW}          /##############@         ${RESET}${PURPLE}  ---------- My Arch Way! ------------      ${RESET}
${BYELLOW}         @######@**%######@        ${RESET}${BBLACK}╓───────────────────────────────────────╖   ${RESET}
${BYELLOW}        @######\`     %#####o      ${RESET}${BBLACK} ║  https://github.com/stenioas/myarch   ║  ${RESET}
${BYELLOW}       @######@       ######%      ${RESET}${BBLACK}║    My Personal Arclinux Installer     ║   ${RESET}
${BYELLOW}     -@#######h       ######@.\`   ${RESET}${BBLACK} ║        By Stenio Silveira             ║  ${RESET}
${BYELLOW}    /#####h**\`\`       \`**%@####@${RESET}${BBLACK}   ╙───────────────────────────────────────╜${RESET}
${BYELLOW}   @H@*\`                    \`*%#@${RESET}
${BYELLOW}  *\`                            \`*${RESET}


EOF
tput cup 15 44
read -e -sn 1 -p "${BWHITE}Press any key to start!${RESET}"
_check_connection

while [[ "$1" ]]; do
  case "$1" in
    --install|-i) _setup_install;;
    --config|-c) _setup_config;;
    --desktop|-d) _setup_desktop;;
    --user|-u) _setup_user;;
  esac
  shift
  _print_bye && exit 0
done
