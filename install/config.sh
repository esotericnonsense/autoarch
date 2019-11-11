#!/usr/bin/env bash
# SPDX-Copyright: Copyright (c) 2019 Daniel Edgecumbe (esotericnonsense)
# SPDX-License-Identifier: GPL-2.0-only

# autoarch/install/config.sh
# Configuration variables for the autoarch install script.
set -euxo pipefail

# The ethernet interface used for networking.
export iface="ens1"

# The timezone of the installed system.
export timezone="Europe/London"

# The hostname of the installed system.
export hname="automatic"

# The locale of the installed system.
export userlocale="en_US.UTF-8"

# The disk that will be formatted to install Arch.
export disk="vda"

# The username of the created account.
export user="archuser"

# The initial password of the created account.
export initial_pass="changeme"

# OPTIONAL: An SSH key that will be added to the created account.
export ssh_key="ssh-ed25519 ABCDE example"

# OPTIONAL: A custom SSH port to be used instead of the default 22.
export ssh_port="10022"

# OPTIONAL: A pacman mirror that will be used instead of the defaults.
export pacman_mirror="http://pacman.lan/archlinux/\$repo/os/\$arch"

# OPTIONAL: Create a swap file of this size on the installed system.
export swap_size="2G"

# OPTIONAL: A dotfiles repository that will be executed as the created account.
# The repository should contain a `main.sh` file that will perform all of the
# necessary symlinking.
export dotfiles_repo="http://gitolite.lan/dotfiles.git"
