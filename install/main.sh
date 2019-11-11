#!/usr/bin/env bash
# autoarch/install/main.sh
# The autoarch automatic installation script.
# See 'config.sh' for configuration parameters.
set -euxo pipefail

script_path=$(dirname "$(readlink -f "${0}")")
# shellcheck source=config.sh
source "${script_path}/config.sh"

bash "${script_path}/stage1.sh"

cp -a "${script_path}/"{config.sh,stage2.sh,packages.list} "/mnt/root/"
arch-chroot "/mnt" bash "/root/stage2.sh"
rm -f "/mnt/root/"{config.sh,stage2.sh,packages.list}

cp -a "${script_path}/"{config.sh,stage3.sh} "/mnt/home/${user}/"
systemd-nspawn -D /mnt \
    sudo -u "${user}" bash -c "pushd \${HOME}; ./stage3.sh; popd"
rm -f "/mnt/home/${user}/"{config.sh,stage3.sh}

echo "Installation complete."
