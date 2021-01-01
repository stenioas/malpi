#!/bin/usr/env sh

LUKS_VOLUMES=$(lsblk | awk '{print $6}' | grep 'crypt')

if [[ ! "$LUKS_VOLUMES" = "" ]]; then
  LUKS_OPEN=($(dmsetup ls --target crypt | awk '{print $1}'))
  for ITEM in ${LUKS_OPEN[@]}; do
    cryptsetup close /dev/mapper/${ITEM}
  done
fi