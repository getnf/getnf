# getNF

## A better way to install NerdFonts

### Dependencies

- curl
- fontconfig
- ncurses
- unzip

### Installation

```
curl -fsSL https://raw.githubusercontent.com/getnf/getnf/main/install.sh | bash
```

Make sure that `~/.local/bin` is in your PATH.

#### Arch Linux

Arch linux users can install the package from the AUR:
```
yay -S getnf
```

### Usage

Run `getnf -h` to get a help message.

- run `getnf` from the terminal and it will present you with a list of Nerd Fonts
- choose one or more fonts (by index/number) to install
- hit Return/Enter to install the selected fonts
- type 'q' to quit

By default the downloaded zip files are removed,
use the `-k` flag to keep the zip files in the downloads directory.

By default, the already installed fonts are not listed in the select menu,
unless there is a new version of Nerd Fonts.
You can force reinstalling a font by using the `-f` flag.

If you know the exact font you want to install,
you can do it directly with `getnf -i <font-name>`.<br>
Use `getnf -i <name1>,<name2>` or `getnf -i "<name1> <name2>"`
to install multiple fonts.<br>
You can get the names of the fonts from the menu.

Enjoy!

### Notes

You can suppress the installation output with a flag `--silent` or `-s`:
```
curl -fsSL https://raw.githubusercontent.com/getnf/getnf/main/install.sh | bash -s -- --silent
```
