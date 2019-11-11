#!/usr/bin/env bash
# SPDX-Copyright: Copyright (c) 2019 Daniel Edgecumbe (esotericnonsense)
# SPDX-License-Identifier: GPL-2.0-only

# autoarch/install/stage3.sh
# This stage runs within the chroot as the created user.
set -euxo pipefail

script_path=$(dirname "$(readlink -f "${0}")")
# shellcheck source=config.sh
source "${script_path}/config.sh"

# Check username
[[ "$(whoami)" == "${user}" ]]

# Install dotfiles
if [[ -v dotfiles_repo ]]; then
    mkdir -p "${HOME}/git"
    git clone "${dotfiles_repo}" "${HOME}/git/dotfiles"
    bash "${HOME}/git/dotfiles/main.sh"
fi

echo "autoarch stage3 complete"
