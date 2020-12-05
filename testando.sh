_package_install() {
  _package_was_installed() {
    for PKG in $1; do
      if [[ $(id -u) == 0 ]]; then
        pacman -S --noconfirm --needed "${PKG}" 1> /dev/null && return 0;
      else
        sudo pacman -S --noconfirm --needed "${PKG}" 1> /dev/null && return 0;
      fi
    done
    return 1
  }
  #install packages using pacman
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

_package_install "neofetch nano vim testando"