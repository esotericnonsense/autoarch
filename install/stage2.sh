#!/usr/bin/env bash
# autoarch/install/stage2.sh
# This stage runs within the chroot as the root user.
set -euxo pipefail

script_path=$(dirname "$(readlink -f "${0}")")
# shellcheck source=config.sh
source "${script_path}/config.sh"

setup_networking() {
    cat << EOF > "/etc/systemd/network/20-wired.network"
[Match]
Name=${iface}

[Network]
DHCP=ipv4 
EOF

    systemctl enable systemd-networkd.service
    systemctl enable systemd-networkd-wait-online.service
    systemctl enable systemd-resolved.service
}

set_timezone() {
    ln -sf "/usr/share/zoneinfo/${timezone}" /etc/localtime
    hwclock --systohc
}

set_hostname() {
    echo "${hname}" > /etc/hostname
}

set_locale() {
    echo "${userlocale} UTF-8" > /etc/locale.gen
    locale-gen
    echo "LANG=${userlocale}" > /etc/locale.conf
}

install_bootloader() {
    syslinux-install_update -iam
    cat << EOF > "/boot/syslinux/syslinux.cfg"
PROMPT 0
DEFAULT arch

LABEL arch
	LINUX ../vmlinuz-linux
	INITRD ../initramfs-linux.img
	APPEND root=/dev/${disk}1 rw init=/usr/lib/systemd/systemd
EOF
}

create_user() {
    useradd -m -G wheel -s /bin/bash "${user}"
    echo "${user}:${initial_pass}" | chpasswd
}

install_sudo() {
    cat << EOF > "/etc/sudoers" 
root ALL=(ALL) ALL
%wheel ALL=(ALL) ALL
EOF
}

install_ssh() {
    if [[ -v ssh_port ]]; then
        sed -i "s/^#Port 22/Port ${ssh_port}/g" "/etc/ssh/sshd_config"
    fi

    # Disable password authentication
    sed -i "s/^#PasswordAuthentication yes/PasswordAuthentication no/g" \
        "/etc/ssh/sshd_config"
    sed -i "s/^UsePAM yes/UsePAM no/g" \
        "/etc/ssh/sshd_config"

    systemctl enable sshd.service

    mkdir -p "/home/${user}/.ssh"

    if [[ -v ssh_key ]]; then
        echo "${ssh_key}" > "/home/${user}/.ssh/authorized_keys"
    else
        touch "/home/${user}/.ssh/authorized_keys"
    fi

    chown -R "${user}:${user}" "/home/${user}/.ssh"
    chmod 0400 "/home/${user}/.ssh/authorized_keys"
    chmod 0700 "/home/${user}/.ssh"
}

install_aur_packages() {
    echo "TODO universal-ctags-git"
}

# Check root
[[ "$(id -u)" == "0" ]] || (echo "Need root"; exit 1)

setup_networking
set_hostname
set_timezone
set_locale

install_bootloader
create_user
install_sudo
install_ssh

install_aur_packages

echo "autoarch stage2 complete"
