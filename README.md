![getnf-logo](https://github.com/getnf/getnf/assets/9327361/60822070-8e14-43ae-882c-f36d36b6e4f0)


# `getnf` - Get Nerd Fonts

<!-- [![getnf](https://img.shields.io/github/v/release/getnf/getnf?style=flat-square)](https://github.com/getnf/getnf/releases/latest) -->
[![getnf](https://img.shields.io/github/last-commit/getnf/getnf?style=flat-square)](https://github.com/getnf/getnf/pulse)
[![getnf](https://img.shields.io/github/issues/getnf/getnf?style=flat-square)](https://github.com/getnf/getnf/issues)
[![getnf](https://img.shields.io/github/license/getnf/getnf?style=flat-square)](https://github.com/getnf/getnf/blob/master/LICENSE)
[![getnf](https://img.shields.io/github/stars/getnf/getnf?style=flat-square)](https://github.com/getnf/getnf/stargazers)

Easily install [Nerd Fonts](https://www.nerdfonts.com/) from the terminal.

![image](https://github.com/getnf/getnf/assets/84108846/e60e12d7-5b30-41f9-a95e-742df72ff2b8)

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

Run `getnf` to show the font menu.

There are several flags available:

| Flag                                             | Description                              |
| ------------------------------------------------ | ---------------------------------------- |
| `-h`                                             | Show the help message                    |
| `-k`                                             | Keep the downloaded font archives        |
| `-a`                                             | Include installed Nerd Fonts in the menu |
| `-l`                                             | List installed Nerd Fonts                |
| `-L`                                             | List all Nerd Fonts                      |
| `-i <font>`                                      | Directly install a specified Nerd Font   |
| `-i <name1>,<name2>`,<br> `-i "<name1> <name2>"` | Directly install multiple Nerd Fonts     |
| `-u <font>`                                      | Uninstall a specified Nerd Font          |
| `-u <name1>,<name2>`,<br> `-u "<name1> <name2>"` | Uninstall multiple Nerd Fonts            |
| `-U`                                             | Update all installed Nerd Fonts          |
| `-V`                                             | Print the current version of `getnf`     |

You can get the exact names of the fonts to use with `-i` and `-u` from `getnf -L`.

Enjoy!
