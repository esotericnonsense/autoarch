#!/usr/bin/env bash
# autoarch/install/stage1.sh
# This script runs as the first stage in order to create the chroot.
# See 'config.sh' for configuration parameters.
set -euxo pipefail

script_path=$(dirname "$(readlink -f "${0}")")
# shellcheck source=config.sh
source "${script_path}/config.sh"

partition_and_mount_disk() {
    echo "start=2048,type=83" | sfdisk "/dev/${disk}"

    # Nuke the partition header
    dd if=/dev/urandom of="/dev/${disk}1" bs=1M count=4
    # Clear it to avoid potential misidentification
    dd if=/dev/zero of="/dev/${disk}1" bs=1M count=4

    mkfs.ext4 "/dev/${disk}1"
    mount "/dev/${disk}"1 /mnt
}

create_and_enable_swap() {
    fallocate -l "${swap_size}" /mnt/swapfile
    chmod 0600 /mnt/swapfile
    mkswap /mnt/swapfile
    swapon /mnt/swapfile
}

# Check root
[[ "$(id -u)" == "0" ]] || (echo "Need root"; exit 1)

timedatectl set-ntp true
partition_and_mount_disk
if [[ -v swap_size ]]; then
    create_and_enable_swap
fi

if [[ -v pacman_mirror ]]; then
    echo "Server = ${pacman_mirror}" > "/etc/pacman.d/mirrorlist"
fi

# Install packages
grep -v "^#" "${script_path}/packages.list" | xargs pacstrap /mnt

echo "autoarch stage1 complete"
