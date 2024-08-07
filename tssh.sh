#!/bin/bash
#
# Copyright 2024 Nick Hildebrandt
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# SPDX-License-Identifier: GPL-3.0-or-later

set -o errexit
set -o nounset
set -o pipefail

TSSH_SH="$(realpath "${0}")"
TSSH_PATH="$(dirname "${TSSH_SH}")"

source "${TSSH_PATH}/modules/fstools.sh"

action_ok()
{
    printf "[\e[32m OK \e[0m] %s\n" "${*}"
}

action_fail()
{
    printf "[\e[31m FL \e[0m] %s\n" "${*}" 1>&2
    exit 1
}

update_apt()
{
    apt-get --assume-yes update
    action_ok "Updated apt package index"
}

pkgi()
{
    apt-get --assume-yes \
            --no-install-recommends \
            --install-suggests \
            install "${@}"
}

check_drives()
{
    for drive in "${@}"; do

        if [[ "$(lsblk --nodeps \
                       --output TYPE \
                       "${drive}" 2> /dev/null)" != "disk" ]]; then
            action_fail "'${drive}' is not a valid device"
        fi

        if [[ "$(blockdev --getsize64 "${drive}")" -lt 15000000000 ]]; then
            action_fail "'${drive}' needs to be bigger than 20GB"
        fi

    done
}

check_string()
{
    for str in "${@}"; do

        if ! [[ "${str}" =~ ^[a-zA-Z0-9]+$ &&
                "${#str}" -le 30 ]]; then
            action_fail "'${*}' is not valid"
        fi

    done
}

cp()
{
    command cp --verbose --recursive --update "${@}"
}

mkdir()
{
    command mkdir --verbose --parents "${@}"
}

rm()
{
    command rm --verbose --recursive --force "${@}"
}

install()
{
    command install --verbose "${@}"
}

ln()
{
    command ln --verbose --symbolic --force "${@}"
}

install_tssh()
{
    if [[ $# -gt 0 ]]; then
        action_fail "install-tssh takes no arguments"
    fi

    mkdir "/opt/tssh/modules"
    install "${TSSH_SH}" "/opt/tssh/tssh.sh"
    cp "${TSSH_PATH}/modules" "/opt/tssh"
    ln "/opt/tssh/tssh.sh" "/usr/bin/tssh"
    action_ok "Installing files"

    update_apt

    pkgi iproute2 \
         fdisk \
         dosfstools \
         btrfs-progs \
         squashfs-tools \
         debootstrap \
         openssh-client \
         grub-efi-amd64 \
         ovmf \
         qemu-system-x86 \
         qemu-utils \
         openssh-client

    action_ok "Installing dependencies"
}

remove_tssh()
{
    if [[ $# -gt 0 ]]; then
        action_fail "remove-tssh takes no arguments"
    fi

    rm "/opt/tssh"
    rm "/usr/bin/tssh"

    action_ok "TSSH removed - apt packages will still be installed"
}

setup_server()
{
    while getopts d:k:w:m:u:p: opt
    do
        case "${opt}" in
            d) DRIVES+=("${OPTARG}");;
            k) ROOT_PW="${OPTARG}";;
            w) WAN_LINK="${OPTARG}";;
            m) WAN_MODE="${OPTARG}";;
            u) WAN_USER="${OPTARG}";;
            p) WAN_PW="${OPTARG}";;
            *) action_fail "Run 'tssh help' for usage information";;
        esac
    done

    if [[ -z "${DRIVES+x}" ||
          -z "${ROOT_PW+x}" ||
          -z "${WAN_LINK+x}" ||
          -z "${WAN_MODE+x}" ]]; then
        action_fail "Missing options - run 'tssh help' for usage information"
    fi

    check_drives "${DRIVES[@]}"

    if ! [[ -d "/sys/class/net/${WAN_LINK}" ]]; then
        action_fail "WAN interface is not valid"
    fi

    if ! [[ "${WAN_MODE}" == "dhcp" ||
          "${WAN_MODE}" == "ppp" ]]; then
        action_fail "-m (WAN mode) must be dhcp or ppp"
    fi

    TARGET_HOSTNAME=server

    action_ok "Validated variables"
}

setup_client()
{
    while getopts d:h:f:l:k: opt
    do
        case "${opt}" in
            d) DRIVES+=("${OPTARG}");;
            h) TARGET_HOSTNAME="${OPTARG}";;
            f) FIRST_NAME="${OPTARG}";;
            l) LAST_NAME="${OPTARG}";;
            k) ROOT_PW="${OPTARG}";;
            *) action_fail "Run 'tssh help' for usage information";;
        esac
    done

    if [[ -z "${DRIVES+x}" ||
          -z "${TARGET_HOSTNAME+x}" ||
          -z "${FIRST_NAME+x}" ||
          -z "${LAST_NAME+x}" ||
          -z "${ROOT_PW+x}" ]]; then
        action_fail "Missing options - run 'tssh help' for usage information"
    fi

    check_drives "${DRIVES[@]}"
    check_string "${TARGET_HOSTNAME}"
    check_string "${FIRST_NAME}"
    check_string "${LAST_NAME}"

    action_ok "Validated variables"
}

setup_installer()
{
    while getopts d:k:t: opt
    do
        case "${opt}" in
            d) DRIVE="${OPTARG}";;
            k) ROOT_PW="${OPTARG}";;
            *) action_fail "Run 'tssh help' for usage information";;
        esac
    done

    if [[ -z "${DRIVES+x}" ||
          -z "${ROOT_PW+x}" ]]; then
        action_fail "Missing options - run 'tssh help' for usage information"
    fi

    check_drives "${DRIVES[@]}"
    TARGET_HOSTNAME=live

    action_ok "Validated variables"
}

deploy()
{
    while getopts c opt
    do
        case "${opt}" in
            c) CLEAN=true;;
            *) action_fail "Run 'tssh help' for usage information";;
        esac
    done

    action_ok "Validated variables"
}

dev()
{
    if [[ $# -gt 0 ]]; then
        action_fail "dev takes no arguments"
    fi

    if ! dpkg --status shellcheck > /dev/null; then
        action_fail "'shellcheck' is not available"
    fi

    action_ok "'shellcheck' found"

    shellcheck --check-sourced \
               --external-sources \
               --color \
               --shell bash \
               --enable=all \
               "${TSSH_SH}"
}

help()
{
    if [[ $# -gt 0 ]]; then
        action_fail "help takes no arguments"
    fi

    cat << EOF
Usage: tssh.sh [COMMAND] [OPTIONS]

Commands:

  install             Install TSSH and its dependencies.

  remove              Remove TSSH files, but leave dependencies installed.

  setup-server        Setup the server configuration.
                      Options:
                        -d <drive>    Specify drive(s).
                        -k <password> Set root password (Masterkey).
                        -w <link>     Set WAN link.
                        -m <mode>     Set WAN mode (dhcp | ppp).
                        -u <user>     Set WAN user (only when using ppp).
                        -p <password> Set WAN password (only when using ppp).

  setup-client        Setup the client configuration.
                      Options:
                        -d <drive>    Specify drive(s).
                        -h <hostname> client hostname.
                        -f <fistname> client owner name.
                        -l <lastname> client owner name.
                        -k <password> Set root password (Masterkey).

  setup-installer     Setup the installer configuration.
                      Options:
                        -d <drive>    Specify removeable drive(s) or file(s).
                        -k <password> Set live root password.

  deploy              Test the configuration with kvm.
                      Options:
                        -c <clean>    Force Generate live and server.

  dev                 Run development checks. Requires 'shellcheck'.

  help                Display this help message.
EOF

    exit 0
}

if [[ "${UID}" -eq 0 ]]; then
    action_ok "Root check"
else
    action_fail "Root check"
fi

if [[ $# -lt 1 ]]; then
    action_fail "No argument"
fi

case "${1}" in
    "install") shift; install_tssh "${@}";;
    "remove") shift; remove_tssh "${@}";;
    "setup-server") shift; setup_server "${@}";;
    "setup-client") shift; setup_client "${@}";;
    "setup-installer") shift; setup_installer "${@}";;
    "deploy") shift; deploy "${@}";;
    "dev") shift; dev "${@}";;
    "help") shift; help "${@}";;
    *) action_fail "Run 'tssh help' for usage information";;
esac
