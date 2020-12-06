#!/bin/sh
#
# arch-setup: Install and Config Archlinux
# 
# ----------------------------------------------------------------------#
#
# This script supports UEFI only.
# This script supports GRUB only.
# This script will only consider two partitions, ESP and root.
# This script will format the root partition in btrfs format.
# The ESP partition can be formatted if the user wants to.
# This script will create three subvolumes:
#   @ for /
#   @home for /home
#   @ .snapshots for /.snapshots.
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
      Bold=$(tput bold)
      Underline=$(tput sgr 0 1)
      Reset=$(tput sgr0)
      # Regular Colors
      Red=$(tput setaf 1)
      Green=$(tput setaf 2)
      Yellow=$(tput setaf 3)
      Blue=$(tput setaf 4)
      Purple=$(tput setaf 5)
      Cyan=$(tput setaf 6)
      White=$(tput setaf 7)
      # Bold
      BRed=${Bold}${Red}
      BGreen=${Bold}${Green}
      BYellow=${Bold}${Yellow}
      BBlue=${Bold}${Blue}
      BPurple=${Bold}${Purple}
      BCyan=${Bold}${Cyan}
      BWhite=${Bold}${White}

    # --- ESSENTIALS
      NEW_LANGUAGE="pt_BR"
      NEW_ZONE="America"
      NEW_SUBZONE="Fortaleza"
      NEW_USER="user"
      NEW_HOSTNAME="archlinux"
      TRIM=0

    # --- MOUNTPOINTS
      EFI_PARTITION="/dev/sda1"
      EFI_MOUNTPOINT="/boot/efi"
      ROOT_PARTITION="/dev/sda3"
      ROOT_MOUNTPOINT="/mnt"

    # --- PROMPT
      prompt1=" ${Yellow}Option:${Reset} "

# ----------------------------------------------------------------------#

### BASE FUNCTIONS

# --- INSTALL SECTION --- >

_initial_info() {
  _print_title "READ ME - IMPORTANT !!!"
  _print_warning " 1. This script supports UEFI only.\n 2. This script will install GRUB as default bootloader.\n 3. This script will only consider two partitions, ESP and root.\n 4. This script will format the root partition in btrfs format.\n 5. The ESP partition can be formatted if the user wants to.\n 6. This script does not support swap.\n 7. This script will create three subvolumes:\n   @ for /\n   @home for /home\n   @ .snapshots for /.snapshots.\n 8. THIS SCRIPT IS NOT YET COMPLETE !!!"
  _print_done " DONE!"
  _pause_function
}

_check_connection() {
  _print_title "TESTING CONNECTION..."
    _connection_test() {
      ping -q -w 1 -c 1 "$(ip r | grep default | awk 'NR==1 {print $3}')" &> /dev/null && return 0 || return 1
    }
    if _connection_test; then
      _print_warning " * SUCCESS! Connected!"
    else
      _print_danger " * ERROR! Connection not found!"
      _print_done " EXITING..."
      exit 1
    fi
  _print_done " DONE!"
  _pause_function
}

_time_sync() {
  _print_title "TIME SYNC..."
  timedatectl set-ntp true
  _print_done " DONE!"
  _pause_function
}

_rank_mirrors() {
  _print_title "RANKING MIRRORS..."
  if [[ ! -f /etc/pacman.d/mirrorlist.backup ]]; then
    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
  fi
  reflector -c Brazil --sort score --save /etc/pacman.d/mirrorlist
  nano /etc/pacman.d/mirrorlist
  _print_title "RANKING MIRRORS..."
  pacman -Syy
  _print_done " DONE!"
  _pause_function
}

_select_disk() {
  _print_title "DISK PARTITIONING..."
  PS3="$prompt1"
  devices_list=($(lsblk -d | awk '{print "/dev/" $1}' | grep 'sd\|hd\|vd\|nvme\|mmcblk'))
  _print_info " Disks and partitions:\n"
  lsblk -lnp -I 2,3,8,9,22,34,56,57,58,65,66,67,68,69,70,71,72,91,128,129,130,131,132,133,134,135,259 | awk '{print $1,$4,$6,$7}' | column -t
  _print_warning " * Select disk:\n"
  select device in "${devices_list[@]}"; do
    if _contains_element "${device}" "${devices_list[@]}"; then
      break
    else
      _invalid_option
    fi
  done
  INSTALL_DISK=${device}
  cfdisk ${INSTALL_DISK}
  _print_title "DISK PARTITIONING..."
  _print_info " Selected: ${Purple}[ ${INSTALL_DISK} ]${Reset}"
  _print_done " DONE!"
  _pause_function
}

_format_partitions() {
  _print_title "FORMATTING AND MOUNTING PARTITIONS..."
  block_list=($(lsblk | grep 'part\|lvm' | awk '{print substr($1,3)}'))

  partitions_list=()
  for OPT in "${block_list[@]}"; do
    partitions_list+=("/dev/${OPT}")
  done

  if [[ ${#block_list[@]} -eq 0 ]]; then
    _print_warning " No partition found."
    exit 0
  fi

  _format_root_partition() {
    _print_title "FORMATTING ROOT..."
    PS3="$prompt1"
    _print_warning " * Select partition to create btrfs subvolumes:\n * Remember, this script will create 3 subvolumes:\n   - @ for /,\n   - @home for /home,\n   - @.snapshots for snapshots.\n"
    select partition in "${partitions_list[@]}"; do
      if _contains_element "${partition}" "${partitions_list[@]}"; then
        partition_number=$((REPLY -1))
        ROOT_PARTITION="$partition"
        break;
      else
        _invalid_option
      fi
    done
    if mount | grep "${ROOT_PARTITION}"; then
      umount -R ${ROOT_MOUNTPOINT}
    fi
    mkfs.btrfs -f -L Archlinux ${ROOT_PARTITION}
    mount ${ROOT_PARTITION} ${ROOT_MOUNTPOINT}
    btrfs su cr ${ROOT_MOUNTPOINT}/@
    btrfs su cr ${ROOT_MOUNTPOINT}/@home
    btrfs su cr ${ROOT_MOUNTPOINT}/@.snapshots
    umount -R ${ROOT_MOUNTPOINT}
    mount -o noatime,compress=lzo,space_cache,commit=120,subvol=@ ${ROOT_PARTITION} ${ROOT_MOUNTPOINT}
    mkdir -p ${ROOT_MOUNTPOINT}/{home,.snapshots}
    mount -o noatime,compress=lzo,space_cache,commit=120,subvol=@home ${ROOT_PARTITION} ${ROOT_MOUNTPOINT}/home
    mount -o noatime,compress=lzo,space_cache,commit=120,subvol=@.snapshots ${ROOT_PARTITION} ${ROOT_MOUNTPOINT}/.snapshots
    _print_info " On ${Purple}[ ${ROOT_PARTITION} ]${Reset}"
    _print_info " Formatted!"
    _check_mountpoint "${ROOT_PARTITION}" "${ROOT_MOUNTPOINT}"
    _print_done " DONE!"
    _pause_function
  }

  _format_efi_partiton() {
    _print_title "FORMATTING EFI PARTITION..."
    #PS3="$prompt1"
    _print_warning " * Select EFI partition:\n"
    select partition in "${partitions_list[@]}"; do
      if _contains_element "${partition}" "${partitions_list[@]}"; then
        EFI_PARTITION="${partition}"
        break;
      else
        _invalid_option
      fi
    done
    echo ""
    _read_input_text " Format EFI partition? [y/N]: "
    if [[ $OPTION == y || $OPTION == Y ]]; then
      echo -e "\n"
      mkfs.fat -F32 ${EFI_PARTITION}
      _print_info " On ${Purple}[ ${EFI_PARTITION} ]${Reset}"
      _print_info " Formatted!"
    fi
    mkdir -p ${ROOT_MOUNTPOINT}${EFI_MOUNTPOINT}
    mount -t vfat ${EFI_PARTITION} ${ROOT_MOUNTPOINT}${EFI_MOUNTPOINT}
    _check_mountpoint "${EFI_PARTITION}" "${ROOT_MOUNTPOINT}${EFI_MOUNTPOINT}"
    _print_done " DONE!"
    _pause_function
  }

  _disable_partition() {
    unset partitions_list["${partition_number}"]
    partitions_list=("${partitions_list[@]}")
  }

  _check_mountpoint() {
    if mount | grep "$2"; then
      _print_info " The partition(s) was successfully mounted!"
      _disable_partition "$1"
    else
      _print_warning " * WARNING: The partition was not successfully mounted!"
    fi
  }
  _format_root_partition
  _format_efi_partiton
  _print_title "FORMATTING AND MOUNTING PARTITIONS..."
  _print_done " DONE!"
  _pause_function
}

_install_base() {
  _print_title "INSTALLING THE BASE..."
  pacstrap ${ROOT_MOUNTPOINT} \
    base base-devel \
    linux-lts \
    linux-lts-headers \
    linux-firmware \
    nano \
    intel-ucode \
    btrfs-progs \
    networkmanager    
  arch-chroot ${ROOT_MOUNTPOINT} systemctl enable NetworkManager > /dev/null 2>&1
  _print_info " Networkmanager service ${BYellow}ENABLED!${Reset}"
  _print_done " DONE!"
  _pause_function
}

_fstab_generate() {
  _print_title "GENERATING FSTAB..."
  genfstab -U ${ROOT_MOUNTPOINT} >> ${ROOT_MOUNTPOINT}/etc/fstab
  cat ${ROOT_MOUNTPOINT}/etc/fstab
  _print_done " DONE!"
  _pause_function
}

_set_locale() {
  _print_title "SETTING TIME ZONE..."
  arch-chroot ${ROOT_MOUNTPOINT} timedatectl set-ntp true
  arch-chroot ${ROOT_MOUNTPOINT} ln -sf /usr/share/zoneinfo/${NEW_ZONE}/${NEW_SUBZONE} /etc/localtime > /dev/null 2>&1
  arch-chroot ${ROOT_MOUNTPOINT} sed -i '/#NTP=/d' /etc/systemd/timesyncd.conf
  arch-chroot ${ROOT_MOUNTPOINT} sed -i 's/#Fallback//' /etc/systemd/timesyncd.conf
  arch-chroot ${ROOT_MOUNTPOINT} echo \"FallbackNTP=a.st1.ntp.br b.st1.ntp.br 0.br.pool.ntp.org\" >> /etc/systemd/timesyncd.conf 
  arch-chroot ${ROOT_MOUNTPOINT} systemctl enable systemd-timesyncd.service > /dev/null 2>&1
  arch-chroot ${ROOT_MOUNTPOINT} hwclock --systohc --utc
  sed -i 's/#\('pt_BR.UTF-8'\)/\1/' ${ROOT_MOUNTPOINT}/etc/locale.gen
  arch-chroot ${ROOT_MOUNTPOINT} locale-gen
  _print_done " DONE!"
  _pause_function
}

_set_language() {
  _print_title "SETTING LANGUAGE AND KEYMAP..."
  echo "LANG=pt_BR.UTF-8" > ${ROOT_MOUNTPOINT}/etc/locale.conf
  echo "KEYMAP=br-abnt2" >> ${ROOT_MOUNTPOINT}/etc/vconsole.conf
  _print_done " DONE!"
  _pause_function  
}

_set_hostname() {
  _print_title "SETTING HOSTNAME AND IP ADDRESS..."
  printf "%s" " ${BYellow}Hostname [ex: archlinux]:${Reset} " 
  read -r NEW_HOSTNAME
  echo ${NEW_HOSTNAME} > ${ROOT_MOUNTPOINT}/etc/hostname
  echo -e "127.0.0.1 localhost.localdomain localhost\n::1 localhost.localdomain localhost\n127.0.1.1 ${NEW_HOSTNAME}.localdomain ${NEW_HOSTNAME}" > ${ROOT_MOUNTPOINT}/etc/hosts
  _print_done " DONE!"
  _pause_function  
}

_root_passwd() {
  _print_title "SETTING ROOT PASSWORD..."
  _print_warning " * Setting root password...\n"
  arch-chroot ${ROOT_MOUNTPOINT} passwd
  _print_done " DONE!"
  _pause_function
}

_grub_generate() {
  _print_title "GRUB INSTALLATION..."
  printf "%s" " ${BYellow}Grub entry name [ex: Archlinux]:${Reset} " 
  read -r NEW_GRUB_NAME
  pacstrap ${ROOT_MOUNTPOINT} grub grub-btrfs efibootmgr os-prober
  arch-chroot ${ROOT_MOUNTPOINT} grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=${NEW_GRUB_NAME} --recheck
  arch-chroot ${ROOT_MOUNTPOINT} grub-mkconfig -o /boot/grub/grub.cfg
  _print_done " DONE!"
  _pause_function  
}

_mkinitcpio_generate() {
  _print_title "GENERATE MKINITCPIO..."
  arch-chroot ${ROOT_MOUNTPOINT} mkinitcpio -P
  _print_done " DONE!"
  _pause_function  
}

_finish_install() {
  _print_title "FIRST STEP FINISHED !!!"
  _print_warning " * Copying files to /root/myarch... "
  _print_done " DONE!"
  _print_bline
  PS3="$prompt1"
  cp /etc/pacman.d/mirrorlist.backup ${ROOT_MOUNTPOINT}/etc/pacman.d/mirrorlist.backup
  cp -r /root/myarch/ ${ROOT_MOUNTPOINT}/root/myarch
  chmod +x ${ROOT_MOUNTPOINT}/root/myarch/setup.sh
  _read_input_text " Reboot system? [y/N]: "
  echo ""
  if [[ $OPTION == y || $OPTION == Y ]]; then
    _umount_partitions
    reboot
  fi
  exit 0
}

# --- END INSTALL SECTION --- >

# --- CONFIG SECTION --- >

_create_new_user() {
  _print_title "CREATE NEW USER..."
  printf "%s" " ${BYellow}Username:${Reset} "
  read -r NEW_USER
  NEW_USER=$(echo "$NEW_USER" | tr '[:upper:]' '[:lower:]')
  if [[ "$(grep ${NEW_USER} /etc/passwd)" == "" ]]; then
    useradd -m -g users -G wheel ${NEW_USER}
    _print_info " User ${NEW_USER} created."
    _print_warning " * Setting password...\n"
    passwd ${NEW_USER}
    _print_info " Added privileges."
    sed -i '/%wheel ALL=(ALL) ALL/s/^# //' /etc/sudoers
  else
    _print_info " User ${NEW_USER} already exists!"
  fi
  _print_done " DONE!"
  _pause_function
}

_enable_multilib(){
  _print_title "ENABLING MULTILIB..."
  ARCHI=$(uname -m)
  if [[ $ARCHI == x86_64 ]]; then
    local _has_multilib=$(grep -n "\[multilib\]" /etc/pacman.conf | cut -f1 -d:)
    if [[ -z $_has_multilib ]]; then
      echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
      _print_info " Multilib repository added to pacman.conf."
    else
      sed -i "${_has_multilib}s/^#//" /etc/pacman.conf
      local _has_multilib=$(( _has_multilib + 1 ))
      sed -i "${_has_multilib}s/^#//" /etc/pacman.conf
    fi
  fi
  pacman -Syy
  _print_done " DONE!"
  _pause_function
}

_install_essential_pkgs() {
  _print_title "INSTALLING ESSENTIAL PACKAGES..."
  _package_install "dosfstools mtools udisks2 dialog git wget reflector bash-completion xdg-utils xdg-user-dirs"
  _print_done " DONE!"
  _pause_function
}

_install_xorg() {
  _print_title "INSTALLING XORG..."
  _package_install "xorg-server xorg-xinit xterm"
  _group_package_install "xorg-apps"
  _print_done " DONE!"
  _pause_function
}

_install_vga() {
  _print_title "INSTALLING VIDEO DRIVER..."
  PS3="$prompt1"
  VIDEO_CARD_LIST=("Intel" "AMD" "Nvidia" "Virtualbox");
  _print_warning " * Select video card:\n"
  select VIDEO_CARD in "${VIDEO_CARD_LIST[@]}"; do
    if _contains_element "${VIDEO_CARD}" "${VIDEO_CARD_LIST[@]}"; then
      break
    else
      _invalid_option
    fi
  done
  _print_title "INSTALLING VIDEO DRIVER..."
  VIDEO_DRIVER=$(echo "${VIDEO_CARD}" | tr '[:lower:]' '[:upper:]')
  echo -e " ${Purple}${VIDEO_DRIVER}${Reset}\n"

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
  _print_done " DONE!"
  _pause_function
}

_install_extra_pkgs() {
  _print_title "INSTALLING EXTRA PACKAGES..."
  _print_warning " * Installing utils..."
  _print_line
  _package_install "usbutils lsof dmidecode neofetch bashtop htop avahi nss-mdns logrotate sysfsutils mlocate"
  _print_warning " * Installing compression tools..."
  _print_line
  _package_install "zip unzip unrar p7zip lzop"
  _print_warning " * Installing extra filesystem tools..."
  _print_line
  _package_install "ntfs-3g autofs fuse fuse2 fuse3 fuseiso mtpfs"
  _print_warning " * Installing sound tools..."
  _print_line
  _package_install "alsa-utils pulseaudio"
  _print_done " DONE!"
  _pause_function
}

_install_laptop_pkgs() {
  _print_title "INSTALLING LAPTOP PACKAGES..."
  PS3="$prompt1"
  _read_input_text " Install laptop packages? [y/N]: "
  if [[ $OPTION == y || $OPTION == Y ]]; then
    echo -e "\n"
    _package_install "wpa_supplicant wireless_tools bluez bluez-utils pulseaudio-bluetooth xf86-input-synaptics"
    systemctl enable bluetooth > /dev/null 2>&1
    _print_info " Bluetooth service ${BYellow}ENABLED!${Reset}"
  else
    echo -e "\n"
    echo -e " ${BBlue}Nothing to do!${Reset}"
  fi
  _print_done " DONE!"
  _pause_function
}

_finish_config() {
  _print_title "SECOND STEP FINISHED !!!"
  _print_done " DONE!"
  _print_bline
  exit 0
}

# --- END CONFIG SECTION --- >

# --- DESKTOP SECTION --- >

_install_desktop() {
  _print_title "INSTALLING DESKTOP PACKAGES..."
  PS3="$prompt1"
  DESKTOP_LIST=("Gnome" "Plasma" "Xfce" "i3-gaps" "Bspwm" "Awesome" "Openbox" "Qtile" "None");
  _print_warning " * Select your option:\n"
  select DESKTOP in "${DESKTOP_LIST[@]}"; do
    if _contains_element "${DESKTOP}" "${DESKTOP_LIST[@]}"; then
      break
    else
      _invalid_option
    fi
  done
  _print_title "INSTALLING DESKTOP PACKAGES..."
  DESKTOP_CHOICE=$(echo "${DESKTOP}" | tr '[:lower:]' '[:upper:]')
  echo -e " ${Purple}${DESKTOP_CHOICE}${Reset}"
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
  _print_done " DONE!"
  _pause_function
}

_install_display_manager() {
  _print_title "INSTALLING DISPLAY MANAGER..."
  PS3="$prompt1"
  DMANAGER_LIST=("Lightdm" "Lxdm" "Slim" "GDM" "SDDM" "Xinit" "None");
  _print_warning " * Select your option:\n"
  select DMANAGER in "${DMANAGER_LIST[@]}"; do
    if _contains_element "${DMANAGER}" "${DMANAGER_LIST[@]}"; then
      break
    else
      _invalid_option
    fi
  done
  _print_title "INSTALLING DISPLAY MANAGER..."
  DMANAGER_CHOICE=$(echo "${DMANAGER}" | tr '[:lower:]' '[:upper:]')
  echo -e " ${Purple}${DMANAGER_CHOICE}${Reset}\n"

  if [[ "${DMANAGER}" == "Lightdm" ]]; then
    _package_install "lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings"
    sudo systemctl enable lightdm > /dev/null 2>&1
    _print_info " Lightdm service ${BYellow}ENABLED!${Reset}"

  elif [[ "${DMANAGER}" == "Lxdm" ]]; then
    _print_info "It's not working yet..."

  elif [[ "${DMANAGER}" == "Slim" ]]; then
    _print_info " It's not working yet..."

  elif [[ "${DMANAGER}" == "GDM" ]]; then
    _package_install "gdm"
    sudo systemctl enable gdm > /dev/null 2>&1
    _print_info " GDM service ${BYellow}ENABLED!${Reset}"

  elif [[ "${DMANAGER}" == "SDDM" ]]; then
    _package_install "sddm"
    sudo systemctl enable sddm > /dev/null 2>&1
    _print_info " SDDM service ${BYellow}ENABLED!${Reset}"

  elif [[ "${DMANAGER}" == "Xinit" ]]; then
    _print_info " It's not working yet..."

  elif [[ "${DMANAGER}" == "None" ]]; then
    echo -e " ${BBlue}Nothing to do!${Reset}"

  else
    _invalid_option
    exit 0
  fi
  _print_done " DONE!"
  _pause_function
}

_finish_desktop() {
  _print_title "THIRD STEP FINISHED !!!"
  _print_warning " * Copying files to home ${NEW_USER}..."
  if [[ -d /home/${NEW_USER}/myarch ]]; then 
    rm -rf /home/${NEW_USER}/myarch
  fi
  mv /root/myarch /home/${NEW_USER}/
  chown -R ${NEW_USER} /home/${NEW_USER}/myarch
  _print_warning " 1. Proceed to the last step for install apps. Use ${BCyan}-u${BYellow} option.${Reset}"
  _print_done " DONE!"
  _print_bline
  exit 0
}

# --- END DESKTOP SECTION --- >

# --- USER SECTION --- >

_install_apps() {
  _print_title "INSTALLING CUSTOM APPS..."
  PS3="$prompt1"
  _read_input_text " Install custom apps? [y/N]: "
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
    echo -e " ${BYellow}* Nothing to do!${Reset}"
  fi
  _print_done " DONE!"
  _pause_function
}

_install_pamac() {
  _print_title "INSTALLING PAMAC..."
  PS3="$prompt1"
  _read_input_text " Install pamac? [y/N]: "
  echo -e "\n"
  if [[ "${OPTION}" == "y" || "${OPTION}" == "Y" ]]; then
    if ! _is_package_installed "pamac"; then
      [[ -d pamac ]] && rm -rf pamac
      git clone https://aur.archlinux.org/pamac-aur.git pamac
      cd pamac
      makepkg -csi --noconfirm
    else
      echo -e " ${BCyan}Pamac${Reset} - ${BYellow}Is already installed!${Reset}"
    fi
  else
    echo -e " ${BYellow}* Nothing to do!${Reset}"
  fi
  _print_done " DONE!"
  _pause_function
}

# --- END USER SECTION --- >

### CORE FUNCTIONS

_setup_install(){
    [[ $(id -u) != 0 ]] && {
        _print_warning " * Only for 'root'.\n"
        exit 1
    }
    _initial_info
    _check_connection
    _time_sync
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
        _print_warning " * Only for 'root'.\n"
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
        _print_warning " * Only for 'root'.\n"
        exit 1
    }
    _install_desktop
    _install_display_manager
    _finish_desktop
    exit 0
}

_setup_user(){
    [[ $(id -u) != 1000 ]] && {
        _print_warning " * Only for 'normal user'.\n"
        exit 1
    }
    _install_apps
    _install_pamac
    exit 0
}

# ----------------------------------------------------------------------#

### OTHER FUNCTIONS

_print_line() {
  printf "%$(tput cols)s\n"|tr ' ' '-'
}

_print_bline() {
  printf "%$(tput cols)s\n"|tr ' ' '_'
}

_print_title() {
  clear
  _print_line
  echo -e "${BCyan}# $1${Reset}"
  _print_line
}

_print_done() {
  T_COLS=$(tput cols)
  echo -e "\n${BGreen}$1${Reset}" | fold -sw $(( T_COLS - 1 ))
}

_print_info() {
  T_COLS=$(tput cols)
  echo -e "\n${BBlue}$1${Reset}" | fold -sw $(( T_COLS - 1 ))
}

_print_warning() {
  T_COLS=$(tput cols)
  echo -e "\n${BYellow}$1${Reset}" | fold -sw $(( T_COLS - 1 ))
}

_print_danger()
  T_COLS=$(tput cols)
  echo -e "\n${BRed}$1${Reset}" | fold -sw $(( T_COLS - 1 ))
}

_pause_function() {
  _print_bline
  read -e -sn 1 -p " Press any key to continue..."
}

_contains_element() {
    for e in "${@:2}"; do [[ "$e" == "$1" ]] && break; done;
}

_invalid_option() {
    _print_line
    _print_warning " * Invalid option. Try again..."
    _pause_function
}

_read_input_text() {
  printf "%s" "${BRed}$1${Reset}"
  read -s -n 1 -r OPTION
}

_umount_partitions() {
  _print_warning " * UNMOUNTING PARTITIONS..."
  umount -R ${ROOT_MOUNTPOINT}
}

_is_package_installed() {
  for PKG in $1; do
    pacman -Q "$PKG" &> /dev/null && return 0;
  done
  return 1
}

_package_install() {
  #install packages using pacman
  _package_was_installed() {
    for PKG in $1; do
      if [[ $(id -u) == 0 ]]; then
        pacman -S --noconfirm --needed "${PKG}" 1> /dev/null 2>&1 && return 0;
      else
        sudo pacman -S --noconfirm --needed "${PKG}" 1> /dev/null 2>&1 && return 0;
      fi
    done
    return 1
  }
  for PKG in $1; do
    if ! _is_package_installed "${PKG}"; then
      echo -ne " ${BBlue}Installing${Reset} ${BCyan}[ ${PKG} ]${Reset} ..."
      if _package_was_installed "${PKG}"; then
        echo -e " ${BYellow}[ SUCCESS! ]"
      else
        echo -e " ${BRed}[ ERROR! ]"
      fi
    else
      echo -e " ${BBlue}Installing${Reset} ${BCyan}[ ${PKG} ]${Reset} ... ${Yellow}[ It's already installed. ]${Reset}"
    fi
  done
}

_group_package_install() {
  _package_install "$(pacman -Sqg ${1})"
}

clear
cat <<EOF

${Yellow}
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                                                                 │
│   █████╗ ██████╗  ██████╗██╗  ██╗    ███████╗███████╗████████╗██╗   ██╗██████╗  │
│  ██╔══██╗██╔══██╗██╔════╝██║  ██║    ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗ │
│  ███████║██████╔╝██║     ███████║    ███████╗█████╗     ██║   ██║   ██║██████╔╝ │
│  ██╔══██║██╔══██╗██║     ██╔══██║    ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝  │
│  ██║  ██║██║  ██║╚██████╗██║  ██║    ███████║███████╗   ██║   ╚██████╔╝██║      │
│  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝    ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝      │
└───────────────────────────── By Stenio Silveira ────────────────────────────────┘
${Reset}

EOF

while [[ "$1" ]]; do
  read -e -sn 1 -p " Press any key to start..."
  case "$1" in
    --install|-i) _setup_install;;
    --config|-c) _setup_config;;
    --desktop|-d) _setup_desktop;;
    --user|-u) _setup_user;;
  esac
  shift
  _print_info "\nByye!" && exit 0
done