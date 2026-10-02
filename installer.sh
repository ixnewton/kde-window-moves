#!/bin/bash
# installer.sh - install kde-window-moves and run the per-user session setup

set -e

repo="$(cd "$(dirname "$0")" && pwd)"

for tool in kdotool ydotool kscreen-doctor; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "ERROR: $tool is not installed - install it with your package manager and re-run this installer."
        exit 1
    fi
done

# 1. Install the scripts in /usr/local/bin, executable 755 (mirrors the usr/local/bin layout)
if [ "$(id -u)" -eq 0 ]; then
    install -m 755 "$repo/usr/local/bin/window-moves.sh" /usr/local/bin/window-moves.sh
    install -m 755 "$repo/usr/local/bin/kde-window-moves-setup.sh" /usr/local/bin/kde-window-moves-setup.sh
else
    sudo install -m 755 "$repo/usr/local/bin/window-moves.sh" /usr/local/bin/window-moves.sh
    sudo install -m 755 "$repo/usr/local/bin/kde-window-moves-setup.sh" /usr/local/bin/kde-window-moves-setup.sh
fi

# 2. Install the shortcut set as an application (System Settings > Shortcuts > KDE Window Moves)
mkdir -p ~/.local/share/applications
cp "$repo/usr/share/applications/kde-window-moves.desktop" ~/.local/share/applications/
kbuildsycoca6 2>/dev/null

# 3. Per-user session setup: ydotoold, pointer profile and shortcut registration
"$repo/usr/local/bin/kde-window-moves-setup.sh" \
    "$repo/Hotkeys/WindowMovesKeys.kksrc" \
    "$repo/usr/share/applications/kde-window-moves.desktop"

echo "Installed /usr/local/bin/window-moves.sh and configured ydotool."
