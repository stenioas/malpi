#!/bin/sh

_set_localization() {
	ITEMS=$(find /usr/share/kbd/keymaps/ -type f -printf "%f\n" | sort -V)
	KEYMAP_LIST=()
	for ITEM in ${ITEMS}; do
		KEYMAP_LIST+=("${ITEM%%.*}")
	done
  select KEYMAP_CHOICE in "${KEYMAP_LIST[@]}"; do
    if _contains_element "${KEYMAP_CHOICE}" "${KEYMAP_LIST[@]}"; then
      KEYMAP_CHOICE="${KEYMAP_CHOICE}"
      break;
    else
      echo "Opcao errada"
    fi
  done  
}

_set_localization