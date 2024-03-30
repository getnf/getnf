# `getnf` - Get Nerd Fonts

<!-- [![getnf](https://img.shields.io/github/v/release/getnf/getnf?style=flat-square)](https://github.com/getnf/getnf/releases/latest) -->
[![getnf](https://img.shields.io/github/last-commit/getnf/getnf?style=flat-square)](https://github.com/getnf/getnf/pulse)
[![getnf](https://img.shields.io/github/issues/getnf/getnf?style=flat-square)](https://github.com/getnf/getnf/issues)
[![getnf](https://img.shields.io/github/license/getnf/getnf?style=flat-square)](https://github.com/getnf/getnf/blob/master/LICENSE)
[![getnf](https://img.shields.io/github/stars/getnf/getnf?style=flat-square)](https://github.com/getnf/getnf/stargazers)

Easily install Nerd Fonts from the terminal.

## Supported Platforms
`getnf` is supported on macOS and Linux.

## Prerequisites

- curl
- fontconfig *(only on Linux)*

## Installation

```
curl -fsSL https://raw.githubusercontent.com/getnf/getnf/main/install.sh | bash
```

Make sure that `~/.local/bin` is in your PATH.

You can suppress the installation output with a flag `--silent` or `-s`:
```
curl -fsSL https://raw.githubusercontent.com/getnf/getnf/main/install.sh | bash -s -- --silent
```

### Packages

On Arch Linux you can install `getnf` from the [AUR](https://aur.archlinux.org/packages/getnf):
```
paru -S getnf
```

## Usage

Run getnf to display the list of available Nerd Fonts and install the selected ones.

Run `getnf -h` to get the help message.

- run `getnf` from the terminal and it will present you with the list of Nerd Fonts
- choose one or more fonts (by index/number) to install
- hit Return/Enter to install the selected fonts
- type 'q' to quit

By default the downloaded font archives are removed,
use the `-k` flag to keep the font archives in the downloads directory.

By default, the already installed fonts are not listed in the font menu,
unless there is a new version of Nerd Fonts available.
You can force reinstalling fonts by using the `-f` flag.

If you know the exact font you want to install,
you can do it directly with `getnf -i <font-name>`.<br>
Use `getnf -i <name1>,<name2>` or `getnf -i "<name1> <name2>"`
to install multiple fonts.<br>
You can get the names of the fonts from the menu.

To uninstall fonts use the `-r` flag with the same syntax as for direct install.

To update getnf to the latest version available use `-u` in isolation before doing anything else 

Enjoy!
