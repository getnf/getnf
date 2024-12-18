![getnf-logo](https://github.com/getnf/getnf/assets/9327361/60822070-8e14-43ae-882c-f36d36b6e4f0)


# `getnf` - Get Nerd Fonts

<!-- [![getnf](https://img.shields.io/github/v/release/getnf/getnf?style=flat-square)](https://github.com/getnf/getnf/releases/latest) -->
[![getnf](https://img.shields.io/github/last-commit/getnf/getnf?style=flat-square)](https://github.com/getnf/getnf/pulse)
[![getnf](https://img.shields.io/github/issues/getnf/getnf?style=flat-square)](https://github.com/getnf/getnf/issues)
[![getnf](https://img.shields.io/github/license/getnf/getnf?style=flat-square)](https://github.com/getnf/getnf/blob/master/LICENSE)
[![getnf](https://img.shields.io/github/stars/getnf/getnf?style=flat-square)](https://github.com/getnf/getnf/stargazers)

Easily install [Nerd Fonts](https://www.nerdfonts.com/) from the terminal.

![image](https://github.com/getnf/getnf/assets/84108846/55e535ea-73af-417f-b65d-7c095d58bdf0)

## Supported Platforms
`getnf` is supported on macOS and Linux.

## Requirements
- curl
- fzf *(optional)*

## Installation
Make sure that `~/.local/bin` is in your PATH.

Run

```
curl -fsSL https://raw.githubusercontent.com/getnf/getnf/main/install.sh | bash
```
to install the latest version of `getnf`, or install a specific [release](https://github.com/getnf/getnf/releases) with
its tag, e.g. `v0.2.0`:
```
curl -fsSL https://raw.githubusercontent.com/getnf/getnf/main/install.sh | bash -s -- --tag=v0.2.0
```

You can suppress the installation output with the flag `--silent` or `-s`:
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

| Flag                                             | Description                                                                |
| ------------------------------------------------ | -------------------------------------------------------------------------- |
| `-h`                                             | Show the help message                                                      |
| `-k`                                             | Keep the downloaded font archives                                          |
| `-a`                                             | Include installed Nerd Fonts in the menu                                   |
| `-g`                                             | Install/Uninstall/List/Update Nerd Fonts for all users                     |
| `-l`                                             | List installed Nerd Fonts                                                  |
| `-L`                                             | List all Nerd Fonts                                                        |
| `-f`                                             | Select and install Nerd Fonts using [fzf](https://github.com/junegunn/fzf) |
| `-i <font>`                                      | Directly install a specified Nerd Font                                     |
| `-i <name1>,<name2>`,<br> `-i "<name1> <name2>"` | Directly install multiple Nerd Fonts                                       |
| `-u <font>`                                      | Uninstall a specified Nerd Font                                            |
| `-u <name1>,<name2>`,<br> `-u "<name1> <name2>"` | Uninstall multiple Nerd Fonts                                              |
| `-U`                                             | Update all installed Nerd Fonts                                            |
| `-V`                                             | Print the current version of `getnf`                                       |

You can get the exact names of the fonts to use with `-i` and `-u` from `getnf -L`.

Enjoy!

## Notes
In case you can't see newly installed fonts in your application, you may need to update the font cache with
```
fc-cache
```
