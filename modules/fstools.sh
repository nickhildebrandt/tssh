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

lsblk()
{
    command lsblk --raw --noheadings "${@}"
}

mount()
{
    command mount --mkdir --verbose "${@}"
}

umount()
{
    command umount --all-targets --recursive --force --verbose "${@}" || true
}

parted()
{
    command parted --fix --script "${@}"
    sync
}

ls_part()
{
    declare -n partarray="${2}"
    mapfile -t partarray < <(lsblk "${1}" --paths --output NAME)
    export partarray
}

mkfs_efi()
{
    command mkfs.fat -F 32 -n EFI "${@}"
}
