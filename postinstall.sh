#!/usr/bin/env bash
# ----------------------------------------------------------------------------
# Script   : install.sh
# Descrição: Script de instalação do Archlinux
# Versão   : 0.0.5
# Autor    : Stenio Silveira <stenioas@gmail.com>
# Data     : 13/08/2022
# Licença  : GNU/GPL v3.0
# ============================================================================

# ============================================================================
# VARIÁVEIS GLOBAIS
# ----------------------------------------------------------------------------

# CORES
BOLD=$(tput bold 2>/dev/null || printf '')
RESET=$(tput sgr0 2>/dev/null || printf '')
# normal
BLACK=$(tput setaf 0 2>/dev/null || printf '')
RED=$(tput setaf 1 2>/dev/null || printf '')
GREEN=$(tput setaf 2 2>/dev/null || printf '')
YELLOW=$(tput setaf 3 2>/dev/null || printf '')
BLUE=$(tput setaf 4 2>/dev/null || printf '')
PURPLE=$(tput setaf 5 2>/dev/null || printf '')
CYAN=$(tput setaf 6 2>/dev/null || printf '')
WHITE=$(tput setaf 7 2>/dev/null || printf '')
# negrito
BBLACK=${BOLD}${BLACK}
BRED=${BOLD}${RED}
BGREEN=${BOLD}${GREEN}
BYELLOW=${BOLD}${YELLOW}
BBLUE=${BOLD}${BLUE}
BPURPLE=${BOLD}${PURPLE}
BCYAN=${BOLD}${CYAN}
BWHITE=${BOLD}${WHITE}

# título do script
TITLE="Archlinux - Script de Instalação"

# configurações
IS_XORG=0
IS_WAYLAND=0
EFI_MOUNTPOINT="/boot"
ROOT_MOUNTPOINT="/mnt"
CRYPT_NAME="cryptluks"

# prompt
PS3="${BOLD}${GREEN}> ${RESET}"

# ============================================================================
# FUNÇÕES COMUNS
# ----------------------------------------------------------------------------

# imprime o título do script
_title() {
  clear
  _dline
  echo -e "${CYAN}# ${BOLD}${WHITE}${TITLE}${RESET}"
  _dline
  printf '\n'
}

# imprime subtítulos
_subtitle() {
  echo -e "\n${BOLD}${GREEN}$@${RESET}"
  _line
}

# imprime mensagem da ação atual
_action() {
  echo -n "$1"
  tput sc
}

# imprime linha simples da largura do console
_line() {
  local t_cols=$(tput cols)
  echo -e "${CYAN}$(seq -s '-' $(( t_cols + 1 )) | tr -d "[:digit:]")${RESET}"
}

# imprime linha dupla da largura do console
_dline() {
  local t_cols=$(tput cols)
  echo -e "${CYAN}$(seq -s '=' $(( t_cols + 1 )) | tr -d "[:digit:]")${RESET}"
}

# imprime retorno de sucesso
_done() {
  tput rc
  tput cuf 1
  echo "Pronto"
}

# imprime retorno de erro
# aceita argumentos como mensagem
_error() {
  tput rc
  tput cuf 1
  if [[ "$#" -ne 0 ]]; then
    echo "${RED}${BOLD}Erro:${RESET} ${BOLD}$@${RESET}"
  else
    echo "${RED}${BOLD}Algo deu errado!${RESET}"
  fi
}

# imprime retorno de alerta
_warn() {
  tput rc
  tput cuf 1
  echo -e "${YELLOW}${BOLD}Aviso:${RESET} ${BOLD}$@${RESET}"
}

# imprime mensagem informativa
_info() {
  echo -e "${BLUE}${BOLD}Info:${RESET} ${BOLD}$@${RESET}"
}

# spinner de progresso de ação
# &> /dev/null & PID=$!; _progress $PID
_progress() {
  tput civis
  _spinny() {
    local spin="/-\|"
    tput cuf 1
    echo -ne "\b${YELLOW}${BOLD}${spin:i++%${#spin}:1}${RESET}"
  }
  while true; do
    if kill -0 "$PID" &> /dev/null; then
      tput rc
      tput cuf 1
      _spinny
      sleep 0.2
    else
      wait "$PID"
      retcode=$?
      if [ $retcode == 0 ] || [ $retcode == 255 ]; then
        _done
      else
        _error
      fi
      break
    fi
  done
  tput cnorm
}

_reboot() {
  read -p "Deseja reiniciar a máquina? [S/n]: " OPTION
  [[ ${OPTION,,} != "n" ]] && sudo reboot now
}

# pausa a ação e aguarda pressionar qualquer tecla
_pause() {
  read -e -sn 1 -p "Pressione qualquer tecla para continuar..."
}

# ============================================================================
# FUNÇÕES DE TESTE
# ----------------------------------------------------------------------------

# verifica se é o Archlinux
_check_archlinux() {
  _action "Verificando se é o Archlinux..."
  if [[ -e /etc/arch-release ]]; then
    _done
  else
    _error "O script deve ser executado no ${BOLD}${BLUE}Archlinux.${RESET}"
    _line
    echo -e "${BOLD}Script encerrado!${RESET}"
    exit 1
  fi
}

# verifica se está em modo UEFI
_check_uefimode() {
  _action "Verificando se está em modo UEFI..."
  if [[ -d "/sys/firmware/efi/" ]]; then
    _done
  else
    _error "O script deve ser executado em modo ${BOLD}${YELLOW}UEFI${RESET}."
    _line
    echo -e "${BOLD}Script encerrado!${RESET}"
    exit 1
  fi
}

# verifica conexão com a internet
_check_connection() {
  _connection_test() {
    ping -q -w 1 -c 1 "$(ip r | grep default | awk 'NR==1 {print $3}')" &> /dev/null && return 1 || return 0
  }
  _action "Verificando conexão com a internet..."
  if ! _connection_test; then
    _done
  else
    _error "Você está desconectado!"
    _line
    echo -e "${BOLD}Script encerrado!${RESET}"
    exit 1
  fi
}

# verirfica se é root
_check_root() {
  _action "Verificando se é root..."
  if [ "$(id -u)" == "0" ]; then
    _doce
  else
    _error "O script deve ser executado como root..."
    _line
    echo -e "${BOLD}Script encerrado!${RESET}"
    exit 1
  fi
}

# Verifica se o pacman está bloqueado
_check_pacman_blocked() {
  _action "Verificando bloqueio do pacman..."
  if [ ! -f /var/lib/pacman/db.lck ]; then
    _done
  else
    _warn "O Pacman está bloqueado, remova /var/lib/pacman/db.lck se não estiver em uso."
    _line
    echo -e "${BOLD}Script encerrado!${RESET}"
    exit 1
  fi
}

# ============================================================================
# FUNÇÕES DA DISTRO
# ----------------------------------------------------------------------------

# atualiza a base de dados
_pacman_update() {
  _action "Atualizando base de dados..."
  pacman -Syy &> /dev/null & PID=$!; _progress $PID
}

# instala pacote com apt install
_pacman_install() {
  for PKG in $1; do
    echo -e "${BOLD}${MAGENTA}[${YELLOW}$PKG${MAGENTA}]${RESET}"
    pacman -S --needed --noconfirm $PKG
  done
}

# instala pacotes com pacstrap
_pacstrap_install() {
  for PKG in $1; do
    echo -e "${BOLD}${MAGENTA}[${YELLOW}$PKG${MAGENTA}]${RESET}"
    pacstrap $ROOT_MOUNTPOINT $PKG
  done
}

# verifica se o pacote já existe no sistema
_is_package_installed() {
  pacman -Q $1 &> /dev/null && return 0;
  return 1
}

# configura o ntp para true
_enable_timedatectl() {
  _action "Executando timedatectl set-ntp true..."
  timedatectl set-ntp true
}

# classifica os espelhos
_rank_mirrors() {
  _action "Configurando espelhos..."
  cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
  reflector --score 10 --save /etc/pacman.d/mirrorlist
}

# ============================================================================
# FUNÇÕES MICRO
# ----------------------------------------------------------------------------

_set_font() {
  _pacman_install "terminus-font"
  setfont ter-118b
}

_clean() {

}

# ============================================================================
# FUNÇÕES MACRO
# ----------------------------------------------------------------------------
_init() {
  _title
  _pause
  _title
  _check_archlinux
  _check_uefimode
  _check_root
  _check_pacman_blocked
  _check_connection
  _pacman_update
  _enable_timedatectl
  _set_font
  _pause
  _title
}

_install() {

}

_finish() {
  _clean
  _dline
  echo -e "\n${BOLD}Concluído!${RESET}\n"
  _reboot
}

# ============================================================================
# EXECUTANDO
# ----------------------------------------------------------------------------
_init
_install
_finish
