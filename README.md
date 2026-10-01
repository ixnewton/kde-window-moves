# kde-window-moves
A KDE window movement/resize/zoom/minimise script using kdotool for reference positioning of windows in KDE/Plasma 5.27+ and Plasma 6 desktops on Wayland. kdotool is an xdotool-like utility built on KWin scripting, so the window controls that xdotool provided on X11 work here without XWayland quirks. The original X11/xdotool version is kept as window-moves-xdo.sh for reference.

At the outset the aim was to provide a reliable way to position windows with keyboard shorcuts using KDE's khotkeys. The discovery of xdotool gives the opportunity to automate some useful moves without too much sweat; under Wayland kdotool provides the window controls and ydotool provides the pointer control that xdotool used to.

I like to have windows aligned left, right or centred but not neccesarily full screen in a repeatable way. Removing the fiddle of mouse or trackpad actions to grab the window and move or resize. Equally I like to clear the clutter on the desktop and minimise all open windows except the window currently in focus. I have tried to assign consistent intuitive key combinations for any of these actions.

## How it works

- The active window is queried with kdotool: id, name, geometry and the current pointer position.
- The screen the window sits on is selected from the kscreen-doctor geometry output, so the functions work on any monitor in a multi-monitor arrangement; calculated positions are offset by that screen's origin.
- Window type detection: KDE/QT applications (Konsole, Dolphin, Kate, Kwrite, Krusader, Vivaldi, Postman, KDevelop, Code - OSS, System Settings, System Monitor, Octopi etc) get a header_height compensation of 30px; all other windows use the default margins.
- All moves and resizes are issued through kdotool (KWin scripting). A short pause (sync_delay) is inserted between paired resize/move calls - without it KWin drops one of the two operations.
- The order of the paired operations is chosen so any transient is off-screen: when moving down the window is moved before it is shrunk, when moving up it is grown before it is moved, so the bottom edge never shows a gap at the bottom margin.
- After every move or resize the screen cursor is repositioned with ydotool relative moves so it keeps the same relative position on the window and does not lose the window's focus.

## Pointer control requirements (Wayland)

kdotool can read the cursor position but cannot set it, and KWin's scripting API currently has no cursor setter, so pointer repositioning is done with ydotool:

1. Install ydotool and start/enable the daemon: `systemctl --user enable --now ydotool`
2. The user needs read/write access to /dev/uinput (udev grants this to the logged-in user on most distributions, otherwise add the user to the input group).
3. Give the ydotoold virtual device a Flat acceleration profile so relative moves are 1:1 (the physical mouse keeps its own profile):

        kwriteconfig6 --file kcminputrc --group "Libinput" --group "2333" --group "6666" --group "ydotoold virtual device" --key PointerAccelerationProfile 2

   then re-apply with `qdbus org.kde.KWin /KWin reconfigure` or re-login.

## Installation

The script should be placed in /usr/local/bin and set executable 755. The repository layout mirrors this: usr/local/bin/window-moves.sh.

The shortcuts depend on khotkeys being installed so make sure it is there in your package manager. Using the KDE System Settings > Shortcuts > Custom Shortcuts dialogue import the WindowMoves.khotkeys file to create a keymapping group. Due to rework of how shortcuts are set for applications "Custom Shortcuts" has become effectively an additional application. To get everything working the new way it may be necessary reset to defaults the main shortcuts and reload custom shortcut groups/folders from saved .khotkeys files. Once backups of your custom shortcuts are saved delete "Custom Shortcuts" in the "System" part of Shortcuts then set all shortcuts to defaults. To restore custom shortcuts re-apply saved shortcut files including WindowMoves.khotkeys and all should be well. In my case this resolved non functional Ctrl+Z, Ctrl+X, Ctrl+Y shortcuts in key editors like Kate.

## The mapping scheme

All actions: `<Ctrl> + <Shift> + ...` except width which uses `<Ctrl> + {` and `<Ctrl> + }`. The navigation keys `<Left> <Right> <Up> <Down> c (center)` are reasonably intuitive to learn. Window zoom is implemented in sequential steps as `<Ctrl> + <Shift> + w ` (increase) and `<Ctrl> + <Shift> + q ` (decrease), height as `<Ctrl> + <Shift> + e ` (decrease) and `<Ctrl> + <Shift> + r ` (increase), width expand as `<Ctrl> + <Shift> + Return` and minimise all as `<Ctrl> + <Shift> + m `.

| Keys | Command | Action |
| --- | --- | --- |
| Ctrl+Shift+Left | moveL | Move left |
| Ctrl+Shift+Right | moveR | Move right |
| Ctrl+Shift+C | moveC | Move centre |
| Ctrl+Shift+Up | topM | Top margin minus |
| Ctrl+Shift+Down | topP | Top margin plus |
| Ctrl+{ | widthM | Width minus |
| Ctrl+} | widthP | Width plus |
| Ctrl+Shift+E | heightP | Height minus (bottom edge up) |
| Ctrl+Shift+R | heightM | Height plus (bottom edge down) |
| Ctrl+Shift+W | zoomP | Zoom plus |
| Ctrl+Shift+Q | zoomM | Zoom minus |
| Ctrl+Shift+Return | expandP | Expand width about the window position |
| Ctrl+Shift+M | minimize | Minimise all but the focussed window |

Standard KDE global shortcuts group "kwin" can be given alternative key mappings for instance minimize window `<Ctrl> + <Shift> + n ` and close window `<Ctrl> + <Shift> + b ` to be in line with this scheme.

## The command parameters

`window-moves.sh moveL` - Moves window to left margin (3px) horizontally with 3 margin steps (6/24/72px) then centre

`window-moves.sh moveR` - Moves window to right margin (3px) horizontally with 3 margin steps then centre

`window-moves.sh moveC` - Moves window to centre horizontally

`window-moves.sh zoomP` - Zoom increasing in steps of 42px height with width proportional to the window aspect until the window fills the screen inside the margins

`window-moves.sh zoomM` - Zoom decreasing in the same steps down to a minimum of 800x450

`window-moves.sh widthP` - Adjusts width increasing in 42 steps of the screen width, sticky at the margins

`window-moves.sh widthM` - Adjusts width decreasing in 42 steps of the screen width, sticky at the margins

`window-moves.sh heightM` - Adjusts height of window bottom down in 42 steps of the remaining screen height

`window-moves.sh heightP` - Adjusts height of window bottom up in 42 steps

`window-moves.sh topP` - Moves window down in steps of 15px, the bottom edge is pinned at the bottom margin (3px)

`window-moves.sh topM` - Moves window up in steps of 15px, the bottom edge is pinned at the bottom margin

`window-moves.sh expandP` - Expands the window width symmetrically about its position, toggling between the expanded width and the saved width

`window-moves.sh minimize` - Minimizes all but the focussed window

One behaviour implemented in widthM/widthP/topM/topP is that left, right and bottom edges are sticky so when a window is close to the margin zone this edge is static and expansion is then relative to the "sticky" edge.

KDE remembers the size and position of application windows so they re-open at the last used layout position. window-moves.sh can quickly set preferred layouts for most applications.

The set of example key combinations can be a starting point for any preferred scheme.

I favour minimal window borders with only the header and borderless sides and footer, one of the nicer style ideas we can copy from MacOS! There may be position issues if side/bottom borders are used as an additional margin fix would have to be applied for the left window border of GTK windows.

One thing I use to help unify the appearance and to some extent behaviour of GTK styled windows is gtk3-nocsd which replaces any GTK header with the desktop QT style. This should be installed to work with the latest update of window-moves.sh. Available from your package manager (pacman, yum, apt etc) or https://github.com/PCMan/gtk3-nocsd .
