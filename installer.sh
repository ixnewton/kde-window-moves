#!/bin/bash
# installer.sh - install kde-window-moves and configure ydotool for Wayland pointer control

set -e

repo="$(cd "$(dirname "$0")" && pwd)"

for tool in kdotool ydotool kscreen-doctor; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "ERROR: $tool is not installed - install it with your package manager and re-run this installer."
        exit 1
    fi
done

# 1. Install the script in /usr/local/bin, executable 755 (mirrors the usr/local/bin layout)
if [ "$(id -u)" -eq 0 ]; then
    install -m 755 "$repo/usr/local/bin/window-moves.sh" /usr/local/bin/window-moves.sh
else
    sudo install -m 755 "$repo/usr/local/bin/window-moves.sh" /usr/local/bin/window-moves.sh
fi

# 2. Start/enable the ydotoold daemon for the logged-in user
systemctl --user enable --now ydotool

# 3. The user needs read/write access to /dev/uinput (udev grants this to the logged-in
#    user on most distributions, otherwise add the user to the input group)
if [ ! -w /dev/uinput ]; then
    echo "WARNING: no read/write access to /dev/uinput."
    echo "         Add the user to the input group, then log out and back in:"
    echo "             sudo usermod -aG input $USER"
fi

# 4. Give the ydotoold virtual device a Flat acceleration profile so relative moves are 1:1
#    (the physical mouse keeps its own profile)
kwriteconfig6 --file kcminputrc --group "Libinput" --group "2333" --group "6666" \
    --group "ydotoold virtual device" --key PointerAccelerationProfile 2

# Re-apply the input settings without re-login
if ! qdbus org.kde.KWin /KWin reconfigure 2>/dev/null; then
    echo "NOTE: run 'qdbus org.kde.KWin /KWin reconfigure' or re-login to apply the acceleration profile."
fi

# 5. Install the shortcut set as an application (System Settings > Shortcuts > KDE Window Moves)
mkdir -p ~/.local/share/applications
cp "$repo/usr/share/applications/kde-window-moves.desktop" ~/.local/share/applications/
kbuildsycoca6 2>/dev/null

echo "Installed /usr/local/bin/window-moves.sh and configured ydotool."
echo "Registered 'KDE Window Moves' application with its 13-shortcut set."
echo "Assign the shortcuts via System Settings > Shortcuts > KDE Window Moves."
