#!/bin/bash
# SPDX-Copyright: Copyright (c) 2019 Daniel Edgecumbe (esotericnonsense)
# SPDX-License-Identifier: GPL-2.0-only

# autoarch/build/main.sh
# This script builds the archiso used for the automated install.
# It has been adapted from the archiso/baseline.sh script, assumed to be
# compatible with GPLv2.
# Source: https://git.archlinux.org/archiso.git

set -euxo pipefail

script_path=$(dirname "$(readlink -f "${0}")")

iso_name=autoarch
iso_label=autoarch_$(git rev-parse HEAD --git-dir="${script_path}" | head -c 8)
iso_version=$(git rev-parse HEAD --git-dir="${script_path}" | head -c 8)
install_dir=arch
arch=$(uname -m)
work_dir=/tmp/archiso-work
out_dir=/tmp/archiso-out

umask 0022

# Helper function to run make_*() only one time per architecture.
run_once() {
    mkdir -p "${work_dir}"
    if [[ ! -e ${work_dir}/build.${1}_${arch} ]]; then
        local logfile="${work_dir}/build.${1}_${arch}"
        echo "running $1... (see ${logfile})"
        $1 > "${logfile}.stdout" 2> "${logfile}.stderr"
    fi
}

# Base installation (airootfs)
make_basefs() {
    mkarchiso -v -w "${work_dir}" -D "${install_dir}" init
}

# Install necessary dependencies that are no longer in the base group
make_install_kernel() {
    mkarchiso -v -w "${work_dir}" -D "${install_dir}" -p linux install
}

# Copy mkinitcpio archiso hooks and build initramfs (airootfs)
make_setup_mkinitcpio() {
    mkdir -p ${work_dir}/airootfs/etc/initcpio/hooks
    mkdir -p ${work_dir}/airootfs/etc/initcpio/install
    cp /usr/lib/initcpio/hooks/archiso ${work_dir}/airootfs/etc/initcpio/hooks
    cp /usr/lib/initcpio/install/archiso ${work_dir}/airootfs/etc/initcpio/install

    cat << EOF > "${work_dir}/airootfs/etc/mkinitcpio-archiso.conf"
HOOKS=(base udev archiso block filesystems)
EOF

    mkarchiso -v -w "${work_dir}" -D "${install_dir}" -r 'mkinitcpio -c /etc/mkinitcpio-archiso.conf -k /boot/vmlinuz-linux -g /boot/archiso.img' run
}

# Enable autologin on tty1
make_autologin() {
    mkdir -p "${work_dir}/airootfs/etc/systemd/system/getty@tty1.service.d"
    cat << EOF > "${work_dir}/airootfs/etc/systemd/system/getty@tty1.service.d/autologin.conf"
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I 38400 linux
EOF
}

make_networking() {
    local iface
    iface="ens1"
    cat << EOF > "${work_dir}/airootfs/etc/systemd/network/20-wired.network"
[Match]
Name=${iface}

[Network]
DHCP=ipv4
EOF

    mkarchiso -v -w "${work_dir}" -D "${install_dir}" -r "systemctl enable systemd-networkd.service systemd-networkd-wait-online.service systemd-resolved.service" run
}

# Uncomment the servers in the mirrorlist and randomise their order
make_pacman_mirrorlist() {
    local mirrorlist
    mirrorlist="${work_dir}/airootfs/etc/pacman.d/mirrorlist"
    cat "${mirrorlist}" | grep "Server" | sed 's/^#Server/Server/g' | sort -R \
        > "${mirrorlist}.new"
    mv "${mirrorlist}.new" "${mirrorlist}"
}

# Initialize pacman-key
make_pacman_key_init() {
    mkarchiso -v -w "${work_dir}" -D "${install_dir}" -r "pacman-key --init" run
    mkarchiso -v -w "${work_dir}" -D "${install_dir}" -r "pacman-key --populate archlinux" run
}

make_clone_installer_at_run_time() {
    cat << EOF > "${work_dir}/airootfs/root/autorun.sh"
#!/usr/bin/env bash
set -uxo pipefail
git clone "http://github.com/esotericnonsense/autoarch.git" "\${HOME}/autoarch"
bash "\${HOME}/autoarch/install/main.sh"
EOF
}

make_clone_installer_at_build_time() {
    git clone "https://github.com/esotericnonsense/autoarch.git" "${work_dir}/airootfs/root/autoarch"
    cat << EOF > "${work_dir}/airootfs/root/autorun.sh"
#!/usr/bin/env bash
set -uxo pipefail
bash "\${HOME}/autoarch/install/main.sh"
EOF
}

# Set up automatic install 
make_setup_automatic_install() {
    mkarchiso -v -w "${work_dir}" -D "${install_dir}" \
        -p arch-install-scripts -p git install

    # Automatically run the installer on boot
    cat << EOF > "${work_dir}/airootfs/root/.profile"
#!/usr/bin/env bash
set -uxo pipefail

if [[ \$(tty) == "/dev/tty1" ]]; then
    bash "\${HOME}/autorun.sh"
fi
EOF


    # Option 1
    make_clone_installer_at_run_time
    # Option 2
    #make_clone_installer_at_build_time

    chmod +x "${work_dir}/airootfs/root/autorun.sh"
}

# Prepare ${install_dir}/boot/
make_boot() {
    mkdir -p "${work_dir}/iso/${install_dir}/boot/${arch}"
    cp "${work_dir}/airootfs/boot/archiso.img" "${work_dir}/iso/${install_dir}/boot/${arch}/archiso.img"
    cp "${work_dir}/airootfs/boot/vmlinuz-linux" "${work_dir}/iso/${install_dir}/boot/${arch}/vmlinuz"
}

# Prepare /${install_dir}/boot/syslinux
make_syslinux() {
    mkdir -p ${work_dir}/iso/${install_dir}/boot/syslinux
    sed "s|%ARCHISO_LABEL%|${iso_label}|g;
         s|%INSTALL_DIR%|${install_dir}|g;
         s|%ARCH%|${arch}|g" "${script_path}/syslinux/syslinux.cfg" > "${work_dir}/iso/${install_dir}/boot/syslinux/syslinux.cfg"
    cp "${work_dir}/airootfs/usr/lib/syslinux/bios/ldlinux.c32" "${work_dir}/iso/${install_dir}/boot/syslinux/"
    cp "${work_dir}/airootfs/usr/lib/syslinux/bios/menu.c32" "${work_dir}/iso/${install_dir}/boot/syslinux/"
    cp "${work_dir}/airootfs/usr/lib/syslinux/bios/libutil.c32" "${work_dir}/iso/${install_dir}/boot/syslinux/"
}

# Prepare /isolinux
make_isolinux() {
    mkdir -p ${work_dir}/iso/isolinux
    sed "s|%INSTALL_DIR%|${install_dir}|g" "${script_path}/isolinux/isolinux.cfg" > "${work_dir}/iso/isolinux/isolinux.cfg"
    cp "${work_dir}/airootfs/usr/lib/syslinux/bios/isolinux.bin" "${work_dir}/iso/isolinux/"
    cp "${work_dir}/airootfs/usr/lib/syslinux/bios/isohdpfx.bin" "${work_dir}/iso/isolinux/"
    cp "${work_dir}/airootfs/usr/lib/syslinux/bios/ldlinux.c32" "${work_dir}/iso/isolinux/"
}

# Build airootfs filesystem image
make_prepare() {
    mkarchiso -v -w "${work_dir}" -D "${install_dir}" prepare
}

# Build ISO
make_iso() {
    mkarchiso -v -w "${work_dir}" -D "${install_dir}" -L "${iso_label}" -o "${out_dir}" iso "${iso_name}-${iso_version}-${arch}.iso"
}

# Check root
[[ "$(id -u)" == "0" ]] || (echo "Need root"; exit 1)

# First nuke the working directories
rm -rf "${out_dir}"
rm -rf "${work_dir}"

run_once make_basefs
run_once make_install_kernel
run_once make_setup_mkinitcpio
run_once make_networking
run_once make_autologin
run_once make_pacman_mirrorlist
run_once make_pacman_key_init
run_once make_setup_automatic_install
run_once make_boot
run_once make_syslinux
run_once make_isolinux
run_once make_prepare
run_once make_iso
