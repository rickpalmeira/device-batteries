#!/usr/bin/env bash
set -euo pipefail

id=local.devicebatteries
source_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
target_dir="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/plasmoids"
target="$target_dir/$id"

short() {
    printf '%s' "${1/#"$HOME"/\~}"
}

usage() {
    cat <<EOF
Usage: $(basename "$0") [-s | -r | -h]

Installs the Device Batteries Plasma widget ($id) into
$(short "$target")
replacing any version already there, then restarts plasmashell so the
change takes effect.

With no option, it copies metadata.json and contents/ from this folder.

Options:
  -s  Symlink this folder instead of copying it, so edits here apply
      after the next plasmashell restart.
  -r  Uninstall the widget and restart plasmashell.
  -h  Show this help and exit.

-s and -r cannot be combined.
EOF
}

mode=copy
while getopts ":srh" opt; do
    case $opt in
        s|r)
            [[ $mode == copy ]] || { echo "Use only one of -s and -r." >&2; exit 1; }
            [[ $opt == s ]] && mode=link || mode=remove
            ;;
        h) usage; exit 0 ;;
        *) usage >&2; exit 1 ;;
    esac
done
shift $((OPTIND - 1))
(( $# == 0 )) || { usage >&2; exit 1; }

if [[ ! -L $target && $target -ef $source_dir ]]; then
    echo "Refusing to run: $(short "$target") is this folder itself." >&2
    exit 1
fi

installed() {
    [[ -L $target || -e $target ]]
}

remove_installed() {
    if installed; then
        rm -rf -- "$target"
    fi
}

case $mode in
    copy)
        remove_installed
        mkdir -p "$target"
        cp -r "$source_dir/metadata.json" "$source_dir/contents" "$target/"
        echo "Copied to $(short "$target")"
        ;;
    link)
        remove_installed
        mkdir -p "$target_dir"
        ln -s "$source_dir" "$target"
        echo "Linked $(short "$target") -> $(short "$source_dir")"
        ;;
    remove)
        if ! installed; then
            echo "Not installed at $(short "$target")"
            exit 0
        fi
        remove_installed
        echo "Removed $(short "$target")"
        ;;
esac

if systemctl --user --quiet is-active plasma-plasmashell.service; then
    systemctl --user reset-failed plasma-plasmashell.service
    systemctl --user restart plasma-plasmashell.service
    echo "Restarted plasmashell"
else
    echo "plasmashell is not running; the change applies at next login"
fi
