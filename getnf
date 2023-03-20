#!/bin/bash

#defining variables
nerdfontsrepo='https://api.github.com/repos/ryanoasis/nerd-fonts'
aFontInstalled="False"
removeZipFiles="True"
dist_dir="$HOME/.local/share/fonts"
down_dir="$(command -V xdg-user-dir &>/dev/null && xdg-user-dir DOWNLOAD || echo "$HOME/Downloads")/NerdFonts"
cache_dir="$HOME/.cache/nerdFonts"
update_fonts="False"
force_update="False"
os=$(uname)

# For Macs, need to set a few different things
if [[ "$os" == 'Darwin' ]]; then
	dist_dir="$HOME/Library/Fonts"
	cache_dir="$HOME/Library/Caches/NerdFonts"
fi

# help message
usage() {
	echo -e "\e[34mgetNF: A Better way to install NerdFonts\e[0m"
	echo ""
	echo -e "\e[34mUsage:\e[0m"
	echo -e "\e[34m-h print this help message and exit"
	echo -e "-f force reinstall an already installed font"
	echo -e "-k Keep the downloaded fonts zip files\e[0m"
	echo ""
	echo -e "- \e[34mChoose one font at a time from a list of Nerd Fonts"
	echo -e "- Type \e[32mi\e[0m \e[34mto install the selected fonts"
	echo -e "- Or \e[31mq\e[0m \e[34mto cancel\e[0m"
	echo ""
}

# Setting flags
while getopts :hkf option; do
	case "${option}" in
	h) usage && exit 0 ;;
	k) removeZipFiles="False" ;;
	f) force_update="True" ;;
	*) usage && exit 0 ;;
	esac
done

# Check if the distDir and downDir exists, if it doesn't, create it
[ -d "$dist_dir" ] && echo -e "\e[34mFonts directory exists, good.\e[0m" || (mkdir -p "$dist_dir" && echo -e "\e[32mCreated the fonts directory.\e[0m")
[ -d "$down_dir" ] && echo -e "\e[34mFonts download directory exists, good.\e[0m" || (mkdir -p "$down_dir" && echo -e "\e[32mCreated fonts download directory..\e[0m")
[ -d "$cache_dir" ] || mkdir -p "$cache_dir"

## Handle release version
# Set the name of the file to store the release number
release_file="$cache_dir/release.txt"
# Get the local release version
[ -f "$release_file" ] && cached_release=$(cat "$release_file") || cached_release=""
# Get the latest release number from NerdFonts github repo
release=$(curl --silent "$nerdfontsrepo/releases/latest" |
	awk -F'"' '/tag_name/ {print $4}')
# Compare the latest release number with the cached release number
if [ "$release" != "$cached_release" ]; then
	update_fonts=True
	# Update the cached release number
	echo "$release" >"$release_file"
fi

## Handle the font names
# Download the file list and extract the font names
font_list=$(curl -s "$nerdfontsrepo/contents/patched-fonts?ref=master" |
	awk -F'"' '/name/ {print $4}')
# Convert the list into an array
readarray -t fonts <<<"$font_list"
installed_fonts_file="$cache_dir/installed.txt"
[ -f "$installed_fonts_file" ] && installed_fonts_list=$(cat "$installed_fonts_file") || installed_fonts_list=()
readarray -t installed_fonts <<<"$installed_fonts_list"
# a list of currently selectd fonts
selected_fonts=()

# Remove installed fonts from the list of all fonts
if [[ $update_fonts = "False" ]]; then
	available_fonts=()
	for font in "${fonts[@]}"; do
		if [[ ! " ${installed_fonts[@]} " =~ " ${font} " ]]; then
			available_fonts+=("$font")
		fi
	done
else
	echo "" >"$installed_fonts_file"
	available_fonts=("${fonts[@]}")
fi

function print_selected_fonts() {
	if ((${#selected_fonts[@]} > 0)); then
		echo -e "\e[34mSelected fonts:\e[0m"
		echo -e "\e[34m[\e[0m${selected_fonts[@]}\e[34m]\e[0m"
	fi
}

function remove_selected_fonts() {
	local options=("$@")
	for font in "${selected_fonts[@]}"; do
		options=("${options[@]/$font/}")
	done
	local filtered_options=()
	for option in "${options[@]}"; do
		if [[ -n $option ]]; then
			filtered_options+=("$option")
		fi
	done
	echo "${filtered_options[@]}"
}

function download_font() {
	echo -e "\e[34m$1 download started...\e[0m"
	curl -LJO# "https://github.com/ryanoasis/nerd-fonts/releases/download/$release/$1.zip"
	echo -e "\e[32m$1 download finished\e[0m"
}

function install_font() {
	echo -e "\e[34m$1 instalation started...\e[0m"
	unzip -qqo "$1.zip" -d "$dist_dir"
	echo -e "\e[32m$1 installation finished\e[0m"
}

function remove_zip_files() {
	echo -e "\e[34mRemoving downloaded zip files from $down_dir...\e[0m"
	for font in "${selected_fonts[@]}"; do
		rm $down_dir/$font.zip
	done
	echo -e "\e[32mDownloaded zip files removal suceeded!\e[0m"
}

function update_fonts_cache() {
	echo -e "\e[34mUpdating fc-cache...\e[0m"
	fc-cache -f 2>&1
	echo -e "\e[32mfc-cache: update succeeded!\e[0m"
}

# Prompt the user to select one or more fonts
PS3="Select a font ('i' to install, 'q' to quit): "
while true; do
	# Print the selected fonts if any
	print_selected_fonts
	# Remove already selected fonts from the menu
	if [ $force_update = "True" ]; then
		options=("${fonts[@]}")
	else
		options=("${available_fonts[@]}")
	fi
	options=($(remove_selected_fonts "${options[@]}"))
	# if all the avilable options have been selected, proceed to download and install them.
	if ((${#options[@]} == 0)); then
		echo -e "\e[31mAll available fonts have been selected.\e[0m"
		break
	fi
	# Prompt the user to select a font
	select font in "${options[@]}"; do
		if [[ -n $font ]]; then
			selected_fonts+=("$font")
			break
		elif [[ $REPLY == i ]]; then
			break 2
		elif [[ $REPLY == q ]]; then
			exit
		else
			echo -e "\e[31mInvalid selection. Try again.\e[0m"
		fi
	done
done

# loop over the selected fonts and download them
if ((${#selected_fonts[@]} > 0)); then
	for i in "${selected_fonts[@]}"; do
		pushd "$down_dir" >/dev/null
		download_font $i &&
			install_font $i &&
			echo $i >>"$installed_fonts_file"
		aFontInstalled=True
		popd >/dev/null
	done
else
	echo -e "\e[31mNo fonts were selected selected, exiting.\e[0m"
	exit
fi

# If a font was installed
if [ "$aFontInstalled" = "True" ]; then
	# Update the fonts cache
	update_fonts_cache
	# remove downloaded archives if the option -k was not passed
	if [ "$removeZipFiles" = "True" ]; then
		remove_zip_files
	else
		echo -e "\e[32mThe downloaded zip files can be found in $down_dir\e[0m"
	fi
fi

echo -e "\e[32mAll is done!\e[0m"
