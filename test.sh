#!/bin/sh

_set_localization() {
	ITEMS=$(find /usr/share/kbd/keymaps/ -type f -printf "%f" | sort -V)
  OPTIONS=("TESTE" "TESTE2" "TESTE3")
	#KEYMAP_LIST=()
	#for ITEM in ${ITEMS}; do
	#	KEYMAP_LIST+=("${ITEM%%.*}")
	#done
  echo "${ITEMS}"
  echo ${ITEMS}
  echo "${OPTIONS}"
  echo ${OPTIONS}
}

_set_localization