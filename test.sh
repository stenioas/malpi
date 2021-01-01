#!/bin/usr/env sh

_is_luks_volumes_open() {
  local LUKS_VOLUMES=$(lsblk --fs | awk '{print $2}' | grep crypto_LUKS)
  [[ ! "$LUKS_VOLUMES" = "" ]] && return 0 || return 1;
}
LUKS_OPEN=$(dmsetup -ls --target crypt | awk '{print $1}')
if ! _is_luks_volumes_open; then
  for ITEM in ${LUKS_OPEN[@]}; do
    cryptsetup close /dev/mapper/${ITEM}
  done
fi