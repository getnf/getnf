# getNF

## A better way to install NerdFonts

### Dependencies

- curl
- fontconfig
- ncurses
- unzip

### Installation

```
bash <(curl -fsSL https://raw.githubusercontent.com/ronniedroid/getnf/master/install.sh)
```

Make sure that `~/.local/bin` is in your PATH.

### Usage

Run `getnf -h` to get a help message.

- run `getnf` from the terminal and it will present you with a list of Nerd Fonts
- choose one or more fonts (by index/number) to install
- hit Return/Enter to install the selected fonts
- type the index/number corresponding to 'Quit' to cancel

By default the downloaded zip files are removed,
use the `-k` flag to keep the zip files in the downloads directory.

By default, the already installed fonts are not listed in the select menu,
unless there is a new version of Nerd Fonts.
You can force reinstalling a font by using the `-f` flag.

Enjoy!
