# getNF

## A better way to install NerdFonts

### Dependencies

- curl
- unzip
- fontconfig

### Installation

```
git clone https://github.com/ronniedroid/getnf.git
cd getnf
./install.sh
```

Make sure that `~/.local/bin` is in your PATH

### Usage

run `getnf -h` to get a help message.

- run `getnf` from the terminal and it will represent you with a list of Nerd Fonts,
- choose one font at a time from the list.
- Type `i` to install the selected fonts or `q` to  cancel.

By default the downloaded zip files are removed,
use the `-k` flag to keep the zip files in the downloads directory.

By default, the already installed fonts are not listed in the select menu,
unless there is a new version of Nerd Fonts.
You can force reinstalling a font by using the `-f` flag.

Enjoy!
