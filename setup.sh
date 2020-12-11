#!/bin/sh
#
# arch-setup: Install and Config Archlinux
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

usage() {
    cat <<EOF

usage: ${0##*/} [flags]

  Flag options:

    --install | -i         First step, only root user. THIS STEP MUST BE RUN IN LIVE MODE!
    --config  | -c         Second step, only root user.
    --desktop | -d         Third step, only root user.
    --user    | -u         Last step, only normal user.

* Arch-Setup 0.1

EOF
}

[[ -z $1 ]] && {
    usage
    exit 1
}

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
      APP_TITLE="ARCH-SETUP 0.1"
      NEW_LANGUAGE="pt_BR"
      NEW_ZONE="America"
      NEW_SUBZONE="Fortaleza"
      NEW_GRUB_NAME="Archlinux"
      TRIM=0

    # --- MOUNTPOINTS
      EFI_PARTITION="/dev/sda1"
      EFI_MOUNTPOINT="/boot/efi"
      ROOT_PARTITION="/dev/sda3"
      ROOT_MOUNTPOINT="/mnt"

    # --- PROMPT
      PROMPT1="  ${BBLUE}-> ${BWHITE}Option:${RESET} "

# ----------------------------------------------------------------------#

### CORE FUNCTIONS

_setup_install(){
    [[ $(id -u) != 0 ]] && {
      _print_warning "Only for 'root'.\n"
      exit 1
    }
    _check_archlive
    _initial_info
    _check_connection
    _initial_packages
    _rank_mirrors
    _select_disk
    _format_partitions
    _install_base
    _fstab_generate
    _set_locale
    _set_language
    _set_hostname
    _root_passwd
    _grub_generate
    _mkinitcpio_generate
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
    [[ $(id -u) != 1000 ]] && {
      _print_warning "Only for 'normal user'.\n"
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

_check_archlive() {
  [[ $(df | grep -w "/" | awk '{print $1}') != "airootfs" ]] && {
    _print_danger "\n *** FIRST STEP MUST BE RUN IN LIVE MODE ***"
    _pause_function
    exit 1
  }
}

_initial_info() {
  _print_title_alert "IMPORTANT"
  _print_subtitle "Readme"
  echo -e "\n - This script supports UEFI only."
  echo -e "\n - This script will install GRUB as default bootloader."
  echo -e "\n - This script, for now, only installs the lts kernel."
  echo -e "\n - This script will only consider two partitions, ESP and root."
  echo -e "\n - This script will format the root partition in btrfs format."
  echo -e "\n - The ESP partition can be formatted if the user wants to."
  echo -e "\n - This script does not support swap."
  echo -e "\n - This script will create three subvolumes:"
  echo -e "     @ for ${BYELLOW}/${RESET}"
  echo -e "     @home for ${BYELLOW}/home${RESET}"
  echo -e "     @.snapshots for ${BYELLOW}/.snapshots${RESET}"
  echo -e "\n - This script sets zoneinfo as America/Fortaleza."
  echo -e "\n - This script sets hwclock as UTC."
  _print_danger "\n - THIS SCRIPT IS NOT YET COMPLETE"
  _pause_function
}

_check_connection() {
    _connection_test() {
      ping -q -w 1 -c 1 "$(ip r | grep default | awk 'NR==1 {print $3}')" &> /dev/null && return 0 || return 1
    }
    if ! _connection_test; then
      _print_title_alert "CONNECTION"
      _print_warning "You are not connected. Solve this problem and run this script again."
      _print_bye
      _pause_function
      exit 1
    fi
}

_initial_packages() {
  _print_title "REQUIRED PACKAGES"
  _print_subtitle "Packages"
  _package_install "wget git nano"
  _print_done
  _pause_function
}

_rank_mirrors() {
  _print_title "MIRRORS"
  if [[ ! -f /etc/pacman.d/mirrorlist.backup ]]; then
    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
  fi
  _print_subtitle "Generating new mirrorlist..."
  _print_running "reflector -c Brazil --sort score --save /etc/pacman.d/mirrorlist"
  reflector -c Brazil --sort score --save /etc/pacman.d/mirrorlist && echo -e "${BYELLOW} [ OK ]${RESET}"
  _print_subtitle "Updating mirrors..."
  _print_running "pacman -Syy"
  pacman -Syy &> /dev/null && echo -e "${BGREEN} [ OK ]${RESET}"
  _print_done
  _pause_function
}

_select_disk() {
  _print_title "PARTITION THE DISKS"
  PS3="$PROMPT1"
  DEVICES_LIST=($(lsblk -d | awk '{print "/dev/" $1}' | grep 'sd\|hd\|vd\|nvme\|mmcblk'))
  _print_subtitle "Select disk:${RESET}"
  select DEVICE in "${DEVICES_LIST[@]}"; do
    if _contains_element "${DEVICE}" "${DEVICES_LIST[@]}"; then
      break
    else
      _invalid_option
    fi
  done
  INSTALL_DISK=${DEVICE}
  echo -e "${BGREEN}==> ${BWHITE}Selected disk:${RESET} ${INSTALL_DISK}"
  _read_input_text "Edit disk partitions? [y/N]: "
  if [[ $OPTION == y || $OPTION == Y ]]; then
    cfdisk ${INSTALL_DISK}
  fi
}

_format_partitions() {
  _print_title "FORMATTING AND MOUNTING PARTITIONS"
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
    _print_title "ROOT PARTITION"
    PS3="$PROMPT1"
    _print_warning "REMEMBER!!! This script will create 3 subvolumes:"
    echo -e "  ${BBLUE}->${WHITE} @ for ${BYELLOW}/${RESET}"
    echo -e "  ${BBLUE}->${WHITE} @home for ${BYELLOW}/home${RESET}"
    echo -e "  ${BBLUE}->${WHITE} @.snapshots for ${BYELLOW}/.snapshots${RESET}"
    _print_subtitle "Select partition to create btrfs subvolumes:${RESET}"
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
    echo -ne "${BGREEN}==> ${BWHITE}${ROOT_PARTITION}${RESET}"
    mkfs.btrfs -f -L Archlinux ${ROOT_PARTITION} &> /dev/null && echo -e " ${BGREEN}[ FORMATTED ]${RESET}"
    mount ${ROOT_PARTITION} ${ROOT_MOUNTPOINT} &> /dev/null
    _print_subtitle "Subvolumes"
    btrfs su cr ${ROOT_MOUNTPOINT}/@ &> /dev/null && echo -e "${BBLUE}  ->${BWHITE}@${RESET} ${BGREEN}[ CREATED ]${RESET}"
    btrfs su cr ${ROOT_MOUNTPOINT}/@home &> /dev/null && echo -e "${BBLUE}  ->${BWHITE}@home${RESET} ${BGREEN}[ CREATED ]${RESET}"
    btrfs su cr ${ROOT_MOUNTPOINT}/@.snapshots &> /dev/null && echo -e "${BBLUE}  ->${BWHITE}@.snapshots${RESET} ${BGREEN}[ CREATED ]${RESET}"
    umount -R ${ROOT_MOUNTPOINT} &> /dev/null
    mount -o noatime,compress=lzo,space_cache,commit=120,subvol=@ ${ROOT_PARTITION} ${ROOT_MOUNTPOINT} &> /dev/null
    mkdir -p ${ROOT_MOUNTPOINT}/{home,.snapshots} &> /dev/null
    mount -o noatime,compress=lzo,space_cache,commit=120,subvol=@home ${ROOT_PARTITION} ${ROOT_MOUNTPOINT}/home &> /dev/null
    mount -o noatime,compress=lzo,space_cache,commit=120,subvol=@.snapshots ${ROOT_PARTITION} ${ROOT_MOUNTPOINT}/.snapshots &> /dev/null
    _check_mountpoint "${ROOT_PARTITION}" "${ROOT_MOUNTPOINT}"
    _print_done
    _pause_function
  }

  _format_efi_partition() {
    _print_title "EFI PARTITION"
    PS3="$PROMPT1"
    _print_subtitle "Select EFI partition:${RESET}"
    select PARTITION in "${PARTITIONS_LIST[@]}"; do
      if _contains_element "${PARTITION}" "${PARTITIONS_LIST[@]}"; then
        EFI_PARTITION="${PARTITION}"
        break;
      else
        _invalid_option
      fi
    done
    _read_input_text "Format EFI partition? [y/N]: "
    if [[ $OPTION == y || $OPTION == Y ]]; then
      echo -ne "${BGREEN}==> ${BWHITE}${EFI_PARTITION}${RESET}"
      mkfs.fat -F32 ${EFI_PARTITION} &> /dev/null && echo -e " ${BGREEN}[ FORMATTED ]${RESET}"
    else
      echo -e "${BGREEN}==> ${BWHITE}${EFI_PARTITION}${RESET}${BGREEN}[ NOT FORMATTED ]${RESET}"
    fi
    mkdir -p ${ROOT_MOUNTPOINT}${EFI_MOUNTPOINT} &> /dev/null
    mount -t vfat ${EFI_PARTITION} ${ROOT_MOUNTPOINT}${EFI_MOUNTPOINT} &> /dev/null
    _check_mountpoint "${EFI_PARTITION}" "${ROOT_MOUNTPOINT}${EFI_MOUNTPOINT}"
  }

  _disable_partition() {
    unset PARTITIONS_LIST["${PARTITION_NUMBER}"]
    PARTITIONS_LIST=("${PARTITIONS_LIST[@]}")
  }

  _check_mountpoint() {
    if mount | grep "$2" &> /dev/null; then
      echo -ne "${BGREEN}==> ${BWHITE}$1${RESET}"; echo -e " ${BGREEN}[ MOUNTED ]${RESET}"
      _disable_partition "$1"
    else
      _print_warning "The partition was not successfully mounted!"
    fi
  }
  _format_root_partition
  _format_efi_partition
  _print_done
  _pause_function
}

_install_base() {
  _print_title "BASE"
  _pacstrap_install "base base-devel linux-lts linux-lts-headers linux-firmware intel-ucode btrfs-progs wget git nano networkmanager"
  _print_subtitle "Services"
  echo -ne "${BBLUE}  -> ${BWHITE}Enabling: ${RESET}${WHITE}NetworkManager${RESET}"
  arch-chroot ${ROOT_MOUNTPOINT} systemctl enable NetworkManager &> /dev/null && echo -e " ${BGREEN}[ OK ]${RESET}"
  _print_done
  _pause_function
}

_fstab_generate() {
  _print_title "FSTAB"
  _print_subtitle "Generating..."
  _print_running "genfstab -U ${ROOT_MOUNTPOINT} > ${ROOT_MOUNTPOINT}/etc/fstab${RESET}"
  genfstab -U ${ROOT_MOUNTPOINT} > ${ROOT_MOUNTPOINT}/etc/fstab && echo -e " ${BGREEN}[ OK ]${RESET}"
  _print_done
  _pause_function
}

_set_locale() {
  _print_title "TIME ZONE AND SYSTEM CLOCK"
  _print_running "timedatectl set-ntp true"
  arch-chroot ${ROOT_MOUNTPOINT} timedatectl set-ntp true &> /dev/null && echo -e "${BGREEN} [ OK ]${RESET}"
  _print_running "ln -sf /usr/share/zoneinfo/${NEW_ZONE}/${NEW_SUBZONE} /etc/localtime"
  arch-chroot ${ROOT_MOUNTPOINT} ln -sf /usr/share/zoneinfo/${NEW_ZONE}/${NEW_SUBZONE} /etc/localtime &> /dev/null && echo -e "${BGREEN} [ OK ]${RESET}"
  arch-chroot ${ROOT_MOUNTPOINT} sed -i '/#NTP=/d' /etc/systemd/timesyncd.conf
  arch-chroot ${ROOT_MOUNTPOINT} sed -i 's/#Fallback//' /etc/systemd/timesyncd.conf
  arch-chroot ${ROOT_MOUNTPOINT} echo \"FallbackNTP=a.st1.ntp.br b.st1.ntp.br 0.br.pool.ntp.org\" >> /etc/systemd/timesyncd.conf 
  arch-chroot ${ROOT_MOUNTPOINT} systemctl enable systemd-timesyncd.service &> /dev/null
  _print_running "hwclock --systohc --utc"
  arch-chroot ${ROOT_MOUNTPOINT} hwclock --systohc --utc &> /dev/null && echo -e "${BGREEN} [ OK ]${RESET}"
  sed -i 's/#\('pt_BR.UTF-8'\)/\1/' ${ROOT_MOUNTPOINT}/etc/locale.gen
  _print_running "locale-gen"
  arch-chroot ${ROOT_MOUNTPOINT} locale-gen &> /dev/null && echo -e "${BGREEN} [ OK ]${RESET}"
  _print_done
  _pause_function
}

_set_language() {
  _print_title "LANGUAGE AND KEYMAP"
  _print_subtitle "Setting..."
  _print_running "echo LANG=pt_BR.UTF-8 > ${ROOT_MOUNTPOINT}/etc/locale.conf"
  echo "LANG=pt_BR.UTF-8" > ${ROOT_MOUNTPOINT}/etc/locale.conf && echo -e "${BGREEN} [ OK ]${RESET}"
  _print_running "echo KEYMAP=br-abnt2 > ${ROOT_MOUNTPOINT}/etc/vconsole.conf"
  echo "KEYMAP=br-abnt2" > ${ROOT_MOUNTPOINT}/etc/vconsole.conf && echo -e "${BGREEN} [ OK ]${RESET}"
  _print_done
  _pause_function  
}

_set_hostname() {
  _print_title "HOSTNAME AND IP ADDRESS"
  _print_entry "Type a hostname [ex: archlinux]"
  read -r NEW_HOSTNAME
  while [[ "${NEW_HOSTNAME}" == "" ]]; do
    _print_title "HOSTNAME AND IP ADDRESS"
    _print_warning "YOU MUST BE TYPE A HOSTNAME!"
    _print_entry "Type a hostname [ex: archlinux]"
    read -r NEW_HOSTNAME
  done
  NEW_HOSTNAME=$(echo "$NEW_HOSTNAME" | tr '[:upper:]' '[:lower:]')
  _print_running "echo ${NEW_HOSTNAME} > ${ROOT_MOUNTPOINT}/etc/hostname"
  echo ${NEW_HOSTNAME} > ${ROOT_MOUNTPOINT}/etc/hostname && echo -e "${BGREEN} [ OK ]${RESET}"
  echo -ne "${BBLUE}  ->${BWHITE} Setting:${RESET}"
  echo -ne "${WHITE} Ip address on /etc/hosts${RESET}"
  echo -e "127.0.0.1 localhost.localdomain localhost" > ${ROOT_MOUNTPOINT}/etc/hosts
  echo -e "::1 localhost.localdomain localhost" >> ${ROOT_MOUNTPOINT}/etc/hosts
  echo -e "127.0.1.1 ${NEW_HOSTNAME}.localdomain ${NEW_HOSTNAME}" >> ${ROOT_MOUNTPOINT}/etc/hosts && echo -e "${BGREEN} [ OK ]${RESET}"
  _print_done
  _pause_function  
}

_root_passwd() {
  _print_title "ROOT PASSWORD"
  _print_subtitle "Type a root password:\n"
  arch-chroot ${ROOT_MOUNTPOINT} passwd
  _print_done
  _pause_function
}

_grub_generate() {
  _print_title "GRUB BOOTLOADER"
  _print_entry "Type a grub name entry [ex: Archlinux]"
  read -r NEW_GRUB_NAME
  while [[ "${NEW_GRUB_NAME}" == "" ]]; do
    _print_title "GRUB BOOTLOADER"
    _print_warning "YOU MUST BE TYPE A GRUB NAME ENTRY!"
    _print_entry "Type a grub name entry [ex: Archlinux]"
    read -r NEW_GRUB_NAME
  done
  _print_subtitle "Packages"
  _pacstrap_install "grub grub-btrfs efibootmgr"
  _print_subtitle "Installing grub on target\n"
  arch-chroot ${ROOT_MOUNTPOINT} grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=${NEW_GRUB_NAME} --recheck
  echo ""
  _print_subtitle "Generating grub.cfg\n"
  arch-chroot ${ROOT_MOUNTPOINT} grub-mkconfig -o /boot/grub/grub.cfg
  _print_done
  _pause_function  
}

_mkinitcpio_generate() {
  _print_title "MKINITCPIO"
  arch-chroot ${ROOT_MOUNTPOINT} mkinitcpio -P
  _print_done
  _pause_function
}

_finish_install() {
  _print_title "FIRST STEP FINISHED"
  _read_input_text "Save a copy of this script in root directory? [y/N]: "
  if [[ $OPTION == y || $OPTION == Y ]]; then
    _print_title "FIRST STEP FINISHED"
    echo -ne "${BBLUE}  ->${BWHITE} Downloading:${RESET} ${WHITE}setup.sh${RESET} ${BWHITE}to /root${RESET}"
    wget -O ${ROOT_MOUNTPOINT}/root/setup.sh "stenioas.github.io/myarch/setup.sh" &> /dev/null && echo -e "${BGREEN} [ SAVED ]"
  fi
  cp /etc/pacman.d/mirrorlist.backup ${ROOT_MOUNTPOINT}/etc/pacman.d/mirrorlist.backup
  _read_input_text "Reboot system? [y/N]: "
  echo ""
  if [[ $OPTION == y || $OPTION == Y ]]; then
    _umount_partitions
    reboot
  else
    clear
  fi
  exit 0
}

# --- END INSTALL SECTION --- >

# --- CONFIG SECTION --- >

_create_new_user() {
  _print_title "CREATE NEW USER"
  _print_entry "Type your username"
  read -r NEW_USER
  while [[ "${NEW_USER}" == "" ]]; do
    _print_title "CREATE NEW USER"
    _print_warning "YOU MUST BE TYPE A USERNAME!"
    _print_entry "Type your username"
    read -r NEW_USER
  done
  NEW_USER=$(echo "$NEW_USER" | tr '[:upper:]' '[:lower:]')
  if [[ "$(grep ${NEW_USER} /etc/passwd)" == "" ]]; then
    useradd -m -g users -G wheel ${NEW_USER}
    _print_info " User ${NEW_USER} created."
    _print_subtitle "Setting password\n"
    passwd ${NEW_USER}
    _print_info " Privileges added."
    sed -i '/%wheel ALL=(ALL) ALL/s/^# //' /etc/sudoers
  else
    _print_info " User ${NEW_USER} already exists!"
  fi
  _print_done
  _pause_function
}

_enable_multilib(){
  _print_title "MULTILIB"
  ARCHI=$(uname -m)
  if [[ $ARCHI == x86_64 ]]; then
    local _has_multilib=$(grep -n "\[multilib\]" /etc/pacman.conf | cut -f1 -d:)
    if [[ -z $_has_multilib ]]; then
      echo -ne "${BBLUE}  -> ${BWHITE}Enabling: ${RESET} ${WHITE}Multilib${RESET} ..."
      echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
      _print_info " Multilib repository added to pacman.conf."
    else
      sed -i "${_has_multilib}s/^#//" /etc/pacman.conf
      local _has_multilib=$(( _has_multilib + 1 ))
      sed -i "${_has_multilib}s/^#//" /etc/pacman.conf
    fi
  fi
  _print_subtitle "Updating mirrors"
  pacman -Syy
  _print_done
  _pause_function
}

_install_essential_pkgs() {
  _print_title "ESSENTIAL PACKAGES"
  _package_install "dosfstools mtools udisks2 dialog git wget reflector bash-completion xdg-utils xdg-user-dirs"
  _print_done
  _pause_function
}

_install_xorg() {
  _print_title "XORG"
  _group_package_install "xorg"
  _group_package_install "xorg-apps"
  _package_install "xorg-xinit xterm"
  _print_done
  _pause_function
}

_install_vga() {
  _print_title "VIDEO DRIVER"
  PS3="$PROMPT1"
  VIDEO_CARD_LIST=("Intel" "AMD" "Nvidia" "Virtualbox");
  _print_subtitle "Select video card:\n"
  select VIDEO_CARD in "${VIDEO_CARD_LIST[@]}"; do
    if _contains_element "${VIDEO_CARD}" "${VIDEO_CARD_LIST[@]}"; then
      break
    else
      _invalid_option
    fi
  done
  _print_title "VIDEO DRIVER"
  echo -e "${BGREEN}==> ${BWHITE}${VIDEO_CARD}${RESET} ${BGREEN}[ SELECTED ]${RESET}"

  if [[ "$VIDEO_CARD" == "Intel" ]]; then
    _package_install "xf86-video-intel mesa mesa-libgl libvdpau-va-gl"

  elif [[ "$VIDEO_CARD" == "AMD" ]]; then
    _print_info "It's not working yet..."

  elif [[ "$VIDEO_CARD" == "Nvidia" ]]; then
    _print_info "It's not working yet..."

  elif [[ "$VIDEO_CARD" == "Virtualbox" ]]; then
    _package_install "xf86-video-vmware virtualbox-guest-utils virtualbox-guest-dkms mesa mesa-libgl libvdpau-va-gl"

  else
    _invalid_option
    exit 0
  fi
  _print_done
  _pause_function
}

_install_extra_pkgs() {
  _print_title "EXTRA PACKAGES"
  _print_subtitle "Installing Utils"
  _package_install "usbutils lsof dmidecode neofetch bashtop htop avahi nss-mdns logrotate sysfsutils mlocate"
  _print_subtitle "Installing compression tools"
  _package_install "zip unzip unrar p7zip lzop"
  _print_subtitle "Installing extra filesystem tools"
  _package_install "ntfs-3g autofs fuse fuse2 fuse3 fuseiso mtpfs"
  _print_subtitle "Installing sound tools"
  _package_install "alsa-utils pulseaudio"
  _print_done
  _pause_function
}

_install_laptop_pkgs() {
  _print_title "LAPTOP PACKAGES"
  PS3="$PROMPT1"
  _read_input_text "Install laptop packages? [y/N]: "
  if [[ $OPTION == y || $OPTION == Y ]]; then
    _print_title "LAPTOP PACKAGES"
    _package_install "wpa_supplicant wireless_tools bluez bluez-utils pulseaudio-bluetooth xf86-input-synaptics"
    _print_subtitle "Services"
    echo -ne "${BBLUE}  ->${BWHITE}Enabling:${RESET} ${WHITE}Bluetooth${RESET} ..."
    systemctl enable bluetooth &> /dev/null && echo -e " ${BGREEN}[ OK ]${RESET}"
  else
    -_print_info " Nothing to do!"
  fi
  _print_done
  _pause_function
}

_finish_config() {
  _print_title "SECOND STEP FINISHED"
  _print_done
  _pause_function
  exit 0
}

# --- END CONFIG SECTION --- >

# --- DESKTOP SECTION --- >

_install_desktop() {
  _print_title "DESKTOP OR WINDOW MANAGER"
  PS3="$PROMPT1"
  DESKTOP_LIST=("Gnome" "Plasma" "Xfce" "i3-gaps" "Bspwm" "Awesome" "Openbox" "Qtile" "None");
  _print_warning " * Select your option:\n"
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
  echo ""
  
  if [[ "${DESKTOP}" == "Gnome" ]]; then
    _group_package_install "gnome"
    _group_package_install "gnome-extra"
    _package_install "gnome-tweaks"

  elif [[ "${DESKTOP}" == "Plasma" ]]; then
    _package_install "plasma kde-applications packagekit-qt5"

  elif [[ "${DESKTOP}" == "Xfce" ]]; then
    _package_install "xfce4 xfce4-goodies xarchiver network-manager-applet"

  elif [[ "${DESKTOP}" == "i3-gaps" ]]; then
    _package_install "i3-gaps i3status i3blocks i3lock dmenu rofi arandr feh nitrogen picom lxappearance xfce4-terminal xarchiver network-manager-applet"

  elif [[ "${DESKTOP}" == "Bspwm" ]]; then
    _print_info " It's not working yet..."

  elif [[ "${DESKTOP}" == "Awesome" ]]; then
    _print_info " It's not working yet..."

  elif [[ "${DESKTOP}" == "Openbox" ]]; then
    _package_install "openbox obconf dmenu rofi arandr feh nitrogen picom lxappearance xfce4-terminal xarchiver network-manager-applet"

  elif [[ "${DESKTOP}" == "Qtile" ]]; then
    _package_install "qtile dmenu rofi arandr feh nitrogen picom lxappearance xfce4-terminal xarchiver network-manager-applet"

  elif [[ "${DESKTOP}" == "None" ]]; then
    _print_info " Nothing to do!"

  else
    _invalid_option
    exit 0
  fi
  localectl set-x11-keymap br
  _print_done
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
    _print_subtitle "Services"
    echo -ne "${BBLUE}  ->${BWHITE}Enabling:${RESET} ${WHITE}LightDM${RESET} ..."
    sudo systemctl enable lightdm &> /dev/null && echo -e " ${BYELLOW}[ OK ]${RESET}"

  elif [[ "${DMANAGER}" == "Lxdm" ]]; then
    _print_info "It's not working yet..."

  elif [[ "${DMANAGER}" == "Slim" ]]; then
    _print_info " It's not working yet..."

  elif [[ "${DMANAGER}" == "GDM" ]]; then
    _package_install "gdm"
    _print_subtitle "Services"
    echo -ne "${BBLUE}  ->${BWHITE}Enabling:${RESET} ${WHITE}GDM${RESET} ..."
    sudo systemctl enable gdm &> /dev/null && echo -e " ${BYELLOW}[ OK ]${RESET}"

  elif [[ "${DMANAGER}" == "SDDM" ]]; then
    _package_install "sddm"
    _print_subtitle "Services"
    echo -ne "${BBLUE}  ->${BWHITE}Enabling:${RESET} ${WHITE}SDDM${RESET} ..."
    sudo systemctl enable sddm &> /dev/null && echo -e " ${BYELLOW}[ OK ]${RESET}"

  elif [[ "${DMANAGER}" == "Xinit" ]]; then
    _print_info " It's not working yet..."

  elif [[ "${DMANAGER}" == "None" ]]; then
    echo -e " ${BBLUE}Nothing to do!${RESET}"

  else
    _invalid_option
    exit 0
  fi
  _print_done
  _pause_function
}

_finish_desktop() {
  _print_title "THIRD STEP FINISHED"
  _print_subtitle "[ OPTIONAL ] Proceed to the last step for install apps. Use ${BYELLOW}-u${RESET} ${BWHITE}option.${RESET}"
  _print_done
  _pause_function
  exit 0
}

# --- END DESKTOP SECTION --- >

# --- USER SECTION --- >

_install_apps() {
  _print_title "CUSTOM APPS"
  PS3="$PROMPT1"
  _read_input_text "Install custom apps? [y/N]: "
  echo -e "\n"
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
  _print_done
  _pause_function
}

_install_pamac() {
  _print_title "PAMAC"
  PS3="$PROMPT1"
  _read_input_text "Install pamac? [y/N]: "
  echo -e "\n"
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
  _print_done
  _pause_function
}

# --- END USER SECTION --- >

### OTHER FUNCTIONS

_print_line() {
  echo -e "${BGREEN}`seq -s '═' $(tput cols) | tr -d [:digit:]`${RESET}"
}

_print_dline() {
  printf "${BGREEN}%$(tput cols)s\n${RESET}"|tr ' ' '='
}

_print_title() {
  clear
  T_COLS=$(tput cols)
  T_APP_TITLE=$(echo ${#APP_TITLE})
  T_TITLE=$(echo ${#1})
  tput cuf $(( T_COLS - T_APP_TITLE - 1 )); echo -e "${BBLUE}${APP_TITLE}${RESET}"
  echo -ne "${BBLUE}═╡${RESET}${BWHITE} $1 ${RESET}${BBLUE}╞${RESET}"; echo -e "${BBLUE}`seq -s '═' $(( T_COLS - T_TITLE - 4 )) | tr -d [:digit:]`${RESET}\n"
}

_print_title_alert() {
  clear
  T_COLS=$(tput cols)
  T_APP_TITLE=$(echo ${#APP_TITLE})
  T_TITLE=$(echo ${#1})
  tput cuf $(( T_COLS - T_APP_TITLE - 1 )); echo -e "${BBLUE}${APP_TITLE}${RESET}"
  echo -ne "${BRED}═╡${RESET}${BWHITE} $1 ${RESET}${BRED}╞${RESET}"; echo -e "${BRED}`seq -s '═' $(( T_COLS - T_TITLE - 4 )) | tr -d [:digit:]`${RESET}\n"
}

_print_subtitle() {
  echo -e "${BGREEN}==> ${BWHITE}$1${RESET}"
}

_print_entry() {
  printf "%s" "${BGREEN}==> ${BWHITE}$1:${RESET} "
}

_print_info() {
  T_COLS=$(tput cols)
  echo -e "${BBLUE}$1${RESET}" | fold -sw $(( T_COLS - 1 ))
}

_print_installing() {
  T_COLS=$(tput cols)
  echo -ne "${BBLUE}  ->${RESET} ${BWHITE}Installing:${RESET} "
  echo -ne "${WHITE}$1${RESET}" | fold -sw $(( T_COLS - 1 ))
}

_print_running() {
  T_COLS=$(tput cols)
  echo -ne "${BBLUE}  ->${RESET} ${BWHITE}Running:${RESET} "
  echo -ne "${WHITE}$1${RESET}" | fold -sw $(( T_COLS - 1 ))
}

_print_enabling() {
  T_COLS=$(tput cols)
  echo -ne "${BBLUE}  ->${RESET} ${BWHITE}Enabling:${RESET} "
  echo -ne "${WHITE}$1${RESET}" | fold -sw $(( T_COLS - 1 ))
}

_print_warning() {
  T_COLS=$(tput cols)
  echo -e "${BYELLOW}==> WARNING: ${BWHITE}$1${RESET}" | fold -sw $(( T_COLS - 1 ))
}

_print_danger() {
  T_COLS=$(tput cols)
  echo -e "${BRED}$1${RESET}" | fold -sw $(( T_COLS - 1 ))
}

#_print_done() {
#  T_COLS=$(tput cols)
#  T_LINES=$(tput lines)
#  TEXT_COLS=16
#  CENTER_COLS=$(( (T_COLS - TEXT_COLS)/2 ))
#  tput cup $(( T_LINES - 3 ))
#  echo -ne "`seq -s ' ' ${CENTER_COLS} | tr -d [:digit:]`"; echo -e "${BGREEN}[=-   ${BWHITE}COMPLETE   ${BGREEN}-=]${RESET}" | fold -sw $(( T_COLS - 1 ))
#}

_print_done() {
  echo ""
  echo -e "${BGREEN}  →${BPURPLE} COMPLETE${RESET}"
}

_print_bye() {
  echo ""
  echo -e "${BGREEN}  →${BPURPLE} BYE!${RESET}"
}

#_pause_function() {
#  T_COLS=$(tput cols)
#  T_LINES=$(tput lines)
#  tput cup $(( T_LINES - 2 )) 0
#  echo -e "${BGREEN}`seq -s '═' $(( T_COLS + 1 )) | tr -d [:digit:]`${RESET}"
#  read -e -sn 1 -p " ${BWHITE}Press any key to continue...${RESET}"
#}

_pause_function() {
  echo ""
  read -e -sn 1 -p "${BGREEN}  →${BWHITE} Press any key to continue...${RESET}"
}

_contains_element() {
    for e in "${@:2}"; do [[ "$e" == "$1" ]] && break; done;
}

_invalid_option() {
    _print_warning "Invalid option. Try again..."
}

_read_input_text() {
  printf "%s" "${BBLUE}  -> ${BWHITE}$1${RESET}"
  read -r OPTION
}

_umount_partitions() {
  _print_info " Umounting partitions..."
  umount -R ${ROOT_MOUNTPOINT}
}

_is_package_installed() {
  for PKG in $1; do
    pacman -Q "$PKG" &> /dev/null && return 0;
  done
  return 1
}

_package_install() {
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
      _print_installing "${PKG}"
      if _package_was_installed "${PKG}"; then
        echo -e " ${BWHITE}[ ${BGREEN}OK${BWHITE} ]${RESET}"
      else
        echo -e " ${BWHITE}[ ${BRED}ERROR${BWHITE} ]${RESET}"
      fi
    else
      _print_installing "${PKG}"
        echo -e " ${BWHITE}[ ${BLUE}EXISTS${BWHITE} ]${RESET}"
    fi
  done
}

_group_package_install() {
  # install a package group
  _package_install "$(pacman -Sqg ${1})"
}

_pacstrap_install() {
  _pacstrap_was_installed() {
    for PKG in $1; do
      pacstrap "${ROOT_MOUNTPOINT}" "${PKG}" &> /dev/null && return 0;
    done
    return 1
  }
  for PKG in $1; do
    _print_installing "${PKG}"
    if _pacstrap_was_installed "${PKG}"; then
      echo -e " ${BWHITE}[ ${BGREEN}OK${BWHITE} ]${RESET}"
    else
      echo -e " ${BWHITE}[ ${BRED}OK${BWHITE} ]${RESET}"
    fi
  done
}

_initial_screen() {
  T_COLS=$(tput cols)
  T_LINES=$(tput lines)
  LOGO_COLS=77
  LOGO_LINES=9
  CENTER_COLS=$(( (T_COLS - LOGO_COLS)/2 ))
  CENTER_LINES=$(( (T_LINES - LOGO_LINES)/2 ))
  tput cup ${CENTER_LINES} 0
  echo -ne "${BGREEN}"
  echo -ne "`seq -s ' ' ${CENTER_COLS} | tr -d [:digit:]`"; echo -e " █████╗ ██████╗  ██████╗██╗  ██╗    ███████╗███████╗████████╗██╗   ██╗██████╗"
  echo -ne "`seq -s ' ' ${CENTER_COLS} | tr -d [:digit:]`"; echo -e "██╔══██╗██╔══██╗██╔════╝██║  ██║    ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗"
  echo -ne "`seq -s ' ' ${CENTER_COLS} | tr -d [:digit:]`"; echo -e "███████║██████╔╝██║     ███████║    ███████╗█████╗     ██║   ██║   ██║██████╔╝"
  echo -ne "`seq -s ' ' ${CENTER_COLS} | tr -d [:digit:]`"; echo -e "██╔══██║██╔══██╗██║     ██╔══██║    ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝"
  echo -ne "`seq -s ' ' ${CENTER_COLS} | tr -d [:digit:]`"; echo -e "██║  ██║██║  ██║╚██████╗██║  ██║    ███████║███████╗   ██║   ╚██████╔╝██║"
  echo -ne "`seq -s ' ' ${CENTER_COLS} | tr -d [:digit:]`"; echo -e "╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝    ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝"
  echo -ne "`seq -s ' ' ${CENTER_COLS} | tr -d [:digit:]`"; echo -e "                           ╔════════════════════╗"
  echo -ne "`seq -s ' ' ${CENTER_COLS} | tr -d [:digit:]`"; echo -e "    ═══════════════════════╣ By Stenio Silveira ╠═══════════════════════"
  echo -ne "`seq -s ' ' ${CENTER_COLS} | tr -d [:digit:]`"; echo -e "                           ╚════════════════════╝${RESET}"
}

clear
timedatectl set-ntp true
_initial_screen

while [[ "$1" ]]; do
  T_COLS=$(tput cols)
  T_LINES=$(tput lines)
  CENTER_COLS=$(( (T_COLS - 26)/2 ))
  tput cup $(( (T_LINES - LOGO_LINES)/2 + LOGO_LINES + 1 )) $CENTER_COLS
  read -e -sn 1 -p "${BWHITE}Press any key to start!${RESET}"
  case "$1" in
    --install|-i) _setup_install;;
    --config|-c) _setup_config;;
    --desktop|-d) _setup_desktop;;
    --user|-u) _setup_user;;
  esac
  shift
  _print_bye && exit 0
done