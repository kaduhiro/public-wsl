#!/bin/sh
set -eu

init () {
  local dist=unknown

  if [ -e /etc/debian_version ] || [ -e /etc/debian_release ]; then
    if [ -e /etc/lsb-release ]; then
      # Ubuntu
      dist=ubuntu
    else
      # Debian
      dist=debian
    fi
  elif [ -e /etc/fedora-release ]; then
    # Fedra
    dist=fedora
  elif [ -e /etc/redhat-release ]; then
    if [ -e /etc/oracle-release ]; then
      # Oracle Linux
      dist=oracle
    else
      # Red Hat Enterprise Linux
      dist=ehel
    fi
  elif [ -e /etc/arch-release ]; then
    # Arch Linux
    dist=arch
  elif [ -e /etc/turbolinux-release ]; then
    # Turbolinux
    dist=turbol
  elif [ -e /etc/SuSE-release ]; then
    # SuSE Linux
    dist=suse
  elif [ -e /etc/mandriva-release ]; then
    # Mandriva Linux
    dist=mandriva
  elif [ -e /etc/vine-release ]; then
    # Vine Linux
    dist=vine
  elif [ -e /etc/gentoo-release ]; then
    # Gentoo Linux
    dist=gentoo
  fi

  local bootstrap="$(dirname "$(dirname "$0")")/bootstraps/$dist.sh"
  if [ -f "$bootstrap" ]; then
    /bin/sh "$bootstrap"
  fi
}

init
