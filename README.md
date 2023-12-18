# getNF

## A better way to install NerdFonts

### Dependencies

- curl
- fontconfig
- ncurses
- unzip

### Installation

```
curl -fsSL https://raw.githubusercontent.com/ronniedroid/getnf/master/install.sh | bash
```

Make sure that `~/.local/bin` is in your PATH.

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

Enjoy!

### Notes

You can suppress the installation output with a flag `--silent` or `-s`:
```
curl -fsSL https://raw.githubusercontent.com/ronniedroid/getnf/master/install.sh | bash -s -- --silent
```
