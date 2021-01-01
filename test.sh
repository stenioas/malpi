#!/bin/usr/env sh

LUKS_OPEN=$(dmsetup -ls --target crypt | awk '{print $1}')
if [[ ! "$LUKS_OPEN" = "" ]]; then
  for ITEM in ${LUKS_OPEN[@]}; do
    cryptsetup close /dev/mapper/${ITEM}
  done
fi