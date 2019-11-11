# autoarch

`autoarch` provides basic scripts to perform an automated install of
[Arch Linux](https://archlinux.org) in a virtual machine.

Main git repository: <https://git.esotericnonsense.com/pub/autoarch.git>

Sourcehut:           <https://git.sr.ht/~esotericnonsense/autoarch>

GitLab:              <https://gitlab.com/esotericnonsense/autoarch.git>

GitHub:              <https://github.com/esotericnonsense/autoarch.git>

## Contact

Daniel Edgecumbe (esotericnonsense)

[autoarch@esotericnonsense.com](mailto:autoarch@esotericnonsense.com)

## Usage

To build the ISO, enter the `build` directory and run `sudo ./build.sh`.
Root permissions are required in order for the correct permissions to be
set within the built image.

The built ISO will by default be placed in `/tmp/archiso-out`.

By default, this ISO will use the install script present in the repo it is
built from. By modifying `build/config.sh` prior to building, a remote
repository can be specified which will be cloned at runtime.

More options are available in `install/config.sh` for configuration of the
installed system.

## Important note

The created ISO will _completely erase_ the contents of the disk you point it
at (e.g. `vda` by default) without confirmation prior to installation.

Consider yourself warned.

## License

`autoarch` is subject to the GNU GPLv2 only, contained in the document
LICENSE.GPLv2 which should be distributed with the software.
