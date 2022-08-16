#!/usr/bin/env bash
# ============================================================================
# Script   : install.sh
# Descrição: Script de instalação do Archlinux
# Versão   : 0.0.1
# Autor    : Stenio Silveira <stenioas@gmail.com>
# Data     : 13/08/2022
# Licença  : GNU/GPL v3.0
# ----------------------------------------------------------------------------

# ============================================================================
# DEPENDENCIES
# ----------------------------------------------------------------------------

[[ -e ./lib/functions ]] && source ./lib/functions || { echo "O arquivo 'functions' está faltando."; exit 1; }
[[ -e ./install.conf ]] && source ./install.conf || { echo "O arquivo 'install.conf' está faltando."; exit 1; }

# ============================================================================
# TESTS
# ----------------------------------------------------------------------------

_print_title "Arch Linux - Script de instalação"
_check_archlinux
_check_root
_check_uefimode
_check_connection
_check_pacman_blocked
_set_font
_print_line
read -e -sn 1 -p "${BGREEN}Precione qualquer tecla para iniciar!${RESET}"

# ============================================================================
# EXECUTION
# ----------------------------------------------------------------------------

_select_disk
_format_partitions
_install_base
_generate_fstab
_set_timezone
_set_locale
_set_network
_generate_mkinitcpio
_set_bootloader
_set_root_passwd
_install_finish
