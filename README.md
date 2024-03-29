# getNF

## A better way to install NerdFonts

### Dependencies

- curl
- fontconfig

### Installation

```
curl -fsSL https://raw.githubusercontent.com/getnf/getnf/main/install.sh | bash
```

Make sure that `~/.local/bin` is in your PATH.

#### Arch Linux

Arch Linux users can install the package from the [AUR](https://aur.archlinux.org/packages/getnf):
```
paru -S getnf
```

### Usage

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

To uninstall fonts use the `-u` flag with the same syntax as for direct install.

Enjoy!

### Notes

You can suppress the installation output with a flag `--silent` or `-s`:
```
curl -fsSL https://raw.githubusercontent.com/getnf/getnf/main/install.sh | bash -s -- --silent
```
