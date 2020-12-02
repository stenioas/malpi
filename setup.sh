#!/bin/sh
#
# arch-setup: Install and Config Archlinux and AwesomeWM
# 
# ----------------------------------------------------------------------#
#
# This script is for UEFI only.
# This script will only consider two partitions, ESP and root.
# This script will format the root partition in btrfs format.
# It will create three subvolumes:
#   @ for /
#   @home for /home
#   @ .snapshots for /.snapshots.
# The ESP partition can be formatted in FAT32 if the user wants to.
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

  Options:

    --install | -i         First step, only root user. THIS STEP MUST BE RUN IN LIVE MODE!
    --config  | -c         Second step, only root user.
    --user    | -u         Third step, only normal user.
    --desktop | -d         Fourth step, only normal user.

* Stenio Silveira ARCH-SETUP 0.1

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
      prompt1="Option: "

# ----------------------------------------------------------------------#

### BASE FUNCTIONS

# --- INSTALL SECTION --- >

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
  reflector -c Brazil --sort rate --save /etc/pacman.d/mirrorlist
  nano /etc/pacman.d/mirrorlist
  pacman -Syy
  _print_title "RANKING MIRRORS..."
  _print_done " DONE!"
  _pause_function
}

_select_disk() {
  _print_title "DISK PARTITIONING..."
  PS3="$prompt1"
  devices_list=($(lsblk -d | awk '{print "/dev/" $1}' | grep 'sd\|hd\|vd\|nvme\|mmcblk'))
  echo -e " Available disks:\n"
  lsblk -lnp -I 2,3,8,9,22,34,56,57,58,65,66,67,68,69,70,71,72,91,128,129,130,131,132,133,134,135,259 | awk '{print $1,$4,$6,$7}' | column -t
  echo ""
  echo -e " Select disk:\n"
  select device in "${devices_list[@]}"; do
    if _contains_element "${device}" "${devices_list[@]}"; then
      break
    else
      _invalid_option
    fi
  done
  INSTALL_DISK=${device}
  cfdisk ${INSTALL_DISK}
  echo "Selected disk: ${INSTALL_DISK}"
  _print_title "DISK PARTITIONING..."
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
    echo "No partition found."
    exit 0
  fi

  _format_root_partition() {
    _print_title "FORMATTING ROOT..."
    PS3="$prompt1"
    echo -e " Select partition to create subvolumes:"
    select partition in "${partitions_list[@]}"; do
      if _contains_element "${partition}" "${partitions_list[@]}"; then
        partition_number=$((REPLY -1))
        ROOT_PARTITION="$partition"
        mkfs.btrfs -f -L Archlinux ${ROOT_PARTITION}
        mount ${ROOT_PARTITION} ${ROOT_MOUNTPOINT}
        btrfs su cr ${ROOT_MOUNTPOINT}/@
        btrfs su cr ${ROOT_MOUNTPOINT}/@home
        btrfs su cr ${ROOT_MOUNTPOINT}/@.snapshots
        umount ${ROOT_MOUNTPOINT}
        mount -o noatime,compress=lzo,space_cache,commit=120,subvol=@ ${ROOT_PARTITION} ${ROOT_MOUNTPOINT}
        mkdir -p ${ROOT_MOUNTPOINT}/{home,.snapshots}
        mount -o noatime,compress=lzo,space_cache,commit=120,subvol=@home ${ROOT_PARTITION} ${ROOT_MOUNTPOINT}/home
        mount -o noatime,compress=lzo,space_cache,commit=120,subvol=@.snapshots ${ROOT_PARTITION} ${ROOT_MOUNTPOINT}/.snapshots
        _check_mountpoint "${ROOT_PARTITION}" "${ROOT_MOUNTPOINT}"
        _print_done " DONE!"
        break;
      else
        _invalid_option
      fi
    done
    _pause_function
  }

  _format_efi_partiton() {
    _print_title "FORMATTING EFI PARTITION..."
    PS3="$prompt1"
    echo -e " Select EFI partition: "
    select partition in "${partitions_list[@]}"; do
      if _contains_element "${partition}" "${partitions_list[@]}"; then
        EFI_PARTITION="${partition}"
        _read_input_text " Format EFI partition? [y/N]: "
        echo
        if [[ $OPTION == y || $OPTION == Y ]]; then
          mkfs.fat -F32 ${EFI_PARTITION}
          echo "EFI partition formatted!"
        fi
        mkdir -p ${ROOT_MOUNTPOINT}${EFI_MOUNTPOINT}
        mount -t vfat ${EFI_PARTITION} ${ROOT_MOUNTPOINT}${EFI_MOUNTPOINT}
        _check_mountpoint "${EFI_PARTITION}" "${ROOT_MOUNTPOINT}${EFI_MOUNTPOINT}"
        _print_done " DONE!"
        break;
      else
        _invalid_option
      fi
    done
    _pause_function
  }

  _disable_partition() {
    unset partitions_list["${partition_number}"]
    partitions_list=("${partitions_list[@]}")
  }

  _check_mountpoint() {
    if mount | grep "$2"; then
      _print_info " The partition was successfully mounted!"
      _disable_partition "$1"
    else
      _print_warning " WARNING: The partition was not successfully mounted!"
    fi
  }
  _format_root_partition
  _format_efi_partiton
  _print_title "FORMATTING AND MOUNTING PARTITIONS..."
  _print_done " DONE!"
  _pause_function
}

_install_base() {
  _print_title "INSTALLING THE SYSTEM BASE..."
  sleep 1
  pacstrap ${ROOT_MOUNTPOINT} \
    base base-devel \
    linux-lts \
    linux-lts-headers \
    linux-firmware \
    nano \
    intel-ucode \
    btrfs-progs \
    networkmanager    
  arch-chroot ${ROOT_MOUNTPOINT} systemctl enable NetworkManager
  _print_done " DONE!"
  _pause_function
}

_fstab_generate() {
  _print_title "GENERATING FSTAB..."
  genfstab -U ${ROOT_MOUNTPOINT} >> ${ROOT_MOUNTPOINT}/etc/fstab
  _print_done " DONE!"
  _pause_function
}

_set_locale() {
  _print_title "SETTING TIME ZONE..."
  arch-chroot ${ROOT_MOUNTPOINT} timedatectl set-ntp true
  arch-chroot ${ROOT_MOUNTPOINT} ln -sf /usr/share/zoneinfo/${NEW_ZONE}/${NEW_SUBZONE} /etc/localtime
  arch-chroot ${ROOT_MOUNTPOINT} sed -i '/#NTP=/d' /etc/systemd/timesyncd.conf
  arch-chroot ${ROOT_MOUNTPOINT} sed -i 's/#Fallback//' /etc/systemd/timesyncd.conf
  arch-chroot ${ROOT_MOUNTPOINT} echo \"FallbackNTP=a.st1.ntp.br b.st1.ntp.br 0.br.pool.ntp.org\" >> /etc/systemd/timesyncd.conf
  arch-chroot ${ROOT_MOUNTPOINT} systemctl enable systemd-timesyncd.service
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
  printf "%s" "Hostname [ex: archlinux]: " 
  read -r NEW_HOSTNAME
  echo ${NEW_HOSTNAME} > ${ROOT_MOUNTPOINT}/etc/hostname
  echo -e "127.0.0.1 localhost.localdomain localhost\n::1 localhost.localdomain localhost\n127.0.1.1 ${NEW_HOSTNAME}.localdomain ${NEW_HOSTNAME}" > ${ROOT_MOUNTPOINT}/etc/hosts
  _print_done " DONE!"
  _pause_function  
}

_root_passwd() {
  _print_title "SETTING ROOT PASSWORD..."
  arch-chroot ${ROOT_MOUNTPOINT} passwd
  _print_done " DONE!"
  _pause_function
}

_grub_generate() {
  _print_title "INSTALLING AND GENERATE GRUB..."
  pacstrap ${ROOT_MOUNTPOINT} grub grub-btrfs efibootmgr os-prober
  arch-chroot ${ROOT_MOUNTPOINT} grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ArchLinux --recheck
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
  _print_title "CONGRATULATIONS! WELL DONE!"
  _print_warning " Copying files..."
  _print_done " DONE!"
  PS3="$prompt1"
  cp /etc/pacman.d/mirrorlist.backup ${ROOT_MOUNTPOINT}/etc/pacman.d/mirrorlist.backup
  cp -r /root/myarch/ ${ROOT_MOUNTPOINT}/root/myarch
  chmod +x ${ROOT_MOUNTPOINT}/root/myarch/setup.sh
  _read_input_text " Reboot system? [y/N]: "
  echo
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
  printf "%s" "Username: "
  read -r NEW_USER
  NEW_USER=$(echo "$NEW_USER" | tr '[:upper:]' '[:lower:]')
  useradd -m -g users -G wheel ${NEW_USER}
  echo "User ${NEW_USER} created."
  echo ""
  echo "Setting password..."
  passwd ${NEW_USER}
  _print_warning " Added privileges."
  sed -i '/%wheel ALL=(ALL) ALL/s/^# //' /etc/sudoers
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
      _print_info "\nMultilib repository added to the pacman.conf file"
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
  sleep 1
  pacman -S --needed \
    dosfstools \
    mtools \
    udisks2 \
    dialog \
    git \
    wget \
    reflector \
    bash-completion \
    xdg-utils \
    xdg-user-dirs
  _print_done " DONE!"
  _pause_function
}

_install_xorg() {
  _print_title "INSTALLING XORG..."
  pacman -S --needed \
    xorg xorg-apps xorg-xinit \
    xf86-input-synaptics \
    xf86-input-libinput \
    xterm
  _print_done " DONE!"
  _pause_function
}

_install_vga() {
  _print_title "INSTALLING VIDEO DRIVER..."
  PS3="$prompt1"
  VIDEO_CARD_LIST=("Intel" "Virtualbox");
  echo
  echo -e " Select video card:\n"
  select VIDEO_CARD in "${VIDEO_CARD_LIST[@]}"; do
    if _contains_element "${VIDEO_CARD}" "${VIDEO_CARD_LIST[@]}"; then
      break
    else
      _invalid_option
    fi
  done
  if [[ $VIDEO_CARD == "Virtualbox" ]]; then
    pacman -S --needed \
      xf86-video-vmware \
      virtualbox-guest-utils \
      virtualbox-guest-dkms \
      mesa mesa-libgl \
      libvdpau-va-gl
  elif [[ $VIDEO_CARD == "Intel" ]]; then
    pacman -S --needed \
      xf86-video-intel \
      mesa mesa-libgl \
      libvdpau-va-gl
  else
    _invalid_option
    exit 0
  fi
  _print_done " DONE!"
  _pause_function
}

_install_extra_pkgs() {
  _print_title "INSTALLING EXTRA PACKAGES..."
  pacman -S --needed \
    usbutils lsof dmidecode neofetch bashtop \
    avahi nss-mdns logrotate sysfsutils mlocate
  _print_info " Installing compression tools..."
  pacman -S --needed \
    zip unzip unrar p7zip lzop
  _print_info " Installing extra filesystem tools..."
  pacman -S --needed \
    ntfs-3g autofs fuse fuse2 fuse3 fuseiso mtpfs
  _print_info " Installing sound tools..."
  pacman -S --needed \
    alsa-utils pulseaudio
  _print_done " DONE!"
  _pause_function
}

_install_laptop_pkgs() {
  _print_title "INSTALLING LAPTOP PACKAGES..."
  PS3="$prompt1"
  _read_input_text " Install laptop packages? [y/N]: "
  echo
  if [[ $OPTION == y || $OPTION == Y ]]; then
    pacman -S --needed \
      wpa_supplicant \
      wireless_tools \
      bluez \
      bluez-utils \
      pulseaudio-bluetooth
    systemctl enable bluetooth
  fi
  _print_done " DONE!"
  _pause_function
}

_finish_config() {
  _print_title "FINISHING INSTALLATION..."
  _print_info " Copying files..."
  mv /root/myarch /home/${NEW_USER}/
  chown -R ${NEW_USER} /home/${NEW_USER}/myarch
  _print_done " DONE!"
  exit 0
}

# --- END CONFIG SECTION --- >

# --- DESKTOP SECTION --- >

_install_desktop() {
  _print_title "INSTALLING DESKTOP PACKAGES..."
  PS3="$prompt1"
  DESKTOP_LIST=("Gnome" "Plasma" "XFCE" "i3wm" "Bspwm" "Qtile" "Awesome");
  echo
  echo -e " Select your desktop or window manager:\n"
  select DESKTOP in "${DESKTOP_LIST[@]}"; do
    if _contains_element "${DESKTOP}" "${DESKTOP_LIST[@]}"; then
      break
    else
      _invalid_option
    fi
  done
  if [[ $DESKTOP == "Gnome" ]]; then
    _print_info " Developing"
  elif [[ $DESKTOP == "Plasma" ]]; then
    _print_info " Developing"
  elif [[ $DESKTOP == "Xfce4" ]]; then
    _print_info " Developing"
  elif [[ $DESKTOP == "i3wm" ]]; then
    _print_info " Developing"
  elif [[ $DESKTOP == "Bspwm" ]]; then
    _print_info " Developing"
  elif [[ $DESKTOP == "Qtile" ]]; then
    sudo pacman -S --needed \
      qtile \
      dmenu \
      rofi \
      arandr \
      feh \
      nitrogen \
      picom \
      lxappearance \
      termite \
      lightdm \
      lightdm-gtk-greeter \
      lightdm-gtk-greeter-settings
    sudo systemctl enable lightdm.service
  elif [[ $DESKTOP == "Awesome" ]]; then
    _print_info " Developing"
  else
    _invalid_option
    exit 0
  fi
  _print_done " DONE!"
  _pause_function
}

_finish_desktop() {
  _print_title "THIRD STEP FINISHED..."
  echo -e " 1. Proceed to the last step.\n 2. To install apps use the installer's ${BYellow}-u${Reset} option."
  _print_done " DONE!"
  exit 0
}

# --- END DESKTOP SECTION --- >

# --- USER SECTION --- >

_install_apps() {
  sudo pacman -S --needed \
    libreoffice-fresh \
    libreoffice-fresh-pt-br \
    firefox \
    firefox-i18n-pt-br \
    steam \
    gimp \
    inkscape \
    vlc \
    telegram-desktop \
    transmission-gtk \
    simplescreenrecorder \
    redshift \
    adapta-gtk-theme \
    arc-gtk-theme \
    papirus-icon-theme \
    capitaine-cursors \
    ttf-dejavu
  _print_done " DONE!"
  _pause_function
}

_install_pamac() {
  _print_title "INSTALLING PAMAC..."
  if ! _is_package_installed "pamac"; then
    [[ -d pamac ]] && rm -rf pamac
    git clone https://aur.archlinux.org/pamac-aur.git pamac
    cd pamac
    makepkg -csi --noconfirm
  else
    _print_info " Pamac is already installed!"
  fi
  _print_done " DONE!"
  _pause_function
}

# --- END USER SECTION --- >

### CORE FUNCTIONS

_setup_install(){
    [[ $(id -u) != 0 ]] && {
        _print_warning " Only for 'root'.\n"
        exit 1
    }
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
        _print_warning " Only for 'root'.\n"
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
        _print_warning " Only for 'normal user'.\n"
        exit 1
    }
    _install_desktop
    _finish_desktop
    exit 0
}

#_setup_user(){
#    [[ $(id -u) != 1000 ]] && {
#        _print_warning " Only for 'normal user'.\n"
#        exit 1
#    }
#    echo 'xrdb ~/.Xresources' >> /home/$USER/.xinitrc
#    echo 'awesome' >> /home/$USER/.xinitrc
#    mkdir /home/$USER/.config
#    cp -r /etc/xdg/awesome  /home/$USER/.config
#    sed -i 's/xterm/urxvt/g' /home/$USER/.config/awesome/rc.lua
#    svn export https://github.com/terroo/fonts/trunk/fonts
#    mkdir -p ~/.local/share/
#    mv fonts ~/.local/share/
#    fc-cache -fv
#    git clone --recursive https://github.com/lcpz/awesome-copycats.git
#    mv awesome-copycats/* ~/.config/awesome && rm -rf awesome-copycats
#    cd ~/.config/awesome/
#    cp rc.lua bkp.rc.lua
#    cp rc.lua.template rc.lua # Super + Ctrl + r
#    exit 0
#}

_setup_user(){
    [[ $(id -u) != 1000 ]] && {
        _print_warning " Only for 'normal user'.\n"
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

_print_dline() {
  printf "%$(tput cols)s\n"|tr ' ' '='
}

_print_title() {
  clear
  _print_dline
  echo -e "${BCyan}# $1${Reset}"
  _print_dline
}

_print_warning() { #{{{
  T_COLS=$(tput cols)
  echo -e "\n${BYellow}$1${Reset}" | fold -sw $(( T_COLS - 1 ))
}

_print_done() { #{{{
  T_COLS=$(tput cols)
  echo -e "\n${BPurple}$1${Reset}" | fold -sw $(( T_COLS - 1 ))
}

_print_info() { #{{{
  T_COLS=$(tput cols)
  echo -e "\n${BBlue} $1${Reset}" | fold -sw $(( T_COLS - 1 ))
}

_pause_function() { #{{{
  _print_line
  read -e -sn 1 -p " Press any key to continue..."
}

_contains_element() {
    for e in "${@:2}"; do [[ "$e" == "$1" ]] && break; done;
}

_invalid_option() {
    _print_line
    _print_warning " Invalid option. Try again..."
    _pause_function
}

_read_input_text() {
  printf "%s" "${BRed}$1${Reset}"
  read -s -n 1 -r OPTION
}

_umount_partitions() {
  _print_info " UNMOUNTING PARTITIONS..."
  umount -R ${ROOT_MOUNTPOINT}
}

_is_package_installed() {
  for PKG in $1; do
    pacman -Q "$PKG" &> /dev/null && return 0;
  done
  return 1
}

clear
cat <<EOF


┌────────────────────────────────ARCH SETUP 0.1───────────────────────────────────┐
│                                                                                 │
│   █████╗ ██████╗  ██████╗██╗  ██╗    ███████╗███████╗████████╗██╗   ██╗██████╗  │
│  ██╔══██╗██╔══██╗██╔════╝██║  ██║    ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗ │
│  ███████║██████╔╝██║     ███████║    ███████╗█████╗     ██║   ██║   ██║██████╔╝ │
│  ██╔══██║██╔══██╗██║     ██╔══██║    ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝  │
│  ██║  ██║██║  ██║╚██████╗██║  ██║    ███████║███████╗   ██║   ╚██████╔╝██║      │
│  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝    ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝      │
└─────────────────────────────────────────────────────────────────────────────────┘


EOF

while [[ "$1" ]]; do
  read -e -sn 1 -p "Press any key to start ARCH SETUP..."
  case "$1" in
    --install|-i) _setup_install;;
    --config|-c) _setup_config;;
    --desktop|-d) _setup_desktop;;
    --user|-u) _setup_user;;
  esac
  shift
  _print_info "\nByye!" && exit 0
done
