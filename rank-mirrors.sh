#!bin/bash

rank_mirrors() {
  print_title "RANKEANDO ESPELHOS DE REDE..."
  #pacman -Sy --needed pacman-contrib --noconfirm
  if [[ ! -f /etc/pacman.d/mirrorlist.backup ]]; then
    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
  fi
  #curl -so "/etc/pacman.d/mirrorlist.tmp" "https://www.archlinux.org/mirrorlist/?country=BR&use_mirror_status=on"
  #sed -i 's/^#Server/Server/g' "/etc/pacman.d/mirrorlist.tmp"
  #rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
  #rm /etc/pacman.d/mirrorlist.tmp
  reflector -c Brazil --sort rate --save /etc/pacman.d/mirrorlist
  chmod +r /etc/pacman.d/mirrorlist
  nano /etc/pacman.d/mirrorlist
  pacman -Syy
  print_title "RANKEANDO ESPELHOS..."
  print_warning " CONCLUÍDO!"
  pause_function
}
