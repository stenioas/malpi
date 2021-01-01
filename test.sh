#!/bin/usr/env sh

LUKS_OPEN=$(dmsetup ls --target crypt | awk '{print $1}')
LUKS_VOLUMES=$(lsblk | awk '{print $6}' | grep 'crypt')

_is_luks_volumes_open() {
  [[ ! "$LUKS_VOLUMES" = "" ]] && return 0 || return 1;
}

if ! _is_luks_volumes_open; then
  for ITEM in ${LUKS_OPEN[@]}; do
    cryptsetup close /dev/mapper/${ITEM}
  done
fi